# WorldCup 2026 App — Full QA Report

**Date**: 2026-04-01
**Scope**: A-to-Z verification — DB, RLS, business logic, frontend, auth, integrations, E2E
**Agents**: 5 (DB Integrity, Edge Functions, Auth & Permissions, Frontend UX, E2E Integration)
**Test target**: localhost:4178 (Vite dev server)

---

## 1. Executive Summary

| Metric | Value |
|--------|-------|
| Total checks | **144** |
| Pass | **122** |
| Fail / Issue | **22** |
| Critical | **4** |
| High | **3** |
| Medium | **8** |
| Low | **7** |
| Readiness | **NOT READY** — 4 critical blockers must be fixed before launch |

---

## 2. Issues Table

### CRITICAL (4)

| # | Agent | Description | Location | Impact |
|---|-------|-------------|----------|--------|
| C1 | EF | **`api_fixture_id` column missing from `games` table** — Migration 22 exists locally but was never deployed. Blocks ALL API sync operations. | `supabase/migrations/20260317000022_games_api_fixture_id.sql` | API Football setup/sync completely blocked |
| C2 | EF | **Score write uses `goals.home/away` (includes ET)** instead of `score.fulltime.home/away` (90-min only). Will write wrong scores for knockout games with ET/PEN. | `supabase/functions/football-api-sync/index.ts:291-294` | Prediction scoring broken for all knockout ET/PEN games |
| C3 | DB | **`fn_calculate_pick_points` is NOT SECURITY DEFINER** — trigger updates champion_pick and top_scorer_pick across all users but runs as INVOKER. Cross-user updates silently blocked by RLS outside service-role context. | `fn_calculate_pick_points` function | Champion/top scorer points may not be awarded |
| C4 | UX | **Session instability / auth token race condition** — AuthGuard redirects to index.html during token refresh window. Navigation to AI Feed consistently causes logout. | `src/context/AuthContext.jsx:20-23`, `src/App.jsx:20-23` | Users randomly logged out during navigation |

### HIGH (3)

| # | Agent | Description | Location | Impact |
|---|-------|-------------|----------|--------|
| H1 | E2E | **`fn_calculate_points` doesn't reset points when scores revert to NULL** — no ELSE branch. Stale points persist, corrupting leaderboard. | `fn_calculate_points` trigger | Leaderboard corruption on score corrections |
| H2 | DB | **2 auto-predict cron jobs missing** — Mexico vs South Africa (opening match, Jun 11 19:00) and Australia vs UEFA PO-C (Jun 13 04:00) have no auto-predict scheduled. | `cron.job` table | Users who forget to predict the opening match get 0 pts instead of auto-fill |
| H3 | DB+EF | **Vault secrets missing: FOOTBALL_API_KEY + theoddsapi** — Edge Functions deployed but will fail at runtime. | Supabase Vault | Known blocker — user will provide keys |

### MEDIUM (8)

| # | Agent | Description | Location | Impact |
|---|-------|-------------|----------|--------|
| M1 | E2E | **`top_scorer_api_id` always NULL in manual picks** — frontend hardcodes `null`. Trigger checks `WHERE top_scorer_api_id = ANY(...)` — null never matches. Manual picks can never earn 10pts. | `src/pages/Picks.jsx:254,259` | Users who manually pick top scorer get 0 pts |
| M2 | EF | **Auto-predict skips ungrouped users** — `fn_auto_predict_game` only loops `group_members`. Users not in any group get no auto-predictions. | `fn_auto_predict_game` | Ungrouped users always get 0 pts |
| M3 | EF | **Team name mismatches for API sync** — DB has "Ivory Coast" (API: "Cote D'Ivoire"), "South Korea" (API: "Korea Republic"), possibly "Cape Verde" (API: "Cabo Verde"), "United States" (API: "USA"). | `games` table team names | Setup mode will fail to map these teams |
| M4 | DB | **Captain self-inactive guard is UI-only** — RLS UPDATE policy on `group_members` missing `user_id != auth.uid()` in WITH CHECK. A direct API call could bypass the UI guard. | `group_members` UPDATE policy | Captain could accidentally/maliciously deactivate themselves |
| M5 | Auth | **No client-side username validation** — 2-char username "ab" passes client, creates auth user, then `create_profile` RPC rejects it. Orphaned auth.users entry remains. | `js/auth.js:56` | Orphaned auth users accumulate |
| M6 | UX | **Z-index bleed between pages** — Dashboard content appears below/overlapping other pages during scroll or full-page view. | Route rendering / CSS | Visual glitches during navigation |
| M7 | UX | **"1 pts" grammatical error** — Entries with 1 point display as "1 pts" instead of "1 pt". | Dashboard leaderboard | Polish issue |
| M8 | E2E | **Pre-existing stale `points_earned` data** — 11 predictions across 4 unscored games have non-zero points (artifact from previous testing + H1 bug). | `predictions` table | Leaderboard totals currently incorrect |

