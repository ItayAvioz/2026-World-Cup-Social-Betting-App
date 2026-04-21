---
name: qa-round2
description: QA edge-case sweep results (2026-04-01) — 6 new bugs found after initial QA, all fixed
type: project
---

# QA Round 2 — Edge Case Sweep (2026-04-01)

**Context:** Full edge-case review after initial QA (22 issues) was completed. Ran 34 targeted DB + code checks.

## Bugs Found & Fixed

### FIX-1 (HIGH): localStorage key mismatch — invite flow broken
- `js/auth.js` stored `wc2026_pending_invite`, `Groups.jsx` read `pendingInvite`
- **Fix:** Aligned both to `wc2026_pending_invite`. Added auto-join in auth.js for logged-in users AND login handler (both now call `join_group` + remove key before redirect).

### FIX-2 (MEDIUM): Duplicate apiIds in Picks.jsx
- Saka, Griezmann, Havertz all had `apiId: 1465` — at most one correct
- **Fix:** Set all 3 to `null`. Added TODO to verify via API after FOOTBALL_API_KEY is set.
- **Why:** Can't verify without API key. `null` prevents false matches; auto-assign has separate correct IDs.

### FIX-3 (MEDIUM): fn_auto_assign_picks wrong player API IDs
- DB had Vinicius=2295, Kane=3501, Lautaro=4200, Neymar=5001
- Picks.jsx had Vinicius=5765, Kane=184, Lautaro=730, Neymar=276
- **Fix:** Aligned DB to Picks.jsx values (more credible — cross-referenced with confirmed IDs). Migration 40.

### FIX-4 (MEDIUM): Picks.jsx→Game navigation missing group param
- `navigate(/game/${id})` without `?group=` — user can't predict from Game page
- **Fix:** Added `?group=${selectedGroupId}` to both onClick and onKeyDown.

### FIX-5 (MEDIUM): get_group_summary_data not scoped to group
- Predictions, champion_pick, top_scorer_pick JOINs had no `group_id = p_group_id` filter
- AI summary leaderboard/predictions/streak were cross-group contaminated
- **Fix:** Added `AND pr.group_id = p_group_id` / `AND cp.group_id = p_group_id` / `AND ts.group_id = p_group_id` to all 4 sections. Migration 40.

### FIX-6 (LOW): error.message mismatch in Groups.jsx
- RPC raises `'invalid_invite_code'`, frontend checked `'invalid_code'`
- **Fix:** Changed to `'invalid_invite_code'`.

## Still Pending (not bugs — blocked on external input)
- All 30 STRIKERS apiIds need verification via `GET /players?search=NAME` after FOOTBALL_API_KEY set
- 3 players currently null (Saka, Griezmann, Havertz) — will be filled during API sync setup
- Contrarian auto-predict (improvement, not bug) — deferred

## Deployment
- DB fixes (FIX-3, FIX-5): deployed live via execute_sql + Migration 40 file for version control
- Code fixes (FIX-1, FIX-2, FIX-4, FIX-6): applied locally, build passes
