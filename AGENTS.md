# AGENTS.md

Agent-specific guidance for this repository. Complements CLAUDE.md — read both.

## Stack at a Glance

- **Flutter** (Dart) — cross-platform (iOS / Android / Web)
- **Drift** — type-safe SQLite ORM; schema in `lib/models/tables.dart`, queries in `lib/database/app_database.dart`
- **Riverpod** — state management; all providers in `lib/providers/providers.dart`
- **Supabase** — auth + cloud sync; sync logic in `lib/services/sync_service.dart`
- **`build_runner`** — code generation for Drift and Riverpod; run after any schema or `@riverpod` change

## Layer Contract

```
UI screens
  └─ Riverpod providers  (lib/providers/providers.dart)
       └─ Repositories   (lib/repositories/repositories.dart)
            └─ AppDatabase  (lib/database/app_database.dart)
```

**Never cross layers.** Screens never call `AppDatabase` directly; providers never call `AppDatabase` directly. Repositories are the only callers of `AppDatabase` methods.

## Key Invariants for Agents

### Active Workout
- `activeWorkoutIdProvider` is **derived**, not settable. It reads `incompleteWorkoutProvider` which watches for `Workouts` rows where `endTime IS NULL`.
- To start a workout: `WorkoutRepository.start({routineId})`. To finish: `WorkoutRepository.finish(id)`.
- On app launch, `AppShell` checks `incompleteWorkoutProvider` and prompts resume-or-discard.

### Routine Drafts
- New routines start as drafts (`isDraft = true`). Drafts are never pushed to Supabase sync.
- Call `RoutineRepository.commitDraft(id)` to promote a draft to a real routine and trigger sync.
- Call `RoutineRepository.discardDraft(id)` to soft-delete a draft without syncing.

### Soft Deletes
- No row is ever hard-deleted. Use `isDeleted = true` via the appropriate repository method.
- All `AppDatabase` read queries filter `WHERE isDeleted = false` already.
- Sync service replicates `isDeleted = true` to Supabase to propagate deletions.

### Weight Units
- Global unit preference: `useLbsProvider` (SharedPreferences-backed).
- Per-exercise override: `RoutineExercises.useLbs` / `WorkoutExercises.useLbs` (nullable).
- `null` = follow global/routine preference; `true` = lbs; `false` = kg.

### Exercise Permissions
- Global exercises (`isCustom = false`): pre-seeded, cannot be deleted.
- Custom exercises (`isCustom = true`): user-created, can be soft-deleted.

## Schema Changes — Required Steps

1. Edit `lib/models/tables.dart`
2. Increment `schemaVersion` in `lib/database/app_database.dart`
3. Add a migration block in the `onUpgrade` callback (pattern: `if (from < N) { ... }`)
4. `dart run build_runner build -d`

Schema is currently at **version 6**.

## Testing Patterns

```dart
// In-memory DB for fast unit/integration tests
db = AppDatabase(NativeDatabase.memory());

// Widget test wrapper (handles sharedPreferencesProvider override)
await tester.pumpApp(MyWidget(), overrides: [
  someProvider.overrideWithValue(mockValue),
]);

// Fake SyncService — avoids real Supabase calls in tests
class FakeSyncService extends SyncService {
  FakeSyncService(super.db);
  @override Future<bool> pushExercise(Exercise e) async => true;
  @override Future<bool> pushRoutine(Routine r) async => true;
  @override Future<bool> pushRoutineExercise(RoutineExerciseEntry re) async => true;
  @override Future<bool> pushWorkout(Workout w) async => true;
  @override Future<bool> pushLoggedSet(LoggedSet s) async => true;
  @override Future<void> syncAll() async {}
}
```

Test files live in `test/` organized by type:
- `test/database/` — direct DB layer tests
- `test/repositories/` — repository tests (use real in-memory DB + FakeSyncService)
- `test/providers/` — provider logic tests
- `test/screens/` — widget tests for specific screens
- `test/features/` — feature/integration tests (e.g. edit_past_workout, minimize_workout)
- `test/helpers/pump_app.dart` — shared `pumpApp` WidgetTester extension

Run a single file: `flutter test test/features/edit_past_workout_test.dart`

## Commands

```bash
flutter pub get                        # install deps
dart run build_runner build -d         # codegen (required after schema/provider changes)
flutter test                           # all tests
flutter test <path>                    # single test file
flutter analyze                        # lint
flutter run -d chrome                  # web
flutter run                            # device/emulator
```

## Adding a New Feature — Checklist

1. **Schema change?** → follow the 4-step schema process above
2. **New repository method?** → add to the appropriate class in `lib/repositories/repositories.dart`; call sync immediately after writing locally
3. **New provider?** → add to `lib/providers/providers.dart`; prefer stream providers for data backed by Drift `.watch()`
4. **New screen?** → add under `lib/screens/<feature>/`; register in `AppShell` nav if it's a top-level tab
5. **Shared UI component?** → add to `lib/widgets/`
6. **Reusable bottom sheet?** → export a `showXxxSheet(context, ref)` function (see `exercise_create_form.dart` as the pattern)

## UI & Theming Conventions

- Dark theme by default; colors defined in `lib/theme/app_theme.dart` (`AppColors`)
- Primary accent: `AppColors.primary` = electric green/teal (`0xFF10B981`)
- Background: `AppColors.surface` = deep navy (`0xFF0F172A`)
- Rounded corners: 16–24 px for cards and bottom sheets
- Gym mode UI (active workout): oversized buttons for use with sweaty hands

## Sync Architecture

Local-first. Every mutation:
1. Writes to Drift immediately
2. Calls the matching `SyncService.push*()` method — returns `bool` (success/fail)
3. On success: `AppDatabase.markSynced(table, id)` sets `syncStatus = 0`
4. On failure: `syncStatus` stays `1` (pending); `syncAll()` retries on next opportunity

`syncAll()` is called automatically on `WorkoutRepository.finish()`. `syncDown()` pulls all user records from Supabase (used on login to restore data on a new device).

Foreign key mapping: local int IDs ↔ remote UUIDs (`clientId`). `SyncService` resolves these when pushing relations.
