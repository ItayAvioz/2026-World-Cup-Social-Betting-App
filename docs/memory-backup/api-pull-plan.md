---
name: api-pull-plan
description: API Football data pull — teams + players from API (not hardcoded), champion/top-scorer selection tables
type: project
---

# API Football Data Pull — Plan

**Why:** User wants champion + top scorer selection lists pulled from API Football, NOT hardcoded arrays.

## Scope
1. **Teams for champion selection** — pull all 48 WC teams from API Football, store in DB
2. **Players for top scorer selection** — pull players from API Football with `api_player_id`, store in DB
3. **Picks.jsx** — replace hardcoded TEAMS + STRIKERS arrays with DB queries
4. **This is a single API pull** — both teams and players fetched together

## How to apply
- During football-api-sync `mode=setup`: also pull teams + squad/player data
- Create DB tables or use existing structures to store team list + player list
- Picks.jsx reads from Supabase instead of hardcoded arrays
- Solves W7 (3 null apiIds) completely — all player IDs come from API
- Legacy leaderboard view already dropped (W1)
