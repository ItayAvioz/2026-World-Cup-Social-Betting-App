-- Migration 47: Odds enrichment + champion_odds table
-- Adds over_2_5 / under_2_5 to game_odds
-- Creates champion_odds table for outright winner odds per team
-- Adds daily cron helpers for champion odds + API Football odds

-- ═══════════════════════════════════════════════════════════
-- 1. game_odds — over/under 2.5 goals
-- ═══════════════════════════════════════════════════════════
ALTER TABLE public.game_odds
  ADD COLUMN IF NOT EXISTS over_2_5  numeric(5,2),  -- e.g. 1.57
  ADD COLUMN IF NOT EXISTS under_2_5 numeric(5,2);  -- e.g. 2.35

-- ═══════════════════════════════════════════════════════════
-- 2. champion_odds — outright odds for each team to win WC2026
-- ═══════════════════════════════════════════════════════════
CREATE TABLE IF NOT EXISTS public.champion_odds (
  id         uuid        PRIMARY KEY DEFAULT gen_random_uuid(),
  team_name  text        NOT NULL,   -- raw name from TheOddsAPI (e.g. "Bosnia & Herzegovina")
  bookmaker  text        NOT NULL,   -- e.g. "Betfair", "William Hill"
  odds       numeric(8,2),           -- decimal odds (e.g. 6.00 for Spain)
  updated_at timestamptz NOT NULL DEFAULT now(),
  UNIQUE (team_name, bookmaker)
);

ALTER TABLE public.champion_odds ENABLE ROW LEVEL SECURITY;

CREATE POLICY "champion_odds: authenticated read"
  ON public.champion_odds FOR SELECT TO authenticated USING (true);

-- ═══════════════════════════════════════════════════════════
-- 3. fn_schedule_champion_odds_sync — daily cron (07:30 UTC)
--    Calls sync-odds EF with mode=champion
-- ═══════════════════════════════════════════════════════════
CREATE OR REPLACE FUNCTION public.fn_schedule_champion_odds_sync()
RETURNS void
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
  v_url  text;
  v_key  text;
BEGIN
  SELECT decrypted_secret INTO v_url  FROM vault.decrypted_secrets WHERE name = 'app_edge_function_url';
  SELECT decrypted_secret INTO v_key  FROM vault.decrypted_secrets WHERE name = 'app_service_role_key';

  IF v_url IS NULL OR v_key IS NULL THEN
    RAISE EXCEPTION 'Vault secrets missing: app_edge_function_url or app_service_role_key';
  END IF;

  -- Remove any existing champion odds cron
  PERFORM cron.unschedule(jobname)
  FROM cron.job
  WHERE jobname = 'champion-odds-daily';

  -- Schedule daily at 07:30 UTC
  PERFORM cron.schedule(
    'champion-odds-daily',
    '30 7 * * *',
    format(
      $$
      SELECT net.http_post(
        url     := %L,
        body    := '{"mode":"champion"}'::jsonb,
        headers := jsonb_build_object(
          'Content-Type',  'application/json',
          'Authorization', 'Bearer ' || %L
        )
      );
      $$,
      v_url || '/sync-odds',
      v_key
    )
  );
END;
$$;

-- ═══════════════════════════════════════════════════════════
-- 4. fn_schedule_af_odds_sync — daily cron (07:15 UTC)
--    Calls football-api-sync EF with mode=sync_af_odds
--    Syncs API Football pre-match h2h + over/under for upcoming games
-- ═══════════════════════════════════════════════════════════
CREATE OR REPLACE FUNCTION public.fn_schedule_af_odds_sync()
RETURNS void
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
  v_url  text;
  v_key  text;
BEGIN
  SELECT decrypted_secret INTO v_url  FROM vault.decrypted_secrets WHERE name = 'app_edge_function_url';
  SELECT decrypted_secret INTO v_key  FROM vault.decrypted_secrets WHERE name = 'app_service_role_key';

  IF v_url IS NULL OR v_key IS NULL THEN
    RAISE EXCEPTION 'Vault secrets missing: app_edge_function_url or app_service_role_key';
  END IF;

  -- Remove any existing af odds cron
  PERFORM cron.unschedule(jobname)
  FROM cron.job
  WHERE jobname = 'af-odds-daily';

  -- Schedule daily at 07:15 UTC (before sync-odds at 07:30, after TheOddsAPI at 07:00)
  PERFORM cron.schedule(
    'af-odds-daily',
    '15 7 * * *',
    format(
      $$
      SELECT net.http_post(
        url     := %L,
        body    := '{"mode":"sync_af_odds"}'::jsonb,
        headers := jsonb_build_object(
          'Content-Type',  'application/json',
          'Authorization', 'Bearer ' || %L
        )
      );
      $$,
      v_url || '/football-api-sync',
      v_key
    )
  );
END;
$$;
