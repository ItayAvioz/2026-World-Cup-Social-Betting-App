-- ================================================================
-- Migration 29: Per-group champion + top scorer picks
-- ================================================================
-- Changes UNIQUE(user_id) → UNIQUE(user_id, group_id) on both tables.
-- Each user has one champion pick and one top scorer pick per group.
-- Updates leaderboard RPCs + auto-assign function accordingly.
-- Safe to run on empty tables (pre-tournament).
-- ================================================================


-- ----------------------------------------------------------------
-- 1. champion_pick — add group_id, change unique constraint
-- ----------------------------------------------------------------

ALTER TABLE public.champion_pick
  ADD COLUMN group_id uuid REFERENCES public.groups(id) ON DELETE CASCADE;

-- Drop pre-existing picks (no group context — cannot migrate safely)
DELETE FROM public.champion_pick;

ALTER TABLE public.champion_pick
  ALTER COLUMN group_id SET NOT NULL;

ALTER TABLE public.champion_pick
  DROP CONSTRAINT champion_pick_user_id_key;

ALTER TABLE public.champion_pick
  ADD CONSTRAINT champion_pick_user_group_unique UNIQUE (user_id, group_id);


-- ----------------------------------------------------------------
-- 2. top_scorer_pick — add group_id, change unique constraint
-- ----------------------------------------------------------------

ALTER TABLE public.top_scorer_pick
  ADD COLUMN group_id uuid REFERENCES public.groups(id) ON DELETE CASCADE;

DELETE FROM public.top_scorer_pick;

ALTER TABLE public.top_scorer_pick
  ALTER COLUMN group_id SET NOT NULL;

ALTER TABLE public.top_scorer_pick
  DROP CONSTRAINT top_scorer_pick_user_id_key;

ALTER TABLE public.top_scorer_pick
  ADD CONSTRAINT top_scorer_pick_user_group_unique UNIQUE (user_id, group_id);


-- ----------------------------------------------------------------
-- 3. RLS — champion_pick: replace policies
-- ----------------------------------------------------------------

DROP POLICY IF EXISTS "champion_pick: select" ON public.champion_pick;
DROP POLICY IF EXISTS "champion_pick: insert" ON public.champion_pick;
DROP POLICY IF EXISTS "champion_pick: update" ON public.champion_pick;

-- Own rows always visible; all visible after deadline (public reveal)
CREATE POLICY "champion_pick: select"
  ON public.champion_pick FOR SELECT
  USING (
    auth.uid() = user_id
    OR now() >= '2026-06-11T19:00:00Z'::timestamptz
  );

-- Must be own row + group member + before deadline
CREATE POLICY "champion_pick: insert"
  ON public.champion_pick FOR INSERT
  WITH CHECK (
    auth.uid() = user_id
    AND public.is_group_member(group_id, auth.uid())
    AND now() < '2026-06-11T19:00:00Z'::timestamptz
  );

CREATE POLICY "champion_pick: update"
  ON public.champion_pick FOR UPDATE
  USING (auth.uid() = user_id)
  WITH CHECK (
    auth.uid() = user_id
    AND public.is_group_member(group_id, auth.uid())
    AND now() < '2026-06-11T19:00:00Z'::timestamptz
  );


-- ----------------------------------------------------------------
-- 4. RLS — top_scorer_pick: replace policies
-- ----------------------------------------------------------------

DROP POLICY IF EXISTS "top_scorer_pick: select" ON public.top_scorer_pick;
DROP POLICY IF EXISTS "top_scorer_pick: insert" ON public.top_scorer_pick;
DROP POLICY IF EXISTS "top_scorer_pick: update" ON public.top_scorer_pick;

CREATE POLICY "top_scorer_pick: select"
  ON public.top_scorer_pick FOR SELECT
  USING (
    auth.uid() = user_id
    OR now() >= '2026-06-11T19:00:00Z'::timestamptz
  );

CREATE POLICY "top_scorer_pick: insert"
  ON public.top_scorer_pick FOR INSERT
  WITH CHECK (
    auth.uid() = user_id
    AND public.is_group_member(group_id, auth.uid())
    AND now() < '2026-06-11T19:00:00Z'::timestamptz
  );

CREATE POLICY "top_scorer_pick: update"
  ON public.top_scorer_pick FOR UPDATE
  USING (auth.uid() = user_id)
  WITH CHECK (
    auth.uid() = user_id
    AND public.is_group_member(group_id, auth.uid())
    AND now() < '2026-06-11T19:00:00Z'::timestamptz
  );


