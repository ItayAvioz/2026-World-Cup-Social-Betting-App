-- Migration 43: Max 3 groups = total membership (created + joined)
-- H3: create_group checks group_members count (not groups.created_by count)
-- H3: join_group adds membership cap + tournament deadline + ungrouped data migration
-- M4: On first group join, migrate group_id=NULL predictions/picks to that group
--     On second/third group join: no migration (user starts fresh in new group)

-- ── create_group: check total membership ─────────────────────────────────────
CREATE OR REPLACE FUNCTION public.create_group(group_name text)
RETURNS public.groups LANGUAGE plpgsql SECURITY DEFINER AS $$
DECLARE
  v_count int;
  v_group public.groups;
BEGIN
  IF char_length(trim(group_name)) = 0 THEN
    RAISE EXCEPTION 'invalid_name' USING HINT = 'Group name cannot be empty';
  END IF;

  SELECT COUNT(*) INTO v_count
  FROM public.group_members
  WHERE user_id = auth.uid();

  IF v_count >= 3 THEN
    RAISE EXCEPTION 'max_groups_reached' USING HINT = 'You can be in at most 3 groups';
  END IF;

  INSERT INTO public.groups (name, created_by)
  VALUES (trim(group_name), auth.uid())
  RETURNING * INTO v_group;

  RETURN v_group;
END;
$$;

-- ── join_group: membership cap + deadline + ungrouped data migration ──────────
CREATE OR REPLACE FUNCTION public.join_group(p_invite_code text)
RETURNS public.group_members LANGUAGE plpgsql SECURITY DEFINER AS $$
DECLARE
  v_group      public.groups;
  v_count      int;
  v_my_groups  int;
  v_membership public.group_members;
BEGIN
  -- Cannot join after tournament kickoff
  IF now() >= '2026-06-11T19:00:00Z'::timestamptz THEN
    RAISE EXCEPTION 'tournament_started' USING HINT = 'Cannot join groups after tournament starts';
  END IF;

  SELECT * INTO v_group
  FROM public.groups
  WHERE invite_code = upper(trim(p_invite_code));

  IF NOT FOUND THEN
    RAISE EXCEPTION 'invalid_invite_code' USING HINT = 'No group found with this invite code';
  END IF;

  IF public.is_group_member(v_group.id, auth.uid()) THEN
    RAISE EXCEPTION 'already_member' USING HINT = 'You are already in this group';
  END IF;

  -- Check user is not already in 3 groups
  SELECT COUNT(*) INTO v_my_groups
  FROM public.group_members
  WHERE user_id = auth.uid();

  IF v_my_groups >= 3 THEN
    RAISE EXCEPTION 'max_groups_reached' USING HINT = 'You can be in at most 3 groups';
  END IF;

  SELECT COUNT(*) INTO v_count
  FROM public.group_members
  WHERE group_id = v_group.id;

  IF v_count >= 10 THEN
    RAISE EXCEPTION 'group_full' USING HINT = 'This group has reached its 10-member limit';
  END IF;

  INSERT INTO public.group_members (group_id, user_id)
  VALUES (v_group.id, auth.uid())
  RETURNING * INTO v_membership;

  -- First group join: migrate ungrouped (group_id=NULL) data to this group.
  -- Predictions, champion pick, and top scorer pick all move to the new group.
  -- Second/third group join: v_my_groups > 0, no NULL data exists, UPDATEs affect 0 rows.
  IF v_my_groups = 0 THEN
    UPDATE public.predictions
    SET group_id = v_group.id
    WHERE user_id = auth.uid() AND group_id IS NULL;

    UPDATE public.champion_pick
    SET group_id = v_group.id
    WHERE user_id = auth.uid() AND group_id IS NULL;

    UPDATE public.top_scorer_pick
    SET group_id = v_group.id
    WHERE user_id = auth.uid() AND group_id IS NULL;
  END IF;

  RETURN v_membership;
END;
$$;
