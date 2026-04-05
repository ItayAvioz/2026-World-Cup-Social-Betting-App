> ⚠️ **STALE (2026-04-05)** — This plan predates EF versions v18–v24 (football-api-sync) and v13–v14 (sync-odds). Architecture has shifted: game 1X2/over-under odds now come from API Football Bet365 (not TheOddsAPI), champion odds moved to cron-job.org external cron, passes/events/xG enrichment added, USA→United States team mapping added. Kept for historical reference. Source of truth: `supabase/functions/*/index.ts`, `supabase/CLAUDE.md`, `memory/edge-function-phase.md`.

# Plan: API Sync Edge Functions + Cron Infrastructure

## Scope

Two Edge Functions + cron infrastructure for automated data pipeline.
Nightly-summary EF is **deferred** — only football-api-sync and sync-odds.

## Deliverables

| File | Purpose |
|---|---|
| `supabase/migrations/20260326000027_api_sync_cron_infrastructure.sql` | pg_cron scheduler SQL functions |
| `supabase/functions/football-api-sync/index.ts` | Score + stats sync from api-football.com |
| `supabase/functions/sync-odds/index.ts` | Daily odds sync from theoddsapi.com |
| `test/test-api-sync.html` | Manual test page for football-api-sync |
| `test/test-odds-sync.html` | Manual test page for sync-odds |

---

## Architecture

### EF Invocation Pattern

Free Supabase = 150s timeout. EFs **never block-poll**. Each invocation makes one API call then:
- Writes result and exits (done), OR
- Schedules a new retry cron +5min (or +40min for ET) and exits

### football-api-sync — 3 Modes

| Mode | Trigger | Action |
|---|---|---|
| `setup` | Manual (once before tournament) | Fetch all fixture IDs from API → map to DB games |
| `verify` | pg_cron 30min before KO | Check API KO time == DB KO time, fix if mismatch |
| `sync` | pg_cron KO+120min + retries | Poll score, write result + stats, schedule retry if not done |

### sync-odds

| Trigger | Action |
|---|---|
| pg_cron daily 07:00 UTC | Fetch 1X2 odds for games in next 3 days → upsert game_odds |

### Cron Lifecycle Per Game

```
api_fixture_id mapped via setup mode
        ↓
fn_schedule_game_sync(game_id)
        ↓
 ┌────────────────────────────────────┐
 │ verify-game-{id}  KO - 30min       │ → verify mode → self-unschedules
 │ sync-game-{id}    KO + 120min      │ → sync mode → self-unschedules
 └────────────────────────────────────┘
        ↓ if game not done (extra time, VAR, etc.)
 retry-sync-{id}-{ts}  +5min         → sync mode → self-unschedules
        ↓ repeat until done
 fn_unschedule_game_sync(game_id)    → cleans up remaining jobs
```

### Knockout ET/Penalty Flow

```
KO+120min → status=FT   → write score + went_to_extra_time=false → done
KO+120min → status=AET  → write score + ET score + winner → done
KO+120min → status=PEN  → write score + ET + pens + winner → done
KO+120min → status=ET   → write 90-min + went_to_extra_time=true → retry +40min
        ↓ +40min
KO+160min → status=AET/PEN → write ET/pen scores + winner → done
```

---

## DB Functions (Migration 27)

| Function | Called By |
|---|---|
| `fn_schedule_game_sync(game_id)` | Manual / after fixture ID mapped |
| `fn_schedule_retry_sync(game_id, stage, delay_min)` | football-api-sync EF |
| `fn_unschedule_game_sync(game_id)` | football-api-sync EF after sync complete |
| `fn_schedule_odds_sync()` | Manual once after EF deployed |

All use pg_cron + pg_net. Service role key read via `current_setting('app.service_role_key')` at runtime (not stored as literal).

---

## Secrets Required

```bash
supabase secrets set FOOTBALL_API_KEY=<rapidapi_key_for_v3.football.api-sports.io>
supabase secrets set ODDS_API_KEY=<theoddsapi.com_key>
```

Auto-available: `SUPABASE_URL`, `SUPABASE_SERVICE_ROLE_KEY`

---

## DB Config (set manually after deploying EFs)

```sql
ALTER DATABASE postgres SET app.edge_function_url = 'https://ftryuvfdihmhlzvbpfeu.supabase.co/functions/v1';
ALTER DATABASE postgres SET app.service_role_key  = '<service_role_key>';
```

---

## API Rate Budget

| API | Free tier | Est. monthly usage |
|---|---|---|
| api-football.com | 100 req/day | ~616 / month |
| theoddsapi.com | — | ~60 / month |

---

## Post-Deploy Setup Order

1. Deploy EFs: `supabase functions deploy football-api-sync sync-odds`
2. Set secrets (above)
3. Set DB config vars (above)
4. Run setup mode → maps api_fixture_id for all 104 games
5. `SELECT fn_schedule_odds_sync();` → registers daily odds cron
6. For each upcoming game: `SELECT fn_schedule_game_sync(id) FROM games WHERE kick_off_time > now() AND api_fixture_id IS NOT NULL;`

---

## Verification

1. Setup: check `games` table — `api_fixture_id` populated for group stage games
2. Odds: run sync-odds test page → check `game_odds` has rows
3. Cron jobs: `SELECT jobname, schedule FROM cron.job;`
4. Sync (manual): call sync mode with a past WC fixture ID → score + stats written
5. Triggers: after score write → check `predictions.points_earned` updated
