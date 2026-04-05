# API Test Plan — Football + Odds APIs

**Goal**: Verify both APIs work end-to-end (API → EF → DB) using real league data before WC2026 goes live.

---

## Where to Enter API Keys (Safe)

Keys must **never** go into code files or git. Enter them via terminal only — they go straight into Supabase Vault (encrypted, server-side only).

Run these two commands in the terminal (the `!` prefix runs them in Claude Code's terminal):

```
! supabase secrets set FOOTBALL_API_KEY=<paste_your_football_key_here> --project-ref ftryuvfdihmhlzvbpfeu
! supabase secrets set theoddsapi=<paste_your_odds_key_here> --project-ref ftryuvfdihmhlzvbpfeu
```

**Where to find your keys:**
- Football API key: https://dashboard.api-football.com → My Account → API Key
- Odds API key: https://the-odds-api.com → My Account → API Key

**After setting**, verify they're stored:
```
! supabase secrets list --project-ref ftryuvfdihmhlzvbpfeu
```
Expected output: shows `FOOTBALL_API_KEY` and `theoddsapi` in the list.

---

## Phase 1 — Raw API Verification (no EF, no DB)

Confirm both API keys work and understand the data structure.

### 1A — Football API: Account status + quota check
```
! curl -s "https://v3.football.api-sports.io/status" -H "x-apisports-key: <your_key>"
```
Expected: `{ "account": { "plan": "...", "requests_remaining": ... } }`

### 1B — Football API: Pull Premier League 2024 fixtures (historical, finished games)
- League: Premier League, ID = 39, Season = 2024
- Returns: team names, kickoff times, scores, fixture IDs
- We'll use this to verify the data structure matches what our EF expects

### 1C — Odds API: List available sport keys
```
! curl -s "https://api.the-odds-api.com/v4/sports/?apiKey=<your_key>"
```
Expected: list of sport keys including soccer leagues currently active.
We'll find a live soccer league key to use for testing (WC2026 key = `soccer_fifa_world_cup`, not active yet).

---

## Phase 2 — EF Probe Mode (API → EF, no DB write)

Add a `probe` mode to `football-api-sync` EF that:
- Accepts any `league_id` + `season` (not hardcoded to WC2026)
- Fetches 5 fixtures from that league
- Returns raw API response — **does not write to DB**
- Confirms the EF can reach the API and parse the response

**Test call:**
```json
POST https://ftryuvfdihmhlzvbpfeu.supabase.co/functions/v1/football-api-sync
{ "mode": "probe", "league_id": 39, "season": 2024 }
```

---

## Phase 3 — EF Sync Mode with Historical Game (API → EF → DB)

Test the full write pipeline using a real finished PL game.

Steps:
1. From Phase 1B, pick one finished Premier League fixture (get its `fixture_id`)
2. Insert a test game row into `games` table with that `api_fixture_id`
3. Call `mode=sync` with that game's ID
4. Verify: `score_home`, `score_away`, team stats, player stats written to DB
5. Clean up: delete the test game row after verification

This proves the full pipeline: EF reads API → normalizes data → writes to Supabase.

---

## Phase 4 — Real-Time Test (Live Game)

Test with a game happening today or in the next few hours.

Steps:
1. Find a live/upcoming match via Football API `/fixtures?date=<today>`
2. Insert test game row with that fixture's ID and kickoff time
3. Call `mode=verify` (30min before KO) → confirm kickoff time matches
4. After KO, call `mode=sync` → watch score update in real time
5. Verify stats written after game ends
6. Clean up test row

---

## Phase 5 — Odds EF Test

1. Find an active soccer sport key from Phase 1C (e.g. Premier League = `soccer_england_premier_league`)
2. Temporarily update `sync-odds` EF to use that sport key
3. Call the EF → verify odds land in `game_odds` table
4. Revert EF to `soccer_fifa_world_cup` for production

---

## Phase 6 — WC2026 Setup (when tournament data goes live)

Once FIFA WC2026 fixtures appear on the API:
1. Run `mode=setup` → maps all 104 games to `api_fixture_id`
2. Run `fn_schedule_game_sync()` for all upcoming games
3. Run `fn_schedule_odds_sync()` for odds cron
4. Verify mappings: check how many of 104 games got matched

---

## Success Criteria

| Check | Pass Condition |
|---|---|
| Football API key valid | `/status` returns account info, no 401 |
| Fixtures pull works | Returns team names, dates, scores in expected structure |
| Odds API key valid | `/sports` returns list without 401 |
| EF probe mode | Returns 5 fixtures from PL 2024 |
| EF sync mode | Historical game: score + stats written to DB |
| Real-time sync | Live game: score updates within 5min of FT |
| Odds sync | Odds land in `game_odds` for matched games |

---

## Notes

- Football API rate limit: depends on plan. Each sync call = 1-3 API calls (fixture + stats + players).
- Odds API: free plan has limited requests/month — use sparingly during testing.
- All test DB rows will be cleaned up after each phase.
- EF changes for probe/test are temporary — will be reverted before WC2026 go-live.
