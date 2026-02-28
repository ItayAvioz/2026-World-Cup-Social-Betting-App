# WorldCup 2026 — Social Prediction Game

A social predictions app for the 2026 FIFA World Cup. Compete with friends in private groups — predict match results, pick the tournament champion and top scorer, climb the leaderboard, and get roasted nightly by AI.

---

## What it does

- **Predict** every match scoreline before kickoff
- **Pick** your tournament champion and top scorer before June 11
- **Compete** in private friend groups with their own leaderboard
- **Watch** predictions reveal the moment the whistle blows
- **See** group vs global prediction stats per game
- **Read** a nightly AI-generated roast of your group's standings

## Scoring

| Prediction | Points |
|---|---|
| Correct outcome (win / draw / loss) | 1 |
| Exact scoreline | 3 |
| Correct champion | 10 |
| Correct top scorer | 10 |

## Groups

- One user creates a group and shares a WhatsApp invite link
- Friends click the link, register, and automatically join the group
- Each group has its own leaderboard and nightly AI summary
- Users can belong to multiple groups

## Tech Stack

| Layer | Technology |
|---|---|
| Frontend | Vanilla HTML + CSS + JavaScript |
| Auth / Database | Supabase (PostgreSQL + Auth + RLS) |
| Backend logic | Supabase Edge Functions |
| AI summaries | Claude API (nightly cron) |
| Game data | Football API (automatic) |
| Hosting | GitHub Pages |

## Project Status

Under active development. Tournament starts **June 11, 2026**.
