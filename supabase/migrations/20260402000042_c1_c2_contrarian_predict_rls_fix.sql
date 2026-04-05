-- Migration 42: C1 (contrarian auto-predict) + C2 (predictions SELECT RLS fix)
--
-- C1: fn_auto_predict_game — contrarian logic was present in M24 but lost
--     when M30 rewrote the function for per-group predictions. This restores
--     the least-popular-outcome logic for both grouped and ungrouped users.
--     Tiebreak priority: away_win > draw > home_win.
--
-- C2: predictions SELECT RLS — the M36 rewrite used share_a_group(user_id)
--     which returns TRUE if any group is shared, leaking predictions across
--     groups. Replaced with is_group_member(group_id, auth.uid()) so a user
--     can only see predictions scoped to groups they belong to.

-- ============================================================
-- C1: Rewrite fn_auto_predict_game with contrarian logic
-- ============================================================
CREATE OR REPLACE FUNCTION public.fn_auto_predict_game(p_game_id uuid)
RETURNS void
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
  v_combo   record;
  v_user_id uuid;
  v_home    int;
  v_away    int;
  v_hw      bigint;  -- home win count
  v_dr      bigint;  -- draw count
  v_aw      bigint;  -- away win count
  v_min_val bigint;
  v_outcome text;    -- 'home_win', 'draw', 'away_win'
BEGIN
  -- ============================================================
  -- GROUPED USERS: one prediction per (user, group) combo
  -- ============================================================
  FOR v_combo IN
    SELECT DISTINCT gm.user_id, gm.group_id
    FROM public.group_members gm
    WHERE NOT EXISTS (
      SELECT 1 FROM public.predictions pr
      WHERE pr.user_id  = gm.user_id
        AND pr.game_id  = p_game_id
        AND pr.group_id = gm.group_id
    )
  LOOP
    -- Count existing W/D/L predictions for this game IN THIS GROUP
    SELECT
      COUNT(*) FILTER (WHERE pred_home > pred_away),
      COUNT(*) FILTER (WHERE pred_home = pred_away),
      COUNT(*) FILTER (WHERE pred_home < pred_away)
    INTO v_hw, v_dr, v_aw
    FROM public.predictions
    WHERE game_id = p_game_id
      AND group_id = v_combo.group_id;

    -- Find the least popular outcome
    -- Tiebreak priority: away_win > draw > home_win
    v_min_val := LEAST(v_hw, v_dr, v_aw);

    IF    v_aw = v_min_val THEN v_outcome := 'away_win';
    ELSIF v_dr = v_min_val THEN v_outcome := 'draw';
    ELSE                        v_outcome := 'home_win';
    END IF;

    -- Generate a score matching the chosen outcome
    IF v_outcome = 'draw' THEN
      v_home := floor(random() * 6)::int;  -- 0-5
      v_away := v_home;
    ELSIF v_outcome = 'home_win' THEN
      v_home := floor(random() * 5)::int + 1;  -- 1-5
      v_away := floor(random() * v_home)::int;  -- 0 to v_home-1
    ELSE  -- away_win
      v_away := floor(random() * 5)::int + 1;  -- 1-5
      v_home := floor(random() * v_away)::int;  -- 0 to v_away-1
    END IF;

    INSERT INTO public.predictions (user_id, game_id, group_id, pred_home, pred_away, is_auto)
    VALUES (v_combo.user_id, p_game_id, v_combo.group_id, v_home, v_away, true)
    ON CONFLICT (user_id, game_id, group_id) DO NOTHING;
  END LOOP;

  -- ============================================================
  -- UNGROUPED USERS (profiles not in any group)
  -- ============================================================
  FOR v_user_id IN
    SELECT p.id FROM public.profiles p
    WHERE NOT EXISTS (SELECT 1 FROM public.group_members gm WHERE gm.user_id = p.id)
    AND NOT EXISTS (
      SELECT 1 FROM public.predictions pr
      WHERE pr.user_id = p.id AND pr.game_id = p_game_id AND pr.group_id IS NULL
    )
  LOOP
    -- Count existing W/D/L predictions for this game WHERE group_id IS NULL
    SELECT
      COUNT(*) FILTER (WHERE pred_home > pred_away),
      COUNT(*) FILTER (WHERE pred_home = pred_away),
      COUNT(*) FILTER (WHERE pred_home < pred_away)
    INTO v_hw, v_dr, v_aw
    FROM public.predictions
    WHERE game_id = p_game_id
      AND group_id IS NULL;

    -- Find the least popular outcome (same tiebreak: away > draw > home)
    v_min_val := LEAST(v_hw, v_dr, v_aw);

    IF    v_aw = v_min_val THEN v_outcome := 'away_win';
    ELSIF v_dr = v_min_val THEN v_outcome := 'draw';
    ELSE                        v_outcome := 'home_win';
    END IF;

    -- Generate a score matching the chosen outcome
    IF v_outcome = 'draw' THEN
      v_home := floor(random() * 6)::int;  -- 0-5
      v_away := v_home;
    ELSIF v_outcome = 'home_win' THEN
      v_home := floor(random() * 5)::int + 1;  -- 1-5
      v_away := floor(random() * v_home)::int;  -- 0 to v_home-1
    ELSE  -- away_win
      v_away := floor(random() * 5)::int + 1;  -- 1-5
      v_home := floor(random() * v_away)::int;  -- 0 to v_away-1
    END IF;

    INSERT INTO public.predictions (user_id, game_id, group_id, pred_home, pred_away, is_auto)
    VALUES (v_user_id, p_game_id, NULL, v_home, v_away, true)
    ON CONFLICT ON CONSTRAINT predictions_user_game_group_unique DO NOTHING;
  END LOOP;

  -- Self-unschedule the cron job
  PERFORM cron.unschedule('auto-predict-' || p_game_id::text);
END;
$$;

-- ============================================================
-- C2: Fix predictions SELECT RLS — use is_group_member not share_a_group
-- ============================================================
-- Old policy (from M36) used share_a_group(user_id) which returns TRUE
-- if the viewer shares ANY group with the prediction owner — allowing
-- cross-group prediction visibility. Replace with is_group_member(group_id, ...)
-- so only predictions within shared groups are visible.

DROP POLICY IF EXISTS "predictions: select" ON public.predictions;

CREATE POLICY "predictions: select" ON public.predictions
FOR SELECT USING (
  auth.uid() = user_id
  OR (
    group_id IS NOT NULL
    AND is_group_member(group_id, auth.uid())
    AND EXISTS (
      SELECT 1 FROM public.games g
      WHERE g.id = predictions.game_id
        AND g.kick_off_time <= now()
    )
  )
);
