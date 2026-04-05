# WorldCup 2026 — React + Vite Frontend Plan

_Follows `/frontend` skill workflow. React + Vite for all inner pages. `index.html` stays vanilla._

---

## 1. Reference Files (read before every session)

| File | Purpose |
|------|---------|
| `CLAUDE.md` | App characterization, features, scoring, deadlines |
| `docs/DESIGN_TOKENS.md` | CSS vars, fonts, all component patterns |
| `docs/SDK_PATTERNS.md` | All Supabase SDK code blocks |
| `docs/PAGE_SPECS.md` | Per-page build spec + invite flow + deadline rules |
| `.claude/skills/db-feature/SKILL.md` | Live ERD + RLS + RPCs (source of truth) |

---

## 2. Design Language

### Fonts
- **Oswald** — headings, numbers, scores, times, nav logo (300/400/600/700)
- **Inter** — body text, labels, buttons (300/400/500/600)

```html
<link href="https://fonts.googleapis.com/css2?family=Oswald:wght@300;400;600;700&family=Inter:wght@300;400;500;600&display=swap" rel="stylesheet">
```

In Vite: load via `index.html` or `@import` in `css/style.css`.

### CSS Variables (unchanged from style.css)

```css
--bg: #0a0a0a       /* page background */
--bg2: #111111      /* cards, inputs */
--bg3: #1a1a1a      /* elevated cards, modals */
--accent: #f5c518   /* gold — primary CTA */
--green: #2ecc71    /* success, win */
--red: #e74c3c      /* error, loss */
--blue: #3498db     /* info, group stage */
--text: #f0f0f0     /* body text */
--muted: #888888    /* secondary text */
--border: #2a2a2a   /* all borders */
--radius: 12px      /* standard border-radius */
```

### Component Patterns (from DESIGN_TOKENS.md — use in JSX)

| Pattern | Class / Usage |
|---------|--------------|
| Primary button | `className="btn btn-gold"` |
| Secondary button | `className="btn btn-outline"` |
| Large / full-width | `btn-lg` / `btn-full` |
| Section label | `className="section-pill"` |
| Section heading | `className="section-title"` |
| Card | `style={{ background:'var(--bg3)', border:'1px solid var(--border)', borderRadius:'var(--radius)', padding:'1.5rem' }}` |
| Stats bar (4-up) | `className="stats-bar"` > `stat-item` > `stat-num` + `stat-desc` |
| Stat grid (2-col) | `className="stat-grid-2"` > `stat-box` |
| Phase tag | `className="hs-tag group"` or `"hs-tag knockout"` |
| Section divider | `className="phase-divider"` |
| Rank badges | 🥇🥈🥉 for top 3 |
| Flag | `<img src={\`https://flagcdn.com/w40/${code}.png\`} />` |
| Radial hero bg | `background: radial-gradient(ellipse 80% 60% at 50% 0%, #1a1000 0%, var(--bg) 70%)` |
| Inactive member | `style={{ opacity: 0.5 }}` |
| Current user row | `style={{ background: 'rgba(245,197,24,.08)' }}` |

### Modal (React — controlled)

```jsx
<Modal isOpen={open} onClose={() => setOpen(false)}>
  {/* content */}
</Modal>
```

### Toast (React — context hook)

```jsx
const { showToast } = useToast();
showToast('Saved!', 'success');
showToast('Error message', 'error');
```

### Page Shell (every inner page)

```jsx
<Layout title="Page Title">
  {/* page content in page-body */}
</Layout>
```
`Layout.jsx` renders: `page-nav` (← Back + logo) + `page-body` div + `Toast`.

---

## 3. Coding Rules

| Category | Rule |
|----------|------|
| **Supabase client** | Always import `supabase` from `src/lib/supabase.js` — never call `createClient` again |
| **Session** | `getSession()` not `getUser()`. Auth guard fires before any data fetch. |
| **Games** | Finished = `score_home IS NOT NULL`. No `game.status` column — doesn't exist. |
| **Scores** | `score_home/away` = 90-min only. ET and pen scores shown separately. |
| **Deadlines** | `const isLocked = (d) => new Date() >= new Date(d)` — client-side + RLS backstop |
| **Design** | Dark theme always. Mobile-first. Oswald for numbers/scores. Inter for body. |
| **Code** | `async/await` only. No `console.log`. No inline handlers (except `onClick={() => history.back()}`). |
| **Picks** | Top scorer upsert must send both `player_name` AND `top_scorer_api_id`. |
| **Groups** | Never show other users' picks before `kick_off_time` — hide in UI, RLS enforces. |
| **Error codes** | `error.message === 'max_groups_reached'` etc. — see SDK_PATTERNS.md |

