# Multi-Environment Setup (dev / prod)

Plan for splitting the current setup (Supabase via `.env` + Firebase Hosting for web, with `google-services.json` for future Firebase mobile use) into isolated dev and prod environments.

## 1. Supabase — two projects

Create a second Supabase project (`gymapp-dev`) alongside prod. Apply `supabase_schema.sql` to both. Don't try to share one project — RLS policies, migrations, and seed data will collide.

## 2. `.env` per environment

```
.env.dev      # dev Supabase URL + anon key
.env.prod     # prod Supabase URL + anon key
.env          # gitignored; symlink or copy of the active one
```

Better: drop dotenv at runtime and use `--dart-define` so the keys are baked into each build.

```dart
// main.dart
const supabaseUrl = String.fromEnvironment('SUPABASE_URL');
const supabaseAnonKey = String.fromEnvironment('SUPABASE_ANON_KEY');
const flavor = String.fromEnvironment('FLAVOR', defaultValue: 'dev');
```

Run with:

```bash
flutter run --dart-define-from-file=env/dev.json
flutter build web --dart-define-from-file=env/prod.json
```

Where `env/dev.json` and `env/prod.json` hold the keys. Commit `env/*.example.json`, gitignore the real ones. This also kills the `await dotenv.load()` step on startup.

## 3. Firebase Hosting — two sites

In the Firebase console, add a second site (e.g. `gymapp-dev`) to your project. Then:

```bash
firebase target:apply hosting prod gymapp
firebase target:apply hosting dev  gymapp-dev
```

Update `firebase.json` to use targets:

```json
"hosting": [
  { "target": "prod", "public": "build/web", ... },
  { "target": "dev",  "public": "build/web", ... }
]
```

Deploy:

```bash
flutter build web --dart-define-from-file=env/dev.json
firebase deploy --only hosting:dev
```

## 4. Mobile flavors (when adding Firebase mobile SDKs or separate app IDs)

- **Android:** add `productFlavors { dev { applicationIdSuffix ".dev" } prod {} }` in `android/app/build.gradle.kts`, then `flutter run --flavor dev`. Place `google-services.json` under `android/app/src/dev/` and `src/prod/`.
- **iOS:** duplicate the Runner scheme → `Runner-dev` / `Runner-prod`, each with its own bundle ID and `GoogleService-Info.plist`.
- Run `flutterfire configure` once per flavor to generate `firebase_options_dev.dart` / `firebase_options_prod.dart`, and pick based on `FLAVOR`.

## 5. Show the environment in-app

Add a tiny banner in debug builds when `flavor == 'dev'` so you never confuse the two while testing. Stripe the app icon for dev too (makes accidental prod writes much harder).

---

## Minimum viable first step

If moving fast: just do **#1 + #2** (two Supabase projects + `--dart-define-from-file`). That alone gives safe dev/prod isolation for the current feature set. Add #3/#4 only when deploying web or shipping to stores.
