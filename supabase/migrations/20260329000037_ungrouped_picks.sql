-- ================================================================
-- Migration 37: Ungrouped champion + top scorer picks
-- ================================================================
-- Allows champion_pick.group_id and top_scorer_pick.group_id to be
-- NULL so users who are not in any group can still make picks.
-- Users in groups continue to use per-group picks (group_id NOT NULL).
--
-- UNIQUE NULLS NOT DISTINCT treats two NULL group_ids as equal →
-- one ungrouped pick per user (same as the predictions pattern in m36).
--
-- Mutual exclusivity enforced via trigger:
--   - Grouped users (any group_member row) may NOT insert group_id=NULL.
--   - Ungrouped users may NOT insert group_id != NULL (RLS handles that
--     via is_group_member check).
--
-- fn_auto_assign_picks extended to cover ungrouped users.
--
-- Leaderboard scoring of ungrouped picks: the existing get_leaderboard
-- LEFT JOINs on champion_pick/top_scorer_pick without a group_id filter,
-- so ungrouped picks' points_earned ARE counted in total_points already.
-- The displayed champion_team/top_scorer_player columns remain NULL for
-- ungrouped users (future improvement).
-- ================================================================


-- ----------------------------------------------------------------
-- 1. champion_pick — make group_id nullable, NULLS NOT DISTINCT
-- ----------------------------------------------------------------

ALTER TABLE public.champion_pick
  ALTER COLUMN group_id DROP NOT NULL;

ALTER TABLE public.champion_pick
  DROP CONSTRAINT IF EXISTS champion_pick_user_group_unique;

ALTER TABLE public.champion_pick
  ADD CONSTRAINT champion_pick_user_group_unique
  UNIQUE NULLS NOT DISTINCT (user_id, group_id);


-- ----------------------------------------------------------------
-- 2. top_scorer_pick — same
-- ----------------------------------------------------------------

ALTER TABLE public.top_scorer_pick
  ALTER COLUMN group_id DROP NOT NULL;

ALTER TABLE public.top_scorer_pick
  DROP CONSTRAINT IF EXISTS top_scorer_pick_user_group_unique;

ALTER TABLE public.top_scorer_pick
  ADD CONSTRAINT top_scorer_pick_user_group_unique
  UNIQUE NULLS NOT DISTINCT (user_id, group_id);


-- ----------------------------------------------------------------
-- 3. Mutual exclusivity trigger
--    A grouped user (any row in group_members) cannot insert a
--    NULL group_id pick — they must use a group-scoped pick.
-- ----------------------------------------------------------------

CREATE OR REPLACE FUNCTION public.check_pick_group_consistency()
RETURNS trigger
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
BEGIN
  IF NEW.group_id IS NULL AND EXISTS (
    SELECT 1 FROM public.group_members WHERE user_id = NEW.user_id LIMIT 1
  ) THEN
    RAISE EXCEPTION 'pick_group_mismatch'
      USING HINT = 'You are in a group — use a group-scoped pick instead of an ungrouped pick';
  END IF;
  RETURN NEW;
END;
$$;

DROP TRIGGER IF EXISTS trg_champion_pick_group_check ON public.champion_pick;
CREATE TRIGGER trg_champion_pick_group_check
  BEFORE INSERT OR UPDATE ON public.champion_pick
  FOR EACH ROW EXECUTE FUNCTION public.check_pick_group_consistency();

DROP TRIGGER IF EXISTS trg_top_scorer_pick_group_check ON public.top_scorer_pick;
CREATE TRIGGER trg_top_scorer_pick_group_check
  BEFORE INSERT OR UPDATE ON public.top_scorer_pick
  FOR EACH ROW EXECUTE FUNCTION public.check_pick_group_consistency();


-- ----------------------------------------------------------------
-- 4. RLS — champion_pick: allow group_id IS NULL for ungrouped users
-- ----------------------------------------------------------------

