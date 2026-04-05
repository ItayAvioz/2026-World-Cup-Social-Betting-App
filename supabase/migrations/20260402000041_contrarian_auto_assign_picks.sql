-- Migration 41: Rewrite fn_auto_assign_picks with contrarian logic
-- Instead of random picks, auto-assign the LEAST popular team/player in each group.

CREATE OR REPLACE FUNCTION public.fn_auto_assign_picks()
RETURNS void
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
  v_combo    record;
  v_uid      uuid;
  v_champion text;
  v_player   jsonb;
  v_min_cnt  int;
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
  -- ========== CHAMPION PICKS — grouped users ==========
  FOR v_combo IN
    SELECT gm.user_id, gm.group_id
    FROM public.group_members gm
    WHERE NOT EXISTS (
      SELECT 1 FROM public.champion_pick cp
      WHERE cp.user_id = gm.user_id AND cp.group_id = gm.group_id
    )
  LOOP
    -- Find the least-picked champion team in THIS group
    WITH all_teams AS (
      SELECT unnest(v_teams) AS team
    ),
    team_counts AS (
      SELECT at.team, COALESCE(cc.cnt, 0) AS cnt
      FROM all_teams at
      LEFT JOIN (
        SELECT team, COUNT(*) AS cnt
        FROM public.champion_pick
        WHERE group_id = v_combo.group_id
        GROUP BY team
      ) cc ON cc.team = at.team
    ),
    min_count AS (
      SELECT MIN(cnt) AS mn FROM team_counts
    )
    SELECT tc.team INTO v_champion
    FROM team_counts tc, min_count mc
    WHERE tc.cnt = mc.mn
    ORDER BY random()
    LIMIT 1;

    INSERT INTO public.champion_pick (user_id, group_id, team, is_auto)
    VALUES (v_combo.user_id, v_combo.group_id, v_champion, true)
    ON CONFLICT ON CONSTRAINT champion_pick_user_group_unique DO NOTHING;
  END LOOP;

  -- ========== CHAMPION PICKS — ungrouped users ==========
  FOR v_uid IN
    SELECT p.id
    FROM public.profiles p
    WHERE NOT EXISTS (SELECT 1 FROM public.group_members WHERE user_id = p.id)
    AND NOT EXISTS (SELECT 1 FROM public.champion_pick WHERE user_id = p.id AND group_id IS NULL)
  LOOP
    -- Find the least-picked champion team among ungrouped users (group_id IS NULL)
    WITH all_teams AS (
      SELECT unnest(v_teams) AS team
    ),
    team_counts AS (
      SELECT at.team, COALESCE(cc.cnt, 0) AS cnt
      FROM all_teams at
      LEFT JOIN (
        SELECT team, COUNT(*) AS cnt
        FROM public.champion_pick
        WHERE group_id IS NULL
        GROUP BY team
      ) cc ON cc.team = at.team
    ),
    min_count AS (
      SELECT MIN(cnt) AS mn FROM team_counts
    )
    SELECT tc.team INTO v_champion
    FROM team_counts tc, min_count mc
    WHERE tc.cnt = mc.mn
    ORDER BY random()
    LIMIT 1;

    INSERT INTO public.champion_pick (user_id, group_id, team, is_auto)
    VALUES (v_uid, NULL, v_champion, true)
    ON CONFLICT ON CONSTRAINT champion_pick_user_group_unique DO NOTHING;
  END LOOP;

  -- ========== TOP SCORER PICKS — grouped users ==========
  FOR v_combo IN
    SELECT gm.user_id, gm.group_id
    FROM public.group_members gm
    WHERE NOT EXISTS (
      SELECT 1 FROM public.top_scorer_pick ts
      WHERE ts.user_id = gm.user_id AND ts.group_id = gm.group_id
    )
  LOOP
    -- Find the least-picked top scorer player in THIS group
    WITH all_players AS (
      SELECT unnest(v_players) AS player
    ),
    player_counts AS (
      SELECT ap.player, COALESCE(pc.cnt, 0) AS cnt
      FROM all_players ap
      LEFT JOIN (
        SELECT player_name, COUNT(*) AS cnt
        FROM public.top_scorer_pick
        WHERE group_id = v_combo.group_id
        GROUP BY player_name
      ) pc ON pc.player_name = (ap.player->>'name')
    ),
    min_count AS (
      SELECT MIN(cnt) AS mn FROM player_counts
    )
    SELECT pc.player INTO v_player
    FROM player_counts pc, min_count mc
    WHERE pc.cnt = mc.mn
    ORDER BY random()
    LIMIT 1;

    INSERT INTO public.top_scorer_pick (user_id, group_id, player_name, top_scorer_api_id, is_auto)
    VALUES (v_combo.user_id, v_combo.group_id, v_player->>'name', (v_player->>'id')::int, true)
    ON CONFLICT ON CONSTRAINT top_scorer_pick_user_group_unique DO NOTHING;
  END LOOP;

  -- ========== TOP SCORER PICKS — ungrouped users ==========
  FOR v_uid IN
    SELECT p.id
    FROM public.profiles p
    WHERE NOT EXISTS (SELECT 1 FROM public.group_members WHERE user_id = p.id)
    AND NOT EXISTS (SELECT 1 FROM public.top_scorer_pick WHERE user_id = p.id AND group_id IS NULL)
  LOOP
    -- Find the least-picked top scorer player among ungrouped users (group_id IS NULL)
    WITH all_players AS (
      SELECT unnest(v_players) AS player
    ),
    player_counts AS (
      SELECT ap.player, COALESCE(pc.cnt, 0) AS cnt
      FROM all_players ap
      LEFT JOIN (
        SELECT player_name, COUNT(*) AS cnt
        FROM public.top_scorer_pick
        WHERE group_id IS NULL
        GROUP BY player_name
      ) pc ON pc.player_name = (ap.player->>'name')
    ),
    min_count AS (
      SELECT MIN(cnt) AS mn FROM player_counts
    )
    SELECT pc.player INTO v_player
    FROM player_counts pc, min_count mc
    WHERE pc.cnt = mc.mn
    ORDER BY random()
    LIMIT 1;

    INSERT INTO public.top_scorer_pick (user_id, group_id, player_name, top_scorer_api_id, is_auto)
    VALUES (v_uid, NULL, v_player->>'name', (v_player->>'id')::int, true)
    ON CONFLICT ON CONSTRAINT top_scorer_pick_user_group_unique DO NOTHING;
  END LOOP;
END;
$$;
