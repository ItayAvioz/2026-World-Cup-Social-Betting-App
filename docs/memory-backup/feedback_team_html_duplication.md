---
name: team.html data duplication issue
description: team.html has its own hardcoded TEAMS+TEAM_EXTRA — must be kept in sync with js/main.js manually; approved fix is to load js/main.js via script tag instead
type: feedback
originSessionId: a1602d8e-41af-4074-b41b-4abf6224607f
---
`team.html` (mobile team page) contains a full hardcoded copy of `TEAMS` and `TEAM_EXTRA` in its own `<script>` block, completely separate from `js/main.js`. Desktop uses a modal that reads from `js/main.js`; mobile navigates to `team.html?code=...` which reads its own inline data.

**Why:** This caused the "Team not found" bug on mobile when new teams were added to `js/main.js` but not to `team.html`. Ranks were also stale for the same reason.

**How to apply:** Any time team data is edited in `js/main.js`, the same edit must also be made in `team.html` — until the fix below is implemented.

**Approved fix (not yet done):** Remove the hardcoded `const TEAMS` and `const TEAM_EXTRA` blocks from `team.html` and add `<script src="js/main.js"></script>` before the inline render script. The render logic already uses `TEAMS`/`TEAM_EXTRA` by name — no other change needed. Zero risk.
