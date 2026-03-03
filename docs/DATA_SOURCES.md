# World Cup 2026 — Data Sources (Exact Fields)

---

## API-Football — Fixtures & Scores

**Endpoint:** `GET /fixtures`
**Used by:** `setup-tournament`, `sync-results`, `sync-knockouts`

| Field from API | Stored In | Column |
|---|---|---|
| fixture.id | games | api_football_id |
| fixture.date | games | kick_off_time |
| fixture.venue.name | games | venue |
| fixture.status.short | games | status |
| teams.home.id | games | team_home_id (matched to teams.api_football_id) |
| teams.away.id | games | team_away_id |
| goals.home | games | score_home |
| goals.away | games | score_away |
| score.extratime.home | games | score_home_et |
| score.extratime.away | games | score_away_et |
| score.penalty.home | games | penalties (bool) |
| score.penalty.away | games | penalties (bool) |

---

## API-Football — Match Statistics

**Endpoint:** `GET /fixtures/statistics?fixture={id}`
**Used by:** `sync-results` — after game completed only

| Field from API | Stored In | Column |
|---|---|---|
| team.id | game_results | team_id |
| Shots on Goal | game_results | shots_on_target |
| Total Shots | game_results | shots_total |
| Corner Kicks | game_results | corners |
| Fouls | game_results | fouls |
| Yellow Cards | game_results | yellow_cards |
| Red Cards | game_results | red_cards |
| Ball Possession | game_results | possession |
| Offsides | game_results | offsides |
| goals (derived home/away) | game_results | goals_scored, goals_conceded |

---

## API-Football — Standings

**Endpoint:** `GET /standings?league={wc}&season=2026`
**Used by:** `sync-results` — group stage only

| Field from API | Stored In | Column |
|---|---|---|
| team.id | standings | team_id |
| group | standings | group_letter |
| rank | standings | position |
| points | standings | points |
| all.played | standings | played |
| all.win | standings | wins (derived) |
| all.draw | standings | draws (derived) |
| all.lose | standings | losses (derived) |
| goals.for | standings | goals_scored |
| goals.against | standings | goals_conceded |
| goalsDiff | standings | goal_diff |

---

## API-Football — Players / Squads

**Endpoint:** `GET /players/squads?team={id}`
**Used by:** `setup-tournament`

| Field from API | Stored In | Column |
|---|---|---|
| player.id | players | api_football_id |
| player.name | players | name |
| player.age | players | age |
| player.number | players | shirt_number |
| player.pos | players | position |
| statistics[0].team.name | players | club |

---

## API-Football — Player Statistics

**Endpoint:** `GET /players?fixture={id}`
**Used by:** `sync-results` — after game completed only

| Field from API | Stored In | Column |
|---|---|---|
| player.id | player_tournament_stats | player_id (matched) |
| statistics.goals.total | player_tournament_stats | goals |
| statistics.goals.assists | player_tournament_stats | assists |
| statistics.games.minutes | player_tournament_stats | games_played |
| statistics.cards.yellow | player_tournament_stats | yellow_cards_total / yellow_cards_phase |
| statistics.cards.red | player_tournament_stats | red_cards |

---

## API-Football — Injuries

**Endpoint:** `GET /injuries?league={wc}&season=2026`
**Used by:** `sync-injuries` — daily

| Field from API | Stored In | Column |
|---|---|---|
| player.id | player_unavailability | player_id |
| team.id | player_unavailability | team_id |
| player.name | player_unavailability | player_name |
| fixture.id | player_unavailability | game_id |
| player.type | player_unavailability | injury_type |
| player.reason | player_unavailability | status (out / doubtful) |

---

## API-Football — Teams

**Endpoint:** `GET /teams?league={wc}&season=2026`
**Used by:** `setup-tournament`

| Field from API | Stored In | Column |
|---|---|---|
| team.id | teams | api_football_id |
| team.name | teams | name |
| team.code | teams | code |
| team.logo | teams | flag_url |

---

## Team data.txt — Static Team Data

**Used by:** `setup-tournament` (merged with API-Football teams data)

| Field | Stored In | Column |
|---|---|---|
| FIFA rank | teams | fifa_rank |
| Group letter | teams | group_letter |
| Confederation | teams | confederation |
| WC appearances | teams | wc_appearances |
| WC best result | teams | wc_best_result |

---

## The Odds API

**Endpoint:** `GET /odds?sport=soccer_fifa_world_cup`
**Used by:** `sync-odds` — daily

| Field from API | Stored In | Column |
|---|---|---|
| id (fixture match) | odds | game_id (matched) |
| bookmakers[0].key | odds | bookmaker |
| h2h outcome: Home | odds | home_win |
| h2h outcome: Draw | odds | draw |
| h2h outcome: Away | odds | away_win |
| Derived: 1/home_win | odds | home_prob |
| Derived: 1/draw | odds | draw_prob |
| Derived: 1/away_win | odds | away_prob |

---

## Derived / Computed (no external API)

| Data | Derived From | Stored In | Column |
|---|---|---|---|
| W / D / L result per team | game scores | game_results | result |
| Avg goals scored | game_results aggregated | team_tournament_stats | avg_goals_scored |
| Avg goals conceded | game_results aggregated | team_tournament_stats | avg_goals_conceded |
| Avg corners | game_results aggregated | team_tournament_stats | avg_corners |
| Avg fouls | game_results aggregated | team_tournament_stats | avg_fouls |
| Avg yellow cards | game_results aggregated | team_tournament_stats | avg_yellow_cards |
| Avg possession | game_results aggregated | team_tournament_stats | avg_possession |
| Form string | game_results ordered by date | team_tournament_stats | form |
| Card suspension | yellow_cards_phase >= 2 or red card | player_unavailability | reason |
| Implied probability | 1 / decimal odds | odds | home/draw/away_prob |
| Points earned | prediction vs score | predictions | points_earned |
| User achievements | predictions + game_results | user_achievements | achievement |
| Rank snapshot | leaderboard at time of run | leaderboard_snapshots | rank, total_points |

---

## Edge Function Run Schedule

| Function | Trigger | API Called | Writes To |
|---|---|---|---|
| `setup-tournament` | Manual once (pre June 11 2026) | API-Football | `teams`, `players`, `games` |
| `sync-results` | Every 15 min on matchdays / daily otherwise | API-Football | `games`, `game_results`, `team_tournament_stats`, `standings`, `player_tournament_stats`, `player_unavailability`, `user_achievements` |
| `sync-knockouts` | Daily during knockout phase | API-Football | `games` |
| `sync-odds` | Daily 06:00 UTC | The Odds API | `odds` |
| `sync-injuries` | Daily 08:00 UTC | API-Football | `player_unavailability` |
| `nightly-summary` | Nightly 23:00 UTC | Claude API | `leaderboard_snapshots`, `ai_summaries` |

---

## API Request Volume Estimate

| Function | Frequency | Req / Call | Est. Monthly |
|---|---|---|---|
| `setup-tournament` | Once | ~35 | 35 |
| `sync-results` | 15 min on matchdays | ~5 | ~450 |
| `sync-knockouts` | Daily (knockout phase) | ~2 | ~60 |
| `sync-odds` | Daily | ~3 | ~90 |
| `sync-injuries` | Daily | ~5 | ~150 |
| **API-Football total** | | | **~785 / month** |
| **The Odds API total** | Daily | ~3 | **~90 / month** |
