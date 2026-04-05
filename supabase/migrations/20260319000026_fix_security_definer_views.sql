-- ================================================================
-- WORLDCUP 2026 — Migration 26: Fix SECURITY DEFINER views
-- Problem: leaderboard, team_tournament_stats, player_tournament_stats
--          were implicitly SECURITY DEFINER (postgres role), bypassing RLS.
-- Fix:     Recreate all three with SECURITY INVOKER + grant public SELECT.
-- ================================================================


-- ----------------------------------------------------------------
-- 1. leaderboard VIEW — SECURITY INVOKER
--    Internal view used by get_leaderboard() and get_group_leaderboard() RPCs.
--    Clients always query via the SECURITY DEFINER RPCs, not this view directly.
-- ----------------------------------------------------------------

CREATE OR REPLACE VIEW public.leaderboard
  WITH (security_invoker = true)
AS
SELECT
  p.id                                                          AS user_id,
  p.username,
  cp.team                                                       AS champion_team,
  COALESCE(SUM(pr.points_earned), 0)
    + COALESCE(cp.points_earned, 0)
    + COALESCE(ts.points_earned, 0)                             AS total_points,
  COUNT(*) FILTER (WHERE pr.points_earned = 3)                  AS exact_scores,
  RANK() OVER (
    ORDER BY
      COALESCE(SUM(pr.points_earned), 0)
        + COALESCE(cp.points_earned, 0)
        + COALESCE(ts.points_earned, 0) DESC,
      COUNT(*) FILTER (WHERE pr.points_earned = 3) DESC,
      p.username ASC
  )                                                             AS rank
FROM public.profiles p
LEFT JOIN public.predictions     pr ON pr.user_id = p.id
LEFT JOIN public.champion_pick   cp ON cp.user_id = p.id
LEFT JOIN public.top_scorer_pick ts ON ts.user_id = p.id
GROUP BY p.id, p.username, cp.team, cp.points_earned, ts.points_earned;


-- ----------------------------------------------------------------
-- 2. team_tournament_stats VIEW — SECURITY INVOKER
--    Public read: tournament-aggregated team stats for game.html.
--    Underlying tables (game_team_stats, games) have public RLS read policies.
-- ----------------------------------------------------------------

CREATE OR REPLACE VIEW public.team_tournament_stats
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
  ROUND(AVG(ts.possession),      1)                          AS avg_possession,
  ROUND(AVG(ts.shots_total),     1)                          AS avg_shots_total,
  ROUND(AVG(ts.shots_on_target), 1)                          AS avg_shots_on_target,
  ROUND(AVG(ts.corners),         1)                          AS avg_corners,
  ROUND(AVG(ts.fouls),           1)                          AS avg_fouls,
  ROUND(AVG(ts.yellow_cards),    1)                          AS avg_yellow_cards,
  ROUND(AVG(ts.red_cards),       1)                          AS avg_red_cards,
  ROUND(AVG(
    CASE WHEN g.team_home = ts.team THEN g.score_home ELSE g.score_away END
  ), 1)                                                       AS avg_goals_scored,
  ROUND(AVG(
    CASE WHEN g.team_home = ts.team THEN g.score_away ELSE g.score_home END
  ), 1)                                                       AS avg_goals_conceded
FROM public.game_team_stats ts
JOIN public.games g ON g.id = ts.game_id
WHERE g.score_home IS NOT NULL   -- finished games only
GROUP BY ts.team;


-- ----------------------------------------------------------------
-- 3. player_tournament_stats VIEW — SECURITY INVOKER
--    Public read: tournament-aggregated player stats.
--    Underlying tables (game_player_stats, games) have public RLS read policies.
-- ----------------------------------------------------------------

CREATE OR REPLACE VIEW public.player_tournament_stats
  WITH (security_invoker = true)
AS
SELECT
  ps.api_player_id,
  ps.player_name,
  ps.team,
  SUM(ps.goals)         AS total_goals,
  SUM(ps.assists)       AS total_assists,
  SUM(ps.yellow_cards)  AS total_yellow_cards,
  SUM(ps.red_cards)     AS total_red_cards,
  COUNT(*)              AS games_played
FROM public.game_player_stats ps
JOIN public.games g ON g.id = ps.game_id
WHERE g.score_home IS NOT NULL   -- finished games only
GROUP BY ps.api_player_id, ps.player_name, ps.team
ORDER BY total_goals DESC, total_assists DESC;


-- ----------------------------------------------------------------
-- 4. Grant SELECT on views to anon + authenticated
-- ----------------------------------------------------------------

GRANT SELECT ON public.leaderboard               TO anon, authenticated;
GRANT SELECT ON public.team_tournament_stats     TO anon, authenticated;
GRANT SELECT ON public.player_tournament_stats   TO anon, authenticated;


-- ----------------------------------------------------------------
-- 5. Grant SELECT on underlying tables for stats views
--    (required for SECURITY INVOKER views to work for anon/authenticated)
-- ----------------------------------------------------------------

GRANT SELECT ON public.games              TO anon, authenticated;
GRANT SELECT ON public.game_team_stats    TO anon, authenticated;
GRANT SELECT ON public.game_player_stats  TO anon, authenticated;
