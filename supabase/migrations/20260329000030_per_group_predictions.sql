-- ================================================================
-- Migration 30: Per-group predictions
-- ================================================================
-- Changes UNIQUE(user_id, game_id) → UNIQUE(user_id, game_id, group_id).
-- Each user has one prediction per (game, group).
-- Updates auto-predict, leaderboard RPCs accordingly.
-- Safe to migrate existing rows: assigns first group (by joined_at).
-- ================================================================


-- ----------------------------------------------------------------
-- 1. Add group_id (nullable for safe migration)
-- ----------------------------------------------------------------

ALTER TABLE public.predictions
  ADD COLUMN group_id uuid REFERENCES public.groups(id) ON DELETE CASCADE;


-- ----------------------------------------------------------------
-- 2. Assign first group to existing prediction rows
-- ----------------------------------------------------------------

UPDATE public.predictions p
SET group_id = (
  SELECT gm.group_id
  FROM public.group_members gm
  WHERE gm.user_id = p.user_id
  ORDER BY gm.joined_at ASC
  LIMIT 1
);

-- Remove rows with no group (user somehow not in any group)
DELETE FROM public.predictions WHERE group_id IS NULL;


-- ----------------------------------------------------------------
-- 3. Enforce NOT NULL, replace unique constraint
-- ----------------------------------------------------------------

ALTER TABLE public.predictions
  ALTER COLUMN group_id SET NOT NULL;

ALTER TABLE public.predictions
  DROP CONSTRAINT IF EXISTS predictions_user_id_game_id_key;

ALTER TABLE public.predictions
  ADD CONSTRAINT predictions_user_game_group_unique UNIQUE (user_id, game_id, group_id);


-- ----------------------------------------------------------------
-- 4. RLS — predictions: replace insert + update policies
-- ----------------------------------------------------------------

DROP POLICY IF EXISTS "predictions: insert" ON public.predictions;
DROP POLICY IF EXISTS "predictions: update" ON public.predictions;

CREATE POLICY "predictions: insert"
  ON public.predictions FOR INSERT
  WITH CHECK (
    auth.uid() = user_id
    AND public.is_group_member(group_id, auth.uid())
    AND now() < (SELECT kick_off_time FROM public.games WHERE id = game_id)
  );

CREATE POLICY "predictions: update"
  ON public.predictions FOR UPDATE
  USING (auth.uid() = user_id)
  WITH CHECK (
    auth.uid() = user_id
    AND public.is_group_member(group_id, auth.uid())
    AND now() < (SELECT kick_off_time FROM public.games WHERE id = game_id)
  );


-- ----------------------------------------------------------------
-- 5. fn_auto_predict_game() — one prediction per (user, group) pair
-- ----------------------------------------------------------------

CREATE OR REPLACE FUNCTION public.fn_auto_predict_game(p_game_id uuid)
RETURNS void
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
  v_combo record;
  v_home  int;
  v_away  int;
BEGIN
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
    v_home := floor(random() * 6)::int;
    v_away := floor(random() * 6)::int;
    INSERT INTO public.predictions (user_id, game_id, group_id, pred_home, pred_away, is_auto)
    VALUES (v_combo.user_id, p_game_id, v_combo.group_id, v_home, v_away, true)
    ON CONFLICT (user_id, game_id, group_id) DO NOTHING;
  END LOOP;
  -- Self-unschedule cron job for this game
  PERFORM cron.unschedule('auto-predict-' || p_game_id::text);
END;
$$;


-- ----------------------------------------------------------------
-- 6. get_group_leaderboard() — filter predictions by group_id
-- ----------------------------------------------------------------

DROP FUNCTION IF EXISTS public.get_group_leaderboard(uuid);