---

## 4. Architecture

### Hybrid SPA

- `index.html` (root) = Vanilla landing + auth — **stays vanilla, also needs `js/auth.js` built**
- All 7 inner pages = React + Vite SPA (`HashRouter`)
- After login redirect:
  - **Dev**: `window.location.href = 'http://localhost:5173/app.html#/dashboard'`
  - **Prod**: `window.location.href = './app.html#/dashboard'`
  - Use `const isProd = !window.location.hostname.includes('localhost')` to branch
- `css/style.css` imported in `src/main.jsx` as `import '../css/style.css'` (relative to src/)

### File Structure

```
/
├── index.html                        # Vanilla landing + auth (unchanged)
├── css/style.css                     # Design tokens — imported by Vite
├── js/supabase.js                    # UMD client — index.html only
├── js/main.js                        # TEAMS data — index.html only
│
├── src/                              # React + Vite source
│   ├── app.html                      # Vite HTML entry → builds to dist/app.html
│   ├── main.jsx                      # ReactDOM.createRoot + providers
│   ├── App.jsx                       # HashRouter + all routes + auth guard
│   │
│   ├── lib/
│   │   ├── supabase.js               # ESM createClient (npm @supabase/supabase-js)
│   │   └── teams.js                  # TEAMS[] + HOST_SCHEDULES as ES exports
│   │
│   ├── context/
│   │   ├── AuthContext.jsx           # session, user, loading, signOut
│   │   └── ToastContext.jsx          # showToast(msg, type) hook
│   │
│   ├── pages/
│   │   ├── Dashboard.jsx             # Group leaderboard + toggle global + today's games
│   │   ├── Game.jsx                  # /game/:id — predict, reveal, score display
│   │   ├── Picks.jsx                 # Champion grid + top scorer list
│   │   ├── Groups.jsx                # Create/join/manage groups + members
│   │   ├── AiFeed.jsx                # Nightly AI summaries per group
│   │   ├── Host.jsx                  # Host city schedule (migrate from host.html)
│   │   └── Team.jsx                  # Team info (migrate from team.html)
│   │
│   └── components/
│       ├── Layout.jsx                # page-nav + bottom nav + page-body + Toast wrapper
│       ├── BottomNav.jsx             # Persistent bottom nav: Dashboard|Groups|Picks|AI Feed
│       ├── Modal.jsx                 # Controlled: isOpen, onClose, children
│       ├── LeaderboardTable.jsx      # Group + global (rank badges, champion flag, highlight self, dim inactive)
│       ├── GameCard.jsx              # Game row: time, teams, user pick, score if finished
│       ├── GroupSelector.jsx         # Reusable group dropdown — used by Dashboard + AiFeed
│       └── Flag.jsx                  # <img> with flagcdn.com helper
│
├── vite.config.js
├── package.json
├── .github/workflows/deploy.yml
└── dist/                             # Build output (gitignored on main branch)
```

### Routes

| Route | Page | Guard |
|-------|------|-------|
| `#/dashboard` | Dashboard.jsx | ✅ session required |
| `#/game/:id` | Game.jsx | ✅ session required |
| `#/picks` | Picks.jsx | ✅ session required |
| `#/groups` | Groups.jsx | ✅ session required |
| `#/ai-feed` | AiFeed.jsx | ✅ session required |
| `#/host` | Host.jsx | ✅ session required |
| `#/team/:id` | Team.jsx | ✅ session required |
| `*` | → `#/dashboard` | — |

Auth guard: `getSession()` on mount → no session → `window.location.href = '../index.html'`

---

## 5. Dependencies

```json
{
  "react": "^18",
  "react-dom": "^18",
  "react-router-dom": "^6",
  "@supabase/supabase-js": "^2",
  "vite": "^5",
  "@vitejs/plugin-react": "^4"
}
```

**6 packages only.** No UI library, no state manager, no query library.

---

## 6. Vite Config

```js
// vite.config.js
import { defineConfig } from 'vite'
import react from '@vitejs/plugin-react'

export default defineConfig({
  root: 'src',
  plugins: [react()],
  build: {
    outDir: '../dist',
    emptyOutDir: true,
    rollupOptions: {
      // ⚠ path is relative to root ('src/'), NOT repo root
      input: { app: './app.html' }
    }
  },
  base: './',
})
```

