import 'package:drift/drift.dart' show Value;
import 'package:supabase_flutter/supabase_flutter.dart';
import '../database/app_database.dart';
import '../services/supabase_service.dart';

/// Handles syncing local Drift data to/from Supabase.
///
/// Strategy: local-first writes. Every mutation writes to Drift immediately,
/// then attempts to push to Supabase. If the push fails (e.g. offline), the
/// record stays with syncStatus = pending and retries on next syncAll().
class SyncService {
  final AppDatabase _db;
  SyncService(this._db);

  SupabaseClient get _client => SupabaseService.client;
  String? get _userId => SupabaseService.currentUser?.id;

  // ─── Push helpers (local → remote) ──────────────────────────────────────

  /// Push a single routine to Supabase.
  Future<bool> pushRoutine(Routine r) async {
    if (_userId == null) return false;
    try {
      await _client.from('routines').upsert({
        'id': r.clientId,
        'name': r.name,
        'description': r.description,
        'color_hex': r.colorHex,
        'user_id': _userId,
        'created_at': r.createdAt.toIso8601String(),
        'last_modified_at': r.lastModifiedAt.toIso8601String(),
        'is_deleted': r.isDeleted,
      }, onConflict: 'id');
      return true;
    } catch (_) {
      return false;
    }
  }

  /// Push a single workout to Supabase.
  Future<bool> pushWorkout(Workout w) async {
    if (_userId == null) return false;
    try {
      // Need to map the local routine's clientId if it exists
      String? remoteRoutineId;
      if (w.routineId != null) {
        final routine = await _db.getRoutineById(w.routineId!);
        remoteRoutineId = routine?.clientId;
      }

      await _client.from('workouts').upsert({
        'id': w.clientId,
        'routine_id': remoteRoutineId,
        'start_time': w.startTime.toIso8601String(),
        'end_time': w.endTime?.toIso8601String(),
        'notes': w.notes,
        'user_id': _userId,
        'last_modified_at': w.lastModifiedAt.toIso8601String(),
        'is_deleted': w.isDeleted,
      }, onConflict: 'id');
      return true;
    } catch (_) {
      return false;
    }
  }

  /// Push a single exercise to Supabase.
  Future<bool> pushExercise(Exercise e) async {
    try {
      await _client.from('exercises').upsert({
        'id': e.clientId,
        'name': e.name,
        'category': e.category,
        'target_muscle': e.targetMuscle,
        'equipment': e.equipment,
        'is_custom': e.isCustom,
        'user_id': _userId,
        'last_modified_at': e.lastModifiedAt.toIso8601String(),
        'is_deleted': e.isDeleted,
      }, onConflict: 'id');
      return true;
    } catch (_) {
      return false;
    }
  }

  /// Push a logged set to Supabase.
  Future<bool> pushLoggedSet(LoggedSet s) async {
    if (_userId == null) return false;
    try {
      // Map local IDs to clientIds for foreign keys
      final workout = await _db.getWorkoutById(s.workoutId);
      final exercise = await _db.getExerciseById(s.exerciseId);
      if (workout == null || exercise == null) return false;

      await _client.from('logged_sets').upsert({
        'id': s.clientId,
        'workout_id': workout.clientId,
        'exercise_id': exercise.clientId,
        'set_number': s.setNumber,
        'weight': s.weight,
        'reps': s.reps,
        'rpe': s.rpe,
        'set_type': s.setType,
        'rest_seconds': s.restSeconds,
        'completed_at': s.completedAt?.toIso8601String(),
        'user_id': _userId,
        'last_modified_at': s.lastModifiedAt.toIso8601String(),
        'is_deleted': s.isDeleted,
      }, onConflict: 'id');
      return true;
    } catch (_) {
      return false;
    }
  }

