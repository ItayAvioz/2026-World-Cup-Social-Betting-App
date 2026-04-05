-- Migration 50: game_events table
-- Stores goal and red card events per game with minute data
-- Populated by football-api-sync EF via /fixtures/events

CREATE TABLE game_events (
  id             uuid DEFAULT gen_random_uuid() PRIMARY KEY,
  game_id        uuid NOT NULL REFERENCES games(id) ON DELETE CASCADE,
  team           text NOT NULL,
  player_name    text,
  event_type     text NOT NULL CHECK (event_type IN ('goal', 'red_card')),
  minute         smallint NOT NULL,
  minute_extra   smallint,
  detail         text,  -- 'Normal Goal', 'Own Goal', 'Penalty', 'Red Card', 'Second Yellow card'
  UNIQUE (game_id, team, player_name, event_type, minute)
);

CREATE INDEX game_events_game_id_idx ON game_events (game_id);

ALTER TABLE game_events ENABLE ROW LEVEL SECURITY;

-- Public read for finished games (score_home IS NOT NULL)
CREATE POLICY "game_events_select" ON game_events
  FOR SELECT USING (
    EXISTS (SELECT 1 FROM games WHERE id = game_id AND score_home IS NOT NULL)
  );