### LOW (7)

| # | Agent | Description | Location | Impact |
|---|-------|-------------|----------|--------|
| L1 | Auth | **Registration with existing email doesn't show error** — Supabase `signUp` with existing email (no email confirmation) creates a session instead of erroring. | `js/auth.js` | Confusing UX for existing users |
| L2 | Auth | **Toast visibility transient** — Error toasts appear 3.5s then vanish. May also have CSS issue where toast is always visible after first display. | Toast component | Users may miss error messages |
| L3 | UX | **Profile dialog always in DOM** — Hidden via CSS, not conditional render. Screen readers may announce hidden content. | Dashboard profile dialog | Accessibility concern |
| L4 | UX | **No loading skeleton/shimmer** — Content appears abruptly after data loads. | All pages | Perceived performance |
| L5 | UX | **Team name truncation** — "South Africa" truncated to "South Af..." on Dashboard game cards. | Dashboard next games | Minor readability |
| L6 | EF | **Orphaned retry cron cleanup** — `fn_unschedule_game_sync` doesn't clean up retry jobs. They self-unschedule but may fire redundantly. | `fn_unschedule_game_sync` | Wastes 1 API call per orphan |
| L7 | EF | **sync-odds writes null to NOT NULL columns** — If API returns no outcome data, null is written to `home_win`/`away_win` NOT NULL columns, causing silent DB error. | `supabase/functions/sync-odds/index.ts` | Odds silently not saved for malformed API data |

---

## 3. Solutions

### C1: Deploy Migration 22 (api_fixture_id)
```sql
ALTER TABLE public.games ADD COLUMN api_fixture_id integer;
CREATE INDEX idx_games_api_fixture_id ON public.games(api_fixture_id);
```
**Effort**: 5 min — deploy via MCP execute_sql or `supabase db push`

### C2: Fix score write in football-api-sync
Change `index.ts:291-294`:
```js
// BEFORE (wrong — includes ET goals):
score_home: goals.home,
score_away: goals.away,

// AFTER (correct — 90-min only):
score_home: score.fulltime?.home ?? goals.home,
score_away: score.fulltime?.away ?? goals.away,
```
**Effort**: 10 min — edit + redeploy EF v10

### C3: Add SECURITY DEFINER to fn_calculate_pick_points
```sql
ALTER FUNCTION fn_calculate_pick_points() SECURITY DEFINER;
```
**Effort**: 2 min — single SQL statement

### C4: Fix AuthGuard race condition
In `AuthContext.jsx`, add a loading state that waits for auth to stabilize:
```jsx
// Don't redirect during initial auth check
const [authReady, setAuthReady] = useState(false);
useEffect(() => {
  supabase.auth.getSession().then(({ data: { session } }) => {
    setSession(session);
    setAuthReady(true);
  });
  const { data: { subscription } } = supabase.auth.onAuthStateChange(
    (_event, session) => { setSession(session); setAuthReady(true); }
  );
  return () => subscription.unsubscribe();
}, []);
```
In AuthGuard: `if (!authReady) return <Loading />; if (!session) redirect;`
**Effort**: 30 min

### H1: Add ELSE branch to fn_calculate_points
```sql
-- When scores revert to NULL, reset points
IF NEW.score_home IS NULL OR NEW.score_away IS NULL THEN
  UPDATE predictions SET points_earned = 0 WHERE game_id = NEW.id;
  RETURN NEW;
END IF;
```
**Effort**: 10 min — new migration

### H2: Create missing auto-predict cron jobs
```sql
SELECT fn_schedule_auto_predictions('<mexico_vs_sa_game_id>');
SELECT fn_schedule_auto_predictions('<australia_vs_uefa_poc_game_id>');
```
**Effort**: 2 min

### M1: Add API IDs to STRIKERS array in Picks.jsx
Add `apiId` field to each player in the STRIKERS array, pass it in the upsert:
```js
{ name: 'Kylian Mbappe', team: 'France', apiId: 278 },
{ name: 'Erling Haaland', team: 'Norway', apiId: 1100 },
// ... etc for all 30 players
```
**Effort**: 30 min — needs API ID lookup for all 30 players

### M2: Add ungrouped user loop to fn_auto_predict_game
Follow the same pattern as `fn_auto_assign_picks` (M37) — add a second loop for profiles not in group_members.
**Effort**: 20 min — new migration

### M3: Add team name alias map to football-api-sync
```js
const TEAM_ALIASES = {
  "Cote D'Ivoire": "Ivory Coast",
  "Korea Republic": "South Korea",
  "Cabo Verde": "Cape Verde",
  "USA": "United States",
};
```
**Effort**: 15 min — edit + redeploy EF

