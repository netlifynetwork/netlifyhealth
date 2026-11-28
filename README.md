# Netlify Health

A Flutter application targeting Android, iOS/iPadOS, Windows, macOS and Linux. The interface follows the supplied blue-violet gradient / lime-accent design reference. The supplied app mark is stored under `assets/branding/`.

## Current architecture

- Flutter shared UI and application logic.
- Supabase Auth + Postgres for accounts and cloud data.
- Row Level Security on all user-owned tables.
- Local preferences for non-sensitive UI preferences and offline-friendly state.
- Curated nutrition entries are estimates; verify packaged-food labels for exact values.

## Required cloud setup

1. Create a Supabase project in your organization.
2. In the SQL Editor, run `supabase/migrations/20261128000000_initial_schema.sql`.
3. In Authentication settings, enable email/password sign-in and configure your redirect / email confirmation policy.
4. Supply the project URL and publishable key at build time. Never put a service-role or secret key in the client.

Example:

```bash
flutter run \
  --dart-define=SUPABASE_URL=https://YOUR_PROJECT_REF.supabase.co \
  --dart-define=SUPABASE_PUBLISHABLE_KEY=sb_publishable_YOUR_KEY
```

The app intentionally shows a configuration screen until valid Supabase settings are supplied; it does not silently create fake accounts or pretend cloud sync is active.

## Generate platform runners

Install the current stable Flutter SDK, then from this directory:

```bash
flutter create . --platforms=android,ios,windows,macos,linux --project-name netlify_health
python -c "import base64,pathlib; p=pathlib.Path('assets/branding'); (p/'app_icon.jpg').write_bytes(base64.b64decode((p/'app_icon.jpg.b64').read_text()))"
flutter pub get
dart run flutter_launcher_icons
flutter analyze
flutter test
flutter run --dart-define=SUPABASE_URL=... --dart-define=SUPABASE_PUBLISHABLE_KEY=...
```

## Release builds

```bash
flutter build apk --release
flutter build appbundle --release
flutter build ios --release --no-codesign
flutter build windows --release
flutter build macos --release
flutter build linux --release
```

iOS/iPadOS and macOS builds require macOS with Xcode. App Store distribution additionally requires Apple signing and an Apple Developer account. Windows builds require Windows + Visual Studio with the Desktop development with C++ workload. Linux builds require the Flutter Linux desktop prerequisites. Android release distribution should be signed with a private keystore; keep signing secrets in GitHub Actions secrets, never in git.

## CI

GitHub Actions runs formatting, analysis and tests, then builds Android, Linux, Windows, iOS and macOS artifacts on the matching hosted runners. iOS CI is an unsigned build and is not an App Store-ready IPA. Artifacts are available from the Actions run after jobs succeed.

## Nutrition and health data

Food nutrition numbers shown in the curated catalogue are estimates per stated serving, not medical advice or laboratory measurements. The app does not diagnose, treat, or replace a clinician or dietitian. Device steps and wearable integrations require platform permissions and an integration provider; they are not fabricated when unavailable.

## Privacy

Personal records are stored under the authenticated user's ID and protected by Postgres RLS. Configure Supabase retention, backups, email delivery and privacy disclosures before public release.
