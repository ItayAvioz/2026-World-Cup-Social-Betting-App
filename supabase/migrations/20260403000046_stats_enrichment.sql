-- Migration 46: Stats enrichment
-- Adds shots_insidebox + xG to game_team_stats
-- Adds position + rating + gk_saves + gk_conceded to game_player_stats

-- ═══════════════════════════════════════════════════════════
-- 1. game_team_stats — new columns
-- ═══════════════════════════════════════════════════════════
ALTER TABLE public.game_team_stats
  ADD COLUMN IF NOT EXISTS shots_insidebox int,       -- shots inside penalty box
  ADD COLUMN IF NOT EXISTS xg              numeric(4,2); -- expected goals (e.g. 2.43)

-- ═══════════════════════════════════════════════════════════
-- 2. game_player_stats — new columns
-- ═══════════════════════════════════════════════════════════
ALTER TABLE public.game_player_stats
  ADD COLUMN IF NOT EXISTS position    char(1),      -- G / D / M / F
  ADD COLUMN IF NOT EXISTS rating      numeric(3,1), -- API rating 0.0–10.0 (e.g. 9.3)
  ADD COLUMN IF NOT EXISTS gk_saves    int,          -- goalkeeper saves (GK only)
  ADD COLUMN IF NOT EXISTS gk_conceded int;          -- goals conceded (GK only)
