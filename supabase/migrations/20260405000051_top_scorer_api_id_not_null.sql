-- Migration 51: enforce NOT NULL on top_scorer_candidates.api_player_id
--
-- Why: the scoring function fn_calculate_pick_points matches picks via
--   WHERE top_scorer_api_id = ANY(v_top_scorer_ids)
-- NULL never matches, so any candidate without an api_player_id causes
-- silent zero-scoring for anyone who picks them. Prevent at DB level.
--
-- Cleanup: deletes the 3 orphan rows seeded in M45 without api_ids
-- (Griezmann / Saka / Havertz). The real candidate list will be repopulated
-- from API Football /players during the API data-pull phase.
--
-- Picks referencing deleted candidates are NOT affected structurally
-- (top_scorer_pick has no FK to top_scorer_candidates), but any existing
-- pick row with top_scorer_api_id IS NULL stays a 0-pt pick — users can
-- overwrite before the 2026-06-11 deadline.

BEGIN;

-- 1. Remove orphan seed rows (test data — will be repopulated from API)
DELETE FROM public.top_scorer_candidates
WHERE api_player_id IS NULL;

-- 2. Enforce NOT NULL going forward
ALTER TABLE public.top_scorer_candidates
  ALTER COLUMN api_player_id SET NOT NULL;

COMMIT;
