import 'package:drift/drift.dart';
import 'package:uuid/uuid.dart';

import '../models/tables.dart';

part 'app_database.g.dart';

const _uuid = Uuid();

@DriftDatabase(tables: [Exercises, Routines, RoutineExercises, WorkoutExercises, Workouts, LoggedSets])
class AppDatabase extends _$AppDatabase {
  AppDatabase(super.e);

  @override
  int get schemaVersion => 4;

  @override
  MigrationStrategy get migration => MigrationStrategy(
        onCreate: (Migrator m) async {
          await m.createAll();
          await _seedExercises();
        },
        onUpgrade: (Migrator m, int from, int to) async {
          if (from < 2) {
            // Mark all global seeded exercises as pending sync so they push to Supabase
            // and satisfy routine_exercises foreign key constraints.
            await (update(exercises)..where((e) => e.isCustom.equals(false) & e.syncStatus.equals(0))).write(
              const ExercisesCompanion(syncStatus: Value(1)),
            );
          }
          if (from < 3) {
            await m.addColumn(exercises, exercises.description);
            await m.addColumn(routineExercises, routineExercises.sectionName);
          }
          if (from < 4) {
            await m.addColumn(routineExercises, routineExercises.notes);
            await m.createTable(workoutExercises);
          }
        },
      );

  // ─── Exercise DAO ──────────────────────────────────────────────────────────

  Future<List<Exercise>> getAllExercises() =>
      (select(exercises)..where((e) => e.isDeleted.equals(false))).get();

  Stream<List<Exercise>> watchAllExercises() =>
      (select(exercises)..where((e) => e.isDeleted.equals(false))).watch();

  Future<List<Exercise>> searchExercises(String query) => (select(exercises)
        ..where((e) =>
            e.isDeleted.equals(false) &
            e.name.lower().like('%${query.toLowerCase()}%')))
      .get();

  Future<List<Exercise>> getExercisesByCategory(String category) =>
      (select(exercises)
            ..where((e) =>
                e.isDeleted.equals(false) & e.category.equals(category)))
          .get();

  Future<Exercise?> getExerciseById(int id) =>
      (select(exercises)..where((e) => e.id.equals(id))).getSingleOrNull();

  Future<int> insertExercise(ExercisesCompanion entry) => into(exercises).insert(
        entry.copyWith(
          clientId: Value(_uuid.v4()),
          lastModifiedAt: Value(DateTime.now()),
          syncStatus: const Value(1), // pending
        ),
      );

  Future<bool> updateExercise(ExercisesCompanion entry) =>
      (update(exercises)..where((e) => e.id.equals(entry.id.value))).write(
        entry.copyWith(
          lastModifiedAt: Value(DateTime.now()),
          syncStatus: const Value(1),
        ),
      ).then((rows) => rows > 0);

  Future<void> softDeleteExercise(int id) =>
      (update(exercises)..where((e) => e.id.equals(id))).write(
        ExercisesCompanion(
          isDeleted: const Value(true),
          lastModifiedAt: Value(DateTime.now()),
          syncStatus: const Value(1),
        ),
      );

  Future<void> upsertExercisesFromRemote(List<ExercisesCompanion> remotes) async {
    for (final remote in remotes) {
      var existing = await (select(exercises)..where((e) => e.clientId.equals(remote.clientId.value))..limit(1)).getSingleOrNull();

      if (existing == null && remote.isCustom.value == false) {
        // Find existing global exercises by name to merge and adopt remote clientId
        existing = await (select(exercises)..where((e) => e.name.equals(remote.name.value) & e.isCustom.equals(false))..limit(1)).getSingleOrNull();
      }

      if (existing == null) {
        await into(exercises).insert(remote.copyWith(syncStatus: const Value(0)));
      } else if (remote.lastModifiedAt.value.isAfter(existing.lastModifiedAt) || existing.clientId != remote.clientId.value) {
        await (update(exercises)..where((e) => e.id.equals(existing!.id))).write(
          remote.copyWith(syncStatus: const Value(0)),
        );
      }
    }
  }

