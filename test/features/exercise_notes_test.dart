import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gymapp/database/app_database.dart';
import 'package:gymapp/repositories/repositories.dart';
import 'package:gymapp/services/sync_service.dart';

// ─── Fake sync (no-op) ───────────────────────────────────────────────────────

class FakeSyncService extends SyncService {
  FakeSyncService(super.db);
  @override Future<bool> pushExercise(Exercise e) async => true;
  @override Future<bool> pushRoutine(Routine r) async => true;
  @override Future<bool> pushRoutineExercise(RoutineExerciseEntry re) async => true;
  @override Future<bool> pushWorkout(Workout w) async => true;
  @override Future<bool> pushLoggedSet(LoggedSet s) async => true;
  @override Future<void> syncAll() async {}
}

// ─── Tests ───────────────────────────────────────────────────────────────────

void main() {
  late AppDatabase db;
  late FakeSyncService sync;
  late ExerciseRepository exerciseRepo;
  late RoutineRepository routineRepo;
  late WorkoutRepository workoutRepo;

  setUp(() {
    db = AppDatabase(NativeDatabase.memory());
    sync = FakeSyncService(db);
    exerciseRepo = ExerciseRepository(db, sync);
    routineRepo = RoutineRepository(db, sync);
    workoutRepo = WorkoutRepository(db, sync);
  });

  tearDown(() async => db.close());

  // ── Schema: RoutineExercises.notes ────────────────────────────────────────

  group('RoutineExercises — notes column', () {
    test('addExercise stores notes on routine exercise', () async {
      final routineId = await routineRepo.create(name: 'Push Day');
      final exercises = await exerciseRepo.getAll();
      final benchId = exercises.firstWhere((e) => e.name.contains('Bench')).id;

      await routineRepo.addExercise(
        routineId,
        benchId,
        0,
        sets: 4,
        reps: 8,
        notes: 'Keep elbows at 45°',
      );

      final entries = await routineRepo.getExercises(routineId);
      expect(entries.length, 1);
      expect(entries.first.notes, 'Keep elbows at 45°');
    });

    test('updateExercise updates notes without touching other fields', () async {
      final routineId = await routineRepo.create(name: 'Back Day');
      final exercises = await exerciseRepo.getAll();
      final pullUpId = exercises.firstWhere((e) => e.name.contains('Pull')).id;

      await routineRepo.addExercise(routineId, pullUpId, 0, sets: 3, reps: 10);
      final entries = await routineRepo.getExercises(routineId);
      final entryId = entries.first.id;

      await routineRepo.updateExercise(entryId, notes: 'Full dead hang each rep');

      final updated = await routineRepo.getExercises(routineId);
      expect(updated.first.notes, 'Full dead hang each rep');
      expect(updated.first.targetSets, 3); // unchanged
    });

    test('notes default to empty string when not provided', () async {
      final routineId = await routineRepo.create(name: 'Leg Day');
      final exercises = await exerciseRepo.getAll();
      final squatId = exercises.firstWhere((e) => e.name.contains('Squat')).id;

      await routineRepo.addExercise(routineId, squatId, 0, sets: 5, reps: 5);

      final entries = await routineRepo.getExercises(routineId);
      expect(entries.first.notes, '');
    });
  });

  // ── Schema: WorkoutExercises table ───────────────────────────────────────

  group('WorkoutExercises — notes and ordering', () {
    test('upsertWorkoutExercise creates a row with notes', () async {
      final workoutId = await workoutRepo.start();
      final exercises = await exerciseRepo.getAll();
      final benchId = exercises.firstWhere((e) => e.name.contains('Bench')).id;

      await workoutRepo.upsertWorkoutExercise(
        workoutId: workoutId,
        exerciseId: benchId,
        displayOrder: 0,
        notes: 'Pause at the bottom',
      );

      final entries = await workoutRepo.getWorkoutExercises(workoutId);
      expect(entries.length, 1);
      expect(entries.first.notes, 'Pause at the bottom');
      expect(entries.first.displayOrder, 0);
    });

    test('updateWorkoutExerciseNotes updates just the notes field', () async {
      final workoutId = await workoutRepo.start();
      final exercises = await exerciseRepo.getAll();
      final sqId = exercises.firstWhere((e) => e.name.contains('Squat')).id;

      await workoutRepo.upsertWorkoutExercise(
        workoutId: workoutId,
        exerciseId: sqId,
        displayOrder: 0,
        notes: 'Initial note',
      );

      final entries = await workoutRepo.getWorkoutExercises(workoutId);
      await workoutRepo.updateWorkoutExerciseNotes(entries.first.id, 'Revised note');

      final updated = await workoutRepo.getWorkoutExercises(workoutId);
      expect(updated.first.notes, 'Revised note');
      expect(updated.first.displayOrder, 0); // unchanged
    });

    test('notes are soft-deleted with the workout exercise row', () async {
      final workoutId = await workoutRepo.start();
      final exercises = await exerciseRepo.getAll();
      final dlId = exercises.firstWhere((e) => e.name.contains('Deadlift')).id;

      await workoutRepo.upsertWorkoutExercise(
        workoutId: workoutId,
        exerciseId: dlId,
        displayOrder: 0,
        notes: 'Hip hinge, not squat',
      );

      final entries = await workoutRepo.getWorkoutExercises(workoutId);
      await workoutRepo.removeWorkoutExercise(entries.first.id);

      final remaining = await workoutRepo.getWorkoutExercises(workoutId);
      expect(remaining.isEmpty, isTrue);
    });

    test('upsert on same workoutId+exerciseId updates rather than duplicates', () async {
      final workoutId = await workoutRepo.start();
      final exercises = await exerciseRepo.getAll();
      final benchId = exercises.firstWhere((e) => e.name.contains('Bench')).id;

      await workoutRepo.upsertWorkoutExercise(
        workoutId: workoutId,
        exerciseId: benchId,
        displayOrder: 0,
        notes: 'First note',
      );
      await workoutRepo.upsertWorkoutExercise(
        workoutId: workoutId,
        exerciseId: benchId,
        displayOrder: 0,
        notes: 'Updated note',
      );

      final entries = await workoutRepo.getWorkoutExercises(workoutId);
      expect(entries.length, 1);
      expect(entries.first.notes, 'Updated note');
    });
  });

  // ── Routine → Workout notes propagation ─────────────────────────────────

  group('Notes propagation from routine to workout', () {
    test('starting a workout from routine seeds WorkoutExercise rows with routine notes',
        () async {
      final routineId = await routineRepo.create(name: 'Full Body');
      final exercises = await exerciseRepo.getAll();
      final benchId = exercises.firstWhere((e) => e.name.contains('Bench')).id;

      await routineRepo.addExercise(
        routineId,
        benchId,
        0,
        sets: 4,
        reps: 8,
        notes: 'Tuck elbows',
      );

      // When a workout is started from a routine the repo should copy notes
      final workoutId = await workoutRepo.start(routineId: routineId);
      final workoutExercises = await workoutRepo.getWorkoutExercises(workoutId);

      expect(workoutExercises.any((e) => e.notes == 'Tuck elbows'), isTrue);
    });
  });
}
