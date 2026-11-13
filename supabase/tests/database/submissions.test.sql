-- Phase 3: submissions + badges RLS tests.
begin;
create extension if not exists pgtap with schema extensions;
select plan(20);

delete from public.challenges;
insert into public.challenges (id, title, description, category, opens_at, closes_at) values
  ('aaaaaaaa-0000-0000-0000-000000000001', 'Past quest', 'd', 'baking',
     now() - interval '14 days', now() - interval '7 days'),
  ('aaaaaaaa-0000-0000-0000-000000000004', 'Just closed', 'd', 'music',
     now() - interval '7 days', now() - interval '30 minutes'),
  ('aaaaaaaa-0000-0000-0000-000000000002', 'Current quest', 'd', 'poetry',
     now() - interval '30 minutes', now() + interval '7 days');
-- "Just closed" ended 30 min ago: inside the 1-hour upload grace period.

insert into auth.users (id, email) values
  ('11111111-1111-1111-1111-111111111111', 'alice@test.dev'),
  ('22222222-2222-2222-2222-222222222222', 'bob@test.dev'),
  ('33333333-3333-3333-3333-333333333333', 'carol@test.dev');

-- Alice accepted current + just-closed; Bob declined current; Carol accepted current.
insert into public.participations (user_id, challenge_id, status) values
  ('11111111-1111-1111-1111-111111111111', 'aaaaaaaa-0000-0000-0000-000000000002', 'accepted'),
  ('22222222-2222-2222-2222-222222222222', 'aaaaaaaa-0000-0000-0000-000000000002', 'declined'),
  ('33333333-3333-3333-3333-333333333333', 'aaaaaaaa-0000-0000-0000-000000000002', 'accepted');
insert into public.participations (user_id, challenge_id, status, responded_at) values
  ('11111111-1111-1111-1111-111111111111', 'aaaaaaaa-0000-0000-0000-000000000004', 'accepted', now());

-- Carol posts a private entry, as the owner (bypasses RLS) to set up state.
insert into public.submissions (user_id, challenge_id, media_type, body, visibility) values
  ('33333333-3333-3333-3333-333333333333', 'aaaaaaaa-0000-0000-0000-000000000002', 'text', 'secret poem', 'private');

set local role authenticated;
set local request.jwt.claims = '{"sub":"11111111-1111-1111-1111-111111111111","role":"authenticated"}';

select lives_ok(
  $$insert into public.submissions (user_id, challenge_id, media_type, media_key, thumb_key, caption)
    values ('11111111-1111-1111-1111-111111111111', 'aaaaaaaa-0000-0000-0000-000000000002', 'video',
            'submissions/aaaaaaaa-0000-0000-0000-000000000002/11111111-1111-1111-1111-111111111111/x.mp4',
            'submissions/aaaaaaaa-0000-0000-0000-000000000002/11111111-1111-1111-1111-111111111111/x.jpg',
            'my bake')$$,
  'can post a video to an accepted, open challenge'
);
select is(
  (select count(*)::int from public.badges
    where user_id = '11111111-1111-1111-1111-111111111111'
      and challenge_id = 'aaaaaaaa-0000-0000-0000-000000000002'),
  1,
  'posting awards the week''s badge'
);
select throws_ok(
  $$insert into public.submissions (user_id, challenge_id, media_type, body)
    values ('11111111-1111-1111-1111-111111111111', 'aaaaaaaa-0000-0000-0000-000000000002', 'text', 'again')$$,
  '23505', null,
  'only one entry per challenge'
);
select lives_ok(
  $$insert into public.submissions (user_id, challenge_id, media_type, body)
    values ('11111111-1111-1111-1111-111111111111', 'aaaaaaaa-0000-0000-0000-000000000004', 'text', 'just made it')$$,
  'can still post during the 1-hour grace period'
);
select is(
  (select count(*)::int from public.badges where user_id = '11111111-1111-1111-1111-111111111111'),
  2,
  'grace-period entries still earn the badge'
);
select throws_ok(
  $$insert into public.submissions (user_id, challenge_id, media_type, body)
    values ('11111111-1111-1111-1111-111111111111', 'aaaaaaaa-0000-0000-0000-000000000001', 'text', 'late')$$,
  '42501', null,
  'cannot post after the deadline + grace'
);
select throws_ok(
  $$insert into public.badges (user_id, challenge_id)
    values ('11111111-1111-1111-1111-111111111111', 'aaaaaaaa-0000-0000-0000-000000000001')$$,
  '42501', null,
  'users cannot award themselves badges'
);
select throws_ok(
  $$update public.participations set status = 'declined'
    where user_id = '11111111-1111-1111-1111-111111111111'
      and challenge_id = 'aaaaaaaa-0000-0000-0000-000000000002'$$,
  '42501', null,
  'cannot decline after posting an entry'
);
select throws_ok(
  $$update public.submissions set like_count = 999
    where user_id = '11111111-1111-1111-1111-111111111111'$$,
  '42501', null,
  'like_count is not client-writable'
);
select lives_ok(
  $$update public.submissions set caption = 'edited', visibility = 'friends'
    where user_id = '11111111-1111-1111-1111-111111111111'
      and challenge_id = 'aaaaaaaa-0000-0000-0000-000000000002'$$,
  'can edit own caption and visibility'
);
select is_empty(
  $$select body from public.submissions where user_id = '33333333-3333-3333-3333-333333333333'$$,
  'cannot see another user''s private entry'
);