  // ─── Routine DAO ───────────────────────────────────────────────────────────

  Future<List<Routine>> getAllRoutines() =>
      (select(routines)..where((r) => r.isDeleted.equals(false))).get();

  Stream<List<Routine>> watchAllRoutines() =>
      (select(routines)..where((r) => r.isDeleted.equals(false))).watch();

  Future<Routine?> getRoutineById(int id) =>
      (select(routines)..where((r) => r.id.equals(id))).getSingleOrNull();

  Future<int> insertRoutine(RoutinesCompanion entry) => into(routines).insert(
        entry.copyWith(
          clientId: Value(_uuid.v4()),
          createdAt: Value(DateTime.now()),
          lastModifiedAt: Value(DateTime.now()),
          syncStatus: const Value(1),
        ),
      );

  Future<bool> updateRoutine(RoutinesCompanion entry) =>
      (update(routines)..where((r) => r.id.equals(entry.id.value))).write(
        entry.copyWith(
          lastModifiedAt: Value(DateTime.now()),
          syncStatus: const Value(1),
        ),
      ).then((rows) => rows > 0);

  Future<void> softDeleteRoutine(int id) async {
    await (update(routines)..where((r) => r.id.equals(id))).write(
      RoutinesCompanion(
        isDeleted: const Value(true),
        lastModifiedAt: Value(DateTime.now()),
        syncStatus: const Value(1),
      ),
    );
    // Also soft-delete associated routine exercises
    await (update(routineExercises)..where((re) => re.routineId.equals(id)))
        .write(RoutineExercisesCompanion(
      isDeleted: const Value(true),
      lastModifiedAt: Value(DateTime.now()),
      syncStatus: const Value(1),
    ));
  }

  Future<int> duplicateRoutine(int routineId, String newName) async {
    final original = await getRoutineById(routineId);
    if (original == null) throw Exception('Routine not found');

    final newId = await insertRoutine(RoutinesCompanion(
      name: Value(newName),
      description: Value(original.description),
      colorHex: Value(original.colorHex),
    ));

    final entries = await getRoutineExercises(routineId);
    for (final entry in entries) {
      await insertRoutineExercise(RoutineExercisesCompanion(
        routineId: Value(newId),
        exerciseId: Value(entry.exerciseId),
        displayOrder: Value(entry.displayOrder),
        targetSets: Value(entry.targetSets),
        targetReps: Value(entry.targetReps),
        targetWeight: Value(entry.targetWeight),
      ));
    }
    return newId;
  }

  Future<void> upsertRoutinesFromRemote(List<RoutinesCompanion> remotes) async {
    for (final remote in remotes) {
      final existing = await (select(routines)..where((r) => r.clientId.equals(remote.clientId.value))..limit(1)).getSingleOrNull();
      if (existing == null) {
        await into(routines).insert(remote.copyWith(syncStatus: const Value(0)));
      } else if (remote.lastModifiedAt.value.isAfter(existing.lastModifiedAt)) {
        await (update(routines)..where((r) => r.id.equals(existing.id))).write(
          remote.copyWith(syncStatus: const Value(0)),
        );
      }
    }
  }

  // ─── RoutineExercise DAO ───────────────────────────────────────────────────

  Future<List<RoutineExerciseEntry>> getRoutineExercises(int routineId) =>
      (select(routineExercises)
            ..where((re) =>
                re.routineId.equals(routineId) &
                re.isDeleted.equals(false))
            ..orderBy([(re) => OrderingTerm.asc(re.displayOrder)]))
          .get();

  Stream<List<RoutineExerciseEntry>> watchRoutineExercises(int routineId) =>
      (select(routineExercises)
            ..where((re) =>
                re.routineId.equals(routineId) &
                re.isDeleted.equals(false))
            ..orderBy([(re) => OrderingTerm.asc(re.displayOrder)]))
          .watch();