### M4: Add captain self-guard to RLS
```sql
DROP POLICY "captain_can_update_members" ON group_members;
CREATE POLICY "captain_can_update_members" ON group_members FOR UPDATE
  USING (EXISTS (SELECT 1 FROM groups WHERE id = group_id AND created_by = auth.uid()))
  WITH CHECK (
    EXISTS (SELECT 1 FROM groups WHERE id = group_id AND created_by = auth.uid())
    AND user_id != auth.uid()
  );
```
**Effort**: 5 min — new migration

### M5: Add client-side username validation
```js
if (username.length < 3 || username.length > 20 || !/^[a-zA-Z0-9_]+$/.test(username)) {
  showToast('Username must be 3-20 chars, letters/numbers/underscores only', 'error');
  return;
}
```
**Effort**: 5 min

### M8: Clean up stale points_earned data
```sql
UPDATE predictions SET points_earned = 0
WHERE game_id IN (SELECT id FROM games WHERE score_home IS NULL)
AND points_earned != 0;
```
**Effort**: 1 min

---

## 4. Improvements (Not Bugs)

| # | Area | Suggestion |
|---|------|-----------|
| I1 | UX | Add loading skeletons/shimmer to all pages during data fetch |
| I2 | UX | Conditional render profile dialog (instead of CSS hide) for accessibility |
| I3 | UX | Auto-truncate team names with tooltip on hover |
| I4 | Auth | Rate-limit registration attempts to prevent orphaned auth users |
| I5 | DB | Add contrarian logic back to auto-predict (M24/M25 style — pick least popular W/D/L) |
| I6 | EF | Add structured logging table (`sync_log`) for EF operations |
| I7 | UX | Show group context indicator on Game page when ?group= param is used |
| I8 | UX | Fix toast CSS — ensure it hides properly after timeout |

---

## 5. Missing Items

| # | Item | Status | Blocker? |
|---|------|--------|----------|
| 1 | Nightly-summary Edge Function | NOT BUILT | No — deferred |
| 2 | FOOTBALL_API_KEY secret | NOT SET | Yes — blocks API sync |
| 3 | theoddsapi secret | NOT SET | Yes — blocks odds sync |
| 4 | API Football setup mode (fixture ID mapping) | NOT RUN | Yes — blocked by C1 + key |
| 5 | Game sync cron scheduling | NOT RUN | Yes — blocked by setup |
| 6 | Invite flow for logged-in users (BUG 5 from plan) | NOT TESTED | Unknown |
| 7 | Migration 32 physical file | MISSING | No — deployed via MCP |
| 8 | Test users dave + eve | NOT CREATED | No |
| 9 | docs/SDK_PATTERNS.md | STALE | No |
| 10 | docs/PAGE_SPECS.md | STALE | No |

---

## 6. Pre-Launch Checklist

### Must Fix (Blockers)
- [ ] C1: Deploy api_fixture_id column (M22)
- [ ] C2: Fix score write to use score.fulltime in football-api-sync
- [ ] C3: ALTER fn_calculate_pick_points SECURITY DEFINER
- [ ] C4: Fix AuthGuard race condition
- [ ] H1: Add ELSE branch to fn_calculate_points for NULL scores
- [ ] H2: Create 2 missing auto-predict cron jobs
- [ ] H3: Set FOOTBALL_API_KEY + theoddsapi vault secrets
- [ ] M1: Add API IDs to STRIKERS array in Picks.jsx
- [ ] M8: Clean up stale points_earned data

### Should Fix (Before Launch)
- [ ] M2: Add ungrouped users to fn_auto_predict_game
- [ ] M3: Add team name alias map to football-api-sync
- [ ] M4: Add captain self-guard to RLS WITH CHECK
- [ ] M5: Add client-side username validation in js/auth.js
- [ ] M6: Fix z-index bleed between route pages
- [ ] M7: Fix "1 pts" → "1 pt" singular grammar

### Nice to Have
- [ ] L1-L7: Low-severity fixes
- [ ] I1-I8: Improvement suggestions

### Post-Fix Steps
- [ ] Run football-api-sync mode=setup
- [ ] Verify fixture ID mappings
- [ ] Schedule game syncs: fn_schedule_game_sync() for all mapped games
- [ ] Test odds sync manually
- [ ] Build + deploy nightly-summary EF (future session)
- [ ] Deploy to GitHub Pages

---

## Agent Performance

| Agent | Checks | Pass | Issues | Duration |
|-------|--------|------|--------|----------|
| 1 - DB Integrity | 38 | 28 | 8 | ~5 min |
| 5 - Edge Functions | 23 | 17 | 7 | ~6 min |
| 2 - Auth & Permissions | 24 | 22 | 3 | ~20 min |
| 3 - Frontend UX | 58 | 50 | 6 | ~14 min |
| 4 - E2E Integration | 13 | 13 | 3 | ~12 min |
| **Total** | **156** | **130** | **22 unique** | — |

Note: Some issues were discovered by multiple agents (e.g., M1/BUG1 confirmed by both DB and E2E agents, M2/BUG3 by both DB and EF agents). Deduplicated to 22 unique issues.
