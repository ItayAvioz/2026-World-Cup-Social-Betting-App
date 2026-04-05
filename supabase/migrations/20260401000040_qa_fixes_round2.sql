-- Migration 40: QA Fixes Round 2 (2026-04-01)
-- FIX-3: fn_auto_assign_picks — align player API IDs with Picks.jsx
-- FIX-5: get_group_summary_data — scope predictions/picks/streak to group_id

-- ── FIX-3: fn_auto_assign_picks player API IDs ────────────────────────────────
-- Vinicius 2295→5765, Kane 3501→184, Lautaro 4200→730, Neymar 5001→276
CREATE OR REPLACE FUNCTION public.fn_auto_assign_picks()
RETURNS void LANGUAGE plpgsql SECURITY DEFINER AS $$
DECLARE
  v_combo    record;
  v_uid      uuid;
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
    '{"name":"Vinicius Jr","id":5765}'::jsonb,
    '{"name":"Harry Kane","id":184}'::jsonb,
    '{"name":"Lautaro Martínez","id":730}'::jsonb,
    '{"name":"Neymar Jr","id":276}'::jsonb
  ];
BEGIN
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
    ON CONFLICT ON CONSTRAINT champion_pick_user_group_unique DO NOTHING;
  END LOOP;

  FOR v_uid IN
    SELECT p.id
    FROM public.profiles p
    WHERE NOT EXISTS (SELECT 1 FROM public.group_members WHERE user_id = p.id)
    AND NOT EXISTS (SELECT 1 FROM public.champion_pick WHERE user_id = p.id AND group_id IS NULL)
  LOOP
    v_champion := v_teams[1 + floor(random() * array_length(v_teams, 1))::int];
    INSERT INTO public.champion_pick (user_id, group_id, team, is_auto)
    VALUES (v_uid, NULL, v_champion, true)
    ON CONFLICT ON CONSTRAINT champion_pick_user_group_unique DO NOTHING;
  END LOOP;

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
    ON CONFLICT ON CONSTRAINT top_scorer_pick_user_group_unique DO NOTHING;
  END LOOP;

  FOR v_uid IN
    SELECT p.id
    FROM public.profiles p
    WHERE NOT EXISTS (SELECT 1 FROM public.group_members WHERE user_id = p.id)
    AND NOT EXISTS (SELECT 1 FROM public.top_scorer_pick WHERE user_id = p.id AND group_id IS NULL)
  LOOP
    v_player := v_players[1 + floor(random() * array_length(v_players, 1))::int];
    INSERT INTO public.top_scorer_pick (user_id, group_id, player_name, top_scorer_api_id, is_auto)
    VALUES (v_uid, NULL, v_player->>'name', (v_player->>'id')::int, true)
    ON CONFLICT ON CONSTRAINT top_scorer_pick_user_group_unique DO NOTHING;
  END LOOP;
END;
$$;

-- ── FIX-5: get_group_summary_data — scope to group_id ─────────────────────────
CREATE OR REPLACE FUNCTION public.get_group_summary_data(p_group_id uuid, p_date date)
RETURNS jsonb LANGUAGE plpgsql SECURITY DEFINER AS $$
DECLARE
  v_games        jsonb;
  v_members      jsonb;
  v_leaderboard  jsonb;
