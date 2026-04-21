---
name: Project Structure
description: File organization decisions made 2026-04-11 — where things live and why
type: project
originSessionId: 1170e1c8-5f86-4e78-bf81-1de3d58aece2
---
## Reorganization done 2026-04-11

### Moves completed
- Root PNGs (`after-click.png`, `before-click.png`, `after-visited.png`) → `screenshots/`
- `test/prompt_v*.csv` (v1–v10) → `test/prompts/`
- All docs CSVs → `docs/data/` (API_DATA_STRUCTURE, API_FULL_SUMMARY, GAME_DATA_SAMPLE, ODDS samples, laliga/snap test CSVs)
- `docs/"Plan Nightly-Summary Edge Function + Prompt Versions Table.md"` renamed → `docs/PLAN_NIGHTLY_SUMMARY.md`
- Playwright artifacts added to `.gitignore` (`.playwright-mcp/`, `.playwright-session.json`, `.playwright-storage.json`, `.vite/`)

### Root legacy HTML duplicates
`dashboard.html`, `host.html`, `team.html`, `server.py` remain at root AND in `archive/` (both copies exist — not deleted per user preference).

### Skipped — docs subdirectory reorganization
Suggested `docs/plans/`, `docs/specs/`, `docs/qa/` structure was NOT implemented.
**Why:** 10+ skill files (`.claude/skills/`) and CLAUDE.md reference `docs/PLAN_*.md`, `docs/DESIGN_TOKENS.md`, etc. by direct path — moving them would break all those internal markdown links across the skills system.

### Key locations
- Prompt test CSVs: `test/prompts/prompt_v1.csv` … `test/prompts/prompt_v10.csv`
- API data CSVs: `docs/data/`
- Playwright/Vite artifacts: gitignored