  Future<int> insertRoutineExercise(RoutineExercisesCompanion entry) =>
      into(routineExercises).insert(
        entry.copyWith(
          clientId: Value(_uuid.v4()),
          lastModifiedAt: Value(DateTime.now()),
          syncStatus: const Value(1),
        ),
      );

  Future<void> updateRoutineExercise(RoutineExercisesCompanion entry) =>
      (update(routineExercises)..where((re) => re.id.equals(entry.id.value)))
          .write(entry.copyWith(
        lastModifiedAt: Value(DateTime.now()),
        syncStatus: const Value(1),
      ));

  Future<void> softDeleteRoutineExercise(int id) =>
      (update(routineExercises)..where((re) => re.id.equals(id))).write(
        RoutineExercisesCompanion(
          isDeleted: const Value(true),
          lastModifiedAt: Value(DateTime.now()),
          syncStatus: const Value(1),
        ),
      );

  Future<void> reorderRoutineExercises(int routineId, List<int> orderedIds) async {
    for (var i = 0; i < orderedIds.length; i++) {
      await (update(routineExercises)
            ..where((re) => re.id.equals(orderedIds[i])))
          .write(RoutineExercisesCompanion(
        displayOrder: Value(i),
        lastModifiedAt: Value(DateTime.now()),
        syncStatus: const Value(1),
      ));
    }
  }

  Future<void> upsertRoutineExercisesFromRemote(List<RoutineExercisesCompanion> remotes) async {
    for (var remote in remotes) {
      final existing = await (select(routineExercises)..where((re) => re.clientId.equals(remote.clientId.value))..limit(1)).getSingleOrNull();

      if (existing == null) {
        await into(routineExercises).insert(remote.copyWith(syncStatus: const Value(0)));
      } else if (remote.lastModifiedAt.value.isAfter(existing.lastModifiedAt)) {
        await (update(routineExercises)..where((re) => re.id.equals(existing.id))).write(
          remote.copyWith(syncStatus: const Value(0)),
        );
      }
    }
  }

  // ─── WorkoutExercise DAO ───────────────────────────────────────────────────

  Future<List<WorkoutExerciseEntry>> getWorkoutExercises(int workoutId) =>
      (select(workoutExercises)
            ..where((we) =>
                we.workoutId.equals(workoutId) & we.isDeleted.equals(false))
            ..orderBy([(we) => OrderingTerm.asc(we.displayOrder)]))
          .get();

  Stream<List<WorkoutExerciseEntry>> watchWorkoutExercises(int workoutId) =>
      (select(workoutExercises)
            ..where((we) =>
                we.workoutId.equals(workoutId) & we.isDeleted.equals(false))
            ..orderBy([(we) => OrderingTerm.asc(we.displayOrder)]))
          .watch();

  Future<int> upsertWorkoutExercise(WorkoutExercisesCompanion entry) async {
    final existing = await (select(workoutExercises)
          ..where((we) =>
              we.workoutId.equals(entry.workoutId.value) &
              we.exerciseId.equals(entry.exerciseId.value) &
              we.isDeleted.equals(false))
          ..limit(1))
        .getSingleOrNull();
    if (existing != null) {
      await (update(workoutExercises)..where((we) => we.id.equals(existing.id)))
          .write(entry.copyWith(
        lastModifiedAt: Value(DateTime.now()),
        syncStatus: const Value(1),
      ));
      return existing.id;
    }
    return into(workoutExercises).insert(
      entry.copyWith(
        clientId: Value(_uuid.v4()),
        lastModifiedAt: Value(DateTime.now()),
        syncStatus: const Value(1),
      ),
    );
  }

  Future<void> updateWorkoutExerciseNotes(int id, String notes) =>
      (update(workoutExercises)..where((we) => we.id.equals(id))).write(
        WorkoutExercisesCompanion(
          notes: Value(notes),
          lastModifiedAt: Value(DateTime.now()),
          syncStatus: const Value(1),
        ),
      );

  Future<void> updateWorkoutExerciseOrder(int id, int displayOrder) =>
      (update(workoutExercises)..where((we) => we.id.equals(id))).write(
        WorkoutExercisesCompanion(
          displayOrder: Value(displayOrder),
          lastModifiedAt: Value(DateTime.now()),
          syncStatus: const Value(1),
        ),
      );