-- ----------------------------------------------------------------
-- 5. get_group_leaderboard() — picks scoped to group_id
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
    -- Points for each member using only this group's picks
    SELECT
      p.id                                                          AS user_id,
      p.username,
      cp.team                                                       AS champion_team,
      ts.player_name                                                AS top_scorer_player,
      COALESCE(SUM(pr.points_earned), 0)
        + COALESCE(cp.points_earned, 0)
        + COALESCE(ts.points_earned, 0)                             AS total_points,
      COUNT(*) FILTER (WHERE pr.points_earned = 3)                  AS exact_scores
    FROM public.profiles p
    INNER JOIN public.group_members gm
           ON gm.user_id = p.id AND gm.group_id = p_group_id
    LEFT JOIN public.predictions     pr ON pr.user_id = p.id
    LEFT JOIN public.champion_pick   cp
           ON cp.user_id = p.id AND cp.group_id = p_group_id
    LEFT JOIN public.top_scorer_pick ts
           ON ts.user_id = p.id AND ts.group_id = p_group_id
    GROUP BY p.id, p.username,
             cp.team, cp.points_earned,
             ts.player_name, ts.points_earned
  ),
  global_scores AS (
    -- Global score: prediction points + best pick result across all groups
    SELECT
      p.id                                                          AS user_id,
      COALESCE(SUM(pr.points_earned), 0)
        + COALESCE(MAX(cp_a.points_earned), 0)
        + COALESCE(MAX(ts_a.points_earned), 0)                      AS total_points,
      COUNT(*) FILTER (WHERE pr.points_earned = 3)                  AS exact_scores
    FROM public.profiles p
    LEFT JOIN public.predictions     pr    ON pr.user_id = p.id
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
-- 6. get_leaderboard() — global: first-group picks for display,
--    MAX(points_earned) across groups (prevents multi-group advantage)
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
    -- First group name (by joined_at)
    (
      SELECT g.name
      FROM public.group_members gm2
      JOIN public.groups g ON g.id = gm2.group_id
      WHERE gm2.user_id = p.id
      ORDER BY gm2.joined_at ASC
      LIMIT 1
    )                                                               AS group_name,
    -- Champion pick from first group
    (
      SELECT cp2.team
      FROM public.champion_pick cp2
      JOIN public.group_members gm3
        ON gm3.group_id = cp2.group_id AND gm3.user_id = cp2.user_id
      WHERE cp2.user_id = p.id
      ORDER BY gm3.joined_at ASC
      LIMIT 1
    )                                                               AS champion_team,
    -- Top scorer pick from first group
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
      + COALESCE(MAX(ts.points_earned), 0)                          AS total_points,
    COUNT(*) FILTER (WHERE pr.points_earned = 3)                    AS exact_scores
  FROM public.profiles p
  LEFT JOIN public.predictions     pr ON pr.user_id = p.id
  LEFT JOIN public.champion_pick   cp ON cp.user_id = p.id
  LEFT JOIN public.top_scorer_pick ts ON ts.user_id = p.id
  GROUP BY p.id, p.username
  ORDER BY rank, p.username ASC;
$$;


-- ----------------------------------------------------------------
-- 7. fn_auto_assign_picks() — one pick per (user, group) pair
-- ----------------------------------------------------------------

CREATE OR REPLACE FUNCTION public.fn_auto_assign_picks()
RETURNS void
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
  v_combo    record;
  v_champion text;
  v_player   jsonb;
  v_teams    text[] := ARRAY[
    'Mexico','South Africa','South Korea','Canada','Qatar','Switzerland',
    'Brazil','Morocco','Haiti','Scotland','United States','Paraguay',
    'Australia','Germany','Curaçao','Ivory Coast','Ecuador','Netherlands',
    'Japan','Tunisia','Belgium','Egypt','Iran','New Zealand','Spain',
    'Cape Verde','Saudi Arabia','Uruguay','France','Senegal','Norway',
    'Argentina','Algeria','Austria','Jordan','Portugal','Uzbekistan',
    'Colombia','England','Croatia','Ghana','Panama',
    'UEFA PO-A','UEFA PO-B','UEFA PO-C','UEFA PO-D','IC PO-1','IC PO-2'
  ];
  v_players  jsonb[] := ARRAY[
    '{"name":"Kylian Mbappé","id":278}'::jsonb,
    '{"name":"Erling Haaland","id":1100}'::jsonb,
    '{"name":"Lionel Messi","id":154}'::jsonb,
    '{"name":"Vinicius Jr","id":2295}'::jsonb,
    '{"name":"Harry Kane","id":3501}'::jsonb,
    '{"name":"Lautaro Martinez","id":4200}'::jsonb,
    '{"name":"Neymar Jr","id":5001}'::jsonb
  ];
BEGIN
  -- Auto-assign champion pick for each (user, group) pair that has no pick yet
  FOR v_combo IN
    SELECT gm.user_id, gm.group_id
    FROM public.group_members gm
    WHERE NOT EXISTS (
      SELECT 1 FROM public.champion_pick cp
      WHERE cp.user_id = gm.user_id AND cp.group_id = gm.group_id
    )
  LOOP
    v_champion := v_teams[1 + floor(random() * array_length(v_teams, 1))::int];
    INSERT INTO public.champion_pick (user_id, group_id, team, is_auto)
    VALUES (v_combo.user_id, v_combo.group_id, v_champion, true)
    ON CONFLICT (user_id, group_id) DO NOTHING;
  END LOOP;

  -- Auto-assign top scorer pick for each (user, group) pair that has no pick yet
  FOR v_combo IN
    SELECT gm.user_id, gm.group_id
    FROM public.group_members gm
    WHERE NOT EXISTS (
      SELECT 1 FROM public.top_scorer_pick ts
      WHERE ts.user_id = gm.user_id AND ts.group_id = gm.group_id
    )
  LOOP
    v_player := v_players[1 + floor(random() * array_length(v_players, 1))::int];
    INSERT INTO public.top_scorer_pick (user_id, group_id, player_name, top_scorer_api_id, is_auto)
    VALUES (v_combo.user_id, v_combo.group_id, v_player->>'name', (v_player->>'id')::int, true)
    ON CONFLICT (user_id, group_id) DO NOTHING;
  END LOOP;
END;
$$;
