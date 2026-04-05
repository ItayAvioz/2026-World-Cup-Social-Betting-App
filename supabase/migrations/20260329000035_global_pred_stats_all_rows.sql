-- ================================================================
-- Migration 35: get_global_prediction_stats — count all rows
-- ================================================================
-- Remove DISTINCT ON deduplication. Count every prediction row:
-- same user in 3 groups = 3 predictions counted.
-- Handles future support for group-less predictions automatically.
-- ================================================================

CREATE OR REPLACE FUNCTION public.get_global_prediction_stats(p_game_id uuid)
RETURNS TABLE (
  total      bigint,
  home_wins  bigint,
  draws      bigint,
  away_wins  bigint,
  g01        bigint,
  g23        bigint,
  g4p        bigint
)
LANGUAGE sql
STABLE
SECURITY DEFINER
AS $$
  SELECT
    COUNT(*)                                                      AS total,
    COUNT(*) FILTER (WHERE pr.pred_home > pr.pred_away)           AS home_wins,
    COUNT(*) FILTER (WHERE pr.pred_home = pr.pred_away)           AS draws,
    COUNT(*) FILTER (WHERE pr.pred_home < pr.pred_away)           AS away_wins,
    COUNT(*) FILTER (WHERE pr.pred_home + pr.pred_away <= 1)      AS g01,
    COUNT(*) FILTER (WHERE pr.pred_home + pr.pred_away BETWEEN 2 AND 3) AS g23,
    COUNT(*) FILTER (WHERE pr.pred_home + pr.pred_away >= 4)      AS g4p
  FROM public.predictions pr
  JOIN public.games g ON g.id = pr.game_id AND g.kick_off_time <= NOW()
  WHERE pr.game_id = p_game_id;
$$;
