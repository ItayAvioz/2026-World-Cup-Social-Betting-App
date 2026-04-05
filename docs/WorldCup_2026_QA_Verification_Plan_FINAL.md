# WorldCup 2026 — Full QA Verification Plan (FINAL)

## Context

App is feature-complete (React SPA + Supabase, 38 migrations, 2 EFs). Full A-to-Z verification before launch: DB, RLS, business logic, frontend, integrations, E2E. Then pull real data from API Football.

**Scope**: QA + API data pull. Nightly-summary EF deferred to a future session.
**Test target**: Local dev server (`npm run dev` → localhost:4178)
**Tools**: MCP Playwright (browser), MCP Supabase (execute_sql), code review
**API Football key**: User will provide — data pull is Step 2 of this session
**Google Stitch**: User will provide MCP URL/package — UX/UI review tool (integrated when available, not blocking)

---

## Pre-Verified Bugs to Fix

### BUG 1 — CRITICAL: Top Scorer Manual Picks Never Earn Points
- **Location**: `Picks.jsx:254,259` — `top_scorer_api_id: null` hardcoded
- **Impact**: `fn_calculate_pick_points` (M38) checks `WHERE top_scorer_api_id = ANY(v_top_scorer_ids)` — null never matches
- **Auto-assigned picks** (M37) correctly set API IDs (Mbappé=278, Haaland=1100, Messi=154, etc.) — only these can earn points
- **Fix**: Add API IDs to STRIKERS array in Picks.jsx; pass them in save handler

### BUG 2 — HIGH: Auto-Predict Lost Contrarian Logic
- **Location**: M30 `fn_auto_predict_game` replaced M24/M25 contrarian with simple `random()*6`
- **Expected behavior**: Count existing W/D/L predictions → pick the LEAST popular outcome → generate score matching that outcome
- **Example**: If fewest predicted "USA loses", auto-predict should generate a score where USA loses
- **Fix**: Merge M24/M25 contrarian logic back into M30's per-group structure

### BUG 3 — HIGH: Ungrouped Users Get No Auto-Predictions
- **Location**: M30 `fn_auto_predict_game` only loops `group_members` — ungrouped users skipped
- **M36 comment**: "Auto-predict still only covers grouped"
- **Fix**: Add ungrouped user loop (same pattern as M37 `fn_auto_assign_picks`)

### BUG 4 — MEDIUM: Game Page Requires Group Context
- **Location**: `Game.jsx:120-124` — no `?group=` param → "No group context" toast
- **Impact**: Users arriving via direct URL/bookmark cannot submit predictions
- **Fix**: Auto-select first group, or show group picker on Game page

### BUG 5 — HIGH: Invite Flow — Join Dialog Not Pre-Filled for Logged-In Users
- **Location**: `js/auth.js` handles `?invite=CODE` for new registrations, but logged-in users clicking an invite link are not auto-joined
- **Expected**: Logged-in user clicks `?invite=ABC123` → auto-calls `join_group('ABC123')` → redirects to Groups
- **Fix**: Add invite code detection in `AuthContext.jsx` or `App.jsx` on mount

### Stale Docs (flag during QA, fix after)
- `docs/SDK_PATTERNS.md` — shows old `onConflict: 'user_id'` pattern, missing `group_id`
- `docs/PAGE_SPECS.md` — references vanilla HTML pages (groups.html, picks.html), not React components
- Migration 32 — deployed via MCP without physical .sql file in `supabase/migrations/`

---

## Agent 1: DB Integrity (MCP Supabase execute_sql)

### Pass 1 — Structure
- [ ] All 17 tables exist with correct columns/types
- [ ] All CHECK, UNIQUE, FK constraints present
- [ ] RLS enabled on all user-facing tables
- [ ] All 25+ RLS policies with correct conditions
- [ ] 104 games: group=48, r32=16, r16=8, qf=4, sf=2, third=1, final=1
- [ ] 3 views queryable
- [ ] All 15 RPCs exist
- [ ] All 10 triggers exist
- [ ] 5 test users + test groups in correct state

### Pass 2 — Business Logic

