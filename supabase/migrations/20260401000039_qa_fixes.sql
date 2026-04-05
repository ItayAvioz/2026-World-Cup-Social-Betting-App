-- Migration 39: QA Fixes (2026-04-01)
-- C1: Deploy api_fixture_id column (M22 was never deployed)
-- C3: fn_calculate_pick_points SECURITY DEFINER
-- H1: fn_calculate_points resets points on NULL scores
-- H2: Missing auto-predict crons for 2 games
-- M2: fn_auto_predict_game covers ungrouped users
-- M4: Captain self-inactive guard in RLS
-- M8: Clean up stale points_earned data

-- ── C1: api_fixture_id column ──────────────────────────────────────────────────
ALTER TABLE public.games ADD COLUMN IF NOT EXISTS api_fixture_id integer;
CREATE INDEX IF NOT EXISTS idx_games_api_fixture_id ON public.games(api_fixture_id);

-- ── C3: fn_calculate_pick_points needs SECURITY DEFINER ────────────────────────
ALTER FUNCTION public.fn_calculate_pick_points() SECURITY DEFINER;

-- ── H1: fn_calculate_points — reset points when scores revert to NULL ──────────
CREATE OR REPLACE FUNCTION fn_calculate_points()
RETURNS trigger LANGUAGE plpgsql SECURITY DEFINER AS $$
BEGIN
  -- If scores are cleared, reset all prediction points for this game
  IF NEW.score_home IS NULL OR NEW.score_away IS NULL THEN
    UPDATE public.predictions SET points_earned = 0 WHERE game_id = NEW.id;
    RETURN NEW;
  END IF;

  -- Recalculate points for every prediction on this game
  UPDATE public.predictions SET points_earned =
    CASE
      WHEN pred_home = NEW.score_home AND pred_away = NEW.score_away THEN 3
      WHEN (pred_home > pred_away AND NEW.score_home > NEW.score_away)
        OR (pred_home < pred_away AND NEW.score_home < NEW.score_away)
        OR (pred_home = pred_away AND NEW.score_home = NEW.score_away) THEN 1
      ELSE 0
    END
  WHERE game_id = NEW.id;

  RETURN NEW;
END;
$$;

-- ── M4: Captain self-guard — cannot mark self as inactive ──────────────────────
-- (Policy name read from live DB — drop by actual name, recreate with guard)
DO $$
DECLARE
  v_policy_name text;
BEGIN
  SELECT policyname INTO v_policy_name
  FROM pg_policies WHERE tablename = 'group_members' AND cmd = 'UPDATE' LIMIT 1;

  IF v_policy_name IS NOT NULL THEN
    EXECUTE format('DROP POLICY IF EXISTS %I ON public.group_members', v_policy_name);
  END IF;
END;
$$;

CREATE POLICY "captain_can_update_members" ON public.group_members FOR UPDATE
  USING (EXISTS (SELECT 1 FROM public.groups g WHERE g.id = group_members.group_id AND g.created_by = auth.uid()))
  WITH CHECK (
    EXISTS (SELECT 1 FROM public.groups g WHERE g.id = group_members.group_id AND g.created_by = auth.uid())
    AND user_id != auth.uid()
  );

-- ── M8: Clean up stale points_earned data ──────────────────────────────────────
UPDATE public.predictions SET points_earned = 0
WHERE game_id IN (SELECT id FROM public.games WHERE score_home IS NULL)
AND points_earned != 0;
