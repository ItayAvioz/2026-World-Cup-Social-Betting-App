-- Migration: passes_stats
-- Adds passes_total and passes_accuracy to game_team_stats
-- Populated by football-api-sync EF v22+ via /fixtures/statistics
--   (API keys: 'Total passes' for count, 'Passes %' for accuracy 0-100)
--
-- NOTE: This migration was originally applied via MCP apply_migration
-- (deployed version 20260405120733) without a physical file.
-- File reconstructed 2026-04-05 to protect against `supabase db reset`.
-- Uses IF NOT EXISTS so re-applying against the live DB is a no-op.

ALTER TABLE game_team_stats
  ADD COLUMN IF NOT EXISTS passes_total    integer,
  ADD COLUMN IF NOT EXISTS passes_accuracy integer;