**Scoring (fn_calculate_points)**:
- [ ] Exact match (2-1 pred / 2-1 actual) → 3 pts
- [ ] Correct outcome only (2-1 pred / 3-0 actual, both home win) → 1 pt
- [ ] Wrong outcome (2-1 pred / 0-0 actual) → 0 pts
- [ ] Draw prediction matches draw result → 1 pt (if not exact)
- [ ] Exact draw (0-0 pred / 0-0 actual) → 3 pts
- [ ] NOT additive: exact = 3, not 3+1=4
- [ ] Score correction: re-update score → points recalculated (idempotent)

**Champion scoring (fn_calculate_pick_points)**:
- [ ] Pick team='Brazil', final knockout_winner='Brazil' → 10 pts
- [ ] Change knockout_winner to 'France' → Brazil picks reset to 0, France picks get 10
- [ ] Re-trigger same winner → same result (idempotent)

**Top scorer scoring with ties**:
- [ ] 3 players tied at max goals → ARRAY_AGG collects all 3 api_player_ids
- [ ] User picked any of the 3 (with valid api_id) → 10 pts
- [ ] User picked non-top (with valid api_id) → 0 pts
- [ ] User picked with api_id=NULL (manual pick) → 0 pts (BUG 1 confirmation)
- [ ] Auto-assigned pick with real api_id → CAN earn 10 pts

**RPC error handling** (every named exception):
- [ ] create_profile: 'username_taken' (duplicate)
- [ ] create_profile: 'invalid_username' (<3 chars, special chars)
- [ ] create_group: 'invalid_name' (empty)
- [ ] create_group: 'max_groups_reached' (user has 3 groups already)
- [ ] join_group: 'invalid_invite_code' (bad code)
- [ ] join_group: 'already_member' (already in group)
- [ ] join_group: 'group_full' (10 members)
- [ ] delete_account: 'account_locked' (after June 11)
- [ ] delete_account: 'cannot_delete_in_group' (user in any group)
- [ ] get_group_leaderboard: 'not_a_member' (non-member query)

**Per-group uniqueness**:
- [ ] Duplicate (user, game, group) prediction → constraint violation
- [ ] Duplicate (user, group) champion_pick → constraint violation
- [ ] Duplicate (user, NULL) champion_pick → NULLS NOT DISTINCT violation

**Auto-predict (M30 deployed)**:
- [ ] Verify uses simple random 0-5 (NOT contrarian — BUG 2)
- [ ] Verify per-group: one prediction per (user_id, group_id)
- [ ] Verify ungrouped users SKIPPED (BUG 3)
- [ ] Verify self-unschedule after firing

**Auto-assign picks (M37)**:
- [ ] Grouped user missing champion → random team, is_auto=true
- [ ] Grouped user missing top scorer → random player WITH api_id, is_auto=true
- [ ] Ungrouped user missing both → assigned with group_id=NULL
- [ ] Partial: picked champion but NOT scorer → only scorer assigned
- [ ] ON CONFLICT DO NOTHING (idempotent)

**Cascade chains**:
- [ ] auth.users DELETE → profiles, predictions, picks, group_members CASCADE
- [ ] groups DELETE → group_members, ai_summaries, failed_summaries CASCADE
- [ ] groups.created_by DELETE → SET NULL (group survives)

**Constraints**:
- [ ] group_name NOT NULL iff phase='group'
- [ ] All invite codes unique, 6-char, uppercase alphanumeric
- [ ] games.phase IN ('group','r32','r16','qf','sf','third','final')
- [ ] predictions.pred_home/pred_away ≥ 0
- [ ] profiles.username: 3-20 chars, alphanumeric + underscore

**Leaderboard logic**:
- [ ] get_leaderboard(): one row per (user × group)
- [ ] User in 2 groups → 2 rows with independent scores
- [ ] Ungrouped user → one row (group_name = NULL)
- [ ] RANK() with ties: same pts = same rank, numbering skips
- [ ] get_group_leaderboard(): group_rank + global_rank correct