-- Act as Bob (declined the current challenge).
set local request.jwt.claims = '{"sub":"22222222-2222-2222-2222-222222222222","role":"authenticated"}';
select throws_ok(
  $$insert into public.submissions (user_id, challenge_id, media_type, body)
    values ('22222222-2222-2222-2222-222222222222', 'aaaaaaaa-0000-0000-0000-000000000002', 'text', 'hi')$$,
  '42501', null,
  'cannot post without accepting'
);
select throws_ok(
  $$insert into public.submissions (user_id, challenge_id, media_type, body)
    values ('11111111-1111-1111-1111-111111111111', 'aaaaaaaa-0000-0000-0000-000000000004', 'text', 'impersonate')$$,
  '42501', null,
  'cannot post as someone else'
);
select is(
  (select count(*)::int from public.submissions),
  1,
  'sees only the public entry (Alice''s grace-period text), not private or friends-only'
);

-- Bob accepts, then tries to attach Alice's file.
update public.participations set status = 'accepted'
  where user_id = '22222222-2222-2222-2222-222222222222';
select throws_ok(
  $$insert into public.submissions (user_id, challenge_id, media_type, media_key)
    values ('22222222-2222-2222-2222-222222222222', 'aaaaaaaa-0000-0000-0000-000000000002', 'video',
            'submissions/aaaaaaaa-0000-0000-0000-000000000002/11111111-1111-1111-1111-111111111111/x.mp4')$$,
  '42501', null,
  'cannot attach a file uploaded under another user''s key'
);
select throws_ok(
  $$insert into public.submissions (user_id, challenge_id, media_type)
    values ('22222222-2222-2222-2222-222222222222', 'aaaaaaaa-0000-0000-0000-000000000002', 'video')$$,
  '23514', null,
  'a video entry needs a media key'
);
select throws_ok(
  $$insert into public.submissions (user_id, challenge_id, media_type, body)
    values ('22222222-2222-2222-2222-222222222222', 'aaaaaaaa-0000-0000-0000-000000000002', 'text', '   ')$$,
  '23514', null,
  'a text entry needs a non-blank body'
);
select is(
  public.can_submit('33333333-3333-3333-3333-333333333333', 'aaaaaaaa-0000-0000-0000-000000000002'),
  false,
  'can_submit does not reveal whether another user accepted'
);
select lives_ok(
  $$insert into public.submissions (user_id, challenge_id, media_type, media_key)
    values ('22222222-2222-2222-2222-222222222222', 'aaaaaaaa-0000-0000-0000-000000000002', 'image',
            'submissions/aaaaaaaa-0000-0000-0000-000000000002/22222222-2222-2222-2222-222222222222/p.jpg')$$,
  'can post a photo under own key'
);

reset role;
set local role anon;
select throws_ok('select * from public.submissions', '42501', null,
  'anon cannot read submissions');

select * from finish();
rollback;