  /// Push a routine exercise mapping to Supabase.
  Future<bool> pushRoutineExercise(RoutineExerciseEntry re) async {
    if (_userId == null) return false;
    try {
      await _client.from('routine_exercises').upsert({
        'id': re.clientId,
        'routine_id': (await _db.getRoutineById(re.routineId))?.clientId,
        'exercise_id': (await _db.getExerciseById(re.exerciseId))?.clientId,
        'display_order': re.displayOrder,
        'target_sets': re.targetSets,
        'target_reps': re.targetReps,
        'target_weight': re.targetWeight,
        'user_id': _userId,
        'last_modified_at': re.lastModifiedAt.toIso8601String(),
        'is_deleted': re.isDeleted,
      }, onConflict: 'id');
      return true;
    } catch (_) {
      return false;
    }
  }

  // ─── Bulk sync ──────────────────────────────────────────────────────────

  /// Pull all records from Supabase for the current user and update local DB.
  Future<void> syncDown() async {
    if (_userId == null) return;

    try {
      // 1. Exercises
      final exercisesData = await _client.from('exercises').select().eq('user_id', _userId!);
      final exercises = exercisesData.map((e) => ExercisesCompanion.insert(
        clientId: e['id'],
        name: e['name'],
        category: e['category'],
        targetMuscle: e['target_muscle'],
        equipment: e['equipment'],
        isCustom: Value(e['is_custom'] ?? false),
        lastModifiedAt: DateTime.parse(e['last_modified_at']),
        isDeleted: Value(e['is_deleted'] ?? false),
      )).toList();
      await _db.upsertExercisesFromRemote(exercises);

      // 2. Routines
      final routinesData = await _client.from('routines').select().eq('user_id', _userId!);
      final routines = routinesData.map((r) => RoutinesCompanion.insert(
        clientId: r['id'],
        name: r['name'],
        description: Value(r['description'] ?? ''),
        colorHex: Value(r['color_hex'] ?? 'FF6366F1'),
        createdAt: DateTime.parse(r['created_at']),
        lastModifiedAt: DateTime.parse(r['last_modified_at']),
        isDeleted: Value(r['is_deleted'] ?? false),
      )).toList();
      await _db.upsertRoutinesFromRemote(routines);

      // 3. Routine Exercises
      final routineExercisesData = await _client.from('routine_exercises').select().eq('user_id', _userId!);
      
      // We need to resolve remote `routine_id` and `exercise_id` (which are uuids) to local int ids.
      final List<RoutineExercisesCompanion> routineExercises = [];
      
      // A better way is to rely on drift's lookup or fetch all into a map
      final allLocalRoutines = await _db.getAllRoutines();
      final allLocalExercises = await _db.getAllExercises();
      final routineMap = {for (var r in allLocalRoutines) r.clientId: r.id};
      final exerciseMap = {for (var e in allLocalExercises) e.clientId: e.id};

      for (final re in routineExercisesData) {
        final localRoutineId = routineMap[re['routine_id']];
        final localExerciseId = exerciseMap[re['exercise_id']];
        if (localRoutineId == null || localExerciseId == null) {
          print('DEBUG: syncDown SKIPPING routine_exercise ${re['id']} - localRoutineId: $localRoutineId (from remote ${re['routine_id']}), localExerciseId: $localExerciseId (from remote ${re['exercise_id']})');
          print('DEBUG: routineMap contains keys? ${routineMap.containsKey(re['routine_id'])}');
          print('DEBUG: exerciseMap contains keys? ${exerciseMap.containsKey(re['exercise_id'])}');
          continue;
        }

        routineExercises.add(RoutineExercisesCompanion.insert(
          clientId: re['id'],
          routineId: localRoutineId,
          exerciseId: localExerciseId,
          displayOrder: Value(re['display_order'] ?? 0),
          targetSets: Value(re['target_sets'] ?? 3),
          targetReps: Value(re['target_reps'] ?? 10),
          targetWeight: Value((re['target_weight'] ?? 0).toDouble()),
          lastModifiedAt: DateTime.parse(re['last_modified_at']),
          isDeleted: Value(re['is_deleted'] ?? false),
        ));
      }
      await _db.upsertRoutineExercisesFromRemote(routineExercises);

      // 4. Workouts
      final workoutsData = await _client.from('workouts').select().eq('user_id', _userId!);
      final List<WorkoutsCompanion> workouts = [];
      for (final w in workoutsData) {
        final localRoutineId = w['routine_id'] != null ? routineMap[w['routine_id']] : null;
        workouts.add(WorkoutsCompanion.insert(
          clientId: w['id'],
          routineId: Value(localRoutineId),
          startTime: DateTime.parse(w['start_time']),
          endTime: Value(w['end_time'] != null ? DateTime.parse(w['end_time']) : null),
          notes: Value(w['notes'] ?? ''),
          lastModifiedAt: DateTime.parse(w['last_modified_at']),
          isDeleted: Value(w['is_deleted'] ?? false),
        ));
      }
      await _db.upsertWorkoutsFromRemote(workouts);

      // 5. Logged Sets
      final allLocalWorkouts = await _db.getAllWorkouts();
      final workoutMap = {for (var w in allLocalWorkouts) w.clientId: w.id};
      final loggedSetsData = await _client.from('logged_sets').select().eq('user_id', _userId!);
      final List<LoggedSetsCompanion> loggedSets = [];

      for (final s in loggedSetsData) {
        final localWorkoutId = workoutMap[s['workout_id']];
        final localExerciseId = exerciseMap[s['exercise_id']];
        if (localWorkoutId == null || localExerciseId == null) continue;

        loggedSets.add(LoggedSetsCompanion.insert(
          clientId: s['id'],
          workoutId: localWorkoutId,
          exerciseId: localExerciseId,
          setNumber: s['set_number'],
          weight: Value((s['weight'] ?? 0).toDouble()),
          reps: Value(s['reps'] ?? 0),
          rpe: Value(s['rpe'] != null ? (s['rpe'] as num).toDouble() : null),
          setType: Value(s['set_type'] ?? 0),
          restSeconds: Value(s['rest_seconds'] ?? 0),
          completedAt: Value(s['completed_at'] != null ? DateTime.parse(s['completed_at']) : null),
          lastModifiedAt: DateTime.parse(s['last_modified_at']),
          isDeleted: Value(s['is_deleted'] ?? false),
        ));
      }
      await _db.upsertLoggedSetsFromRemote(loggedSets);

    } catch (e) {
      print('Error during syncDown: $e');
    }
  }

