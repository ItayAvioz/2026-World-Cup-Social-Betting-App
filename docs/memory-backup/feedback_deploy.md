---
name: GitHub Pages deploy process
description: Correct manual deploy steps to gh-pages — dist/ contents must go to ROOT, not a dist/ subfolder
type: feedback
originSessionId: 160ef209-545c-43fc-b9ae-acdde82d9177
---
Deploy to root of `gh-pages`, not into a `dist/` subfolder. The live link is `/app.html` (root), so files must land there.

**Why:** First deploy attempt ran `git checkout main -- dist/` which copied `dist/` as a subfolder. Root `/app.html` was never updated — it kept serving the old JS bundle. Live site showed stale version even after push.

**How to apply:** Manual deploy steps every time:
1. `npm run build` (on main branch)
2. Note the new JS filename from build output (e.g. `app-BqCohTZm.js`)
3. `git stash` (if any unstaged changes)
4. `git checkout gh-pages`
5. **Edit `app.html` at root directly** — update the `src=` JS filename to match the new build. Do NOT rely on `cp dist/app.html .` — it silently fails to stage on Windows.
6. `cp -r dist/assets/* assets/` — copy new JS/CSS assets
7. `git checkout main -- team.html host.html` — restore vanilla mobile pages (NOT in dist/, must be copied from main manually each deploy)
8. `git add app.html assets/ team.html host.html`
9. `git commit -m "Deploy — <description>"`
10. `git push origin gh-pages`
11. `git checkout main && git stash pop`

**Critical:** `team.html` and `host.html` are vanilla pages used by mobile navigation (desktop uses modals). They live in main root, not in dist/. They get wiped on every deploy unless explicitly restored in step 7.

**Critical:** Always verify `app.html` at root points to the correct JS file before committing: `cat app.html | grep src=`

No GitHub Actions workflow exists — deploy is fully manual.