**`src/lib/supabase.js` credentials** — hardcode same values as `js/supabase.js` (anon key is safe to expose in frontend):
```js
import { createClient } from '@supabase/supabase-js'
const SUPABASE_URL      = 'https://ftryuvfdihmhlzvbpfeu.supabase.co'
const SUPABASE_ANON_KEY = 'sb_publishable_hNTtICDrKMNgAclh28BhrQ_bHTeeFB9'
export const supabase   = createClient(SUPABASE_URL, SUPABASE_ANON_KEY)
```

**`.gitignore`** — add `dist/` so build output is not committed to `main`:
```
dist/
node_modules/
```

---

## 7. Deployment

```
main branch (source)
  → push triggers GitHub Actions
  → npm ci && npm run build  (Vite → dist/)
  → cp index.html dist/      (vanilla landing into build)
  → cp -r css dist/css       (shared styles)
  → push dist/ → gh-pages branch
  → GitHub Pages serves gh-pages

Live URL: https://itayavioz.github.io/2026-World-Cup-Social-Predicting-App/
Landing:  /                         → dist/index.html (vanilla)
App:      /app.html#/dashboard      → dist/app.html (React SPA)
```

### deploy.yml

```yaml
name: Deploy to GitHub Pages
on:
  push:
    branches: [main]
jobs:
  deploy:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - uses: actions/setup-node@v4
        with: { node-version: '20' }
      - run: npm ci
      - run: npm run build
      - run: cp index.html dist/
      - run: cp -r css dist/css
      - uses: peaceiris/actions-gh-pages@v4
        with:
          github_token: ${{ secrets.GITHUB_TOKEN }}
          publish_dir: ./dist
```

---

## 8. Per-Feature Build Workflow

For **every page / feature**, follow these 5 steps:

### Step 1 — Plan
State before writing any code:
- Files touched + new components/hooks needed
- Supabase calls (tables, RPCs) — ⚠ use `score_home IS NOT NULL` not `game.status`
- New CSS classes or component patterns needed
- Reuse from `DESIGN_TOKENS.md` wherever possible

### Step 2 — Flag Blockers
Check for:
- Missing RPC or DB column?
- Ambiguous deadline logic?
- Placeholder/loading state needed?
→ If nothing missing: **"No blockers."** and proceed.

### Step 3 — Build
- Write the component/page
- Mark milestones as you go
- Follow all coding rules from section 3

### Step 4 — Local Server Review
After build, start dev server and review in browser:
```bash
npm run dev
# open http://localhost:5173/app.html#/<route>
```
Check: layout, mobile view, loading states, empty states, error states, locked states (post-deadline).

### Step 5 — Wrap Up
- Update `memory/frontend-phase.md` — mark file done, add SDK patterns found
- If any RPC/DB decision clarified → update `.claude/skills/db-feature/SKILL.md`
- New CSS pattern added → append to `docs/DESIGN_TOKENS.md`
- Output file path for immediate review

---

## 9. Build Order

### Phase 0 — Vanilla (parallel, before React)
| # | File | Notes |
|---|------|-------|
| 0 | `js/auth.js` | Vanilla: register, login, invite code parse, redirect to app.html |

### Phase 1 — Foundation
| # | File | Notes |
|---|------|-------|
| 1 | `package.json` + `vite.config.js` + `.gitignore` | Init project, install 6 deps, ignore dist/ |
| 2 | `src/lib/supabase.js` | ESM client, hardcoded URL+key |
| 3 | `src/lib/teams.js` | Extract TEAMS[] + HOST_SCHEDULES from main.js as ES exports |
| 4 | `src/context/AuthContext.jsx` | session, user, signOut |
| 5 | `src/context/ToastContext.jsx` | showToast hook |
| 6 | `src/components/Layout.jsx` | page-nav + BottomNav + page-body shell |
| 7 | `src/components/BottomNav.jsx` | Dashboard / Groups / Picks / AI Feed icons + active state |
| 8 | `src/components/Modal.jsx` | Controlled modal |
| 9 | `src/components/GroupSelector.jsx` | Group dropdown (used by Dashboard + AiFeed) |
| 10 | `src/components/Flag.jsx` | flagcdn helper |

### Phase 2 — App Shell
| # | File | Notes |
|---|------|-------|
| 11 | `src/app.html` | Vite entry + font links |
| 12 | `src/main.jsx` | Root + providers + `import '../css/style.css'` |
| 13 | `src/App.jsx` | HashRouter + all routes + auth guard |

