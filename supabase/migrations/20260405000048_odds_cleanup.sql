-- Migration 48: Odds source cleanup
-- 1. Unschedule sync-odds-daily pg_cron (TheOddsAPI game h2h — replaced by API Football / Bet365)
-- 2. champion-odds-daily pg_cron also removed — now handled by cron-job.org external cron
-- 3. af-odds-daily pg_cron remains active (API Football Bet365 1X2 + over/under)

-- Remove TheOddsAPI game odds cron (was 07:00 UTC daily)
SELECT cron.unschedule(jobname)
FROM cron.job
WHERE jobname = 'sync-odds-daily';

-- Remove champion odds pg_cron (now handled by cron-job.org external cron, expires Jun 11 2026)
SELECT cron.unschedule(jobname)
FROM cron.job
WHERE jobname = 'champion-odds-daily';
