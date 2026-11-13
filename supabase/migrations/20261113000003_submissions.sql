-- Phase 3: submissions + badges
-- Media files live in R2; rows hold only their keys. Keys are issued by the
-- create-upload-url Edge Function as submissions/{challenge_id}/{user_id}/{uuid}.ext
-- and RLS checks that prefix, so nobody can attach someone else's file.

create table public.submissions (
  id            uuid primary key default gen_random_uuid(),
  user_id       uuid not null references public.profiles (id) on delete cascade,
  challenge_id  uuid not null references public.challenges (id) on delete cascade,
  media_type    text not null check (media_type in ('video', 'image', 'text')),
  media_key     text,
  thumb_key     text,
  body          text check (char_length(body) <= 2000),
  caption       text check (char_length(caption) <= 300),
  visibility    text not null default 'public'
                  check (visibility in ('public', 'friends', 'private')),
  like_count    integer not null default 0,
  comment_count integer not null default 0,
  is_hidden     boolean not null default false,
  created_at    timestamptz not null default now(),

  -- One entry per user per challenge (MVP).
  constraint one_submission_per_challenge unique (user_id, challenge_id),
  -- Video/image entries need a file; text entries (poems, stories) need a body.
  constraint media_matches_type check (
    (media_type in ('video', 'image') and media_key is not null)
    or (media_type = 'text' and media_key is null and thumb_key is null
        and char_length(trim(body)) > 0)
  )
);

create index submissions_challenge_feed_idx
  on public.submissions (challenge_id, created_at desc);

-- How long after closes_at an in-flight upload may still be saved.
create function public.upload_grace()
returns interval
language sql
immutable
as $$ select interval '1 hour' $$;

-- True if the user may post an entry to this challenge right now:
-- accepted it, and the window (plus grace) is still open.
-- Only answers for the caller (uid must be auth.uid()), so it can't be used
-- to find out whether someone else accepted.
create function public.can_submit(uid uuid, cid uuid)
returns boolean
language sql
stable
security definer
set search_path = ''
as $$
  select uid = (select auth.uid()) and exists (
    select 1
    from public.challenges c
    join public.participations p
      on p.challenge_id = c.id and p.user_id = uid and p.status = 'accepted'
    where c.id = cid
      and c.opens_at <= now()
      and now() < c.closes_at + public.upload_grace()
  );
$$;

revoke all on function public.can_submit(uuid, uuid) from public, anon;
grant execute on function public.can_submit(uuid, uuid) to authenticated, service_role;

alter table public.submissions enable row level security;

-- Phase 3: you see your own entries, and public non-hidden ones.
-- Friends-only visibility and blocks arrive in Phases 5 and 7.
create policy "own or public submissions are readable"
  on public.submissions for select
  to authenticated
  using (
    (select auth.uid()) = user_id
    or (visibility = 'public' and not is_hidden)
  );

create policy "users post to challenges they accepted"
  on public.submissions for insert
  to authenticated
  with check (
    (select auth.uid()) = user_id
    and public.can_submit(user_id, challenge_id)
    and (media_key is null
         or media_key like 'submissions/' || challenge_id || '/' || user_id || '/%')
    and (thumb_key is null
         or thumb_key like 'submissions/' || challenge_id || '/' || user_id || '/%')
  );

create policy "users edit own caption and visibility"
  on public.submissions for update
  to authenticated
  using ((select auth.uid()) = user_id)
  with check ((select auth.uid()) = user_id);

-- Deleting needs R2 cleanup, so it goes through an Edge Function (Phase 7).

revoke all on public.submissions from anon, authenticated;
grant select on public.submissions to authenticated;
grant insert (user_id, challenge_id, media_type, media_key, thumb_key, body, caption, visibility)
  on public.submissions to authenticated;
grant update (caption, visibility) on public.submissions to authenticated;


-- Badges: one per completed challenge, awarded by trigger.
create table public.badges (
  user_id      uuid not null references public.profiles (id) on delete cascade,
  challenge_id uuid not null references public.challenges (id) on delete cascade,
  awarded_at   timestamptz not null default now(),
  primary key (user_id, challenge_id)
);

alter table public.badges enable row level security;

create policy "badges are visible to signed-in users"
  on public.badges for select
  to authenticated
  using (true);

revoke all on public.badges from anon, authenticated;
grant select on public.badges to authenticated;

-- Award the badge when an entry lands inside the window (+ grace, so an
-- upload that started before the deadline still counts).
create function public.award_badge()
returns trigger
language plpgsql
security definer
set search_path = ''
as $$
begin
  insert into public.badges (user_id, challenge_id)
  select new.user_id, new.challenge_id
  from public.challenges c
  where c.id = new.challenge_id
    and new.created_at < c.closes_at + public.upload_grace()
  on conflict do nothing;
  return new;
end;
$$;

create trigger submissions_award_badge
  after insert on public.submissions
  for each row execute function public.award_badge();


-- Once you've posted an entry you can't switch to "declined".
drop policy "users change response while open" on public.participations;

create policy "users change response while open"
  on public.participations for update
  to authenticated
  using ((select auth.uid()) = user_id)
  with check (
    (select auth.uid()) = user_id
    and public.challenge_is_open(challenge_id)
    and (
      status = 'accepted'
      or not exists (
        select 1 from public.submissions s
        where s.user_id = participations.user_id
          and s.challenge_id = participations.challenge_id
      )
    )
  );
