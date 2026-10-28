-- SceneLock visibility rule. Run with `npm run test:db` (requires `supabase start`).
-- Any change to public.scenelock_can_view must keep every case here passing; add cases, don't
-- delete them. Mirrors src/lib/scenelock/visibility.test.ts.
begin;
create extension if not exists pgtap with schema extensions;
select plan(18);

insert into auth.users (id, email) values
  ('00000000-0000-0000-0000-00000000000a', 'mid@example.test'),
  ('00000000-0000-0000-0000-00000000000b', 'fresh@example.test'),
  ('00000000-0000-0000-0000-00000000000c', 'done@example.test');

insert into public.shows (id, slug, title, source)
values ('10000000-0000-0000-0000-000000000001', 'test-show', 'Test Show', 'test fixture');
insert into public.editions (id, show_id, name, is_default) values
  ('20000000-0000-0000-0000-000000000001', '10000000-0000-0000-0000-000000000001', 'Broadcast', true),
  ('20000000-0000-0000-0000-000000000002', '10000000-0000-0000-0000-000000000001', 'Streamer cut', false);

-- a: in E2 at 10:00 on Broadcast. c: finished E2 on Broadcast. b: no progress row.
insert into public.viewer_progress (user_id, show_id, edition_id, episode_order, position_seconds, episode_completed) values
  ('00000000-0000-0000-0000-00000000000a', '10000000-0000-0000-0000-000000000001', '20000000-0000-0000-0000-000000000001', 2, 600, false),
  ('00000000-0000-0000-0000-00000000000c', '10000000-0000-0000-0000-000000000001', '20000000-0000-0000-0000-000000000001', 2, 0, true);

create temp table t as select
  '00000000-0000-0000-0000-00000000000a'::uuid as mid,
  '00000000-0000-0000-0000-00000000000b'::uuid as fresh,
  '00000000-0000-0000-0000-00000000000c'::uuid as done,
  '10000000-0000-0000-0000-000000000001'::uuid as show,
  '20000000-0000-0000-0000-000000000001'::uuid as broadcast,
  '20000000-0000-0000-0000-000000000002'::uuid as streamer;

-- Viewer at E2 10:00 (PRD acceptance tests 1 and 2)
select ok(    scenelock_can_view(mid, show, broadcast, 1, null), 'E1 whole-episode content visible') from t;
select ok(    scenelock_can_view(mid, show, broadcast, 2, 600),  'E2 10:00 visible at E2 10:00') from t;
select ok(not scenelock_can_view(mid, show, broadcast, 2, 601),  'E2 10:01 hidden at E2 10:00') from t;
select ok(not scenelock_can_view(mid, show, broadcast, 2, null), 'E2 whole-episode hidden until completed') from t;
select ok(not scenelock_can_view(mid, show, broadcast, 3, 0),    'E3 hidden') from t;
select ok(    scenelock_can_view(mid, show, null, 0, null),      'show-level content visible') from t;
-- Alternate cuts: timestamps from another edition fall back to episode-level gating
select ok(not scenelock_can_view(mid, show, streamer, 2, 300),   'other-edition timestamp treated as whole episode') from t;
select ok(not scenelock_can_view(mid, show, null, 2, 300),       'timestamp without edition treated as whole episode') from t;
select ok(    scenelock_can_view(mid, show, streamer, 1, 9999),  'earlier episode visible regardless of edition') from t;
-- Unknown / malformed boundaries are denied
select ok(not scenelock_can_view(mid, null, broadcast, 1, null), 'null show denied') from t;
select ok(not scenelock_can_view(mid, show, broadcast, null, 0), 'null episode denied') from t;
select ok(not scenelock_can_view(mid, show, broadcast, -1, 0),   'negative episode denied') from t;
-- Not started / signed out
select ok(    scenelock_can_view(fresh, show, null, 0, null),    'not started: show-level visible') from t;
select ok(not scenelock_can_view(fresh, show, broadcast, 1, 0),  'not started: E1 hidden') from t;
select ok(    scenelock_can_view(null, show, null, 0, null),     'signed out: show-level visible') from t;
select ok(not scenelock_can_view(null, show, broadcast, 1, 0),   'signed out: E1 hidden') from t;
-- Completed episode
select ok(    scenelock_can_view(done, show, broadcast, 2, null), 'completed E2: whole-episode visible') from t;
select ok(not scenelock_can_view(done, show, broadcast, 3, null), 'completed E2: E3 hidden') from t;

select * from finish();
rollback;
