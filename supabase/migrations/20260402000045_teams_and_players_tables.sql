-- Migration 45: teams + top_scorer_candidates tables
-- Replace hardcoded TEAMS/STRIKERS arrays with DB-driven data
-- Picks.jsx + fn_auto_assign_picks read from these tables

-- ═══════════════════════════════════════════════════════════
-- 1. teams table
-- ═══════════════════════════════════════════════════════════
CREATE TABLE public.teams (
  id            uuid        PRIMARY KEY DEFAULT gen_random_uuid(),
  name          text        UNIQUE NOT NULL,
  flag_code     text,
  group_name    text,
  api_team_id   int,
  is_tbd        boolean     NOT NULL DEFAULT false,
  fifa_rank     int,
  confederation text,
  created_at    timestamptz NOT NULL DEFAULT now()
);

ALTER TABLE public.teams ENABLE ROW LEVEL SECURITY;
CREATE POLICY "teams: public read" ON public.teams FOR SELECT USING (true);

-- ═══════════════════════════════════════════════════════════
-- 2. top_scorer_candidates table
-- ═══════════════════════════════════════════════════════════
CREATE TABLE public.top_scorer_candidates (
  id            uuid        PRIMARY KEY DEFAULT gen_random_uuid(),
  name          text        UNIQUE NOT NULL,
  team_name     text        NOT NULL REFERENCES public.teams(name),
  flag_code     text,
  api_player_id int,
  is_active     boolean     NOT NULL DEFAULT true,
  created_at    timestamptz NOT NULL DEFAULT now()
);

ALTER TABLE public.top_scorer_candidates ENABLE ROW LEVEL SECURITY;
CREATE POLICY "top_scorer_candidates: public read" ON public.top_scorer_candidates FOR SELECT USING (true);

-- ═══════════════════════════════════════════════════════════
-- 3. Seed 48 confirmed teams + 6 TBD qualifier slots
-- ═══════════════════════════════════════════════════════════
INSERT INTO public.teams (name, flag_code, group_name, is_tbd, fifa_rank, confederation) VALUES
  -- Group A
  ('Mexico',         'mx',     'A', false, 16, 'CONCACAF'),
  ('South Africa',   'za',     'A', false, 61, 'CAF'),
  ('South Korea',    'kr',     'A', false, 22, 'AFC'),
  ('UEFA PO-D',       NULL,    'A', true,  NULL, 'UEFA'),
  -- Group B
  ('Canada',         'ca',     'B', false, 29, 'CONCACAF'),
  ('Qatar',          'qa',     'B', false, 51, 'AFC'),
  ('Switzerland',    'ch',     'B', false, 18, 'UEFA'),
  ('UEFA PO-A',       NULL,    'B', true,  NULL, 'UEFA'),
  -- Group C
  ('Brazil',         'br',     'C', false,  5, 'CONMEBOL'),
  ('Morocco',        'ma',     'C', false,  8, 'CAF'),
  ('Haiti',          'ht',     'C', false, 84, 'CONCACAF'),
  ('Scotland',       'gb-sct', 'C', false, 38, 'UEFA'),
  -- Group D
  ('United States',  'us',     'D', false, 15, 'CONCACAF'),
  ('Paraguay',       'py',     'D', false, 40, 'CONMEBOL'),
  ('Australia',      'au',     'D', false, 27, 'AFC'),
  ('UEFA PO-C',       NULL,    'D', true,  NULL, 'UEFA'),
  -- Group E
  ('Germany',        'de',     'E', false, 10, 'UEFA'),
  ('Curaçao',        'cw',     'E', false, 82, 'CONCACAF'),
  ('Ivory Coast',    'ci',     'E', false, 37, 'CAF'),
  ('Ecuador',        'ec',     'E', false, 23, 'CONMEBOL'),
  -- Group F
  ('Netherlands',    'nl',     'F', false,  7, 'UEFA'),
  ('Japan',          'jp',     'F', false, 19, 'AFC'),
  ('Tunisia',        'tn',     'F', false, 47, 'CAF'),
  ('UEFA PO-B',       NULL,    'F', true,  NULL, 'UEFA'),
  -- Group G
  ('Belgium',        'be',     'G', false,  9, 'UEFA'),
  ('Egypt',          'eg',     'G', false, 31, 'CAF'),
  ('Iran',           'ir',     'G', false, 20, 'AFC'),
  ('New Zealand',    'nz',     'G', false, 86, 'OFC'),
  -- Group H
  ('Spain',          'es',     'H', false,  1, 'UEFA'),
  ('Cape Verde',     'cv',     'H', false, 68, 'CAF'),
  ('Saudi Arabia',   'sa',     'H', false, 60, 'AFC'),
  ('Uruguay',        'uy',     'H', false, 17, 'CONMEBOL'),
  -- Group I
  ('France',         'fr',     'I', false,  3, 'UEFA'),
  ('Senegal',        'sn',     'I', false, 12, 'CAF'),
  ('Norway',         'no',     'I', false, 32, 'UEFA'),
  ('IC PO-2',         NULL,    'I', true,  NULL, NULL),
  -- Group J
  ('Argentina',      'ar',     'J', false,  2, 'CONMEBOL'),
  ('Algeria',        'dz',     'J', false, 28, 'CAF'),
  ('Austria',        'at',     'J', false, 24, 'UEFA'),
  ('Jordan',         'jo',     'J', false, 66, 'AFC'),
  -- Group K
  ('Portugal',       'pt',     'K', false,  6, 'UEFA'),
  ('Uzbekistan',     'uz',     'K', false, 52, 'AFC'),
  ('Colombia',       'co',     'K', false, 14, 'CONMEBOL'),
  ('IC PO-1',         NULL,    'K', true,  NULL, NULL),
  -- Group L
  ('England',        'gb-eng', 'L', false,  4, 'UEFA'),
  ('Croatia',        'hr',     'L', false, 11, 'UEFA'),
  ('Ghana',          'gh',     'L', false, 72, 'CAF'),
  ('Panama',         'pa',     'L', false, 33, 'CONCACAF');

