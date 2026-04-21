---
name: feedback_odds_sources
description: Odds data source decisions — which API/bookmaker to use for each odds type
type: feedback
---

Use API Football (Bet365) for game odds. Use TheOddsAPI (William Hill only) for champion odds. Never mix sources per data type.

**Why:** User explicitly defined this architecture on 2026-04-05 to keep a single clean source per odds type and avoid duplicate rows in DB.

**How to apply:**
- game_odds (1X2 + over/under 2.5) → `sync_af_odds` mode in football-api-sync EF, bookmaker ID 8 (Bet365), source='bet365'
- champion_odds → sync-odds EF champion mode, William Hill only (`b.title === 'William Hill'`), single row per team
- TheOddsAPI default mode (game h2h) is dead — `sync-odds-daily` pg_cron unscheduled, do not re-enable
- champion-odds pg_cron is dead — handled by cron-job.org external cron (expires Jun 11 2026)
