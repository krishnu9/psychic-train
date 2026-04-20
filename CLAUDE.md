# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Commands

```bash
# Install dependencies
flutter pub get

# Code generation (required after schema/provider changes)
dart run build_runner build -d

# Run app
flutter run              # on connected device/emulator
flutter run -d chrome    # web

# Tests
flutter test

# Lint
flutter analyze
```

## Architecture

See `ARCHITECTURE.md` for full context. Summary of what matters for development:

**Stack:** Flutter + Drift (SQLite ORM) + Riverpod + Supabase

**Layer ordering:** UI screens → Riverpod providers (`lib/providers/providers.dart`) → Repositories (`lib/repositories/repositories.dart`) → Drift `AppDatabase` (`lib/database/app_database.dart`). Screens and providers never touch the database directly.

**State management rules:**
- Don't use `StatefulWidget` for data that needs to be shared. Use Riverpod `StateProvider` or `@riverpod` annotations.
- Stream providers (`exercisesProvider`, `routinesProvider`, `workoutsProvider`) are backed by Drift `.watch()` queries — they auto-update on any DB write.
- UI state lives in dedicated small providers (e.g. `useLbsProvider`).
- `activeWorkoutIdProvider` is a **derived** `Provider<int?>` (not a `StateProvider`) — it reads from `incompleteWorkoutProvider` which watches for workouts where `endTime IS NULL`. Never write to it directly; starting or finishing a workout updates the DB and the provider auto-follows.

**Code generation:** Drift and Riverpod both rely on `build_runner`. After any change to `lib/models/tables.dart` or any `@riverpod`-annotated code, run `dart run build_runner build -d` to regenerate `*.g.dart` files.

**Schema changes:**
1. Edit table definitions in `lib/models/tables.dart`
2. Increment `schemaVersion` in `lib/database/app_database.dart` and add a migration in `onUpgrade`
3. Run code generation

**Sync-ready columns:** Every Drift table has `clientId` (UUID), `lastModifiedAt`, `syncStatus` (0=synced, 1=pending, 2=conflict), and `isDeleted` (soft delete). Repositories are the intended injection point for future cloud sync logic — no UI changes needed when implementing sync.

**Active workout persistence:** On app launch, `AppShell` listens to `incompleteWorkoutProvider`. If an incomplete workout is found (e.g. after a crash), it prompts the user to resume or discard. `ActiveWorkoutScreen` restores elapsed time and already-logged sets from the DB on resume.

**Exercise filtering:** Exercises are split into global (seeded, `isCustom=false`) and personal (user-created, `isCustom=true`). Use `filteredExercisesProvider` (driven by `exerciseFilterModeProvider`) in screens that need filtering. `ExercisePickerSheet` uses local state for its filter mode to avoid side effects. Custom exercises can be deleted; global exercises cannot.

**Reusable exercise creation:** `lib/screens/exercises/exercise_create_form.dart` exports `showCreateExerciseSheet(context, ref)` which returns `Future<Exercise?>`. Use this anywhere an exercise needs to be created — it's used in both `ExerciseListScreen` and `ExercisePickerSheet`.

**Auth:** Supabase handles auth. `AppShell` (`lib/screens/app_shell.dart`) gates all screens behind `isAuthenticatedProvider`; unauthenticated users see `AuthScreen`. Google OAuth uses redirect on web and native plugin on mobile.

**Environment:** Supabase credentials are loaded from `.env` via `flutter_dotenv`. This file is not committed to git.

## Graphify

Graphify maps the codebase into a queryable knowledge graph for faster AI-assisted navigation.

**Venv:** `.venv/` in project root (not committed to git).

**One-time setup:**
```bash
python3 -m venv .venv
.venv/bin/pip install graphifyy
.venv/bin/graphify install
```

**Usage in Claude Code:** `/graphify lib/` — builds/updates the graph from the Flutter source.
**Incremental update:** `/graphify lib/ --update` — re-extracts only changed files.
**Graph output:** `graphify-out/graph.html` (open in browser), `graphify-out/GRAPH_REPORT.md`.

## Planned features (PLAN.md)

1. Markdown support for routine descriptions
2. Exercise descriptions
3. ~~Persist active workout across app restarts/refreshes~~ ✓ Done
4. Categories/sections within routine exercises
5. ~~New Exercise Addition option in exercise picker~~ ✓ Done
6. ~~Global vs personal exercise list~~ ✓ Done
