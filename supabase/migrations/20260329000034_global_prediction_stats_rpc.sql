-- ================================================================
-- Migration 34: get_global_prediction_stats(game_id)
-- ================================================================
-- Returns aggregate prediction distribution for a game across ALL
-- users globally, bypassing RLS (SECURITY DEFINER).
-- Only callable after kick_off_time to avoid revealing distributions
-- before the game starts.
-- Deduplicates per user (each user counted once, picks earliest group).
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
  WITH kickoff_check AS (
    SELECT kick_off_time FROM public.games WHERE id = p_game_id
  ),
  deduped AS (
    SELECT DISTINCT ON (pr.user_id)
      pr.pred_home,
      pr.pred_away
    FROM public.predictions pr
    JOIN kickoff_check kc ON kc.kick_off_time <= NOW()
    WHERE pr.game_id = p_game_id
    ORDER BY pr.user_id, pr.group_id
  )
  SELECT
    COUNT(*)                                                      AS total,
    COUNT(*) FILTER (WHERE pred_home > pred_away)                 AS home_wins,
    COUNT(*) FILTER (WHERE pred_home = pred_away)                 AS draws,
    COUNT(*) FILTER (WHERE pred_home < pred_away)                 AS away_wins,
    COUNT(*) FILTER (WHERE pred_home + pred_away <= 1)            AS g01,
    COUNT(*) FILTER (WHERE pred_home + pred_away BETWEEN 2 AND 3) AS g23,
    COUNT(*) FILTER (WHERE pred_home + pred_away >= 4)            AS g4p
  FROM deduped;
$$;
