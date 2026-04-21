---
name: qa-round3
description: QA round 3 fixes (2026-04-02) — 8 issues reviewed, 7 fixed, 44 migrations deployed
type: project
---

# QA Round 3 — Full Logic Verification (2026-04-02)

**Context:** Verified entire app logic spec against DB, RLS, frontend, Edge Functions. 15 issues found across 5 agents, 7 fixed, rest skipped/deferred.

## QA Round 4 — Delta Verification (2026-04-05) ✅ ALL CLEAR
- BUG 1 (top_scorer api_id null) → M51 NOT NULL constraint enforced ✅
- BUG 2 (auto-predict contrarian) → verified FIXED in fn_auto_predict_game (M42) ✅
- BUG 3 (ungrouped auto-predict) → verified FIXED in fn_auto_predict_game (M42) ✅
- BUG 4 (Game.jsx group context) → resolvedGroupId fix in Game.jsx ✅
- BUG 5 (logged-in invite flow) → verified FIXED in Groups.jsx:179-185 ✅
- sync-odds v14: USA→United States map + filter non-WC teams ✅
- M51: top_scorer_candidates.api_player_id NOT NULL ✅
- All docs/memory synced ✅
**Status: App is pre-launch ready. Next: browser smoke test → GitHub Pages deploy.**

## Fixes Applied

### C1 (CRITICAL): fn_auto_predict_game — contrarian logic restored
- M30 replaced M24's contrarian with pure random. Now counts W/D/L per group, picks least popular outcome (tiebreak: away > draw > home), generates matching score.
- **Migration 42**

### C2 (CRITICAL): predictions SELECT RLS — cross-group leak fixed
- `share_a_group(user_id)` leaked predictions across groups. Replaced with `is_group_member(group_id, auth.uid())`.
- **Migration 42**

### C3 (MEDIUM): js/auth.js register handler — param name `invite_code` → `p_invite_code`
- **Code fix only** (js/auth.js line 101)

### H1 (HIGH): fn_auto_assign_picks — contrarian logic added
- Random → least popular team/player per group. Player pool stays 7 (expanded from API later).
- **Migration 41**

### H3 (HIGH): Max 3 groups = total membership
- `create_group()`: checks group_members count (was checking groups.created_by)
- `join_group()`: adds membership cap check
- Groups.jsx: both Join + Create disabled at 3, message updated
- **Migration 43**

### M4 (MEDIUM): join_group — tournament deadline + ungrouped data migration
- Can't join after 2026-06-11T19:00:00Z (`tournament_started` error)
- First group join: migrates all group_id=NULL predictions/picks to the new group
- Second/third group join: no migration (user starts fresh)
- Groups.jsx: handles `tournament_started` error
- **Migration 43** (same file as H3)

### M3 (MEDIUM): Dashboard predictPct — participation → W/D/L accuracy
- Changed from manual prediction count / finished games → correct outcome count (points >= 1) / total predictions. Label: "W/D/L".
- **Code fix** (Dashboard.jsx)

### M5 (MEDIUM): fn_schedule_ai_summaries — vault instead of current_setting
- Was returning NULL. Now reads from vault.decrypted_secrets (same as fn_schedule_game_sync).
- **Migration 44**

### L1 (LOW): Dashboard countdown — skip live games
- Was showing 0:00:00 during live games. Now filters `kick_off_time > now` to target next upcoming game.
- **Code fix** (Dashboard.jsx)

## Skipped / Deferred
- H2: 5 game schedule mismatches — API data pull will fix kick_off_times
- M1: Game page member predictions — shown only in Groups.jsx (by design)
- M2: Game page global stats — shown only in Groups.jsx (by design)
- M6: Nightly summary EF — deferred to future session
- L2: Game page without ?group= — only reachable by manual URL, not a real scenario
- L3: ET retry 40min vs 45min — keep 40min

## Stale Docs (flagged, not fixed — cosmetic)
- SDK_PATTERNS.md, PAGE_SPECS.md, DATA_SOURCES.md, frontend-phase.md, db-phase.md

## Deployment
- Migrations 41-44: all deployed live via execute_sql + files for version control
- Code fixes: js/auth.js, Dashboard.jsx, Groups.jsx — build passes
