-- Phase 1: profiles
-- One row per auth user, created by a trigger on sign-up. The user completes
-- onboarding (username + 13+ confirmation) by updating their own row.

create table public.profiles (
  id            uuid primary key references auth.users (id) on delete cascade,
  username      text unique,
  display_name  text,
  avatar_key    text,
  bio           text,
  is_private    boolean not null default false,
  age_confirmed boolean not null default false,
  created_at    timestamptz not null default now(),

  -- lowercase letters, digits, underscore; 3–20 chars
  constraint username_format check (username ~ '^[a-z0-9_]{3,20}$'),
  -- can't claim a username without confirming 13+
  constraint username_requires_age check (username is null or age_confirmed),
  constraint display_name_length check (char_length(display_name) <= 40),
  constraint bio_length check (char_length(bio) <= 160)
);

comment on table public.profiles is
  'Public profile per user. username is null until onboarding is complete.';

-- Create the profile row when a user signs up (email or Google).
create function public.handle_new_user()
returns trigger
language plpgsql
security definer
set search_path = ''
as $$
begin
  insert into public.profiles (id, display_name)
  values (
    new.id,
    left(coalesce(new.raw_user_meta_data ->> 'full_name',
                  new.raw_user_meta_data ->> 'name'), 40)
  );
  return new;
end;
$$;

create trigger on_auth_user_created
  after insert on auth.users
  for each row execute function public.handle_new_user();

-- Row Level Security
alter table public.profiles enable row level security;

-- Signed-in users can see profiles (blocks are added in Phase 7).
create policy "profiles are readable by signed-in users"
  on public.profiles for select
  to authenticated
  using (true);

-- Users can update only their own row.
create policy "users update own profile"
  on public.profiles for update
  to authenticated
  using ((select auth.uid()) = id)
  with check ((select auth.uid()) = id);

-- No insert/delete policies: rows are created by the trigger and removed by
-- the account-deletion function (Phase 7) via cascade.

-- Column-level privileges: id and created_at can never be changed by clients.
revoke all on public.profiles from anon, authenticated;
grant select on public.profiles to authenticated;
grant update (username, display_name, avatar_key, bio, is_private, age_confirmed)
  on public.profiles to authenticated;

-- Username availability without exposing anything else. Works before
-- onboarding is complete; usernames are public anyway.
create function public.username_available(name text)
returns boolean
language sql
stable
security definer
set search_path = ''
as $$
  select not exists (select 1 from public.profiles where username = lower(name));
$$;

revoke all on function public.username_available(text) from public, anon;
grant execute on function public.username_available(text) to authenticated;
