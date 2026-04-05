-- ================================================================
-- Migration 31: Global leaderboard — one row per (user × group)
-- ================================================================
-- Previously: get_leaderboard() returned one row per user (first-group
-- scoring via first_group CTE + MAX across groups for picks).
-- Now: one row per (user, group). User in 3 groups → 3 leaderboard rows.
-- Score per row = predictions for that group + champion + top scorer picks
-- for that group. No multi-group deduplication needed.
--
-- get_group_leaderboard(): global_rank now ranks all (user, group)
-- combos globally — consistent with the new get_leaderboard() output.
-- ================================================================


-- ----------------------------------------------------------------
-- 1. get_leaderboard() — one row per (user, group)
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
  WITH scores AS (
    SELECT
      p.id                                                          AS user_id,
      p.username,
      g.name                                                        AS group_name,
      MAX(cp.team)                                                  AS champion_team,
      MAX(ts.player_name)                                           AS top_scorer_player,
      COALESCE(SUM(pr.points_earned), 0)
        + COALESCE(MAX(cp.points_earned), 0)
        + COALESCE(MAX(ts.points_earned), 0)                       AS total_points,
      COUNT(*) FILTER (WHERE pr.points_earned = 3)                 AS exact_scores
    FROM public.profiles p
    INNER JOIN public.group_members gm ON gm.user_id = p.id
    INNER JOIN public.groups         g  ON g.id = gm.group_id
    LEFT  JOIN public.predictions     pr ON pr.user_id = p.id AND pr.group_id = gm.group_id
    LEFT  JOIN public.champion_pick   cp ON cp.user_id = p.id AND cp.group_id = gm.group_id
    LEFT  JOIN public.top_scorer_pick ts ON ts.user_id = p.id AND ts.group_id = gm.group_id
    GROUP BY p.id, p.username, g.id, g.name
  )
  SELECT
    RANK() OVER (
      ORDER BY total_points DESC, exact_scores DESC, username ASC, group_name ASC
    )                   AS rank,
    user_id,
    username,
    group_name,
    champion_team,
    top_scorer_player,
    total_points,
    exact_scores
  FROM scores
  ORDER BY rank, username ASC, group_name ASC;
$$;


-- ----------------------------------------------------------------
-- 2. get_group_leaderboard() — global_rank from all (user, group) combos
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
    -- Score for each member in THIS group
    SELECT
      p.id                                                          AS user_id,
      p.username,
      MAX(cp.team)                                                  AS champion_team,
      MAX(ts.player_name)                                           AS top_scorer_player,
      COALESCE(SUM(pr.points_earned), 0)
        + COALESCE(MAX(cp.points_earned), 0)
        + COALESCE(MAX(ts.points_earned), 0)                       AS total_points,
      COUNT(*) FILTER (WHERE pr.points_earned = 3)                 AS exact_scores
    FROM public.profiles p
    INNER JOIN public.group_members gm ON gm.user_id = p.id AND gm.group_id = p_group_id
    LEFT  JOIN public.predictions     pr ON pr.user_id = p.id AND pr.group_id = p_group_id
    LEFT  JOIN public.champion_pick   cp ON cp.user_id = p.id AND cp.group_id = p_group_id
    LEFT  JOIN public.top_scorer_pick ts ON ts.user_id = p.id AND ts.group_id = p_group_id
    GROUP BY p.id, p.username
  ),
  all_group_scores AS (
    -- One score per (user, group) across the whole app — for global ranking
    SELECT
      p2.id                                                         AS user_id,
      gm2.group_id,
      COALESCE(SUM(pr2.points_earned), 0)
        + COALESCE(MAX(cp2.points_earned), 0)
        + COALESCE(MAX(ts2.points_earned), 0)                      AS total_points,
      COUNT(*) FILTER (WHERE pr2.points_earned = 3)                AS exact_scores
    FROM public.profiles p2
    INNER JOIN public.group_members gm2 ON gm2.user_id = p2.id
    LEFT  JOIN public.predictions     pr2 ON pr2.user_id = p2.id AND pr2.group_id = gm2.group_id
    LEFT  JOIN public.champion_pick   cp2 ON cp2.user_id = p2.id AND cp2.group_id = gm2.group_id
    LEFT  JOIN public.top_scorer_pick ts2 ON ts2.user_id = p2.id AND ts2.group_id = gm2.group_id
    GROUP BY p2.id, gm2.group_id
  ),
  global_ranked AS (
    SELECT
      user_id,
      group_id,
      RANK() OVER (
        ORDER BY total_points DESC, exact_scores DESC
      ) AS global_rank
    FROM all_group_scores
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
  LEFT JOIN global_ranked gr
         ON gr.user_id = gs.user_id AND gr.group_id = p_group_id
  ORDER BY group_rank, gs.username ASC;
END;
$$;
