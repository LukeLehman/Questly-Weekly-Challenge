# Questly: Weekly Challenge — Build Plan

Nov 13, 2026. Source of truth for stack, schema, video pipeline, phases and acceptance criteria.

## The idea

Questly is buildable for $0 as a university project: Flutter for the app, Supabase for accounts and data, Cloudflare R2 for videos, GitHub for code and the web build.

The loop: a new challenge drops every Monday (bake something, write a poem, learn a trick). Users accept or decline. By Sunday they upload a video or photo, earn that week's badge, and scroll everyone else's entries in a TikTok-style feed with likes and comments.

### Product principles

- The badge is for **completing**, not winning. Keep likes, but streaks and "first try" are the headline.
- Friend circles fix the empty-feed problem: the feed you care about is your circle's.
- Video is the expensive part: cap uploads at 60 seconds and compress on the phone.
- Report, block and hide are in the MVP (app-store requirement).
- Societal issue: boredom, routine fatigue and social disconnection. Impact metrics: weekly completion rate, number of new categories each user tries.

## Stack (do not substitute)

| Layer | Choice | Why |
|---|---|---|
| App | Flutter 3 (Dart), Riverpod, go_router | One codebase for Android, iOS and web |
| Accounts | Supabase Auth (email + Google) | Free up to 50,000 monthly users |
| Database | Supabase Postgres with Row Level Security | Privacy rules enforced in the database |
| Server logic | Supabase Edge Functions (TypeScript) | Signs upload URLs; storage keys never ship in the app |
| Video and image files | Cloudflare R2 | 10 GB free, free egress |
| Web hosting | GitHub Pages via GitHub Actions | Free public link |
| Android | APK attached to GitHub Releases | No Play Store fee |
| Push (optional) | Firebase Cloud Messaging | Only for the Monday ping |

Ship web + Android APK first; iOS only if needed (needs a Mac and a $99/yr developer account).

Not Firebase Storage: requires the Blaze billing plan since 3 Feb 2026. Not Supabase Storage for videos: 1 GB files / ~5 GB egress on free tier.

## Free-tier limits

| Service | Free allowance |
|---|---|
| Supabase | 500 MB DB, 1 GB files, ~5 GB egress/month, 50k MAU, 500k Edge Function calls, 2 projects |
| Cloudflare R2 | 10 GB stored, 1M uploads, 10M reads/month, egress free (~1,250 one-minute clips) |
| GitHub Pages + Actions | Free for public repos |
| FCM | Free |

### Gotchas

- Supabase pauses free projects after 7 days idle → scheduled GitHub Action pings it every few days.
- Compress before upload: 720p, 60 s max, ~1 Mbps (~5–10 MB per clip).
- Delete media for deleted submissions; optionally archive challenges older than 8 weeks.
- Cloudflare may ask for a payment method to enable R2. Fallback: Supabase Storage with ~15 s videos.

## Data model (Supabase Postgres)

Text data in Postgres; only media files in R2. The DB stores the R2 key, never the file. Passwords are handled by Supabase Auth.

| Table | Key columns | Notes |
|---|---|---|
| profiles | id (= auth user id), username, display_name, avatar_key, bio, is_private, created_at | Created by a trigger on sign-up |
| challenges | id, title, description, category, tips, cover_key, opens_at, closes_at | One per week; Mon 00:00 – Sun 23:59 in one app-wide time zone |
| participations | user_id, challenge_id, status (accepted / declined), responded_at | Unique per user + challenge |
| submissions | id, user_id, challenge_id, media_type (video / image / text), media_key, thumb_key, caption, visibility (public / friends / private), like_count, comment_count, is_hidden, created_at | One per user per challenge (MVP) |
| likes | user_id, submission_id, created_at | PK on both; trigger updates like_count |
| comments | id, submission_id, user_id, body, created_at, is_hidden | Max 500 chars |
| friendships | requester_id, addressee_id, status (pending / accepted) | Powers friends visibility and friends feed |
| circles, circle_members | id, name, owner_id, invite_code / circle_id, user_id | Stretch goal |
| badges | user_id, challenge_id, awarded_at | Inserted by trigger when a submission lands before closes_at |
| reports | id, reporter_id, submission_id or comment_id, reason, status | Moderation queue |
| blocks | blocker_id, blocked_id | Blocked users vanish from each other's feeds |

