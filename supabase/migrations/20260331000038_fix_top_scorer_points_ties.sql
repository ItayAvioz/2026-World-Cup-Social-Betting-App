-- Migration 38: Fix top scorer points to award all tied players
-- Before: LIMIT 1 → only one player got points even if multiple tied at max goals
-- After: finds ALL players at max goals, awards 10pts to anyone who picked any of them

CREATE OR REPLACE FUNCTION fn_calculate_pick_points()
RETURNS trigger LANGUAGE plpgsql AS $$
DECLARE
  v_max_goals      bigint;
  v_top_scorer_ids int[];
BEGIN
  IF NEW.phase = 'final'
     AND NEW.knockout_winner IS NOT NULL
     AND (OLD.knockout_winner IS NULL OR OLD.knockout_winner != NEW.knockout_winner)
  THEN
    -- Champion points
    UPDATE public.champion_pick SET points_earned = 0;
    UPDATE public.champion_pick SET points_earned = 10
    WHERE team = NEW.knockout_winner;

    -- Top scorer points — award ALL players tied at max goals
    SELECT MAX(total_goals) INTO v_max_goals
    FROM public.player_tournament_stats;

    IF v_max_goals IS NOT NULL AND v_max_goals > 0 THEN
      SELECT ARRAY_AGG(api_player_id) INTO v_top_scorer_ids
      FROM public.player_tournament_stats
      WHERE total_goals = v_max_goals;

      UPDATE public.top_scorer_pick SET points_earned = 0;
      UPDATE public.top_scorer_pick SET points_earned = 10
      WHERE top_scorer_api_id = ANY(v_top_scorer_ids);
    END IF;
  END IF;
  RETURN NEW;
END;
$$;
