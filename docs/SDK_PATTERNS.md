# Supabase SDK Patterns

Always use `_supabase` from `js/supabase.js` — never create a new client.

## Auth
```js
// Register → profile → redirect
const { error } = await _supabase.auth.signUp({ email, password, options: { data: { username } } });
if (!error) {
  await _supabase.rpc('create_profile', { p_username: username });
  window.location.href = 'dashboard.html';
}

// Login
const { error } = await _supabase.auth.signInWithPassword({ email, password });
if (!error) window.location.href = 'dashboard.html';

// Logout
await _supabase.auth.signOut();
window.location.href = 'index.html';

// Session guard (top of every protected page)
const { data: { session } } = await _supabase.auth.getSession(); // NOT getUser()
if (!session) { window.location.href = 'index.html'; return; }
```

## Predictions
Per-group since M30. Each user has ONE prediction per `(game_id, group_id)`. For
ungrouped users, `group_id` is `NULL` (`UNIQUE NULLS NOT DISTINCT`).

```js
// Upsert — contextGroupId is null for ungrouped users, otherwise a uuid
const row = { user_id: session.user.id, game_id, pred_home, pred_away };
if (contextGroupId !== null) row.group_id = contextGroupId;
const { error } = await _supabase.from('predictions').upsert(
  row,
  { onConflict: 'user_id,game_id,group_id' }
);
if (error?.code === '42501') showToast('Predictions are locked', 'error');

// Load group predictions post-kickoff — ALWAYS filter by group_id
// (RLS via is_group_member enforces the backstop, but the filter keeps the
//  query small and prevents leaking your OTHER groups' predictions)
let q = _supabase.from('predictions')
  .select('pred_home, pred_away, is_auto, profiles(username)')
  .eq('game_id', gameId);
q = contextGroupId !== null ? q.eq('group_id', contextGroupId) : q.is('group_id', null);
const { data } = await q;
```

## Picks (Champion + Top Scorer)
Per-group since M29. Each user has ONE champion + ONE top scorer pick per group.
Ungrouped users: `group_id` is `NULL` (`UNIQUE NULLS NOT DISTINCT`). A grouped user
cannot insert a `group_id = NULL` pick — mutual exclusivity trigger rejects it.

```js
// Champion — lock at 2026-06-11T19:00:00Z
const champRow = { user_id: session.user.id, team };
if (contextGroupId !== null) champRow.group_id = contextGroupId;
await _supabase.from('champion_pick').upsert(
  champRow,
  { onConflict: 'user_id,group_id' }
);

// Top scorer — must send BOTH player_name AND top_scorer_api_id
// (NULL api_id scores 0 forever — M51 enforces NOT NULL on candidates)
const scorerRow = { user_id: session.user.id, player_name, top_scorer_api_id };
if (contextGroupId !== null) scorerRow.group_id = contextGroupId;
await _supabase.from('top_scorer_pick').upsert(
  scorerRow,
  { onConflict: 'user_id,group_id' }
);
// RLS 42501 = deadline passed
```

## Leaderboard
```js
// Global — rank, user_id, username, champion_team, top_scorer_player, total_points, exact_scores
const { data } = await _supabase.rpc('get_leaderboard');

// Group — adds group_rank, global_rank
const { data } = await _supabase.rpc('get_group_leaderboard', { p_group_id: groupId });
```

## Groups
```js
// Create (max 3 per user) — param is group_name, NOT name
const { data, error } = await _supabase.rpc('create_group', { group_name: groupName });
// error.message: 'max_groups_reached'

// Join via invite code (max 10 members) — param is p_invite_code
const { data, error } = await _supabase.rpc('join_group', { p_invite_code: code });
// error.message: 'group_full' | 'invalid_code' | 'already_member'

// Load user's groups with members
const { data } = await _supabase.from('groups')
  .select('id, name, invite_code, created_by, group_members(user_id, is_inactive, profiles(username))')
  .order('created_at');

// Flag member inactive (captain only)
await _supabase.from('group_members')
  .update({ is_inactive: true })
  .eq('group_id', groupId).eq('user_id', targetUserId);
```

## AI Summaries
```js
const { data } = await _supabase.from('ai_summaries')
  .select('date, content, games_count, generated_at')
  .eq('group_id', groupId)
  .order('date', { ascending: false })
  .limit(10);
```

## Games
```js
// Today's games
const today = new Date().toISOString().split('T')[0];
const { data } = await _supabase.from('games')
  .select('*')
  .gte('kick_off_time', today + 'T00:00:00Z')
  .lt('kick_off_time', today + 'T23:59:59Z')
  .order('kick_off_time');

// Single game with odds + stats
const { data: game } = await _supabase.from('games')
  .select('*, game_odds(*), game_team_stats(*)')
  .eq('id', gameId)
  .single();
```

## Error Codes
```js
// Named RPC errors come as plain text in error.message
if (error?.message === 'max_groups_reached') showToast('You can only create 3 groups', 'error');
if (error?.message === 'group_full')         showToast('Group is full (max 10)', 'error');
if (error?.message === 'account_locked')     showToast('Account locked after June 11', 'error');
if (error?.message === 'already_member')     showToast('Already in this group', 'error');
// RLS violation
if (error?.code === '42501')                 showToast('Action not allowed', 'error');
```