**RLS on every table.** A submission is readable if it's public, or yours, or "friends" and you're an accepted friend — and neither has blocked the other.

Streaks, totals and "categories tried" are SQL views, not stored columns.

## Video pipeline

The phone uploads straight to R2 with a short-lived signed URL; viewers stream straight from R2.

**Upload**
1. Record or pick a clip (image_picker / camera), max 60 s.
2. Compress to 720p MP4 (video_compress on mobile; on web enforce a 25 MB cap, skip compression) and grab a thumbnail.
3. Call the `create-upload-url` Edge Function with challenge id and file type.
4. Function checks: signed in, accepted this challenge, week still open, size under cap. Returns two presigned PUT URLs (video + thumb), valid 10 min, keys `submissions/{challenge_id}/{user_id}/{uuid}.mp4`.
5. App PUTs both files to R2 with a progress bar.
6. App inserts the submissions row; a trigger awards the badge.

**Playback**
1. Feed query returns submission rows (filtered by RLS) with keys.
2. Public media loads from the R2 public URL. Private / friends-only media via the `get-media-url` function (presigned GET, 1 hour) after the same visibility check.
3. Vertical PageView with video_player: play visible, preload next, dispose the rest. Thumbnail until ready.
4. Encode MP4 with faststart.

Later, not MVP: HLS via Cloudflare Stream or Mux.

## MVP screens

Bottom nav: This Week, Feed, Upload (centre), Profile.

| Screen | What it does | MVP? |
|---|---|---|
| Onboarding + sign-in | Email or Google, username, public/private account, confirm 13+ | Yes |
| This Week | Challenge card (title, description, tips, countdown), Accept / Decline, your status, friends who accepted | Yes |
| Upload | Record/pick video/photo (or text for poems), preview, caption, visibility picker, progress, success screen with badge animation | Yes |
| Feed | Full-screen vertical scroll of this week's entries; Friends / Everyone tabs; like, comments, share, report | Yes |
| Profile | Avatar, bio, badge grid, streak, categories tried, submissions grid; edit profile; settings | Yes |
| Other user's profile | Public entries, add friend, block, report | Yes |
| Past challenges | Archive of previous weeks | Nice to have |
| Circles | Private group with invite code and leaderboard | Stretch |
| Admin panel | Schedule challenges, review reports, hide content | Yes (web-only, admin role) |

Look and feel: bright, playful, game-like. Quest cards, badges as collectible medals, streaks as a flame counter. Dark mode from the start.

## Weekly cycle

No cron: a challenge's state is derived from now vs `opens_at` / `closes_at`, in one app-wide time zone (config, e.g. Europe/London).

- Admin schedules challenges in advance. Seed 12: baking, poetry, drawing, music, fitness, photography, a magic trick, origami, cooking a new cuisine, a phrase in a new language, a dance, a short story.
- Monday 00:00: the challenge whose window contains now becomes current. Optional push.
- Mon–Sun: accept/decline. Accepting unlocks Upload. Decline can become accept before the deadline.
- Optional Thursday nudge to accepted-but-not-submitted.
- Sunday 23:59: uploads close (Edge Function refuses URLs; RLS refuses inserts after `closes_at`), with a 1-hour grace period for in-flight uploads.
- After close: entries viewable forever under Past challenges.

Streak = consecutive weeks with a submission; one "freeze" per user per month.

## Privacy, safety, moderation