-- ═══════════════════════════════════════════════════════════
-- 4. Seed 30 top scorer candidates
-- ═══════════════════════════════════════════════════════════
INSERT INTO public.top_scorer_candidates (name, team_name, flag_code, api_player_id) VALUES
  ('Kylian Mbappé',      'France',      'fr',     278),
  ('Erling Haaland',     'Norway',      'no',     1100),
  ('Lionel Messi',       'Argentina',   'ar',     154),
  ('Cristiano Ronaldo',  'Portugal',    'pt',     874),
  ('Vinicius Jr',        'Brazil',      'br',     5765),
  ('Lamine Yamal',       'Spain',       'es',     404386),
  ('Jude Bellingham',    'England',     'gb-eng', 132964),
  ('Harry Kane',         'England',     'gb-eng', 184),
  ('Jamal Musiala',      'Germany',     'de',     305452),
  ('Florian Wirtz',      'Germany',     'de',     305450),
  ('Lautaro Martínez',   'Argentina',   'ar',     730),
  ('Julian Álvarez',     'Argentina',   'ar',     46788),
  ('Mohamed Salah',      'Egypt',       'eg',     306),
  ('Bukayo Saka',        'England',     'gb-eng', NULL),
  ('Phil Foden',         'England',     'gb-eng', 186),
  ('Neymar Jr',          'Brazil',      'br',     276),
  ('Richarlison',        'Brazil',      'br',     6031),
  ('Antoine Griezmann',  'France',      'fr',     NULL),
  ('Marcus Thuram',      'France',      'fr',     2078),
  ('Cody Gakpo',         'Netherlands', 'nl',     38880),
  ('Romelu Lukaku',      'Belgium',     'be',     521),
  ('Son Heung-min',      'South Korea', 'kr',     186764),
  ('Rafael Leão',        'Portugal',    'pt',     21588),
  ('Gonçalo Ramos',      'Portugal',    'pt',     311360),
  ('Sadio Mané',         'Senegal',     'sn',     305),
  ('Darwin Núñez',       'Uruguay',     'uy',     35845),
  ('Kai Havertz',        'Germany',     'de',     NULL),
  ('Álvaro Morata',      'Spain',       'es',     2616),
  ('Pedri',              'Spain',       'es',     290907),
  ('Takefusa Kubo',      'Japan',       'jp',     6698);

-- ═══════════════════════════════════════════════════════════
-- 5. Replace champion_pick CHECK with FK to teams
-- ═══════════════════════════════════════════════════════════
ALTER TABLE public.champion_pick DROP CONSTRAINT champion_pick_team_check;
ALTER TABLE public.champion_pick
  ADD CONSTRAINT champion_pick_team_fk
  FOREIGN KEY (team) REFERENCES public.teams(name) ON UPDATE CASCADE;

-- ═══════════════════════════════════════════════════════════
-- 6. Rewrite fn_auto_assign_picks to read from tables
-- ═══════════════════════════════════════════════════════════
CREATE OR REPLACE FUNCTION public.fn_auto_assign_picks()
RETURNS void LANGUAGE plpgsql SECURITY DEFINER AS $$
DECLARE
  v_combo    record;
  v_uid      uuid;
  v_champion text;
  v_player   record;
