-- ================================================================
-- WORLDCUP 2026 — Migration 48: Add avg_offsides to team_tournament_stats
-- Recreates the view (DROP required to insert column mid-definition).
-- ================================================================

DROP VIEW public.team_tournament_stats;

CREATE VIEW public.team_tournament_stats
  WITH (security_invoker = true)
AS
SELECT
  ts.team,
  COUNT(*)                                                    AS games_played,
  COUNT(*) FILTER (WHERE
    (g.team_home = ts.team AND g.score_home > g.score_away)
    OR (g.team_away = ts.team AND g.score_away > g.score_home)
  )                                                           AS wins,
  COUNT(*) FILTER (WHERE g.score_home = g.score_away)        AS draws,
  COUNT(*) FILTER (WHERE
    (g.team_home = ts.team AND g.score_home < g.score_away)
    OR (g.team_away = ts.team AND g.score_away < g.score_home)
  )                                                           AS losses,
  ROUND(AVG(ts.possession),        1)                         AS avg_possession,
  ROUND(AVG(ts.shots_total),       1)                         AS avg_shots_total,
  ROUND(AVG(ts.shots_on_target),   1)                         AS avg_shots_on_target,
  ROUND(AVG(ts.corners),           1)                         AS avg_corners,
  ROUND(AVG(ts.fouls),             1)                         AS avg_fouls,
  ROUND(AVG(ts.yellow_cards),      1)                         AS avg_yellow_cards,
  ROUND(AVG(ts.red_cards),         1)                         AS avg_red_cards,
  ROUND(AVG(ts.offsides),          1)                         AS avg_offsides,
  ROUND(AVG(
    CASE WHEN g.team_home = ts.team THEN g.score_home ELSE g.score_away END
  ), 1)                                                       AS avg_goals_scored,
  ROUND(AVG(
    CASE WHEN g.team_home = ts.team THEN g.score_away ELSE g.score_home END
  ), 1)                                                       AS avg_goals_conceded
FROM public.game_team_stats ts
JOIN public.games g ON g.id = ts.game_id
WHERE g.score_home IS NOT NULL
GROUP BY ts.team;

GRANT SELECT ON public.team_tournament_stats TO anon, authenticated;
