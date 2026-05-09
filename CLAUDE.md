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

# Run a single test file
flutter test test/features/edit_past_workout_test.dart

# Run all tests
flutter test

# Lint
flutter analyze
```

## Architecture

**Stack:** Flutter + Drift (SQLite ORM) + Riverpod + Supabase

**Layer ordering (strict — never skip):**
```
UI screens → providers (lib/providers/providers.dart)
           → repositories (lib/repositories/repositories.dart)
           → AppDatabase (lib/database/app_database.dart)
```
Screens and providers never touch `AppDatabase` directly.

**Screens (lib/screens/):**
- `app_shell.dart` — root shell: bottom nav (Home / Exercises / Routines / History / Settings), auth gate, crash-resume dialog
- `auth/` — Supabase Google OAuth (redirect on web, native plugin on mobile)
- `exercises/` — exercise list, picker sheet, create form (`showCreateExerciseSheet(context, ref)`)
- `routines/` — routine list and editor (draft-based creation)
- `workout/` — `active_workout_screen.dart` (gym mode) + `minimized_workout_bar.dart` (floating dock)
- `history/` — workout history list and detail view

**State management rules:**
- `StatefulWidget` is only for local UI state (animations, scroll controllers). Shared data → Riverpod.
- Stream providers (`exercisesProvider`, `routinesProvider`, `workoutsProvider`) are backed by Drift `.watch()` — they auto-update on any DB write.
- `activeWorkoutIdProvider` is a **derived** `Provider<int?>` — it reads `incompleteWorkoutProvider` (watches for `endTime IS NULL`). Never write to it; starting/finishing a workout updates the DB and the provider follows.
- `sharedPreferencesProvider` must be overridden in `ProviderScope` at startup and in tests.

**Code generation:** Drift and Riverpod both use `build_runner`. After changing `lib/models/tables.dart` or any `@riverpod`-annotated code, run `dart run build_runner build -d` to regenerate `*.g.dart` files.

**Schema changes:**
1. Edit table definitions in `lib/models/tables.dart`
2. Increment `schemaVersion` in `lib/database/app_database.dart` and add a migration block in `onUpgrade`
3. Run code generation

**Sync-ready columns:** Every Drift table has `clientId` (UUID), `lastModifiedAt`, `syncStatus` (0=synced, 1=pending, 2=conflict), and `isDeleted` (soft delete). All mutations go through repositories, which call `SyncService` immediately after writing locally. `syncAll()` retries pending records.

**Key domain types (lib/models/tables.dart):**
- `ExerciseCategories`, `EquipmentTypes` — static string constants for category/equipment values
- `SetType` — int constants (0=Normal, 1=Warmup, 2=DropSet, 3=Failure) with a `label()` helper
- Tables: `Exercises`, `Routines`, `RoutineExercises`, `WorkoutExercises`, `Workouts`, `LoggedSets`
- `RoutineExercises.isDraft` — `true` while user is building a routine; drafts are excluded from the routines list and never pushed to sync until `RoutineRepository.commitDraft()` is called

**Exercise filtering:**
- Global exercises: pre-seeded, `isCustom=false`, cannot be deleted
- Personal exercises: user-created, `isCustom=true`, can be soft-deleted
- `filteredExercisesProvider` driven by `exerciseFilterModeProvider` for list screens
- `ExercisePickerSheet` uses its own local filter state to avoid side effects

**Notifications:** `NotificationService` is abstract. `LocalNotificationService` schedules a 90-minute overdue alert when a workout starts; `NullNotificationService` is the no-op used in tests. Override `notificationServiceProvider` in tests.

**Weight units:** Global toggle `useLbsProvider` (SharedPreferences). Per-exercise override via `RoutineExercises.useLbs` / `WorkoutExercises.useLbs` (nullable: `null` = follow global).

**Auth:** `AppShell` listens to `isAuthenticatedProvider`; unauthenticated users see `AuthScreen`. Supabase credentials come from `.env` (not committed).

## Testing

Tests use `NativeDatabase.memory()` for Drift, `mocktail` for mocks, and `pumpApp` from `test/helpers/pump_app.dart` for widget tests.

```dart
// DB test setup
db = AppDatabase(NativeDatabase.memory());

// Widget test — automatically overrides sharedPreferencesProvider
await tester.pumpApp(MyWidget(), overrides: [
  workoutRepositoryProvider.overrideWithValue(mockRepo),
]);

// Fake sync service (avoids real Supabase calls)
class FakeSyncService extends SyncService {
  FakeSyncService(super.db);
  @override Future<bool> pushExercise(Exercise e) async => true;
  // ... override all push* methods and syncAll()
}
```

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