BEGIN
  -- ═══ CHAMPION PICKS — grouped users ═══
  FOR v_combo IN
    SELECT gm.user_id, gm.group_id
    FROM public.group_members gm
    WHERE NOT EXISTS (
      SELECT 1 FROM public.champion_pick cp
      WHERE cp.user_id = gm.user_id AND cp.group_id = gm.group_id
    )
  LOOP
    SELECT t.name INTO v_champion
    FROM public.teams t
    LEFT JOIN (
      SELECT team, COUNT(*) AS cnt
      FROM public.champion_pick
      WHERE group_id = v_combo.group_id
      GROUP BY team
    ) cc ON cc.team = t.name
    WHERE t.is_tbd = false
    ORDER BY COALESCE(cc.cnt, 0) ASC, random()
    LIMIT 1;

    INSERT INTO public.champion_pick (user_id, group_id, team, is_auto)
    VALUES (v_combo.user_id, v_combo.group_id, v_champion, true)
    ON CONFLICT ON CONSTRAINT champion_pick_user_group_unique DO NOTHING;
  END LOOP;

  -- ═══ CHAMPION PICKS — ungrouped users ═══
  FOR v_uid IN
    SELECT p.id FROM public.profiles p
    WHERE NOT EXISTS (SELECT 1 FROM public.group_members WHERE user_id = p.id)
      AND NOT EXISTS (SELECT 1 FROM public.champion_pick WHERE user_id = p.id AND group_id IS NULL)
  LOOP
    SELECT t.name INTO v_champion
    FROM public.teams t
    LEFT JOIN (
      SELECT team, COUNT(*) AS cnt FROM public.champion_pick
      WHERE group_id IS NULL GROUP BY team
    ) cc ON cc.team = t.name
    WHERE t.is_tbd = false
    ORDER BY COALESCE(cc.cnt, 0) ASC, random()
    LIMIT 1;

    INSERT INTO public.champion_pick (user_id, group_id, team, is_auto)
    VALUES (v_uid, NULL, v_champion, true)
    ON CONFLICT ON CONSTRAINT champion_pick_user_group_unique DO NOTHING;
  END LOOP;

  -- ═══ TOP SCORER PICKS — grouped users ═══
  FOR v_combo IN
    SELECT gm.user_id, gm.group_id
    FROM public.group_members gm
    WHERE NOT EXISTS (
      SELECT 1 FROM public.top_scorer_pick ts
      WHERE ts.user_id = gm.user_id AND ts.group_id = gm.group_id
    )
  LOOP
    SELECT tsc.name, tsc.api_player_id INTO v_player
    FROM public.top_scorer_candidates tsc
    WHERE tsc.is_active = true
    LEFT JOIN (
      SELECT player_name, COUNT(*) AS cnt FROM public.top_scorer_pick
      WHERE group_id = v_combo.group_id GROUP BY player_name
    ) pc ON pc.player_name = tsc.name
    ORDER BY COALESCE(pc.cnt, 0) ASC, random()
    LIMIT 1;

    INSERT INTO public.top_scorer_pick (user_id, group_id, player_name, top_scorer_api_id, is_auto)
    VALUES (v_combo.user_id, v_combo.group_id, v_player.name, v_player.api_player_id, true)
    ON CONFLICT ON CONSTRAINT top_scorer_pick_user_group_unique DO NOTHING;
  END LOOP;

  -- ═══ TOP SCORER PICKS — ungrouped users ═══
  FOR v_uid IN
    SELECT p.id FROM public.profiles p
    WHERE NOT EXISTS (SELECT 1 FROM public.group_members WHERE user_id = p.id)
      AND NOT EXISTS (SELECT 1 FROM public.top_scorer_pick WHERE user_id = p.id AND group_id IS NULL)
  LOOP
    SELECT tsc.name, tsc.api_player_id INTO v_player
    FROM public.top_scorer_candidates tsc
    WHERE tsc.is_active = true
    LEFT JOIN (
      SELECT player_name, COUNT(*) AS cnt FROM public.top_scorer_pick
      WHERE group_id IS NULL GROUP BY player_name
    ) pc ON pc.player_name = tsc.name
    ORDER BY COALESCE(pc.cnt, 0) ASC, random()
    LIMIT 1;

    INSERT INTO public.top_scorer_pick (user_id, group_id, player_name, top_scorer_api_id, is_auto)
    VALUES (v_uid, NULL, v_player.name, v_player.api_player_id, true)
    ON CONFLICT ON CONSTRAINT top_scorer_pick_user_group_unique DO NOTHING;
  END LOOP;
END;
$$;