CREATE OR REPLACE FUNCTION public.get_group_leaderboard(p_group_id uuid)
RETURNS TABLE (
  group_rank          bigint,
  global_rank         bigint,
  user_id             uuid,
  username            text,
  champion_team       text,
  top_scorer_player   text,
  total_points        bigint,
  exact_scores        bigint
)
LANGUAGE plpgsql
SECURITY DEFINER
STABLE
AS $$
BEGIN
  IF NOT public.is_group_member(p_group_id, auth.uid()) THEN
    RAISE EXCEPTION 'not_a_member' USING HINT = 'You are not a member of this group';
  END IF;

  RETURN QUERY
  WITH group_scores AS (
    SELECT
      p.id                                                          AS user_id,
      p.username,
      cp.team                                                       AS champion_team,
      ts.player_name                                                AS top_scorer_player,
      COALESCE(SUM(pr.points_earned), 0)
        + COALESCE(cp.points_earned, 0)
        + COALESCE(ts.points_earned, 0)                            AS total_points,
      COUNT(*) FILTER (WHERE pr.points_earned = 3)                 AS exact_scores
    FROM public.profiles p
    INNER JOIN public.group_members gm
           ON gm.user_id = p.id AND gm.group_id = p_group_id
    LEFT JOIN public.predictions     pr
           ON pr.user_id = p.id AND pr.group_id = p_group_id
    LEFT JOIN public.champion_pick   cp
           ON cp.user_id = p.id AND cp.group_id = p_group_id
    LEFT JOIN public.top_scorer_pick ts
           ON ts.user_id = p.id AND ts.group_id = p_group_id
    GROUP BY p.id, p.username,
             cp.team, cp.points_earned,
             ts.player_name, ts.points_earned
  ),
  global_scores AS (
    -- Global score: first-group predictions + best pick result
    SELECT
      p.id                                                          AS user_id,
      COALESCE(SUM(pr.points_earned), 0)
        + COALESCE(MAX(cp_a.points_earned), 0)
        + COALESCE(MAX(ts_a.points_earned), 0)                    AS total_points,
      COUNT(*) FILTER (WHERE pr.points_earned = 3)                 AS exact_scores
    FROM public.profiles p
    LEFT JOIN (
      SELECT DISTINCT ON (gm2.user_id) gm2.user_id, gm2.group_id
      FROM public.group_members gm2
      ORDER BY gm2.user_id, gm2.joined_at ASC
    ) fg ON fg.user_id = p.id
    LEFT JOIN public.predictions     pr    ON pr.user_id = p.id AND pr.group_id = fg.group_id
    LEFT JOIN public.champion_pick   cp_a  ON cp_a.user_id = p.id
    LEFT JOIN public.top_scorer_pick ts_a  ON ts_a.user_id = p.id
    GROUP BY p.id
  ),
  global_ranked AS (
    SELECT
      user_id,
      RANK() OVER (
        ORDER BY total_points DESC, exact_scores DESC
      ) AS global_rank
    FROM global_scores
  )
  SELECT
    RANK() OVER (
      ORDER BY gs.total_points DESC, gs.exact_scores DESC, gs.username ASC
    )                    AS group_rank,
    gr.global_rank,
    gs.user_id,
    gs.username,
    gs.champion_team,
    gs.top_scorer_player,
    gs.total_points,
    gs.exact_scores
  FROM group_scores gs
  LEFT JOIN global_ranked gr ON gr.user_id = gs.user_id
  ORDER BY group_rank, gs.username ASC;
END;
$$;


-- ----------------------------------------------------------------
-- 7. get_leaderboard() — global: first-group predictions for scoring
-- ----------------------------------------------------------------

DROP FUNCTION IF EXISTS public.get_leaderboard();

CREATE OR REPLACE FUNCTION public.get_leaderboard()
RETURNS TABLE (
  rank                bigint,
  user_id             uuid,
  username            text,
  group_name          text,
  champion_team       text,
  top_scorer_player   text,
  total_points        bigint,
  exact_scores        bigint
)
LANGUAGE sql
STABLE
SECURITY DEFINER
AS $$
  WITH first_group AS (
    SELECT DISTINCT ON (gm.user_id) gm.user_id, gm.group_id
    FROM public.group_members gm
    ORDER BY gm.user_id, gm.joined_at ASC
  )
  SELECT
    RANK() OVER (
      ORDER BY
        COALESCE(SUM(pr.points_earned), 0)
          + COALESCE(MAX(cp.points_earned), 0)
          + COALESCE(MAX(ts.points_earned), 0) DESC,
        COUNT(*) FILTER (WHERE pr.points_earned = 3) DESC,
        p.username ASC
    )                                                               AS rank,
    p.id                                                            AS user_id,
    p.username,
    (
      SELECT g.name
      FROM public.group_members gm2
      JOIN public.groups g ON g.id = gm2.group_id
      WHERE gm2.user_id = p.id
      ORDER BY gm2.joined_at ASC
      LIMIT 1
    )                                                               AS group_name,
    (
      SELECT cp2.team
      FROM public.champion_pick cp2
      JOIN public.group_members gm3
        ON gm3.group_id = cp2.group_id AND gm3.user_id = cp2.user_id
      WHERE cp2.user_id = p.id
      ORDER BY gm3.joined_at ASC
      LIMIT 1
    )                                                               AS champion_team,
    (
      SELECT ts2.player_name
      FROM public.top_scorer_pick ts2
      JOIN public.group_members gm4
        ON gm4.group_id = ts2.group_id AND gm4.user_id = ts2.user_id
      WHERE ts2.user_id = p.id
      ORDER BY gm4.joined_at ASC
      LIMIT 1
    )                                                               AS top_scorer_player,
    COALESCE(SUM(pr.points_earned), 0)
      + COALESCE(MAX(cp.points_earned), 0)
      + COALESCE(MAX(ts.points_earned), 0)                         AS total_points,
    COUNT(*) FILTER (WHERE pr.points_earned = 3)                   AS exact_scores
  FROM public.profiles p
  LEFT JOIN first_group fg                ON fg.user_id = p.id
  LEFT JOIN public.predictions     pr     ON pr.user_id = p.id AND pr.group_id = fg.group_id
  LEFT JOIN public.champion_pick   cp     ON cp.user_id = p.id
  LEFT JOIN public.top_scorer_pick ts     ON ts.user_id = p.id
  GROUP BY p.id, p.username
  ORDER BY rank, p.username ASC;
$$;
