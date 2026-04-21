# WorldCup 2026 — Memory Index

## Project
Semi-public social predictions app for FIFA World Cup 2026.
Stack: **React + Vite** (inner pages) + Vanilla HTML/JS (landing) + Supabase + Claude API. GitHub Pages hosting.
Mobile-first, dark theme, users arrive via WhatsApp invite link.

## Supabase
- URL: https://ftryuvfdihmhlzvbpfeu.supabase.co
- Anon key: in js/supabase.js (safe to expose)
- Client pattern: `_supabase` from js/supabase.js (UMD CDN, window.supabase)

## Active Phase
✅ **LIVE ON GITHUB PAGES** — App deployed 2026-04-05 and verified working end-to-end.
✅ **nightly-summary EF ACTIVE + live tested** (2026-04-12, 5 groups processed, real La Liga/PL data, cron bug fixed).
✅ **Prompt v10 ACTIVE** (2026-04-10) — iterated v1→v10, all test CSVs in test/prompts/prompt_v*.csv.
✅ **Cron bug fixed M56** (2026-04-12) — `fn_schedule_ai_summaries()` body was `::text` not `jsonb`; silent failure; fixed.
✅ **feature/nightly-summary merged to main** (2026-04-12).
✅ **Groups focus-game fix** (2026-04-12) — now shows ALL live games regardless of KO time (not just exact same KO). Max 4 simultaneous (WC Jun 27). Query limit raised to 5.
✅ **Game page + Dashboard UI fixes** (2026-04-13) — 3 fixes: (1) LIVE badge on Dashboard (time-based: after KO + score=null + within 120min); (2) W/D/L form badges in Tournament Stats (colored, chronological order); (3) All-groups predictions on Game page — each group shows own pick, Predict/Edit per group, form labeled with group name.
✅ **AI Feed Total standings** (2026-04-21) — Total standings toggle per summary card (group rank + total pts). Global rank computed in EF v14, stored in ai_summaries.display_data (never sent to LLM). Auto-hidden on old summaries (display_data null), auto-appears on new ones. M57 deployed.
**Next:** Clean up test data (The Legends group + test games/fake scores), run fn_schedule_ai_summaries() after real WC games seeded.

## Deployment
- Landing + register/login: https://itayavioz.github.io/2026-World-Cup-Social-Predicting-App/
- React app entry: https://itayavioz.github.io/2026-World-Cup-Social-Predicting-App/app.html#/dashboard
- GitHub Pages: `gh-pages` branch, `/ (root)` — **no GitHub Actions, fully manual**
- Architecture: vanilla `index.html` landing (intentional) → login → `app.html` React SPA
- [Deploy steps](feedback_deploy.md) — copy dist/ contents to ROOT of gh-pages (not dist/ subfolder)

## Feedback
- [Commit means commit only](feedback_commit_no_push.md) — "commit" = local commit only, never push unless explicitly asked
- [API keys in vault only](feedback_api_keys.md) — keys live ONLY in Supabase vault, never ask for values, never put in frontend/.env
- [API stats null→0 fix](feedback_api_stats_null.md) — API Football returns null for offsides (and possibly others) when count=0; use `?? 0` for all count fields in writeTeamStats; gk_saves/gk_conceded pending bug
- [Odds sources](feedback_odds_sources.md) — game odds: API Football Bet365 only; champion odds: TheOddsAPI William Hill only; single source per data type
- [Deploy to gh-pages](feedback_deploy.md) — copy dist/ contents to ROOT, not dist/ subfolder; fully manual, no GitHub Actions
- [team.html data duplication](feedback_team_html_duplication.md) — team.html has own hardcoded TEAMS+TEAM_EXTRA (independent of js/main.js); any team edit must be applied to BOTH files; approved fix: load js/main.js via script tag instead

