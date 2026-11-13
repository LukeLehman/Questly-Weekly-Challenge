-- Phase 2: weekly challenges + participations
-- A challenge's state comes from comparing now() with its window; no cron.
-- Windows are half-open: [opens_at, closes_at). Seeds use Monday 00:00 to the
-- next Monday 00:00 in the app-wide time zone (Europe/London).

create table public.challenges (
  id          uuid primary key default gen_random_uuid(),
  title       text not null check (char_length(title) between 3 and 80),
  description text not null check (char_length(description) <= 1000),
  category    text not null check (category in (
                'baking', 'poetry', 'drawing', 'music', 'fitness',
                'photography', 'magic', 'origami', 'cooking', 'language',
                'dance', 'writing', 'other')),
  tips        text[] not null default '{}',
  cover_key   text,
  opens_at    timestamptz not null,
  closes_at   timestamptz not null,
  created_at  timestamptz not null default now(),

  constraint window_order check (closes_at > opens_at),
  -- Only one challenge can be live at any moment.
  constraint no_overlapping_windows
    exclude using gist (tstzrange(opens_at, closes_at) with &&)
);

create index challenges_opens_at_idx on public.challenges (opens_at);

alter table public.challenges enable row level security;

-- Signed-in users see current and past challenges; future ones stay secret.
-- Writes come from the admin panel (Phase 7); no client write policies yet.
create policy "challenges visible once opened"
  on public.challenges for select
  to authenticated
  using (opens_at <= now());

revoke all on public.challenges from anon, authenticated;
grant select on public.challenges to authenticated;

-- The challenge whose window contains now (uses the server clock).
create function public.current_challenge()
returns setof public.challenges
language sql
stable
set search_path = ''
as $$
  select * from public.challenges
  where opens_at <= now() and closes_at > now()
  limit 1;
$$;

revoke all on function public.current_challenge() from public, anon;
grant execute on function public.current_challenge() to authenticated;


create table public.participations (
  user_id      uuid not null references public.profiles (id) on delete cascade,
  challenge_id uuid not null references public.challenges (id) on delete cascade,
  status       text not null check (status in ('accepted', 'declined')),
  responded_at timestamptz not null default now(),
  primary key (user_id, challenge_id)
);

create index participations_challenge_idx
  on public.participations (challenge_id, status);

-- responded_at is always the server time of the latest response.
create function public.touch_responded_at()
returns trigger
language plpgsql
set search_path = ''
as $$
begin
  new.responded_at := now();
  return new;
end;
$$;

create trigger participations_touch
  before insert or update on public.participations
  for each row execute function public.touch_responded_at();

-- True while the challenge is accepting responses.
create function public.challenge_is_open(cid uuid)
returns boolean
language sql
stable
security definer
set search_path = ''
as $$
  select exists (
    select 1 from public.challenges
    where id = cid and opens_at <= now() and closes_at > now()
  );
$$;

revoke all on function public.challenge_is_open(uuid) from public, anon;
grant execute on function public.challenge_is_open(uuid) to authenticated;

alter table public.participations enable row level security;

-- Your own responses only. (Friends' responses arrive with friendships in Phase 5.)
create policy "users read own participations"
  on public.participations for select
  to authenticated
  using ((select auth.uid()) = user_id);

create policy "users respond to open challenges"
  on public.participations for insert
  to authenticated
  with check (
    (select auth.uid()) = user_id
    and public.challenge_is_open(challenge_id)
  );

create policy "users change response while open"
  on public.participations for update
  to authenticated
  using ((select auth.uid()) = user_id)
  with check (
    (select auth.uid()) = user_id
    and public.challenge_is_open(challenge_id)
  );

revoke all on public.participations from anon, authenticated;
grant select on public.participations to authenticated;
grant insert (user_id, challenge_id, status) on public.participations to authenticated;
grant update (status) on public.participations to authenticated;

-- How many people accepted a challenge (social proof on This Week),
-- without exposing who.
create function public.challenge_accepted_count(cid uuid)
returns integer
language sql
stable
security definer
set search_path = ''
as $$
  select count(*)::int from public.participations
  where challenge_id = cid and status = 'accepted';
$$;

revoke all on function public.challenge_accepted_count(uuid) from public, anon;
grant execute on function public.challenge_accepted_count(uuid) to authenticated;