- Per-post visibility: public / friends / private. Private accounts default to friends.
- Report on every submission, comment and profile (inappropriate, harassment, spam, unsafe, other). Three reports auto-hide pending review.
- Block: removes the other person from feeds and comments, both ways.
- Admin web panel: open reports with hide / restore / ban.
- 13+ only, confirmed at sign-up. Challenges safe and doable at home.
- "Delete my account" Edge Function removes profile, rows and R2 files. Privacy policy page.
- Secrets (R2 keys, Supabase service key) only in Edge Function secrets and GitHub Actions secrets. The app ships only the Supabase URL and anon key.
- Rate limits: one submission per user per challenge, 30 comments/hour, file size cap in the Edge Function.

## Repo structure

```
questly/
  CLAUDE.md
  docs/PLAN.md
  app/                        # Flutter project
    lib/
      main.dart
      core/                   # theme, router, env config, Supabase client
      features/
        auth/ challenge/ upload/ feed/ profile/ social/ admin/
          data/               # repositories (Supabase + R2 calls)
          domain/             # models (freezed + json_serializable)
          presentation/       # screens, widgets, Riverpod providers
    test/
  supabase/
    migrations/               # SQL: tables, RLS, triggers, views
    functions/
      create-upload-url/ get-media-url/ delete-account/ keep-alive/
    seed.sql                  # 12 starter challenges + demo users
  .github/workflows/
    ci.yml                    # analyze + test on every PR
    deploy-web.yml            # web → GitHub Pages on push to main
    release-android.yml       # APK → GitHub Release on version tag
    supabase-deploy.yml       # migrations + functions on main
    keep-alive.yml            # scheduled ping
```

Local dev: `supabase start` (Docker). `.env` (git-ignored) for local keys, `--dart-define` for build-time config.

GitHub secrets: SUPABASE_URL, SUPABASE_ANON_KEY, SUPABASE_ACCESS_TOKEN, SUPABASE_DB_PASSWORD, R2_ACCOUNT_ID, R2_ACCESS_KEY_ID, R2_SECRET_ACCESS_KEY, R2_BUCKET, R2_PUBLIC_URL.

Manual (owner only): GitHub repo, Supabase project, Cloudflare account + R2 bucket + API token, pasting secrets.

## Build phases

One phase at a time; don't start a phase until the previous "done when" passes.

| # | Phase | Builds | Done when |
|---|---|---|---|
| 0 | Scaffold | Repo layout, Flutter app, local Supabase, CLAUDE.md, CI (analyze + test) | `flutter run -d chrome` shows a placeholder; CI green |
| 1 | Auth + profiles | Email + Google sign-in, username picker, profiles table + trigger + RLS | New user can sign up, set username, sign out and back in |
| 2 | Challenges | challenges + participations, seed data, This Week screen, accept/decline, countdown | Seeded current challenge shows; accept/decline persists |
| 3 | Upload pipeline | R2 bucket, create-upload-url, compression, thumbnail, progress, submissions, badge trigger | A 60 s clip uploads from Android and web; row and badge appear |
| 4 | Feed | Vertical video feed, preload, Friends / Everyone tabs, get-media-url | 20 entries scroll smoothly; private posts never show to strangers (tested) |
| 5 | Social | Likes, comments, friend requests, other user's profile | Counts update; friends-only posts only to friends |
| 6 | Profile + progress | Badge grid, streak with freezes, categories tried, edit profile | Streak maths unit-tested |
| 7 | Safety + admin | Report, block, auto-hide, admin panel, delete account, privacy policy | Admin can hide a reported post; deletion removes R2 files |
| 8 | Ship + polish | Pages deploy, APK release, keep-alive, empty/error/loading states, dark mode, app icon | Public web link and APK work on a fresh device |

Testing: SQL tests (pgTAP or plain queries) for every visibility rule, widget tests for each screen's main state, `flutter analyze` at zero warnings.

Stretch: Circles, past-challenges archive, push notifications, user-suggested challenges with voting, iOS TestFlight.

## Sources

- Supabase pricing and free tier limits, 2026
- Cloudflare R2 pricing
- Cloud Storage for Firebase: Blaze plan requirement
