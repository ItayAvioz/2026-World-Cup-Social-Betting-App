# WorldCup 2026 — Delta QA Report (2026-04-05)

**Scope:** Changes since last report (2026-04-03) at football-api-sync v10 / sync-odds v8 / M38.
**Current state:** football-api-sync **v24**, sync-odds **v12**, migrations through **M50 + 1 phantom**.
**Method:** 4-phase review (inventory → focused tests → 3-way cross-check → report).

---

## 1. Executive Summary

| Area | Delta Scope | Status |
|---|---|---|
| Migrations | M39 → M50 + 1 phantom (12 total) | ✅ All deployed |
| football-api-sync | v10 → v24 (14 versions, 10 modes) | ✅ Deployed + verified live |
| sync-odds | v8 → v12 (4 versions, champion mode rewrite) | ✅ Deployed + verified live |
| Frontend | Game.jsx stats, Picks.jsx champion_odds + top_scorer_api_id | ✅ Built to dist/ (fresh) |
| Crons | af-odds-daily registered; sync-odds-daily + champion-odds-daily unscheduled | ✅ Aligned to plan |
| Memory docs | 3 files stale or contradictory | ⚠️ Needs update |
| Data | 9 La Liga games pollute production | ⛔ Block launch |

**Readiness:** Not launch-ready — 4 blockers, 3 mediums, 5 minors.

---

## 2. Delta Inventory (Phase A)

### 2.1 Migrations deployed since last report

| # | Name | Deployed As | Physical File | Content |
|---|---|---|---|---|
| 39 | qa_fixes | 20260401xxx | ✅ | api_fixture_id, pick_points SECURITY DEFINER, NULL score reset, captain guard, auto_predict ungrouped, stale cleanup |
| 40 | qa_fixes_round2 | 20260401xxx | ✅ | Player API IDs (Kane=184, Vinicius=5765, etc.), summary scoped to group |
| 41 | contrarian_auto_assign_picks | 20260402xxx | ✅ | fn_auto_assign_picks rewritten contrarian |
| 42 | c1_c2_contrarian_predict_rls_fix | 20260402xxx | ✅ | fn_auto_predict_game contrarian restored; predictions SELECT uses is_group_member |
| 43 | max_3_groups_total_membership | 20260402xxx | ✅ | total membership check; tournament deadline on join |
| 44 | fn_schedule_ai_summaries_vault | 20260402xxx | ✅ | reads vault.decrypted_secrets |
| 45 | teams_and_players_tables | 20260402xxx | ✅ | `teams` (42 + 6 TBD), `top_scorer_candidates` (30) |
| 46 | stats_enrichment | 20260403133652 | ✅ | +shots_insidebox, +xg, +position, +rating, +gk_saves, +gk_conceded |
| 47 | odds_champion | 20260403133707 | ✅ | game_odds +over_2_5 +under_2_5; champion_odds table |
| 48 | odds_cleanup | 20260405101632 | `20260405000048_odds_cleanup.sql` | unschedule sync-odds-daily + champion-odds-daily |
| 49 | add_avg_offsides_to_tournament_stats | 20260405093312 | `20260405000049_avg_offsides_tournament_stats.sql` | team_tournament_stats view +avg_offsides |
| 50 | game_events | 20260405120304 | `20260405000050_game_events.sql` | game_events table + RLS |
| **phantom** | passes_stats | 20260405120733 | ❌ **NO FILE** | game_team_stats +passes_total +passes_accuracy |

**M49 IS deployed** (verified: `team_tournament_stats.avg_offsides` column exists). Memory/supabase/CLAUDE.md both claim "NOT deployed" — stale.

### 2.2 Edge Function version deltas

**football-api-sync v10 → v24:**
- v11–v17: Teams/players table integration, contrarian logic, cron infra
- v18: `writeStats` merges team + player stats fetch; **VAR-correct red_cards** derived from player cards.red sum
- v19: `handleSyncAfOdds` mode added, prefers Bet365 ID 8, `source='bet365'`
- v22: +passes_total, +passes_accuracy in writeStats (API key = 'Total passes' / 'Passes %')
- v23–v24: game_events writer, TEAM_ALIASES map (6 entries), setup_lineups path, additional modes
- **10 modes exposed:** setup, verify, sync, handleSyncAfOdds, snap_stats, events, lineups, setup_lineups, probe, schedule

**sync-odds v8 → v12:**
- v9–v11: probe mode, bookmaker filtering
- v12: champion mode filters `b.title === 'William Hill'`, single row per team in champion_odds
- **Dead code retained:** handleDefaultSync (135 lines) still runs on body-less POST — TheOddsAPI game odds pipeline is dead (replaced by API Football Bet365)

