import 'package:drift/drift.dart' show Value;
export 'package:drift/drift.dart' show Value;
import '../database/app_database.dart';
import '../services/sync_service.dart';

/// Repository abstraction for exercises.
/// Providers talk to this – never directly to the database.
/// When cloud sync is added, this class gains a remote data source
/// without any changes to providers or UI.
class ExerciseRepository {
  final AppDatabase _db;
  final SyncService _sync;
  ExerciseRepository(this._db, this._sync);

  Future<List<Exercise>> getAll() => _db.getAllExercises();
  Stream<List<Exercise>> watchAll() => _db.watchAllExercises();
  Future<List<Exercise>> search(String query) => _db.searchExercises(query);
  Future<List<Exercise>> getByCategory(String cat) => _db.getExercisesByCategory(cat);
  Future<Exercise?> getById(int id) => _db.getExerciseById(id);

  Future<int> create({
    required String name,
    required String category,
    required String targetMuscle,
    required String equipment,
  }) async {
    final id = await _db.insertExercise(ExercisesCompanion.insert(
      clientId: '', // will be overwritten by DB
      name: name,
      category: category,
      targetMuscle: targetMuscle,
      equipment: equipment,
      lastModifiedAt: DateTime.now(), // overwritten by DB
      isCustom: const Value(true),
    ));
    final ex = await getById(id);
    if (ex != null) {
      if (await _sync.pushExercise(ex)) await _db.markSynced('exercises', id);
    }
    return id;
  }

  Future<void> delete(int id) async {
    await _db.softDeleteExercise(id);
    final ex = await getById(id);
    if (ex != null) {
      if (await _sync.pushExercise(ex)) await _db.markSynced('exercises', id);
    }
  }
}

/// Repository abstraction for routines.
class RoutineRepository {
  final AppDatabase _db;
  final SyncService _sync;
  RoutineRepository(this._db, this._sync);

  Future<List<Routine>> getAll() => _db.getAllRoutines();
  Stream<List<Routine>> watchAll() => _db.watchAllRoutines();
  Future<Routine?> getById(int id) => _db.getRoutineById(id);

  Future<int> create({
    required String name,
    String description = '',
    String colorHex = 'FF6366F1',
  }) async {
    final id = await _db.insertRoutine(RoutinesCompanion(
      name: Value(name),
      description: Value(description),
      colorHex: Value(colorHex),
    ));
    final r = await getById(id);
    if (r != null) {
      if (await _sync.pushRoutine(r)) await _db.markSynced('routines', id);
    }
    return id;
  }

  Future<bool> update(int id, {String? name, String? description, String? colorHex}) async {
    final ok = await _db.updateRoutine(RoutinesCompanion(
      id: Value(id),
      name: name != null ? Value(name) : const Value.absent(),
      description: description != null ? Value(description) : const Value.absent(),
      colorHex: colorHex != null ? Value(colorHex) : const Value.absent(),
    ));
    if (ok) {
      final r = await getById(id);
      if (r != null) {
        if (await _sync.pushRoutine(r)) await _db.markSynced('routines', id);
      }
    }
    return ok;
  }

  Future<void> delete(int id) async {
    await _db.softDeleteRoutine(id);
    final r = await getById(id);
    if (r != null) {
      if (await _sync.pushRoutine(r)) await _db.markSynced('routines', id);
    }
  }
  
  Future<int> duplicate(int id, String newName) async {
    final newId = await _db.duplicateRoutine(id, newName);
    final r = await getById(newId);
    if (r != null) {
      if (await _sync.pushRoutine(r)) await _db.markSynced('routines', newId);
    }
    final entries = await getExercises(newId);
    for (final e in entries) {
      if (await _sync.pushRoutineExercise(e)) await _db.markSynced('routine_exercises', e.id);
    }
    return newId;
  }

  // Routine exercises
  Future<List<RoutineExerciseEntry>> getExercises(int routineId) =>
      _db.getRoutineExercises(routineId);
  Stream<List<RoutineExerciseEntry>> watchExercises(int routineId) =>
      _db.watchRoutineExercises(routineId);

  Future<int> addExercise(int routineId, int exerciseId, int order,
          {int sets = 3, int reps = 10, double weight = 0}) async {
    final id = await _db.insertRoutineExercise(RoutineExercisesCompanion(
      routineId: Value(routineId),
      exerciseId: Value(exerciseId),
      displayOrder: Value(order),
      targetSets: Value(sets),
      targetReps: Value(reps),
      targetWeight: Value(weight),
    ));
    // Defer push to background sync to keep UI fast
    return id;
  }

