# Questly — agent rules

Questly: Weekly Challenge is a university project app. **`docs/PLAN.md` is the source of truth** for stack, schema, video pipeline, phases and acceptance criteria. Read it before changing anything.

## Stack (do not substitute)

- **App:** Flutter 3 + Dart, Riverpod (`flutter_riverpod`), `go_router`, `freezed` + `json_serializable`
- **Backend:** Supabase — Auth, Postgres + RLS, Edge Functions (TypeScript/Deno)
- **Media:** Cloudflare R2 via presigned URLs from Edge Functions
- **CI/CD:** GitHub Actions; web on GitHub Pages; Android APK on GitHub Releases

## Layout

```
app/                    Flutter project
  lib/main.dart
  lib/core/             env config, theme, router, Supabase client
  lib/features/<name>/  auth, challenge, upload, feed, profile, social, admin
    data/               repositories (Supabase + R2 calls)
    domain/             models (freezed + json_serializable)
    presentation/       screens, widgets, Riverpod providers
  test/
supabase/
  migrations/           all schema changes, as SQL
  functions/            Edge Functions
  seed.sql
.github/workflows/      CI and deploys
docs/PLAN.md
```

## Commands

Run from `app/`:

```sh
flutter pub get
flutter analyze                      # must be zero issues
flutter test
dart run build_runner build -d       # regenerate freezed/json code
flutter run -d chrome --web-port 3000 --dart-define-from-file=../.env.json
```

From the repo root:

```sh
npx supabase start                   # local backend (needs Docker)
npx supabase db reset                # re-apply migrations + seed.sql
npx supabase status                  # local URL + anon key
npx supabase test db                 # pgTAP tests in supabase/tests
```

## Config

The app reads `SUPABASE_URL` and `SUPABASE_ANON_KEY` via `--dart-define` (see `app/lib/core/env.dart`). Local values go in `.env.json` at the repo root (git-ignored; copy `.env.example.json`). The app must run without them, showing an offline placeholder instead of crashing.

Run the web app on port 3000 (`--web-port 3000`): Supabase auth only redirects to URLs listed in `supabase/config.toml`.

## Architecture conventions

- Widgets never touch `Supabase.instance`. Each feature has a repository interface in `data/` with a `Supabase…Repository` implementation, exposed via a Riverpod provider. Tests override those providers with fakes (`app/test/fakes.dart`).
- Routing: `app/lib/core/router.dart`. `authRedirect` sends users to sign-in → onboarding (until `profiles.username` is set) → home.
- Database tests: `supabase/tests/database/*.test.sql` (pgTAP), run with `npx supabase test db`.
- Generated files (`*.g.dart`, `*.freezed.dart`) are committed. Re-run build_runner after changing a model.

## Google sign-in (manual setup)

1. Google Cloud Console → APIs & Services → Credentials → create an OAuth client ID (Web application).
2. Authorised redirect URI: `http://127.0.0.1:54321/auth/v1/callback` (local) and `https://<project-ref>.supabase.co/auth/v1/callback` (hosted).
3. Local: put `SUPABASE_AUTH_EXTERNAL_GOOGLE_CLIENT_ID` / `SUPABASE_AUTH_EXTERNAL_GOOGLE_SECRET` in `supabase/.env` (git-ignored), set `enabled = true` under `[auth.external.google]` in `supabase/config.toml`, restart Supabase. Hosted: Supabase dashboard → Authentication → Providers → Google.
4. Build the app with `"GOOGLE_SIGN_IN": true` in `.env.json` to show the button.

## Rules

- Work **one phase at a time, in order** (phases in `docs/PLAN.md`). Don't start a phase until the previous phase's "done when" passes.
- All schema changes go in `supabase/migrations/` as SQL. **Every table has RLS.** Write a test for every visibility rule.
- **Never** put service keys or R2 credentials in the Flutter app or the repo. They belong in Edge Function secrets or GitHub Actions secrets. The app ships only the Supabase URL and anon key.
- Stay on free tiers: 60 s / 720p video cap, compress on device.
- Develop against local Supabase (`supabase start`), not the live project.
- End of each phase: run `flutter analyze` and all tests, explain how to run it, list anything the owner must do by hand (accounts, secrets), then stop for review.
- If something in the plan is unclear or impossible, ask instead of guessing.