### 2.3 Frontend deltas (verified at `src/`)

- `src/pages/Game.jsx` — delta stats rendered: passes_total, passes_accuracy, shots_insidebox, xg, offsides. Odds panel shows over/under 2.5.
- `src/pages/Picks.jsx`:
  - Loads top_scorer_candidates from DB (M45)
  - Champion section displays `champion_odds` column with William Hill odds
  - Line 227: `top_scorer_api_id: selPlayer.apiId ?? null` — **partial fix with NULL fallback (see Issue #4)**
  - Line 54 of Game.jsx: `searchParams.get('group')` — **no fallback (see Issue #3)**
- `dist/` rebuild: ✅ Fresh (`dist/app.html` timestamp > latest `src/*.jsx` timestamp)

### 2.4 Cron state

| Cron | Status | Notes |
|---|---|---|
| af-odds-daily (07:15 UTC) | ✅ Active | API Football Bet365 1X2 + OU 2.5 |
| sync-odds-daily | ❌ Unscheduled (M48) | TheOddsAPI game odds dead |
| champion-odds-daily | ❌ Unscheduled (M48) | Moved to cron-job.org external |
| Champion odds (cron-job.org) | ✅ Active | Expires 2026-06-11 |
| auto-predict crons (104) | ✅ Active | One per game |
| auto-assign-picks (1) | ✅ Active | Deadline job |
| **snap2–snap6 polling (16)** | ⚠️ **Still active** | Apr 5 test on 4 La Liga games — 17 cron rows still registered |
| **sync_game for La Liga (5)** | ⚠️ **Still active** | Test fixture syncs never cleaned up |

Total cron jobs: **128**.

---

## 3. Phase B — Test Results

### 3.1 DB integrity (Pass/Fail)

✅ All M46–M50 columns present + correctly typed
✅ game_events table exists with correct CHECK + UNIQUE + RLS
✅ champion_odds table: 47 rows (William Hill single source)
✅ game_odds bet365 rows: 4 (upcoming games)
✅ team_tournament_stats.avg_offsides exists (M49 confirmed deployed)
✅ Views remain SECURITY INVOKER (M26 preserved)
✅ RLS captain self-guard preserved on group_members
✅ Predictions SELECT RLS uses `is_group_member(group_id)` (M42)
✅ fn_auto_assign_picks contrarian logic present (verified via prosrc)
✅ fn_auto_predict_game contrarian logic present with grouped + ungrouped loops
✅ fn_schedule_ai_summaries reads vault (M44)
✅ Mutual exclusivity trigger `check_pick_group_consistency` present
✅ UNIQUE NULLS NOT DISTINCT on predictions + picks preserved

### 3.2 Live EF behavior (Atletico 1–2 Barcelona, fixture 1391110)

Verified via browser evaluate on `/game/663c19b4...`:
- Score: **1–2 FT** ✅
- Possession: 33% / 67% ✅
- **Total Passes: 307 / 630** ✅ (v22 field)
- **Passes Accuracy: 80% / 92%** ✅ (v22 field)
- Shots: 6 / 22; On Target: 2 / 8; **Inside Box: 4 / 15** ✅ (M46)
- Corners: 1 / 9; Fouls: 15 / 11
- Yellow: 6 / 2; **Red: 1 / 0** ✅ (v18 VAR correction — Barcelona red_card reverted from 1 → 0 after player-row derivation)
- **Offsides: 4 / 3** ✅
- **xG: 0.92 / 2.22** ✅ (M46)
- Events rendered: G. Simeone 39' ⚽, M. Rashford 42' ⚽, N. González 45+7' 🟥, R. Lewandowski 87' ⚽ ✅ (M50 game_events)

### 3.3 Live EF behavior (upcoming — Alaves vs Osasuna)

- Odds panel renders: **Home 2.60 / Draw 3.20 / Away 2.80** ✅ (af-odds)
- **Under 2.5: 1.67, Over 2.5: 2.20** ✅ (M47 + v19 af-odds)
- Prediction form renders ✅

### 3.4 Picks page — champion_odds + BUG 1

- Champion Odds column renders populated with William Hill odds (Spain 5.5x, France 6.5x, England 6.5x, Argentina 9.0x, Brazil 9.0x, Germany 13.0x, etc.) ✅
- **Austria + United States show blank champion_odds** (real teams, expected populated) ⚠️
- **BUG 1 partial regression test:** selected Bukayo Saka (NULL api_player_id in candidates) → clicked Save Pick → toast "Top scorer pick saved!" → DB row shows `top_scorer_api_id = NULL, is_auto = false` — **still unsaveable as scoring pick**

### 3.5 BUG 4 — Game page without ?group= param

Direct navigation to `/game/<id>` with no query string:
- **Finished game:** Renders read-only (score, stats, events) — OK behavior
- **Upcoming game (Alaves–Osasuna):** Prediction form renders. Entering 1–2 and clicking Predict → toast **"No group context — open this game from your Groups page"** → save fails silently → **bug confirmed**

### 3.6 Dashboard + Groups smoke

- Dashboard: leaderboard, today's games list (3 La Liga + Getafe 2–0 Athletic), countdown clock ✅
- Groups: Test group (4/10 members), invite code 21DAHG, leaderboard includes alice/bob/carol/Itay_Avioz, focus game shows Valencia vs Celta Vigo with prediction stats ✅
- No runtime errors in either page ✅

---

## 4. Phase C — 3-Way Cross-Check (Code vs Memory vs Docs)

### Memory drift

| Location | Claim | Reality | Severity |
|---|---|---|---|
| `memory/MEMORY.md:44` | "49: avg_offsides NOT deployed" | Deployed as 20260405093312 | High |
| `memory/MEMORY.md:45` | "football-api-sync v22 ACTIVE" | v24 | Medium |
| `memory/edge-function-phase.md:8` | "v22 + v12 DEPLOYED" | v24 + v12 | Medium |
| `memory/edge-function-phase.md:7–10` | Claims M50 = passes_stats | M50 physical file = game_events; passes_stats is phantom (no file) | High |
| `supabase/CLAUDE.md:61` | "Migration 49 ⏳ NOT YET DEPLOYED" | Deployed | High |
| `supabase/CLAUDE.md:62` | "Migration 50 (20260405000050_passes_stats.sql)" | File is `20260405000050_game_events.sql`; passes_stats is phantom | High |
| `supabase/CLAUDE.md:65` | "football-api-sync v22" | v24 | Medium |

### Docs drift

| File | Issue |
|---|---|
| `docs/SDK_PATTERNS.md:30-34` | Predictions upsert uses `onConflict: 'user_id,game_id'` — missing `group_id` (since M30) |
| `docs/SDK_PATTERNS.md:45-48` | Champion upsert uses `onConflict: 'user_id'` — should be `'user_id,group_id'` (since M29) |
| `docs/SDK_PATTERNS.md:51-54` | Top scorer upsert uses `onConflict: 'user_id'` — same issue |
| `docs/PAGE_SPECS.md` | References legacy vanilla HTML pages |
| `docs/PLAN_API_SYNC.md` | Predates v18–v24 changes |

### Orphan physical file risk

Migration 32 pattern (MCP `apply_migration` without physical file) recurred:
- `20260405120733 passes_stats` — phantom. If anyone runs `supabase db reset` locally, this migration will not replay, leaving the local DB missing `game_team_stats.passes_total` + `passes_accuracy` columns.

---

## 5. Issues Table

| # | Severity | Domain | Description | Fix |
|---|---|---|---|---|
| 1 | ⛔ Blocker | Data | 9 La Liga games (phase='group') pollute production tables. 18 team_stats rows, 286 player_stats rows, 13 events, 4 bet365 odds all La Liga. Games: Rayo–Elche, Real Sociedad–Levante, Mallorca–Real Madrid, Real Betis–Espanyol, Atletico–Barcelona, Getafe–Athletic, Valencia–Celta, Oviedo–Sevilla, Alaves–Osasuna | Delete via cascade once stats validation complete |
| 2 | ⛔ Blocker | Data integrity | Phantom migration `passes_stats` (20260405120733) has no physical file. Local DB resets will lose passes_total + passes_accuracy columns | Create `supabase/migrations/20260405120733_passes_stats.sql` to match deployed state |
| 3 | ⛔ Blocker | BUG 4 (frontend) | `Game.jsx:54` requires `?group=` URL param. Navigating to a bookmarked/shared game link → Predict → toast "No group context". Users cannot predict from direct URLs | Auto-select user's first group if param missing; or show group picker |
| 4 | ⛔ Blocker | BUG 1 partial (frontend) | `Picks.jsx:227` uses `selPlayer.apiId ?? null`. 3 candidates have NULL api_player_id in DB: **Antoine Griezmann, Bukayo Saka, Kai Havertz**. Manual picks of these 3 save as `top_scorer_api_id = NULL` — `fn_calculate_pick_points` ANY() check never matches → 0 pts guaranteed | Backfill api_player_id for those 3 OR reject save in UI OR set `is_active=false` |
| 5 | 🟡 Medium | Test data | 21 La Liga test crons still active (16 snap2–6 + 5 sync_game for La Liga games). Will re-fire in future if not cleaned up | `SELECT cron.unschedule(jobid) FROM cron.job WHERE jobname LIKE 'snap%' OR jobname LIKE 'sync_game_%'` |
| 6 | 🟡 Medium | Memory | 3 memory files stale: MEMORY.md (v22, M49 not deployed), edge-function-phase.md (M50 mislabeled), supabase/CLAUDE.md (M49 pending, M50 wrong file) | Update to reflect v24 + M49 deployed + M50 = game_events + phantom = passes_stats |
| 7 | 🟡 Medium | Dead code | `sync-odds/index.ts` retains `handleDefaultSync` (135 lines) for TheOddsAPI game odds. Dead pipeline still callable on body-less POST | Remove function + update mode dispatcher to reject missing mode |
| 8 | 🟢 Minor | Docs | `docs/SDK_PATTERNS.md` predictions/picks examples use old `onConflict: 'user_id'` / `'user_id,game_id'` — missing group_id | Update 3 code blocks to include group_id |
| 9 | 🟢 Minor | Data completeness | Austria + United States missing from champion_odds (real teams) | Investigate TheOddsAPI team name mapping for these 2 |
| 10 | 🟢 Minor | Data | `teams` table has 42 real teams + 6 qualifiers = 48. Memory claims "48" consistently — correct, but worth noting teams_real count | None — correct |
| 11 | 🟢 Minor | Docs | `docs/PAGE_SPECS.md` + `docs/PLAN_API_SYNC.md` predate v18–v24 | Refresh after launch |
| 12 | 🟢 Minor | Data | 20 snap polling crons had a purpose (Apr 5 polling test) — confirm CSV captured then unschedule | See Issue #5 |

---

## 6. Pre-Launch Checklist

### Must-fix before launch
- [ ] Delete 9 La Liga games + cascade clean game_team_stats, game_player_stats, game_events, game_odds for those IDs
- [ ] Create physical file `supabase/migrations/20260405120733_passes_stats.sql` mirroring deployed phantom
- [ ] Fix BUG 4: Game.jsx auto-selects first group when `?group=` missing
- [ ] Fix BUG 1 (partial): backfill api_player_id for Griezmann, Saka, Havertz (or deactivate)
- [ ] Unschedule 21 La Liga test crons (snap2–6 + sync_game_la_liga)

### Should-fix before launch
- [ ] Remove dead `handleDefaultSync` from sync-odds
- [ ] Update memory files (MEMORY.md, edge-function-phase.md) to match v24 reality
- [ ] Update supabase/CLAUDE.md migrations log to show M49 deployed + phantom passes_stats
- [ ] Fix docs/SDK_PATTERNS.md onConflict examples

### Can defer
- [ ] Investigate Austria + USA champion_odds gap
- [ ] Refresh PAGE_SPECS.md + PLAN_API_SYNC.md
- [ ] Build nightly-summary EF (still in design)
- [ ] Pull real WC 2026 data once API plan upgraded

---

## 7. What's Validated Live

These delta changes are confirmed working end-to-end in the running app:

| Feature | Evidence |
|---|---|
| VAR-correct red_cards | Atletico vs Barcelona: Barcelona 0 (corrected from 1) |
| passes_total + passes_accuracy | 307/80%, 630/92% rendered in Game.jsx |
| shots_insidebox | 4/15 rendered |
| xg | 0.92/2.22 rendered |
| offsides | 4/3 rendered |
| game_events + EF writer | 4 events (3 goals + 1 red) rendered in timeline |
| Bet365 1X2 via af-odds | 2.60/3.20/2.80 on Alaves–Osasuna |
| Over/Under 2.5 via af-odds | 1.67 / 2.20 on Alaves–Osasuna |
| champion_odds William Hill | 47 rows rendered in Picks.jsx column |
| top_scorer_candidates from DB | 30 players loaded dynamically |
| fn_auto_assign_picks contrarian | Verified via prosrc (LEAST popular team/player) |
| fn_auto_predict_game contrarian | Verified via prosrc, covers grouped + ungrouped |
| Predictions SELECT RLS | is_group_member (M42) — cross-group leak fixed |
| Captain self-guard | WITH CHECK preserved (M25 + M39) |
| Vault-based AI scheduling | fn_schedule_ai_summaries reads vault (M44) |

---

## 8. Versions at Report Time

- football-api-sync: **v24** (deployed 2026-04-05)
- sync-odds: **v12** (deployed 2026-04-05)
- Latest migration: **phantom passes_stats** (20260405120733)
- Latest physical migration: **M50 game_events** (20260405000050)
- Frontend: React 18 + Vite, `dist/` fresh build
- 128 cron jobs, 5 test users, 1 test group "Test" (4/10)

---

_Report generated 2026-04-05 via inline MCP tooling after agent-based runs hit API Error 529._
