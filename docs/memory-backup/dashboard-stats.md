---
name: Dashboard My Stats — counting rules
description: How Exact%, Predicted%, and Streak are counted in the Dashboard My Stats section, including start date decision
type: project
originSessionId: 160ef209-545c-43fc-b9ae-acdde82d9177
---
## Stats counting starts from 2026-04-11

Exact%, Predicted%, and Streak in My Stats all count from 2026-04-11 onwards.
Games finished before that date are excluded (test data scored manually without auto-predict).

**Why:** Test games were scored manually before auto-predict was in place, so those games had no predictions. Counting from 2026-04-11 ensures only real auto-predict-covered games are included.

**How to apply:** The `finGames` query in Dashboard.jsx filters `kick_off_time >= '2026-04-11'`. If the start date ever needs changing, update that filter in the `useEffect` that loads picks + prediction stats.

## Stat definitions

- **Exact%** — % of finished games (from start date) where user predicted the exact score (points_earned === 3)
- **Predicted%** — % of finished games (from start date) where user predicted correct W/D/L (points_earned >= 1)
- **Streak** — walks games oldest→newest (ASC). Resets (not breaks) on direction change. Final value = most recent consecutive run. Positive = correct run, negative = wrong run. 0 only before any finished games. Parallel games (same kick_off_time) ordered by id DESC for consistency.

## Pending fix after test data cleanup

`completedGames` (progress bar) reads from the same `finGames` query (filtered `>= 2026-04-11`), so it shows 7 instead of the real WC game count. After test data is cleared, add a separate query for `completedGames` filtered to `kick_off_time >= '2026-06-11'` (tournament start) only.

## Implementation notes (Dashboard.jsx)

- `finGames` query: `.not('score_home', 'is', null).gte('kick_off_time', '2026-04-11').order('kick_off_time', { ascending: true }).order('id', { ascending: false })`
- Denominator uses `finishedPreds` (predictions filtered to finished game IDs only), not all predictions
- Streak loop: `continue` on missing prediction; reset (not break) on direction change
