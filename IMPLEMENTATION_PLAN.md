# Implementation Plan — Features 7–12

This document describes exactly what to build for each feature, which files change, and in what order to build them.

---

## Feature 7 — Start Workout from Routines

**Goal:** Tap a routine card → workout starts pre-loaded with that routine's exercises.

**No schema change needed.**

### Files to change
| File | Change |
|------|--------|
| `lib/screens/routines/routine_list_screen.dart` | Add a prominent "Start Workout" button to each routine card/detail row. On tap: call `workoutRepo.start(routineId: routine.id)` then push `ActiveWorkoutScreen`. |
| `lib/screens/routines/routine_list_screen.dart` | Guard against starting a workout when one is already active (`activeWorkoutIdProvider != null`): show a dialog asking the user to finish the current workout first. |

### Implementation notes
- The button should be visually distinct (filled, primary colour) so it's the obvious CTA.
- Reuse the same navigation call that `HomeScreen` already uses for "Start Workout" so routing stays consistent.
- Read `activeWorkoutIdProvider` before starting; if non-null, show `AlertDialog` warning.

---

## Feature 8 — Notes per Exercise (Routine Edit + Active Workout)

**Goal:** Every exercise in a routine or active workout has a free-text notes field.

### Schema migration → v4

```
RoutineExercises: add column  notes TEXT NOT NULL DEFAULT ''
New table WorkoutExercises:
  id              INTEGER PRIMARY KEY AUTOINCREMENT
  clientId        TEXT
  workoutId       INTEGER REFERENCES workouts(id)
  exerciseId      INTEGER REFERENCES exercises(id)
  displayOrder    INTEGER DEFAULT 0        ← also used by Feature 10
  notes           TEXT    DEFAULT ''
  lastModifiedAt  DATETIME
  syncStatus      INTEGER DEFAULT 0
  isDeleted       BOOLEAN DEFAULT false
```

### Files to change
| File | Change |
|------|--------|
| `lib/models/tables.dart` | Add `notes` column to `RoutineExercises`. Add new `WorkoutExercises` table class. |
| `lib/database/app_database.dart` | Increment `schemaVersion` to 4. Add migration: `ALTER TABLE routine_exercises ADD COLUMN notes TEXT NOT NULL DEFAULT ''`. `CREATE TABLE workout_exercises (...)`. Add DAOs: `watchWorkoutExercises(workoutId)`, `upsertWorkoutExercise(workoutId, exerciseId, order, notes)`, `updateWorkoutExerciseNotes(id, notes)`, `softDeleteWorkoutExercise(id)`, `reorderWorkoutExercises(workoutId, orderedExerciseIds)`. |
| `lib/repositories/repositories.dart` | `RoutineRepository.addExercise()` — add optional `notes` param. `RoutineRepository.updateExercise()` — add optional `notes` param. `WorkoutRepository`: add `watchWorkoutExercises(workoutId)`, `upsertWorkoutExercise(...)`, `updateWorkoutExerciseNotes(id, notes)`, `reorderWorkoutExercises(workoutId, orderedIds)`. |
| `lib/providers/providers.dart` | Add `workoutExercisesProvider` (StreamProvider.family<int>). |
| `lib/screens/routines/routine_edit_screen.dart` | Below each exercise's sets/reps row add a `TextField` for notes. Wire to `routineRepo.updateExercise(id, notes: value)` on submit. |
| `lib/screens/workout/active_workout_screen.dart` | Below each exercise group header add a collapsible `TextField` for notes. On change, call `workoutRepo.updateWorkoutExerciseNotes(...)`. When a workout starts from a routine, copy `RoutineExerciseEntry.notes` as the initial value when creating `WorkoutExercise` rows. |

### Run after changes
```bash
dart run build_runner build -d
```

---

## Feature 9 — Edit Exercises in Past Workouts

**Goal:** History screen allows editing weight/reps/notes per set in completed workouts.

**No schema change needed** (`updateSet` already exists in `WorkoutRepository`).

### Files to change
| File | Change |
|------|--------|
| `lib/screens/history/history_screen.dart` | Add an edit-mode toggle (pencil icon) per workout card. When active, replace read-only text with `TextFormField` widgets for weight, reps. Add save/cancel buttons per exercise group. On save call `workoutRepo.updateSet(id, weight: w, reps: r)`. Also allow editing per-exercise notes via `workoutRepo.updateWorkoutExerciseNotes(...)`. |

### Implementation notes
- Keep a local `Map<int, bool> _editingWorkouts` in the screen's state.
- Only one workout is editable at a time to avoid complex state.
- Validate numeric inputs before calling update.

---

## Feature 10 — Drag and Rearrange in Active Workout

**Goal:** User can long-press and drag to reorder exercise groups during a session.

**Schema:** Uses `WorkoutExercises.displayOrder` introduced in Feature 8.

### Files to change
| File | Change |
|------|--------|
| `lib/screens/workout/active_workout_screen.dart` | Replace `ListView` with `ReorderableListView`. In `onReorder` callback, call `workoutRepo.reorderWorkoutExercises(workoutId, newOrderedExerciseIds)`. Read exercise order from `workoutExercisesProvider` stream sorted by `displayOrder`. |
| `lib/repositories/repositories.dart` | `reorderWorkoutExercises(workoutId, orderedIds)` — iterate and update `displayOrder` for each `WorkoutExercise` row. Already planned in Feature 8. |

