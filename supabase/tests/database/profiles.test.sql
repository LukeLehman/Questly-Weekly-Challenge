-- Phase 1: profiles RLS + trigger tests. Run with `npx supabase test db`.
begin;
create extension if not exists pgtap with schema extensions;
select plan(14);

-- Two users, created as Supabase Auth would.
insert into auth.users (id, email, raw_user_meta_data)
values
  ('11111111-1111-1111-1111-111111111111', 'alice@test.dev', '{"full_name":"Alice A"}'),
  ('22222222-2222-2222-2222-222222222222', 'bob@test.dev', '{}');

-- Trigger
select is(
  (select count(*)::int from public.profiles),
  2,
  'sign-up trigger creates a profile per user'
);
select is(
  (select display_name from public.profiles where id = '11111111-1111-1111-1111-111111111111'),
  'Alice A',
  'display_name is copied from the auth metadata'
);
select is(
  (select username from public.profiles where id = '22222222-2222-2222-2222-222222222222'),
  null,
  'username starts empty (onboarding not done)'
);

-- Anonymous visitors can't read profiles.
set local role anon;
select throws_ok(
  'select * from public.profiles',
  '42501',
  null,
  'anon cannot read profiles'
);
reset role;

-- Act as Alice.
set local role authenticated;
set local request.jwt.claims = '{"sub":"11111111-1111-1111-1111-111111111111","role":"authenticated"}';

select is(
  (select count(*)::int from public.profiles),
  2,
  'signed-in users can read profiles'
);

select throws_ok(
  $$update public.profiles set username = 'alice'
    where id = '11111111-1111-1111-1111-111111111111'$$,
  '23514',
  null,
  'username needs 13+ confirmation first'
);

select lives_ok(
  $$update public.profiles set username = 'alice', age_confirmed = true
    where id = '11111111-1111-1111-1111-111111111111'$$,
  'user can complete own onboarding'
);

select throws_ok(
  $$update public.profiles set username = 'Bad Name!', age_confirmed = true
    where id = '11111111-1111-1111-1111-111111111111'$$,
  '23514',
  null,
  'username format is enforced'
);

-- Updating Bob's row silently affects 0 rows under RLS.
update public.profiles set bio = 'hacked' where id = '22222222-2222-2222-2222-222222222222';
select is(
  (select bio from public.profiles where id = '22222222-2222-2222-2222-222222222222'),
  null,
  'user cannot update another user''s profile'
);

select throws_ok(
  $$update public.profiles set created_at = now() - interval '1 year'
    where id = '11111111-1111-1111-1111-111111111111'$$,
  '42501',
  null,
  'created_at is not client-writable'
);

select throws_ok(
  $$insert into public.profiles (id) values (gen_random_uuid())$$,
  '42501',
  null,
  'clients cannot insert profiles directly'
);

select throws_ok(
  $$delete from public.profiles where id = '11111111-1111-1111-1111-111111111111'$$,
  '42501',
  null,
  'clients cannot delete profiles'
);

select is(public.username_available('ALICE'), false, 'taken username is unavailable (case-insensitive)');
select is(public.username_available('carol'), true, 'free username is available');

select * from finish();
rollback;