### Pass 3 — Security
- [ ] Cross-user RLS: alice can't read bob's pre-KO predictions
- [ ] Cross-group RLS: alice can't see non-member group data
- [ ] Deadline RLS: profiles UPDATE rejects after 2026-06-11T19:00:00Z
- [ ] Deadline RLS: champion_pick INSERT/UPDATE rejects after deadline
- [ ] Deadline RLS: predictions INSERT/UPDATE rejects after game KO
- [ ] SECURITY DEFINER audit: all 12+ functions that need it
- [ ] Views are SECURITY INVOKER (M26)
- [ ] Mutual exclusivity trigger: grouped user → can't insert NULL group_id pick
- [ ] Captain self-inactive guard: M25 WITH CHECK `user_id != auth.uid()`
- [ ] pg_cron: 104 auto-predict + 1 sync-odds-daily + 1 auto-assign-picks
- [ ] Vault: app_edge_function_url + app_service_role_key exist

---

## Agent 2: Auth & Permissions (Playwright + execute_sql)

### Pass 1 — Happy Path
- [ ] Landing page renders: hero, countdown, groups, register form
- [ ] Register: username + email + password → redirect to app.html#/dashboard
- [ ] Login: existing user → redirect to dashboard
- [ ] Session persists on page refresh
- [ ] Sign out: gear → profile sheet → sign out → redirect to index.html
- [ ] Session guard: no session + app.html → redirect to index.html
- [ ] Invite flow (new user): `?invite=CODE` → register → auto-join → redirect to groups
- [ ] Invite flow (logged-in user): `?invite=CODE` → auto-join → redirect to groups (BUG 5)

### Pass 2 — Error States
- [ ] Register: duplicate email → error toast
- [ ] Register: invalid username (<3 chars) → error
- [ ] Register: empty fields → HTML validation
- [ ] Login: wrong password → error toast
- [ ] Login: non-existent email → error toast
- [ ] Invite: invalid code → join fails silently (non-blocking)
- [ ] Invite: logged-in user with valid code → auto-join (BUG 5 check)
- [ ] Route wildcard: #/nonexistent → redirect to /dashboard
- [ ] Profile fallback: user without profile → AuthContext re-creates

### Pass 3 — Security & Deadlines (Dual-Layer)

**Client-side** (verify UI disabled state):
- [ ] Dashboard: username rename disabled after deadline
- [ ] Dashboard: delete account disabled after deadline
- [ ] Groups: group rename hidden after deadline
- [ ] Picks: champion/scorer form disabled after deadline
- [ ] Game: prediction form disabled after kick_off_time

**Server-side backstop**:
- [ ] Direct INSERT champion_pick after deadline → RLS rejects
- [ ] Direct UPDATE profiles.username after deadline → RLS rejects
- [ ] Direct INSERT prediction after game KO → RLS rejects

**Isolation**:
- [ ] Cannot see non-member group data
- [ ] Cannot see pre-KO predictions of other users
- [ ] No service role key in frontend code

**Account lifecycle**:
- [ ] Delete: not in group + before deadline → success
- [ ] Delete: in group → 'cannot_delete_in_group'
- [ ] Delete: after deadline → 'account_locked'

---

## Agent 3: Frontend UX (Playwright)

### Pass 1 — All Pages Render (login as alice)

**Dashboard**:
- [ ] Trophy hero + countdown clock (ticking)
- [ ] Global leaderboard table with data
- [ ] Current user row highlighted
- [ ] Next games cards
- [ ] Profile gear → sheet (rename, delete, sign out)
- [ ] My Stats per group (rank, champion pick, scorer, streak)

**Groups**:
- [ ] Group tabs + per-group leaderboard
- [ ] Focus game with prediction entry
- [ ] Invite link copy button
- [ ] "Join" + "+ Create" buttons
- [ ] Member list with captain badge + inactive toggle
- [ ] Member count badge "N/10"

**Game**:
- [ ] Team flags + names + phase label
- [ ] Pre-KO: prediction form (inputs, submit button)
- [ ] Odds section (pre-KO, within 3 days)
- [ ] Team tournament stats
- [ ] is_auto badge (⚡) for auto-predictions