### Implementation notes
- When a new exercise is added mid-workout, append it with `displayOrder = current max + 1`.
- `ReorderableListView` requires each child to have a unique `Key`; use `ValueKey(exerciseId)`.

---

## Feature 11 — Minimize Active Workout (Floating Bar)

**Goal:** User can minimize the active workout to a persistent bottom bar and freely navigate the app.

**No schema change needed.**

### New provider
```dart
// lib/providers/providers.dart
final workoutMinimizedProvider = StateProvider<bool>((ref) => false);
```

### Files to change
| File | Change |
|------|--------|
| `lib/providers/providers.dart` | Add `workoutMinimizedProvider`. |
| `lib/screens/workout/active_workout_screen.dart` | Add a minimize button (chevron-down icon) in the app bar. On tap: `ref.read(workoutMinimizedProvider.notifier).state = true`, then pop the screen. |
| `lib/screens/app_shell.dart` | Wrap the body `Stack` with a `MinimizedWorkoutBar` widget. `MinimizedWorkoutBar` listens to `workoutMinimizedProvider` and `incompleteWorkoutProvider`. When both are true, render a fixed-bottom card showing: exercise count, elapsed time, "Expand" button. Tapping "Expand" sets `workoutMinimizedProvider = false` and pushes `ActiveWorkoutScreen`. |

### New file
`lib/screens/workout/minimized_workout_bar.dart` — stateless widget that takes elapsed duration and exercise count.

### Implementation notes
- The elapsed timer keeps running because the `Stopwatch` lives in the `ActiveWorkoutScreen` state. On re-push, the screen re-reads `workout.startTime` and computes elapsed time from the DB — same resume logic already in place.
- If the workout is finished while minimized, `incompleteWorkoutProvider` emits null and the bar auto-hides.

---

## Feature 12 — Notification at 1.5 Hours

**Goal:** Send a local push notification if the user's workout exceeds 90 minutes.

### New dependency
```yaml
# pubspec.yaml
flutter_local_notifications: ^18.0.0
```

### New file
`lib/services/notification_service.dart`
- `initialize()` — request permissions, set up channels.
- `scheduleWorkoutOverdueAlert(workoutId, startTime)` — schedule a notification at `startTime + 90 min`.
- `cancelWorkoutAlert(workoutId)` — cancel by notification ID (use workoutId as the ID).

### Files to change
| File | Change |
|------|--------|
| `pubspec.yaml` | Add `flutter_local_notifications`. |
| `lib/services/notification_service.dart` | New file (see above). |
| `lib/providers/providers.dart` | Add `notificationServiceProvider`. |
| `lib/repositories/repositories.dart` | `WorkoutRepository.start()` — after inserting, call `notificationService.scheduleWorkoutOverdueAlert(id, startTime)`. `WorkoutRepository.finish()` — call `notificationService.cancelWorkoutAlert(id)`. |
| `android/app/src/main/AndroidManifest.xml` | Add `SCHEDULE_EXACT_ALARM` and `RECEIVE_BOOT_COMPLETED` permissions. |
| `ios/Runner/Info.plist` | No changes needed for local notifications (no remote push required). |

### Implementation notes
- Use `workoutId` as the integer notification ID so cancel is trivial.
- Notification body: "Your workout has been running for 90 minutes. Time to finish up or take a break."
- On iOS, local notifications work without push entitlement.

---

## Build Sequence Summary

| Step | Feature | Prerequisite |
|------|---------|-------------|
| 1 | **#7** Start from routines | None — pure UI |
| 2 | **#8** Exercise notes (schema v4) | Step 1 done, run build_runner |
| 3 | **#9** Edit past workouts | Step 2 (WorkoutExercises table for notes editing) |
| 4 | **#10** Drag to reorder | Step 2 (WorkoutExercises.displayOrder exists) |
| 5 | **#11** Minimize workout | Steps 1–4 (stable workout flow) |
| 6 | **#12** 90-min notification | Step 5 (workout lifecycle is finalized) |

---

## Test Coverage Plan

Each feature has a corresponding test file under `test/features/`:

| Test file | What it covers |
|-----------|---------------|
| `test/features/start_from_routine_test.dart` | Start workout button renders; tapping starts workout with correct routineId; blocks if workout already active |
| `test/features/exercise_notes_test.dart` | Schema migration; RoutineExercises.notes persists; WorkoutExercises CRUD; notes appear in UI |
| `test/features/edit_past_workout_test.dart` | Edit mode toggles; updateSet called with correct args; cancel reverts UI |
| `test/features/workout_reorder_test.dart` | reorderWorkoutExercises updates displayOrder; ReorderableListView order reflects DB |
| `test/features/minimize_workout_test.dart` | Minimize button sets provider; floating bar appears; tap expands; bar hides on workout finish |
| `test/features/workout_notification_test.dart` | Notification scheduled on start; cancelled on finish; rescheduled on discard + restart |