  Future<void> softDeleteWorkoutExercise(int id) =>
      (update(workoutExercises)..where((we) => we.id.equals(id))).write(
        WorkoutExercisesCompanion(
          isDeleted: const Value(true),
          lastModifiedAt: Value(DateTime.now()),
          syncStatus: const Value(1),
        ),
      );

  Future<void> reorderWorkoutExercises(
      int workoutId, List<int> orderedExerciseIds) async {
    for (var i = 0; i < orderedExerciseIds.length; i++) {
      await (update(workoutExercises)
            ..where((we) =>
                we.workoutId.equals(workoutId) &
                we.exerciseId.equals(orderedExerciseIds[i])))
          .write(WorkoutExercisesCompanion(
        displayOrder: Value(i),
        lastModifiedAt: Value(DateTime.now()),
        syncStatus: const Value(1),
      ));
    }
  }

  // ─── Workout DAO ───────────────────────────────────────────────────────────

  Future<Workout?> getIncompleteWorkout() =>
      (select(workouts)
            ..where(
                (w) => w.endTime.isNull() & w.isDeleted.equals(false))
            ..orderBy([(w) => OrderingTerm.desc(w.startTime)])
            ..limit(1))
          .getSingleOrNull();

  Stream<Workout?> watchIncompleteWorkout() =>
      (select(workouts)
            ..where(
                (w) => w.endTime.isNull() & w.isDeleted.equals(false))
            ..orderBy([(w) => OrderingTerm.desc(w.startTime)])
            ..limit(1))
          .watchSingleOrNull();

  Stream<List<Exercise>> watchGlobalExercises() =>
      (select(exercises)
            ..where((e) =>
                e.isDeleted.equals(false) & e.isCustom.equals(false)))
          .watch();

  Stream<List<Exercise>> watchCustomExercises() =>
      (select(exercises)
            ..where((e) =>
                e.isDeleted.equals(false) & e.isCustom.equals(true)))
          .watch();

  Future<List<Workout>> getAllWorkouts() => (select(workouts)
        ..where((w) => w.isDeleted.equals(false))
        ..orderBy([(w) => OrderingTerm.desc(w.startTime)]))
      .get();

  Stream<List<Workout>> watchAllWorkouts() => (select(workouts)
        ..where((w) => w.isDeleted.equals(false))
        ..orderBy([(w) => OrderingTerm.desc(w.startTime)]))
      .watch();

  Future<Workout?> getWorkoutById(int id) =>
      (select(workouts)..where((w) => w.id.equals(id))).getSingleOrNull();

  Future<int> insertWorkout(WorkoutsCompanion entry) => into(workouts).insert(
        entry.copyWith(
          clientId: Value(_uuid.v4()),
          startTime: Value(entry.startTime.value),
          lastModifiedAt: Value(DateTime.now()),
          syncStatus: const Value(1),
        ),
      );

  Future<void> finishWorkout(int id, {String? notes}) =>
      (update(workouts)..where((w) => w.id.equals(id))).write(
        WorkoutsCompanion(
          endTime: Value(DateTime.now()),
          notes: notes != null ? Value(notes) : const Value.absent(),
          lastModifiedAt: Value(DateTime.now()),
          syncStatus: const Value(1),
        ),
      );

  Future<void> softDeleteWorkout(int id) async {
    await (update(workouts)..where((w) => w.id.equals(id))).write(
      WorkoutsCompanion(
        isDeleted: const Value(true),
        lastModifiedAt: Value(DateTime.now()),
        syncStatus: const Value(1),
      ),
    );
    await (update(loggedSets)..where((s) => s.workoutId.equals(id))).write(
      LoggedSetsCompanion(
        isDeleted: const Value(true),
        lastModifiedAt: Value(DateTime.now()),
        syncStatus: const Value(1),
      ),
    );
  }

