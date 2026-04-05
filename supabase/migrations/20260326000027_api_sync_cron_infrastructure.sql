-- Migration 27: API Sync Cron Infrastructure
-- SQL helper functions for scheduling football-api-sync and sync-odds Edge Function calls
-- via pg_cron + pg_net.
--
-- Config stored in Supabase Vault (no ALTER DATABASE needed):
--   SELECT vault.create_secret('https://ftryuvfdihmhlzvbpfeu.supabase.co/functions/v1', 'app_edge_function_url', 'EF base URL');
--   SELECT vault.create_secret('<service_role_key>', 'app_service_role_key', 'Service role key for cron EF calls');
--   (app_edge_function_url is pre-inserted by this migration; app_service_role_key must be added manually)
--
-- Post-deploy setup order:
--   1. supabase functions deploy football-api-sync sync-odds
--   2. supabase secrets set FOOTBALL_API_KEY=... ODDS_API_KEY=...
--   3. INSERT service role key into vault (see above)
--   4. Call football-api-sync with mode=setup to map api_fixture_id for all games
--   5. SELECT public.fn_schedule_odds_sync();
--   6. SELECT public.fn_schedule_game_sync(id) FROM games WHERE kick_off_time > now() AND api_fixture_id IS NOT NULL;

-- Store EF base URL in vault (public value)
SELECT vault.create_secret(
  'https://ftryuvfdihmhlzvbpfeu.supabase.co/functions/v1',
  'app_edge_function_url',
  'Base URL for Supabase Edge Functions (used by pg_cron jobs)'
);


-- ─── fn_schedule_game_sync ────────────────────────────────────────────────────
-- Creates two one-shot pg_cron jobs for a game:
--   verify-game-{id}  fires 30min before KO  → football-api-sync mode=verify
--   sync-game-{id}    fires KO+120min         → football-api-sync mode=sync
-- Both jobs self-unschedule after firing.
-- After the initial sync fires, the EF calls fn_schedule_retry_sync if game not done.

CREATE OR REPLACE FUNCTION public.fn_schedule_game_sync(p_game_id uuid)
RETURNS jsonb
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
  v_ko_time     timestamptz;
  v_fixture_id  int;
  v_phase       text;
  v_phase_norm  text;
  v_verify_job  text := 'verify-game-' || p_game_id::text;
  v_sync_job    text := 'sync-game-'   || p_game_id::text;
  v_verify_cron text;
  v_sync_cron   text;
  v_ef_url      text;
BEGIN
  SELECT kick_off_time, api_fixture_id, phase
    INTO v_ko_time, v_fixture_id, v_phase
    FROM public.games
   WHERE id = p_game_id;

  IF NOT FOUND THEN
    RAISE EXCEPTION 'Game % not found', p_game_id;
  END IF;

  IF v_fixture_id IS NULL THEN
    RAISE EXCEPTION 'api_fixture_id not set for game %. Run football-api-sync setup mode first.', p_game_id;
  END IF;

  IF v_ko_time <= now() THEN
    RAISE EXCEPTION 'kick_off_time % is in the past for game %.', v_ko_time, p_game_id;
  END IF;

  -- Read EF base URL from vault
  SELECT decrypted_secret INTO v_ef_url
    FROM vault.decrypted_secrets
   WHERE name = 'app_edge_function_url';

  IF v_ef_url IS NULL THEN
    RAISE EXCEPTION 'app_edge_function_url not found in vault';
  END IF;

  -- Normalize phase: 'group' stays 'group', all knockout phases → 'knockout'
  v_phase_norm := CASE WHEN v_phase = 'group' THEN 'group' ELSE 'knockout' END;

  -- Build cron expressions: format MI HH24 DD MM *
  v_verify_cron := to_char(v_ko_time - interval '30 minutes',  'MI HH24 DD MM') || ' *';
  v_sync_cron   := to_char(v_ko_time + interval '120 minutes', 'MI HH24 DD MM') || ' *';

  -- Remove existing jobs if already scheduled (safe reschedule)
  IF EXISTS (SELECT 1 FROM cron.job WHERE jobname = v_verify_job) THEN
    PERFORM cron.unschedule(v_verify_job);
  END IF;
  IF EXISTS (SELECT 1 FROM cron.job WHERE jobname = v_sync_job) THEN
    PERFORM cron.unschedule(v_sync_job);
  END IF;

  -- Schedule verify job
  PERFORM cron.schedule(
    v_verify_job,
    v_verify_cron,
    format($cron$
      SELECT net.http_post(
        url     := (SELECT decrypted_secret FROM vault.decrypted_secrets WHERE name = 'app_edge_function_url') || '/football-api-sync',
        headers := jsonb_build_object(
                     'Content-Type',  'application/json',
                     'Authorization', 'Bearer ' || (SELECT decrypted_secret FROM vault.decrypted_secrets WHERE name = 'app_service_role_key')
                   ),
        body    := %L::jsonb
      );
      SELECT cron.unschedule(%L);
    $cron$,
    jsonb_build_object('mode', 'verify', 'game_id', p_game_id)::text,
    v_verify_job
  ));

  -- Schedule sync job
  PERFORM cron.schedule(
    v_sync_job,
    v_sync_cron,
    format($cron$
      SELECT net.http_post(
        url     := (SELECT decrypted_secret FROM vault.decrypted_secrets WHERE name = 'app_edge_function_url') || '/football-api-sync',
        headers := jsonb_build_object(
                     'Content-Type',  'application/json',
                     'Authorization', 'Bearer ' || (SELECT decrypted_secret FROM vault.decrypted_secrets WHERE name = 'app_service_role_key')
                   ),
        body    := %L::jsonb
      );
      SELECT cron.unschedule(%L);
    $cron$,
    jsonb_build_object('mode', 'sync', 'game_id', p_game_id, 'phase', v_phase_norm, 'stage', 'initial')::text,
    v_sync_job
  ));

  RAISE LOG 'fn_schedule_game_sync: game=% verify=% (%) sync=% (%)',
    p_game_id, v_verify_job, v_verify_cron, v_sync_job, v_sync_cron;

  RETURN jsonb_build_object(
    'verify_job',  v_verify_job,
    'sync_job',    v_sync_job,
    'verify_cron', v_verify_cron,
    'sync_cron',   v_sync_cron
  );