→ **Review:** start dev server, confirm routing + auth redirect works

### Phase 3 — Pages

| # | Page | Key Supabase Calls | Review Checklist |
|---|------|--------------------|-----------------|
| 14 | **Dashboard.jsx** | `rpc('get_group_leaderboard')`, `rpc('get_leaderboard')`, today's games query | Group/global toggle, rank badges, champion flag, self highlight, inactive dim, today's games, empty state |
| 15 | **Groups.jsx** | `rpc('create_group')`, `rpc('join_group')`, groups+members select, inactive update | Create/join modals, invite link, captain-only controls, inactive hint text, max 3/10 limits |
| 16 | **Game.jsx** | `from('games').select('*, game_odds(*), game_team_stats(*)')`, predictions upsert, group predictions | Pre/post kickoff states, 90-min score + ET (`et_score_home/away`) + pens (`penalty_score_home/away`), locked form, is_auto badge, stat split |
| 17 | **Picks.jsx** | `champion_pick` upsert, `top_scorer_pick` upsert (must include `top_scorer_api_id`) | 48-team grid, player list, lock warning, locked state after June 11 |
| 18 | **AiFeed.jsx** | `from('ai_summaries').select(...)` | Group selector (GroupSelector.jsx), summary cards, empty state, no-groups state |
| 19 | **Host.jsx** | Static (teams.js) | All 104 games by venue, phase dividers, mobile layout |
| 20 | **Team.jsx** | `from('games')` + team stats | Results, schedule, group info, tabs |
| — | ~~predict.html~~ | — | **Out of scope** — marked [TBD] in CLAUDE.md, skip for now |

Each page: Plan → Blockers → Build → **Local server review** → Wrap up

### Phase 4 — Deploy
| # | Task |
|---|------|
| 21 | `.github/workflows/deploy.yml` — CI pipeline |
| 22 | Wire `index.html` + `js/auth.js` redirect → prod `./app.html#/dashboard` |
| 23 | Push to main → verify GitHub Pages deployment |

---

## 10. Page Specs Quick Reference

| Page | Default view | Empty state | Locked state |
|------|-------------|-------------|--------------|
| Dashboard | Group leaderboard | "Join or create a group" → groups.html | — |
| Game | Pre-kickoff prediction form | — | Form disabled after kick_off_time |
| Picks | Champion grid | — | Disabled after 2026-06-11T19:00Z |
| Groups | My groups list | "You're not in any groups yet" | Rename disabled after June 11 |
| AiFeed | Latest summary cards | "No summaries yet…" | — |

---

## 11. JS Files Status (updated)

| File | Status | Notes |
|------|--------|-------|
| `js/supabase.js` | ✅ complete — do not modify | UMD, used by index.html only |
| `js/main.js` | ✅ complete — do not modify | TEAMS data, used by index.html only; TEAMS extracted to `src/lib/teams.js` for React |
| `js/auth.js` | ❌ missing — **must build (vanilla)** | Register, login, invite parse, redirect to app.html |
| `src/lib/supabase.js` | ❌ missing — build Phase 1 | ESM client for React |
| `src/lib/teams.js` | ❌ missing — build Phase 1 | ES export of TEAMS[] + HOST_SCHEDULES |
| `js/predictions.js` | replaced by React | `Game.jsx` handles predictions |
| `js/leaderboard.js` | replaced by React | `Dashboard.jsx` + `LeaderboardTable.jsx` |
| `js/ai-feed.js` | replaced by React | `AiFeed.jsx` |

---

## 12. Open Questions

| # | Question | Needed before |
|---|----------|--------------|
| Q1 | **Bottom nav design** | ✅ 4 tabs, icon + label. Fine-tune during build. |
| Q2 | **Dev redirect** | ✅ Option B — always build first, test via `dist/`. `auth.js` always uses `./app.html#/dashboard`. |
| Q3 | **`predict.html`** | ✅ Skipped — prediction entry lives in `Game.jsx`. Add as `#/predict` later if needed. |

---

## 13. Wrap-Up Files to Update After Each Session

| File | What to update |
|------|---------------|
| `memory/frontend-phase.md` | Mark page done, SDK patterns used |
| `.claude/skills/db-feature/SKILL.md` | Any RPC or column decision clarified |
| `docs/DESIGN_TOKENS.md` | Any new CSS class or React pattern introduced |