  Future<void> upsertWorkoutsFromRemote(List<WorkoutsCompanion> remotes) async {
    for (var remote in remotes) {
      final existing = await (select(workouts)..where((w) => w.clientId.equals(remote.clientId.value))..limit(1)).getSingleOrNull();

      if (existing == null) {
        await into(workouts).insert(remote.copyWith(syncStatus: const Value(0)));
      } else if (remote.lastModifiedAt.value.isAfter(existing.lastModifiedAt)) {
        await (update(workouts)..where((w) => w.id.equals(existing.id))).write(
          remote.copyWith(syncStatus: const Value(0)),
        );
      }
    }
  }

  // ─── LoggedSet DAO ─────────────────────────────────────────────────────────

  Future<List<LoggedSet>> getLoggedSets(int workoutId) => (select(loggedSets)
        ..where((s) =>
            s.workoutId.equals(workoutId) & s.isDeleted.equals(false))
        ..orderBy([
          (s) => OrderingTerm.asc(s.exerciseId),
          (s) => OrderingTerm.asc(s.setNumber),
        ]))
      .get();

  Stream<List<LoggedSet>> watchLoggedSets(int workoutId) =>
      (select(loggedSets)
            ..where((s) =>
                s.workoutId.equals(workoutId) & s.isDeleted.equals(false))
            ..orderBy([
              (s) => OrderingTerm.asc(s.exerciseId),
              (s) => OrderingTerm.asc(s.setNumber),
            ]))
          .watch();

  Future<int> insertLoggedSet(LoggedSetsCompanion entry) =>
      into(loggedSets).insert(
        entry.copyWith(
          clientId: Value(_uuid.v4()),
          lastModifiedAt: Value(DateTime.now()),
          syncStatus: const Value(1),
        ),
      );

  Future<void> updateLoggedSet(LoggedSetsCompanion entry) =>
      (update(loggedSets)..where((s) => s.id.equals(entry.id.value))).write(
        entry.copyWith(
          lastModifiedAt: Value(DateTime.now()),
          syncStatus: const Value(1),
        ),
      );

  Future<void> softDeleteLoggedSet(int id) =>
      (update(loggedSets)..where((s) => s.id.equals(id))).write(
        LoggedSetsCompanion(
          isDeleted: const Value(true),
          lastModifiedAt: Value(DateTime.now()),
          syncStatus: const Value(1),
        ),
      );

    Future<void> upsertLoggedSetsFromRemote(List<LoggedSetsCompanion> remotes) async {
      for (var remote in remotes) {
      final existing = await (select(loggedSets)..where((s) => s.clientId.equals(remote.clientId.value))..limit(1)).getSingleOrNull();

        if (existing == null) {
          await into(loggedSets).insert(remote.copyWith(syncStatus: const Value(0)));
        } else if (remote.lastModifiedAt.value.isAfter(existing.lastModifiedAt)) {
          await (update(loggedSets)..where((s) => s.id.equals(existing.id))).write(
            remote.copyWith(syncStatus: const Value(0)),
          );
        }
      }
    }

  /// Get the last logged sets for a specific exercise (most recent workout).
  Future<List<LoggedSet>> getLastLoggedSetsForExercise(int exerciseId) async {
    // Find the most recent workout that includes this exercise
    final query = selectOnly(loggedSets)
      ..addColumns([loggedSets.workoutId])
      ..where(loggedSets.exerciseId.equals(exerciseId) &
          loggedSets.isDeleted.equals(false))
      ..orderBy([OrderingTerm.desc(loggedSets.completedAt)])
      ..limit(1);

    final result = await query.getSingleOrNull();
    if (result == null) return [];

    final lastWorkoutId = result.read(loggedSets.workoutId);
    if (lastWorkoutId == null) return [];

    return (select(loggedSets)
          ..where((s) =>
              s.workoutId.equals(lastWorkoutId) &
              s.exerciseId.equals(exerciseId) &
              s.isDeleted.equals(false))
          ..orderBy([(s) => OrderingTerm.asc(s.setNumber)]))
        .get();
  }