**Picks**:
- [ ] Picks/Predictions tab switcher
- [ ] Group selector pills
- [ ] Champion: searchable 48 teams + 6 TBD (greyed)
- [ ] Top scorer: searchable 30 players
- [ ] Save buttons functional
- [ ] Predictions tab: games by phase with inline entry

**AiFeed**:
- [ ] Group selector
- [ ] "No summaries yet" empty state (expected — nightly-summary not built)
- [ ] Daily standings section
- [ ] Share button

**Bottom nav**: All 4 tabs navigate with active highlight

### Pass 2 — All States

**Loading** → skeleton on every page
**Empty** (user with no groups):
- [ ] Dashboard: no group ranks
- [ ] Groups: template preview + Join/Create
- [ ] Picks: "Join a group first"
- [ ] AiFeed: "Join or create a group"

**Error** → retry buttons on every page

**Locked**:
- [ ] Picks: lock icon, disabled form, read-only saved pick
- [ ] Game: "Locked" after KO
- [ ] Dashboard: rename disabled after deadline

**Score display** (Game.jsx):
- [ ] Group stage FT: "2–1" (90-min only)
- [ ] Knockout FT (no ET): "2–1"
- [ ] Knockout AET: "1–1" + ET "2–1"
- [ ] Knockout PEN: "1–1" + ET "2–2" + PEN "4–3"
- [ ] knockout_winner displayed for knockout games
- [ ] Points: "3 pts (exact)" / "1 pt (outcome)" / "0 pts"

**TBD games**:
- [ ] Knockout with TBD teams renders "TBD"
- [ ] Cannot predict TBD games
- [ ] No team stats for TBD

**Mobile (375x667)**:
- [ ] Bottom nav fits
- [ ] Touch targets ≥ 48px
- [ ] No horizontal scroll
- [ ] Modals work on mobile

### Pass 3 — Interactions

**Prediction flow**:
- [ ] Enter → save → toast → display saved
- [ ] Edit → modify → save → toast updated
- [ ] Invalid input (negative, NaN) → validation error
- [ ] Rapid double-click → no duplicate rows

**Champion pick**:
- [ ] Search "Bra" → Brazil shown
- [ ] Select → save → toast
- [ ] Change team → save → upsert updates
- [ ] TBD slots disabled

**Top scorer pick**:
- [ ] Search "Mba" → Mbappé shown
- [ ] Select → save → toast (NOTE: api_id=null — BUG 1)

**Group operations**:
- [ ] Create group → appears immediately
- [ ] 4th group → button disabled + "max 3" tooltip
- [ ] Join with valid code → success
- [ ] Join full group → "group is full" toast
- [ ] Copy invite → clipboard contains correct URL

**Captain operations**:
- [ ] Toggle inactive → confirm step → applies
- [ ] Captain's own row: NO toggle button shown
- [ ] Group rename: works before deadline, blocked after

**AiFeed**:
- [ ] Expand/collapse summary
- [ ] Reaction toggle on/off
- [ ] Group tab switch → reload
- [ ] Share → clipboard

---

## Agent 4: Integration & E2E (Playwright + execute_sql)

### Pass 1 — Core Journeys

**J1: Register → Join → Predict → Leaderboard**
- [ ] Navigate with ?invite=CODE → register → auto-join
- [ ] Navigate to Groups → verify group + leaderboard
- [ ] Click game → enter prediction → save
- [ ] Verify DB: prediction row exists with correct group_id
- [ ] Dashboard: leaderboard shows new user
- [ ] Picks: save champion + top scorer
- [ ] Verify DB: picks saved

**J2: Captain Flow**
- [ ] Create group → copy invite code
- [ ] Second user joins via code
- [ ] Captain toggles inactive → DB reflects
- [ ] Captain reactivates → DB reflects
- [ ] Captain cannot toggle self

**J3: Multi-Group Scoring**
- [ ] User in multiple groups → independent picks per group
- [ ] Leaderboard: one row per (user, group)
- [ ] Picks page: group tabs work independently

**J4: Prediction Reveal**
- [ ] Pre-KO: predictions hidden from others
- [ ] Post-KO: group members' predictions visible
- [ ] Global prediction stats shown