  /// Push all pending local records to Supabase.
  /// Called on login and periodically.
  Future<void> syncAll() async {
    if (_userId == null) return;

    // Push pending exercises (custom ones)
    final exercises = await _db.getAllExercises();
    for (final e in exercises.where((e) => e.syncStatus == 1)) {
      final ok = await pushExercise(e);
      if (ok) await _db.markSynced('exercises', e.id);
    }

    // Push pending routines
    final routines = await _db.getAllRoutines();
    for (final r in routines.where((r) => r.syncStatus == 1)) {
      final ok = await pushRoutine(r);
      if (ok) await _db.markSynced('routines', r.id);
    }

    // Push pending routine exercises
    for (final r in routines) {
      final res = await _db.getRoutineExercises(r.id);
      for (final re in res.where((re) => re.syncStatus == 1)) {
        final ok = await pushRoutineExercise(re);
        if (ok) await _db.markSynced('routine_exercises', re.id);
      }
    }

    // Push pending workouts
    final workouts = await _db.getAllWorkouts();
    for (final w in workouts.where((w) => w.syncStatus == 1)) {
      final ok = await pushWorkout(w);
      if (ok) await _db.markSynced('workouts', w.id);
    }

    // Push pending logged sets
    for (final w in workouts) {
      final sets = await _db.getLoggedSets(w.id);
      for (final s in sets.where((s) => s.syncStatus == 1)) {
        final ok = await pushLoggedSet(s);
        if (ok) await _db.markSynced('logged_sets', s.id);
      }
    }
  }
}