  // ─── Sync helpers ──────────────────────────────────────────────────────────
  
  Future<void> markSynced(String tableName, int id) async {
    switch (tableName) {
      case 'exercises':
        await (update(exercises)..where((t) => t.id.equals(id)))
            .write(const ExercisesCompanion(syncStatus: Value(0)));
        break;
      case 'routines':
        await (update(routines)..where((t) => t.id.equals(id)))
            .write(const RoutinesCompanion(syncStatus: Value(0)));
        break;
      case 'routine_exercises':
        await (update(routineExercises)..where((t) => t.id.equals(id)))
            .write(const RoutineExercisesCompanion(syncStatus: Value(0)));
        break;
      case 'workouts':
        await (update(workouts)..where((t) => t.id.equals(id)))
            .write(const WorkoutsCompanion(syncStatus: Value(0)));
        break;
      case 'logged_sets':
        await (update(loggedSets)..where((t) => t.id.equals(id)))
            .write(const LoggedSetsCompanion(syncStatus: Value(0)));
        break;
    }
  }

  // ─── Stats helpers ─────────────────────────────────────────────────────────

  /// Total workouts count
  Future<int> getWorkoutCount() async {
    final count = countAll();
    final query = selectOnly(workouts)
      ..addColumns([count])
      ..where(workouts.isDeleted.equals(false) & workouts.endTime.isNotNull());
    final result = await query.getSingle();
    return result.read(count) ?? 0;
  }

  /// Total workouts count stream
  Stream<int> watchWorkoutCount() {
    final countExp = countAll();
    final query = selectOnly(workouts)
      ..addColumns([countExp])
      ..where(workouts.isDeleted.equals(false) & workouts.endTime.isNotNull());
    return query.map((row) => row.read(countExp) ?? 0).watchSingle();
  }

  /// Workouts this week
  Future<int> getWorkoutsThisWeek() async {
    final now = DateTime.now();
    final startOfWeek = now.subtract(Duration(days: now.weekday - 1));
    final start = DateTime(startOfWeek.year, startOfWeek.month, startOfWeek.day);
    final count = countAll();
    final query = selectOnly(workouts)
      ..addColumns([count])
      ..where(workouts.isDeleted.equals(false) &
          workouts.endTime.isNotNull() &
          workouts.startTime.isBiggerOrEqualValue(start));
    final result = await query.getSingle();
    return result.read(count) ?? 0;
  }

  /// Workouts this week stream
  Stream<int> watchWorkoutsThisWeek() {
    final now = DateTime.now();
    final startOfWeek = now.subtract(Duration(days: now.weekday - 1));
    final start = DateTime(startOfWeek.year, startOfWeek.month, startOfWeek.day);
    final countExp = countAll();
    final query = selectOnly(workouts)
      ..addColumns([countExp])
      ..where(workouts.isDeleted.equals(false) &
          workouts.endTime.isNotNull() &
          workouts.startTime.isBiggerOrEqualValue(start));
    return query.map((row) => row.read(countExp) ?? 0).watchSingle();
  }

  // ─── Seed data ─────────────────────────────────────────────────────────────