**J5: Score → Points → Leaderboard**
- [ ] Insert prediction → service role updates game score
- [ ] Verify trigger calculated points
- [ ] Dashboard leaderboard reflects new points

### Pass 2 — Cross-Layer

- [ ] Dual-layer deadline enforcement (client + RLS) for all 5 deadline types
- [ ] Game page with ?group= → prediction saves correctly
- [ ] Game page without ?group= → error (BUG 4)
- [ ] Profile rename → reflected in leaderboard
- [ ] Invite code case insensitive (lowercase → uppercased)
- [ ] Score display consistent across Dashboard, Groups, Game, Picks

### Pass 3 — Security & Stress

- [ ] Two contexts (alice + bob): isolation verified
- [ ] Rapid clicks: no duplicates
- [ ] Invalid URL params: graceful errors
- [ ] All Supabase requests have auth header
- [ ] Auto-predict end-to-end: set KO to past → call fn → verify ⚡ badge in UI

---

## Agent 5: Edge Functions (execute_sql + code review)

### Pass 1 — Deployment
- [ ] football-api-sync active (v9)
- [ ] sync-odds active (v8)
- [ ] Cron: 104 auto-predict + 1 sync-odds-daily + 1 auto-assign
- [ ] Vault: app_edge_function_url + app_service_role_key present
- [ ] FOOTBALL_API_KEY NOT set (expected pending)
- [ ] theoddsapi NOT set (expected pending)

### Pass 2 — Logic
- [ ] Team name normalization: list all DB team names, flag diacritics (Curaçao, Ivory Coast)
- [ ] Score write matrix: FT / AET / PEN → correct columns
- [ ] Retry params: +5min / +40min ET / +10min rate limit
- [ ] Cron expression format for fn_schedule_game_sync
- [ ] api_fixture_id: all NULL (expected before setup mode)

### Pass 3 — Readiness
- [ ] EF auth: service role key required
- [ ] Check EF logs for errors
- [ ] Idempotency: re-run setup/sync → no duplicates
- [ ] nightly-summary NOT deployed (confirmed, deferred)

---

## Execution Plan

```
Phase 0: npm run dev → localhost:4178 running ✅
Phase 1: Agent 1 (DB) + Agent 5 (EF) — parallel [both execute_sql, no browser]
Phase 2: Agent 2 (Auth) + Agent 3 (UX) — parallel [both Playwright, different flows]
Phase 3: Agent 4 (E2E) — sequential [depends on Phase 1-2]
Phase 3.5: Google Stitch UX review — if user provides MCP details (non-blocking)
Phase 4: Aggregate → full report (issues / solutions / improvements / missing)
Phase 5: Fix bugs (BUG 1-5 + anything found during QA)
Phase 6: API Football data pull (user provides key)
```

---

## Step 2: API Football Data Pull

### Prerequisites
1. User provides RapidAPI key for api-football.com v3
2. `supabase secrets set FOOTBALL_API_KEY=<key> --project-ref ftryuvfdihmhlzvbpfeu`
3. Test: `curl -H "x-rapidapi-key: <key>" "https://v3.football.api-sports.io/status"`

### Execution
1. **Setup mode**: POST football-api-sync `{"mode":"setup"}` → map api_fixture_id
2. **Verify mappings**: check how many games got mapped (~48 group stage)
3. **Schedule syncs**: `SELECT fn_schedule_game_sync(id) FROM games WHERE kick_off_time > now() AND api_fixture_id IS NOT NULL`
4. **Set odds key**: `supabase secrets set theoddsapi=<key>`
5. **Register odds cron**: `SELECT fn_schedule_odds_sync()`
6. **Test odds sync**: manually invoke → verify game_odds populated

---

## Report Format

### 1. Executive Summary
Total checks, pass/fail/warning, readiness score

### 2. Issues Table
| # | Severity | Domain | Description | Expected | Actual | Fix |

### 3. Solutions
Per issue: root cause, fix, effort

### 4. Improvements
Not bugs — enhancements worth doing

### 5. Missing Items
Features not yet built

### 6. Pre-Launch Checklist
Actionable items with checkboxes