DROP POLICY IF EXISTS "champion_pick: insert" ON public.champion_pick;
CREATE POLICY "champion_pick: insert"
  ON public.champion_pick FOR INSERT
  WITH CHECK (
    auth.uid() = user_id
    AND (
      group_id IS NULL
      OR public.is_group_member(group_id, auth.uid())
    )
    AND now() < '2026-06-11T19:00:00Z'::timestamptz
  );

DROP POLICY IF EXISTS "champion_pick: update" ON public.champion_pick;
CREATE POLICY "champion_pick: update"
  ON public.champion_pick FOR UPDATE
  USING (auth.uid() = user_id)
  WITH CHECK (
    auth.uid() = user_id
    AND (
      group_id IS NULL
      OR public.is_group_member(group_id, auth.uid())
    )
    AND now() < '2026-06-11T19:00:00Z'::timestamptz
  );


-- ----------------------------------------------------------------
-- 5. RLS — top_scorer_pick: same
-- ----------------------------------------------------------------

DROP POLICY IF EXISTS "top_scorer_pick: insert" ON public.top_scorer_pick;
CREATE POLICY "top_scorer_pick: insert"
  ON public.top_scorer_pick FOR INSERT
  WITH CHECK (
    auth.uid() = user_id
    AND (
      group_id IS NULL
      OR public.is_group_member(group_id, auth.uid())
    )
    AND now() < '2026-06-11T19:00:00Z'::timestamptz
  );

DROP POLICY IF EXISTS "top_scorer_pick: update" ON public.top_scorer_pick;
CREATE POLICY "top_scorer_pick: update"
  ON public.top_scorer_pick FOR UPDATE
  USING (auth.uid() = user_id)
  WITH CHECK (
    auth.uid() = user_id
    AND (
      group_id IS NULL
      OR public.is_group_member(group_id, auth.uid())
    )
    AND now() < '2026-06-11T19:00:00Z'::timestamptz
  );


-- ----------------------------------------------------------------
-- 6. fn_auto_assign_picks — extend to cover ungrouped users
-- ----------------------------------------------------------------

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
  -- ── Champion pick: grouped users ────────────────────────────────
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

  -- ── Champion pick: ungrouped users (no group_members row) ────────
  FOR v_uid IN
    SELECT p.id
    FROM public.profiles p
    WHERE NOT EXISTS (
      SELECT 1 FROM public.group_members WHERE user_id = p.id
    )
    AND NOT EXISTS (
      SELECT 1 FROM public.champion_pick WHERE user_id = p.id AND group_id IS NULL
    )
  LOOP
    v_champion := v_teams[1 + floor(random() * array_length(v_teams, 1))::int];
    INSERT INTO public.champion_pick (user_id, group_id, team, is_auto)
    VALUES (v_uid, NULL, v_champion, true)
    ON CONFLICT ON CONSTRAINT champion_pick_user_group_unique DO NOTHING;
  END LOOP;

  -- ── Top scorer pick: grouped users ──────────────────────────────
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

  -- ── Top scorer pick: ungrouped users ────────────────────────────
  FOR v_uid IN
    SELECT p.id
    FROM public.profiles p
    WHERE NOT EXISTS (
      SELECT 1 FROM public.group_members WHERE user_id = p.id
    )
    AND NOT EXISTS (
      SELECT 1 FROM public.top_scorer_pick WHERE user_id = p.id AND group_id IS NULL
    )
  LOOP
    v_player := v_players[1 + floor(random() * array_length(v_players, 1))::int];
    INSERT INTO public.top_scorer_pick (user_id, group_id, player_name, top_scorer_api_id, is_auto)
    VALUES (v_uid, NULL, v_player->>'name', (v_player->>'id')::int, true)
    ON CONFLICT ON CONSTRAINT top_scorer_pick_user_group_unique DO NOTHING;
  END LOOP;
END;
$$;
