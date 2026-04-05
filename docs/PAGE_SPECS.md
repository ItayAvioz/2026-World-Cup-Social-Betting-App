> ⚠️ **STALE (2026-04-05)** — This doc predates the React + Vite migration and references the old vanilla HTML pages (`dashboard.html`, `groups.html`, `picks.html`, etc.). The app is now a React SPA under `src/pages/`. Kept for historical reference only. Source of truth: `src/pages/*.jsx` and `memory/frontend-phase.md`.

# Page Build Specs

## index.html — Landing + Auth
**Status:** exists — needs `auth.js` wired up

**Auth logic (add to existing page):**
- On load: parse `?invite=CODE` → `localStorage.setItem('pendingInvite', code)`
- If session exists → redirect `dashboard.html`
- Register: `signUp` → `create_profile` RPC → if `pendingInvite` → `join_group` → redirect
- Login: `signInWithPassword` → if `pendingInvite` → `join_group` → redirect
- Toggle register ↔ login form
- Show inline field errors (not just toast)

---

## dashboard.html — Group + Global Leaderboard
**Status:** exists (placeholder) — replace "coming soon" with real content

**Sections:**
1. **Group leaderboard** (default) — `get_group_leaderboard(groupId)`
   - Rank badges: 🥇🥈🥉 for top 3
   - Current user's row: `background: rgba(245,197,24,.08)`
   - Inactive members: dimmed (`opacity:.5`)
2. **Toggle** → global leaderboard — `get_leaderboard()`
3. **Group selector** (if user in multiple groups)
4. **Today's games** below leaderboard — kickoff time, teams, user's prediction, score if finished
5. **Empty state** — "Join or create a group" → CTA to `groups.html`

---

## game.html — Single Game
**URL:** `game.html?id=GAME_UUID`

**Sections:**
1. Game header — teams + flags, kick_off_time, phase tag, venue
2. **Pre-kickoff:** prediction entry — two number inputs, submit button (disabled after kick_off_time)
3. **Pre-kickoff:** odds — home/draw/away from `game_odds` table
4. **Pre-kickoff:** team stats — `team_tournament_stats` view (W/D/L, goals, cards)
   - First game: "First tournament game — no stats yet" message
5. **Post-kickoff:** group predictions reveal — list of members' picks + `is_auto` badge
6. **Post-kickoff:** stat split — outcome % distribution, avg goals, most popular score
7. **Finished:** score display — 90-min | ET (if `went_to_extra_time`) | pens (if `went_to_penalties`)

**Score display rule:** `score_home/score_away` = 90-min only. Show ET/pen scores separately.

---

## picks.html → #/picks — Champion + Top Scorer (per group)
**Status:** ✅ DONE (React — `src/pages/Picks.jsx`)

**Concept:** Picks are **per-group** — each group has independent champion + top scorer picks. A user in 3 groups makes 3 separate sets of picks.

**Sections:**
1. **Group selector tabs** — pill tabs at top; one per user's group (sorted by joined_at); switching tabs loads/saves picks scoped to that group
2. **Champion pick** — searchable list of all 48 teams A–L + 6 TBD qualifier slots (greyed-out/disabled). Pick for the selected group. Save button enabled only when pick changes.
3. **Top scorer pick** — searchable list of 30 hardcoded star player candidates. Same per-group scoping.
4. **Lock bar** — always visible: deadline "Jun 11, 2026 · 22:00 IDT" or "🔒 Locked" after `2026-06-11T19:00:00Z`
5. **Locked state** — shows existing pick read-only with flag + group name label; no form
6. **No groups state** — "Join or create a group first" + CTA to Groups page
7. **Error states** — groups error (full page retry) + picks error per group (inline retry)

**DB:** `champion_pick.upsert({ user_id, group_id, team }, { onConflict: 'user_id,group_id' })` + same for `top_scorer_pick`

---

## groups.html — Group Management
**Status:** missing

**Sections:**
1. **My groups** — name, member count, invite link, rename button (captain + before June 11 only)
2. **Members list** (per group) — username, rank, points, inactive toggle (captain only, not self)
   - Hint next to inactive button: *"Mark as inactive if this member has stopped playing."*
   - Bottom: *"Members are permanent. To remove a member or delete a group, contact the admin."*
3. **Create group** modal — name input, max 3 groups enforced
4. **Join group** modal — code input, pre-filled from `?invite=CODE`

**Invite link flow:**
1. Captain shares `https://[domain]/index.html?invite=ABC123`
2. Friend lands → registers/logs in → `join_group(code)` → redirect dashboard
3. Already logged-in user → lands on `groups.html` with join dialog pre-filled

---

## ai-feed.html — AI Summaries
**Status:** missing

**Sections:**
1. **Group selector** (if user in multiple groups)
2. **Summary cards** — date header, summary text, game count, generated_at timestamp
3. **Empty state:** "No summaries yet. Summaries are generated nightly after games finish."
4. **No groups state:** CTA to `groups.html`

---

## Deadline Rules (enforce client-side + rely on RLS as backstop)

| Action | Deadline |
|--------|----------|
| Prediction per game | `game.kick_off_time` |
| Champion + top scorer picks | `2026-06-11T19:00:00Z` |
| Rename username / group | `2026-06-11T19:00:00Z` |

```js
const isLocked = (deadline) => new Date() >= new Date(deadline);
```