  Future<void> _seedExercises() async {
    final now = DateTime.now();
    final seedData = <ExercisesCompanion>[
      // Chest
      _ex('Barbell Bench Press', 'Chest', 'Chest', 'Barbell', now),
      _ex('Incline Barbell Bench Press', 'Chest', 'Chest', 'Barbell', now),
      _ex('Dumbbell Bench Press', 'Chest', 'Chest', 'Dumbbell', now),
      _ex('Incline Dumbbell Press', 'Chest', 'Chest', 'Dumbbell', now),
      _ex('Cable Fly', 'Chest', 'Chest', 'Cable', now),
      _ex('Chest Dip', 'Chest', 'Chest', 'Bodyweight', now),
      _ex('Machine Chest Press', 'Chest', 'Chest', 'Machine', now),
      _ex('Push-Up', 'Chest', 'Chest', 'Bodyweight', now),
      // Back
      _ex('Barbell Row', 'Back', 'Back', 'Barbell', now),
      _ex('Deadlift', 'Back', 'Back', 'Barbell', now),
      _ex('Pull-Up', 'Back', 'Back', 'Bodyweight', now),
      _ex('Lat Pulldown', 'Back', 'Back', 'Cable', now),
      _ex('Seated Cable Row', 'Back', 'Back', 'Cable', now),
      _ex('Dumbbell Row', 'Back', 'Back', 'Dumbbell', now),
      _ex('T-Bar Row', 'Back', 'Back', 'Barbell', now),
      // Shoulders
      _ex('Overhead Press', 'Shoulders', 'Shoulders', 'Barbell', now),
      _ex('Dumbbell Shoulder Press', 'Shoulders', 'Shoulders', 'Dumbbell', now),
      _ex('Lateral Raise', 'Shoulders', 'Shoulders', 'Dumbbell', now),
      _ex('Face Pull', 'Shoulders', 'Shoulders', 'Cable', now),
      _ex('Rear Delt Fly', 'Shoulders', 'Shoulders', 'Dumbbell', now),
      _ex('Arnold Press', 'Shoulders', 'Shoulders', 'Dumbbell', now),
      // Biceps
      _ex('Barbell Curl', 'Biceps', 'Biceps', 'Barbell', now),
      _ex('Dumbbell Curl', 'Biceps', 'Biceps', 'Dumbbell', now),
      _ex('Hammer Curl', 'Biceps', 'Biceps', 'Dumbbell', now),
      _ex('Cable Curl', 'Biceps', 'Biceps', 'Cable', now),
      _ex('Preacher Curl', 'Biceps', 'Biceps', 'Barbell', now),
      // Triceps
      _ex('Tricep Pushdown', 'Triceps', 'Triceps', 'Cable', now),
      _ex('Overhead Tricep Extension', 'Triceps', 'Triceps', 'Dumbbell', now),
      _ex('Close-Grip Bench Press', 'Triceps', 'Triceps', 'Barbell', now),
      _ex('Skull Crusher', 'Triceps', 'Triceps', 'Barbell', now),
      _ex('Tricep Dip', 'Triceps', 'Triceps', 'Bodyweight', now),
      // Legs
      _ex('Barbell Squat', 'Legs', 'Legs', 'Barbell', now),
      _ex('Front Squat', 'Legs', 'Legs', 'Barbell', now),
      _ex('Leg Press', 'Legs', 'Legs', 'Machine', now),
      _ex('Romanian Deadlift', 'Legs', 'Legs', 'Barbell', now),
      _ex('Leg Extension', 'Legs', 'Legs', 'Machine', now),
      _ex('Leg Curl', 'Legs', 'Legs', 'Machine', now),
      _ex('Bulgarian Split Squat', 'Legs', 'Legs', 'Dumbbell', now),
      _ex('Calf Raise', 'Legs', 'Legs', 'Machine', now),
      _ex('Hip Thrust', 'Legs', 'Legs', 'Barbell', now),
      _ex('Walking Lunge', 'Legs', 'Legs', 'Dumbbell', now),
      // Core
      _ex('Plank', 'Core', 'Core', 'Bodyweight', now),
      _ex('Cable Crunch', 'Core', 'Core', 'Cable', now),
      _ex('Hanging Leg Raise', 'Core', 'Core', 'Bodyweight', now),
      _ex('Ab Wheel Rollout', 'Core', 'Core', 'Other', now),
    ];

    for (final ex in seedData) {
      await into(exercises).insert(ex);
    }
  }

  static ExercisesCompanion _ex(
    String name,
    String category,
    String targetMuscle,
    String equipment,
    DateTime now,
  ) =>
      ExercisesCompanion(
        clientId: Value(_uuid.v4()),
        name: Value(name),
        category: Value(category),
        targetMuscle: Value(targetMuscle),
        equipment: Value(equipment),
        isCustom: const Value(false),
        lastModifiedAt: Value(now),
        syncStatus: const Value(1),
        isDeleted: const Value(false),
      );
}
