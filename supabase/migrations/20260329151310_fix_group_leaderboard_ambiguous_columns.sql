-- Migration 32: Fix "column reference user_id is ambiguous" in get_group_leaderboard
-- In plpgsql RETURNS TABLE functions, output column names become OUT variables in scope.
-- Bare `user_id`/`group_id` in the global_ranked CTE were ambiguous between
-- all_group_scores columns and the OUT parameter variables.
-- Fix: add alias `ags` to all_group_scores and qualify all column references.
--
-- NOTE: Originally applied via MCP apply_migration (deployed version 20260329151310)
-- without a physical file. File reconstructed 2026-04-05 from the deployed DDL
-- stored in supabase_migrations.schema_migrations.statements to protect against
-- `supabase db reset`. DROP/CREATE OR REPLACE makes this safe to re-apply.
-- (This function was later redefined by Migration 33 to add the ungrouped user pool.)

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
    SELECT
      p2.id                                                         AS user_id,
      gm2.group_id                                                  AS group_id,
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
    -- Qualify via alias to avoid ambiguity with RETURNS TABLE OUT parameters
    SELECT
      ags.user_id                                                   AS gr_user_id,
      ags.group_id                                                  AS gr_group_id,
      RANK() OVER (
        ORDER BY ags.total_points DESC, ags.exact_scores DESC
      )                                                             AS global_rank
    FROM all_group_scores ags
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
         ON gr.gr_user_id = gs.user_id AND gr.gr_group_id = p_group_id
  ORDER BY group_rank, gs.username ASC;
END;
$$;
