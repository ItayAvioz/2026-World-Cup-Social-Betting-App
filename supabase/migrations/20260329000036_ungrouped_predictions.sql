-- ================================================================
-- Migration 36: Ungrouped predictions
-- ================================================================
-- Allows predictions.group_id to be NULL so users who are not in
-- any group can still predict games (one prediction per game).
-- Users in groups continue to predict per-group (group_id NOT NULL).
--
-- Constraint: UNIQUE NULLS NOT DISTINCT (user_id, game_id, group_id)
--   → two rows with same user_id + game_id + NULL group_id conflict
--   → enforces "one ungrouped prediction per user per game"
--   → requires PostgreSQL 15+ (Supabase default as of 2025+)
--
-- RLS: INSERT/UPDATE now allow group_id IS NULL in addition to
--   the existing is_group_member check.
--
-- Leaderboard scoring of ungrouped predictions is future work
-- (get_leaderboard already handles NULL group via LEFT JOIN, but
--  the JOIN condition pr.group_id = gm.group_id won't match NULL
--  predictions without further changes).
--
-- Auto-predict (fn_auto_predict_game) still only covers grouped
-- users (loops group_members). Ungrouped auto-predict is future work.
-- ================================================================


-- ----------------------------------------------------------------
-- 1. Allow NULL group_id
-- ----------------------------------------------------------------

ALTER TABLE public.predictions
  ALTER COLUMN group_id DROP NOT NULL;


-- ----------------------------------------------------------------
-- 2. Replace unique constraint to treat NULLs as equal
--    (NULLS NOT DISTINCT = two rows with NULL group_id conflict)
-- ----------------------------------------------------------------

ALTER TABLE public.predictions
  DROP CONSTRAINT IF EXISTS predictions_user_game_group_unique;

ALTER TABLE public.predictions
  ADD CONSTRAINT predictions_user_game_group_unique
  UNIQUE NULLS NOT DISTINCT (user_id, game_id, group_id);


-- ----------------------------------------------------------------
-- 3. Update INSERT policy — allow NULL group_id (ungrouped users)
-- ----------------------------------------------------------------

DROP POLICY IF EXISTS "predictions: insert" ON public.predictions;

CREATE POLICY "predictions: insert"
  ON public.predictions
  FOR INSERT
  WITH CHECK (
    auth.uid() = user_id
    AND (
      group_id IS NULL
      OR public.is_group_member(group_id, auth.uid())
    )
    AND now() < (SELECT kick_off_time FROM public.games WHERE id = game_id)
  );


-- ----------------------------------------------------------------
-- 4. Update UPDATE policy — allow NULL group_id
-- ----------------------------------------------------------------

DROP POLICY IF EXISTS "predictions: update" ON public.predictions;

CREATE POLICY "predictions: update"
  ON public.predictions
  FOR UPDATE
  USING (auth.uid() = user_id)
  WITH CHECK (
    auth.uid() = user_id
    AND (
      group_id IS NULL
      OR public.is_group_member(group_id, auth.uid())
    )
    AND now() < (SELECT kick_off_time FROM public.games WHERE id = game_id)
  );


-- ----------------------------------------------------------------
-- 5. Tighten SELECT policy: ungrouped predictions are owner-only
--    Group-scoped predictions remain visible to group members
--    post-kickoff (existing share_a_group behaviour unchanged).
-- ----------------------------------------------------------------

DROP POLICY IF EXISTS "predictions: select" ON public.predictions;

CREATE POLICY "predictions: select"
  ON public.predictions
  FOR SELECT
  USING (
    auth.uid() = user_id
    OR (
      group_id IS NOT NULL
      AND public.share_a_group(user_id)
      AND now() >= (SELECT kick_off_time FROM public.games WHERE id = game_id)
    )
  );
