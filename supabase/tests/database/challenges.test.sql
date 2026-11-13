-- Phase 2: challenges + participations RLS tests.
begin;
create extension if not exists pgtap with schema extensions;
select plan(17);

-- Replace seed data with a known past / current / future set.
delete from public.challenges;
insert into public.challenges (id, title, description, category, opens_at, closes_at) values
  ('aaaaaaaa-0000-0000-0000-000000000001', 'Past quest', 'd', 'baking',
     now() - interval '14 days', now() - interval '7 days'),
  ('aaaaaaaa-0000-0000-0000-000000000002', 'Current quest', 'd', 'poetry',
     now() - interval '1 day', now() + interval '6 days'),
  ('aaaaaaaa-0000-0000-0000-000000000003', 'Future quest', 'd', 'drawing',
     now() + interval '6 days', now() + interval '13 days');

insert into auth.users (id, email) values
  ('11111111-1111-1111-1111-111111111111', 'alice@test.dev'),
  ('22222222-2222-2222-2222-222222222222', 'bob@test.dev');

-- Bob accepted the current quest before Alice looks.
insert into public.participations (user_id, challenge_id, status) values
  ('22222222-2222-2222-2222-222222222222', 'aaaaaaaa-0000-0000-0000-000000000002', 'accepted');

-- Schema rules (as the owner)
select throws_ok(
  $$insert into public.challenges (title, description, category, opens_at, closes_at)
    values ('Overlap', 'd', 'music', now(), now() + interval '1 day')$$,
  '23P01', null,
  'two challenges cannot be live at the same time'
);
select throws_ok(
  $$insert into public.challenges (title, description, category, opens_at, closes_at)
    values ('Backwards', 'd', 'music', now() + interval '30 days', now() + interval '29 days')$$,
  '23514', null,
  'closes_at must be after opens_at'
);

set local role anon;
select throws_ok('select * from public.challenges', '42501', null,
  'anon cannot read challenges');
reset role;

-- Act as Alice.
set local role authenticated;
set local request.jwt.claims = '{"sub":"11111111-1111-1111-1111-111111111111","role":"authenticated"}';

select results_eq(
  'select title from public.challenges order by opens_at',
  array['Past quest', 'Current quest'],
  'future challenges are hidden'
);
select is(
  (select title from public.current_challenge()),
  'Current quest',
  'current_challenge() returns the live challenge'
);
select is(
  public.challenge_accepted_count('aaaaaaaa-0000-0000-0000-000000000002'),
  1,
  'accepted count includes other users'
);
select is_empty(
  'select * from public.participations',
  'cannot see other users'' responses'
);

-- Respond to the current challenge.
select lives_ok(
  $$insert into public.participations (user_id, challenge_id, status)
    values ('11111111-1111-1111-1111-111111111111', 'aaaaaaaa-0000-0000-0000-000000000002', 'declined')$$,
  'can decline the current challenge'
);
select lives_ok(
  $$update public.participations set status = 'accepted'
    where user_id = '11111111-1111-1111-1111-111111111111'
      and challenge_id = 'aaaaaaaa-0000-0000-0000-000000000002'$$,
  'can change decline to accept while open'
);
select is(
  (select status from public.participations
    where challenge_id = 'aaaaaaaa-0000-0000-0000-000000000002'),
  'accepted',
  'response persists'
);
select throws_ok(
  $$insert into public.participations (user_id, challenge_id, status)
    values ('11111111-1111-1111-1111-111111111111', 'aaaaaaaa-0000-0000-0000-000000000002', 'declined')$$,
  '23505', null,
  'one response row per user per challenge'
);

select throws_ok(
  $$insert into public.participations (user_id, challenge_id, status)
    values ('11111111-1111-1111-1111-111111111111', 'aaaaaaaa-0000-0000-0000-000000000001', 'accepted')$$,
  '42501', null,
  'cannot respond to a closed challenge'
);
select throws_ok(
  $$insert into public.participations (user_id, challenge_id, status)
    values ('11111111-1111-1111-1111-111111111111', 'aaaaaaaa-0000-0000-0000-000000000003', 'accepted')$$,
  '42501', null,
  'cannot respond to a future challenge'
);
select throws_ok(
  $$insert into public.participations (user_id, challenge_id, status)
    values ('22222222-2222-2222-2222-222222222222', 'aaaaaaaa-0000-0000-0000-000000000002', 'declined')$$,
  '42501', null,
  'cannot respond on behalf of another user'
);
select throws_ok(
  $$update public.participations set responded_at = now() - interval '1 year'$$,
  '42501', null,
  'responded_at is not client-writable'
);
select throws_ok(
  $$insert into public.challenges (title, description, category, opens_at, closes_at)
    values ('Mine', 'd', 'music', now() + interval '60 days', now() + interval '61 days')$$,
  '42501', null,
  'users cannot create challenges'
);
reset role;

-- Closing the window freezes responses.
update public.challenges set closes_at = now() - interval '1 second', opens_at = now() - interval '7 days'
  where id = 'aaaaaaaa-0000-0000-0000-000000000002';
set local role authenticated;
set local request.jwt.claims = '{"sub":"11111111-1111-1111-1111-111111111111","role":"authenticated"}';
select throws_ok(
  $$update public.participations set status = 'declined'
    where user_id = '11111111-1111-1111-1111-111111111111'$$,
  '42501', null,
  'cannot change response after the deadline'
);

select * from finish();
rollback;
