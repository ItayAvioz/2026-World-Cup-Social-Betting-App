-- Migration 28: Add group_name column to get_leaderboard()

DROP FUNCTION IF EXISTS public.get_leaderboard();

CREATE OR REPLACE FUNCTION public.get_leaderboard()
RETURNS TABLE (
  rank              bigint,
  user_id           uuid,
  username          text,
  group_name        text,
  champion_team     text,
  top_scorer_player text,
  total_points      bigint,
  exact_scores      bigint
)
LANGUAGE sql
STABLE
SECURITY DEFINER
AS $$
  SELECT
    RANK() OVER (
      ORDER BY
        COALESCE(SUM(pr.points_earned), 0)
          + COALESCE(cp.points_earned, 0)
          + COALESCE(ts.points_earned, 0) DESC,
        COUNT(*) FILTER (WHERE pr.points_earned = 3) DESC,
        p.username ASC
    )                                                           AS rank,
    p.id                                                        AS user_id,
    p.username,
    (
      SELECT g.name
      FROM public.group_members gm
      JOIN public.groups g ON g.id = gm.group_id
      WHERE gm.user_id = p.id
      ORDER BY gm.joined_at ASC
      LIMIT 1
    )                                                           AS group_name,
    cp.team                                                     AS champion_team,
    ts.player_name                                              AS top_scorer_player,
    COALESCE(SUM(pr.points_earned), 0)
      + COALESCE(cp.points_earned, 0)
      + COALESCE(ts.points_earned, 0)                           AS total_points,
    COUNT(*) FILTER (WHERE pr.points_earned = 3)                AS exact_scores
  FROM public.profiles p
  LEFT JOIN public.predictions     pr ON pr.user_id = p.id
  LEFT JOIN public.champion_pick   cp ON cp.user_id = p.id
  LEFT JOIN public.top_scorer_pick ts ON ts.user_id = p.id
  GROUP BY p.id, p.username, cp.team, cp.points_earned, ts.player_name, ts.points_earned
  ORDER BY rank, p.username ASC;
$$;