END;
$$;


-- ─── fn_schedule_retry_sync ───────────────────────────────────────────────────
-- Called by the football-api-sync EF to schedule a retry when the game is not done.
-- Creates a unique one-shot pg_cron job that fires N minutes from now.
-- Reads game.phase from DB to determine group vs knockout routing.

CREATE OR REPLACE FUNCTION public.fn_schedule_retry_sync(
  p_game_id       uuid,
  p_stage         text,   -- 'initial' | 'et_followup'
  p_delay_minutes int     -- 5 for normal retry, 40 for ET followup
)
RETURNS text  -- job name
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
  v_phase     text;
  v_fire_time timestamptz := now() + (p_delay_minutes || ' minutes')::interval;
  v_cron_expr text        := to_char(v_fire_time, 'MI HH24 DD MM') || ' *';
  v_job_name  text        := 'retry-sync-' || p_game_id::text || '-' || extract(epoch from now())::bigint::text;
BEGIN
  -- Normalize phase from DB
  SELECT CASE WHEN phase = 'group' THEN 'group' ELSE 'knockout' END
    INTO v_phase
    FROM public.games
   WHERE id = p_game_id;

  IF NOT FOUND THEN
    RAISE EXCEPTION 'Game % not found', p_game_id;
  END IF;

  PERFORM cron.schedule(
    v_job_name,
    v_cron_expr,
    format($cron$
      SELECT net.http_post(
        url     := (SELECT decrypted_secret FROM vault.decrypted_secrets WHERE name = 'app_edge_function_url') || '/football-api-sync',
        headers := jsonb_build_object(
                     'Content-Type',  'application/json',
                     'Authorization', 'Bearer ' || (SELECT decrypted_secret FROM vault.decrypted_secrets WHERE name = 'app_service_role_key')
                   ),
        body    := %L::jsonb
      );
      SELECT cron.unschedule(%L);
    $cron$,
    jsonb_build_object('mode', 'sync', 'game_id', p_game_id, 'phase', v_phase, 'stage', p_stage)::text,
    v_job_name
  ));

  RAISE LOG 'fn_schedule_retry_sync: job=% fires=% game=% stage=%',
    v_job_name, v_fire_time, p_game_id, p_stage;

  RETURN v_job_name;
END;
$$;


-- ─── fn_unschedule_game_sync ──────────────────────────────────────────────────
-- Removes verify + sync crons for a game after successful sync.
-- Called by the EF on completion. Safe no-op if jobs already removed.

CREATE OR REPLACE FUNCTION public.fn_unschedule_game_sync(p_game_id uuid)
RETURNS void
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
  v_verify_job text := 'verify-game-' || p_game_id::text;
  v_sync_job   text := 'sync-game-'   || p_game_id::text;
BEGIN
  IF EXISTS (SELECT 1 FROM cron.job WHERE jobname = v_verify_job) THEN
    PERFORM cron.unschedule(v_verify_job);
  END IF;
  IF EXISTS (SELECT 1 FROM cron.job WHERE jobname = v_sync_job) THEN
    PERFORM cron.unschedule(v_sync_job);
  END IF;
END;
$$;


-- ─── fn_schedule_odds_sync ────────────────────────────────────────────────────
-- Registers (or replaces) the daily sync-odds cron at 07:00 UTC.
-- Call once after EFs are deployed and DB config vars are set.

CREATE OR REPLACE FUNCTION public.fn_schedule_odds_sync()
RETURNS void
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
BEGIN
  IF EXISTS (SELECT 1 FROM cron.job WHERE jobname = 'sync-odds-daily') THEN
    PERFORM cron.unschedule('sync-odds-daily');
  END IF;

  PERFORM cron.schedule(
    'sync-odds-daily',
    '0 7 * * *',
    $cron$
      SELECT net.http_post(
        url     := (SELECT decrypted_secret FROM vault.decrypted_secrets WHERE name = 'app_edge_function_url') || '/sync-odds',
        headers := jsonb_build_object(
                     'Content-Type',  'application/json',
                     'Authorization', 'Bearer ' || (SELECT decrypted_secret FROM vault.decrypted_secrets WHERE name = 'app_service_role_key')
                   ),
        body    := '{}'::jsonb
      );
    $cron$
  );

  RAISE LOG 'fn_schedule_odds_sync: daily cron registered at 07:00 UTC';
END;
$$;


-- ─── Grants ───────────────────────────────────────────────────────────────────

GRANT EXECUTE ON FUNCTION public.fn_schedule_game_sync(uuid)             TO service_role;
GRANT EXECUTE ON FUNCTION public.fn_schedule_retry_sync(uuid, text, int) TO service_role;
GRANT EXECUTE ON FUNCTION public.fn_unschedule_game_sync(uuid)           TO service_role;
GRANT EXECUTE ON FUNCTION public.fn_schedule_odds_sync()                 TO service_role;
