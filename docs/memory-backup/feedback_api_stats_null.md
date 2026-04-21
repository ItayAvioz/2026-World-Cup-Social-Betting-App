---
name: feedback_api_stats_null
description: API Football returns null (not 0) for some team stats when count is 0 — use ?? 0 for count fields
type: feedback
---

API Football `/fixtures/statistics` returns `null` for some count stats when the value is 0. Confirmed empirically from Rayo vs Elche (2026-04-03):

- `offsides`: returned **null** for both teams (even if 0 offsides occurred)
- `yellow_cards`, `red_cards`, `corners`, `fouls`, `shots_*`: returned **0** directly (not null)

**Why:** The stat() helper returns null when `entry.value === null`. Without `?? 0`, offsides (and potentially other stats) land as NULL in DB instead of 0.

**How to apply:** In `writeTeamStats`, all count fields use `stat('...') ?? 0`. Applied in v16:
```typescript
shots_total:     stat('Total Shots')     ?? 0,
shots_on_target: stat('Shots on Goal')   ?? 0,
shots_insidebox: stat('Shots insidebox') ?? 0,
corners:         stat('Corner Kicks')    ?? 0,
fouls:           stat('Fouls')           ?? 0,
yellow_cards:    stat('Yellow Cards')    ?? 0,
red_cards:       stat('Red Cards')       ?? 0,
offsides:        stat('Offsides')        ?? 0,
```
`possession` and `xg` stay nullable (legitimate to be missing).

## Pending bug: gk_saves / gk_conceded always NULL
`s.goalkeeper?.saves` and `s.goalkeeper?.conceded` return null for ALL players including actual GKs. Path may be wrong in API response. Needs investigation via probe_stats.

## Validation CSV
- `docs/validation/rayo_elche_team_stats.csv`
- `docs/validation/rayo_elche_player_stats.csv`