BEGIN
  SELECT jsonb_agg(jsonb_build_object(
    'team_home',   g.team_home,
    'team_away',   g.team_away,
    'score_home',  g.score_home,
    'score_away',  g.score_away,
    'phase',       g.phase
  ) ORDER BY g.kick_off_time)
  INTO v_games
  FROM public.games g
  WHERE g.kick_off_time::date = p_date
    AND g.score_home IS NOT NULL;

  SELECT jsonb_agg(member_data ORDER BY member_data->>'username')
  INTO v_members
  FROM (
    SELECT jsonb_build_object(
      'username',         p.username,
      'user_id',          p.id,
      'predictions',      (
        SELECT jsonb_agg(jsonb_build_object(
          'game_id',      pr.game_id,
          'pred_home',    pr.pred_home,
          'pred_away',    pr.pred_away,
          'points',       pr.points_earned,
          'is_auto',      pr.is_auto
        ))
        FROM public.predictions pr
        JOIN public.games g ON g.id = pr.game_id
        WHERE pr.user_id = p.id
          AND pr.group_id = p_group_id
          AND g.kick_off_time::date = p_date
          AND g.score_home IS NOT NULL
      ),
      'total_exact_scores', (
        SELECT COUNT(*)
        FROM public.predictions pr
        WHERE pr.user_id = p.id
          AND pr.group_id = p_group_id
          AND pr.points_earned = 3
      ),
      'current_streak', (
        WITH recent AS (
          SELECT
            pr.points_earned,
            ROW_NUMBER() OVER (ORDER BY g.kick_off_time DESC) AS rn
          FROM public.predictions pr
          JOIN public.games g ON g.id = pr.game_id
          WHERE pr.user_id = p.id
            AND pr.group_id = p_group_id
            AND g.score_home IS NOT NULL
          ORDER BY g.kick_off_time DESC
        ),
        streak_calc AS (
          SELECT
            CASE WHEN (SELECT points_earned FROM recent WHERE rn = 1) >= 1
              THEN  (SELECT COUNT(*) FROM recent r
                     WHERE r.rn <= (
                       SELECT COALESCE(MIN(r2.rn) - 1, (SELECT MAX(rn) FROM recent))
                       FROM recent r2
                       WHERE r2.rn > 0 AND r2.points_earned = 0
                     ) AND r.points_earned >= 1)
              ELSE -(SELECT COUNT(*) FROM recent r
                     WHERE r.rn <= (
                       SELECT COALESCE(MIN(r2.rn) - 1, (SELECT MAX(rn) FROM recent))
                       FROM recent r2
                       WHERE r2.rn > 0 AND r2.points_earned >= 1
                     ) AND r.points_earned = 0)
            END AS streak
        )
        SELECT streak FROM streak_calc
      )
    ) AS member_data
    FROM public.profiles p
    JOIN public.group_members gm ON gm.user_id = p.id
    WHERE gm.group_id = p_group_id
  ) sub;

  SELECT jsonb_agg(jsonb_build_object(
    'group_rank',   ranked.group_rank,
    'username',     ranked.username,
    'total_points', ranked.total_points,
    'exact_scores', ranked.exact_scores
  ) ORDER BY ranked.group_rank)
  INTO v_leaderboard
  FROM (
    SELECT
      RANK() OVER (ORDER BY g.total_points DESC, g.exact_scores DESC, g.username ASC) AS group_rank,
      g.username,
      g.total_points,
      g.exact_scores
    FROM (
      SELECT
        p.username,
        COALESCE(SUM(pr.points_earned), 0)
          + COALESCE(MAX(cp.points_earned), 0)
          + COALESCE(MAX(ts.points_earned), 0)          AS total_points,
        COUNT(*) FILTER (WHERE pr.points_earned = 3) AS exact_scores
      FROM public.profiles p
      JOIN public.group_members gm ON gm.user_id = p.id AND gm.group_id = p_group_id
      LEFT JOIN public.predictions     pr ON pr.user_id = p.id AND pr.group_id = p_group_id
      LEFT JOIN public.champion_pick   cp ON cp.user_id = p.id AND cp.group_id = p_group_id
      LEFT JOIN public.top_scorer_pick ts ON ts.user_id = p.id AND ts.group_id = p_group_id
      GROUP BY p.id, p.username
    ) g
  ) ranked;

  RETURN jsonb_build_object(
    'group_id',    p_group_id,
    'date',        p_date,
    'games',       COALESCE(v_games, '[]'::jsonb),
    'members',     COALESCE(v_members, '[]'::jsonb),
    'leaderboard', COALESCE(v_leaderboard, '[]'::jsonb)
  );
END;
$$;