  Future<void> updateExercise(int id,
          {int? sets, int? reps, double? weight}) async {
    await _db.updateRoutineExercise(RoutineExercisesCompanion(
      id: Value(id),
      targetSets: sets != null ? Value(sets) : const Value.absent(),
      targetReps: reps != null ? Value(reps) : const Value.absent(),
      targetWeight: weight != null ? Value(weight) : const Value.absent(),
    ));
  }

  Future<void> removeExercise(int id) => _db.softDeleteRoutineExercise(id);
  Future<void> reorderExercises(int routineId, List<int> orderedIds) =>
      _db.reorderRoutineExercises(routineId, orderedIds);
}

/// Repository abstraction for workouts and logged sets.
class WorkoutRepository {
  final AppDatabase _db;
  final SyncService _sync;
  WorkoutRepository(this._db, this._sync);

  Future<List<Workout>> getAll() => _db.getAllWorkouts();
  Stream<List<Workout>> watchAll() => _db.watchAllWorkouts();
  Future<Workout?> getById(int id) => _db.getWorkoutById(id);

  Future<int> start({int? routineId}) async {
    final id = await _db.insertWorkout(WorkoutsCompanion(
      routineId: routineId != null ? Value(routineId) : const Value.absent(),
      startTime: Value(DateTime.now()),
    ));
    final w = await getById(id);
    if (w != null) {
      if (await _sync.pushWorkout(w)) await _db.markSynced('workouts', id);
    }
    return id;
  }

  Future<void> finish(int id, {String? notes}) async {
    await _db.finishWorkout(id, notes: notes);
    final w = await getById(id);
    if (w != null) {
      // when a workout finishes, trigger a sync to save all its log sets too
      _sync.syncAll();
    }
  }

  Future<void> delete(int id) async {
    await _db.softDeleteWorkout(id);
    final w = await getById(id);
    if (w != null) {
      if (await _sync.pushWorkout(w)) await _db.markSynced('workouts', id);
    }
  }

  // Logged sets
  Future<List<LoggedSet>> getSets(int workoutId) => _db.getLoggedSets(workoutId);
  Stream<List<LoggedSet>> watchSets(int workoutId) => _db.watchLoggedSets(workoutId);

  Future<int> logSet({
    required int workoutId,
    required int exerciseId,
    required int setNumber,
    required double weight,
    required int reps,
    double? rpe,
    int setType = 0,
    int restSeconds = 0,
  }) async {
    final id = await _db.insertLoggedSet(LoggedSetsCompanion(
      workoutId: Value(workoutId),
      exerciseId: Value(exerciseId),
      setNumber: Value(setNumber),
      weight: Value(weight),
      reps: Value(reps),
      rpe: rpe != null ? Value(rpe) : const Value.absent(),
      setType: Value(setType),
      restSeconds: Value(restSeconds),
      completedAt: Value(DateTime.now()),
    ));
    // defer individual set pushes to finishWorkout/syncAll to reduce latency
    return id;
  }

  Future<void> updateSet(int id,
          {double? weight, int? reps, double? rpe, int? setType}) =>
      _db.updateLoggedSet(LoggedSetsCompanion(
        id: Value(id),
        weight: weight != null ? Value(weight) : const Value.absent(),
        reps: reps != null ? Value(reps) : const Value.absent(),
        rpe: rpe != null ? Value(rpe) : const Value.absent(),
        setType: setType != null ? Value(setType) : const Value.absent(),
      ));

  Future<void> deleteSet(int id) => _db.softDeleteLoggedSet(id);

  Future<List<LoggedSet>> getLastSetsForExercise(int exerciseId) =>
      _db.getLastLoggedSetsForExercise(exerciseId);

  // Stats
  Future<int> getWorkoutCount() => _db.getWorkoutCount();
  Stream<int> watchWorkoutCount() => _db.watchWorkoutCount();
  Future<int> getWorkoutsThisWeek() => _db.getWorkoutsThisWeek();
  Stream<int> watchWorkoutsThisWeek() => _db.watchWorkoutsThisWeek();
}

// Re-export Value for convenience — imported at top of file