## Phase Memory Files
- `memory/db-phase.md` — schema, migrations 1–25, RPCs, decisions, test pages
- `memory/edge-function-phase.md` — EF status, vault config, football-api-sync error handling audit (2026-04-11)
- `memory/frontend-phase.md` — React+Vite migration status, page/component build tracker
- `memory/qa-round2.md` — 6 edge-case bugs found + fixed (2026-04-01)
- `memory/qa-round3.md` — 8 issues: contrarian logic, RLS fix, auth param, max 3 groups, join deadline, ungrouped migration, stats, vault fix (2026-04-02)
- `memory/api-pull-plan.md` — API Football data pull plan: teams + players from API (not hardcoded) ← NEXT
- Point 7 (player rating): two ideas to decide — 1) Game page stat (players sorted by rating), 2) AI summary context (top 3 rated fed to prompt). Details in `memory/edge-function-phase.md`.

## Skills
- `/verify-feature [0-9]` — test runner: DB checks + browser test + feedback report + memory update ← USE NOW
- `/db-feature [name]` — ERD + RLS planner (SKILL.md = live ERD source of truth)
- `/frontend [page|file]` — full workflow: read → plan → fill gaps → build → update memory → link → auto-chains /ux ← READY
- `/ux [page|file]` — UX audit: mobile, visual, states, a11y, component reuse → prioritized report → ask before fix ← AUTO after /frontend
- `/edge-function [nightly-summary|football-api-sync]` — EF builder: pre-checks → questions → build → deploy → auto-verify → report → memory update ← ACTIVE
- `/tips` — Claude Code tips

## Dashboard
- [My Stats counting rules](dashboard-stats.md) — Exact%/Predicted%/Streak count from 2026-04-11 (test data exclusion), definitions, impl notes

## Structure
- [Project structure](project_structure.md) — reorganization decisions 2026-04-11 (what moved where, what was skipped)

## Key Files
- CLAUDE.md — app characterization + file structure
- docs/UX_PATTERNS.md — spacing grid, touch targets, state patterns, a11y rules, do/don'ts (used by /ux)
- .claude/skills/db-feature/SKILL.md — live ERD + RLS (always up to date)
- docs/PLAN_REACT_VITE.md — React+Vite migration plan (full build order) ← ACTIVE
- supabase/migrations/ — 57 migrations (all deployed): 53: prompt_versions + fn_schedule_ai_summaries 150min + v1 prompt; 54: ai_summaries LLM fields; 55: prompt_versions LLM test fields; 56: fix fn_schedule_ai_summaries body type (::text→jsonb); 57: ai_summaries.display_data jsonb
- supabase/functions/football-api-sync/index.ts — ✅ deployed v24 ACTIVE (v22: +passes_total/passes_accuracy; v19: Bet365 odds; v18: VAR red_cards; v23–v24: incremental tweaks, changelog not recorded)
- docs/QA_REPORT.md — full QA report (22 initial issues + 6 edge-case issues, all fixed)
- supabase/functions/sync-odds/index.ts — ✅ deployed v14 ACTIVE (v14: USA→United States map + filter non-WC long-shots from champion_odds; v13: removed dead handleDefaultSync; v12: William Hill only)
- docs/data/API_FULL_SUMMARY.csv — full API field verification (api-football + theoddsapi, all 7 sections)
- supabase/functions/nightly-summary/index.ts — ✅ deployed v14 ACTIVE (2026-04-21, +step 7d all-time global rank deduped, +step 8g writes display_data.global_ranks to ai_summaries; never in LLM payload)
- supabase/CLAUDE.md — deployed migrations log + EF status + pending setup
- docs/PLAN_API_SYNC.md — EF architecture, cron lifecycle, post-deploy setup order
- docs/DATA_SOURCES.md — API field mappings (api-football.com + theoddsapi.com)
- docs/ERROR_HANDLING.md — error groups 1–7 (API sync) + A–D (nightly summary) + implementation status table (audited 2026-04-11) + recommended fix order
- js/main.js — TEAMS array + HOST_SCHEDULES (all 104 games) — to be extracted to src/lib/teams.js
