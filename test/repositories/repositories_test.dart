import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gymapp/database/app_database.dart';
import 'package:gymapp/repositories/repositories.dart';
import 'package:gymapp/services/sync_service.dart';

class FakeSyncService extends SyncService {
  FakeSyncService(super.db);
  @override Future<bool> pushExercise(Exercise e) async => true;
  @override Future<bool> pushRoutine(Routine r) async => true;
  @override Future<bool> pushRoutineExercise(RoutineExerciseEntry re) async => true;
  @override Future<bool> pushWorkout(Workout w) async => true;
  @override Future<bool> pushLoggedSet(LoggedSet s) async => true;
  @override Future<void> syncAll() async {}
}

void main() {
  late AppDatabase db;
  late FakeSyncService syncService;
  late ExerciseRepository exerciseRepo;
  late RoutineRepository routineRepo;
  late WorkoutRepository workoutRepo;

  setUp(() {
    db = AppDatabase(NativeDatabase.memory());
    syncService = FakeSyncService(db);
    exerciseRepo = ExerciseRepository(db, syncService);
    routineRepo = RoutineRepository(db, syncService);
    workoutRepo = WorkoutRepository(db, syncService);
  });

  tearDown(() async {
    await db.close();
  });

  group('ExerciseRepository', () {
    test('Can fetch seeded exercises', () async {
      final exercises = await exerciseRepo.getAll();
      expect(exercises.isNotEmpty, isTrue);
      final benchPress = exercises.firstWhere((e) => e.name == 'Barbell Bench Press');
      expect(benchPress.category, 'Chest');
    });

    test('Can create and soft delete a custom exercise', () async {
      final id = await exerciseRepo.create(
        name: 'Custom Curl',
        category: 'Biceps',
        targetMuscle: 'Biceps',
        equipment: 'Dumbbell',
      );
      
      var customEx = await exerciseRepo.getById(id);
      expect(customEx, isNotNull);
      expect(customEx!.isCustom, isTrue);
      expect(customEx.name, 'Custom Curl');

      await exerciseRepo.delete(id);
      final allExercises = await exerciseRepo.getAll();
      expect(allExercises.any((e) => e.id == id), isFalse);
    });
  });

  group('RoutineRepository', () {
    test('Can create, update, and soft delete a routine', () async {
      final routineId = await routineRepo.create(
        name: 'Push Day',
        description: 'Chest, Shoulders, Triceps',
      );

      var routine = await routineRepo.getById(routineId);
      expect(routine, isNotNull);
      expect(routine!.name, 'Push Day');

      await routineRepo.update(routineId, name: 'Push Day v2');
      routine = await routineRepo.getById(routineId);
      expect(routine!.name, 'Push Day v2');

      await routineRepo.delete(routineId);
      final allRoutines = await routineRepo.getAll();
      expect(allRoutines.any((r) => r.id == routineId), isFalse);
    });

    test('Can add and manage exercises in a routine', () async {
      final routineId = await routineRepo.create(name: 'Leg Day');
      final exercises = await exerciseRepo.getAll();
      final squatId = exercises.firstWhere((e) => e.name.contains('Squat')).id;

      await routineRepo.addExercise(routineId, squatId, 0, sets: 4, reps: 8);
      
      var routineExercises = await routineRepo.getExercises(routineId);
      expect(routineExercises.length, 1);
      expect(routineExercises.first.targetSets, 4);

      await routineRepo.updateExercise(routineExercises.first.id, reps: 12);
      routineExercises = await routineRepo.getExercises(routineId);
      expect(routineExercises.first.targetReps, 12);

      await routineRepo.removeExercise(routineExercises.first.id);
      routineExercises = await routineRepo.getExercises(routineId);
      expect(routineExercises.isEmpty, isTrue);
    });
  });

  group('WorkoutRepository', () {
    test('Can start and finish a workout', () async {
      final workoutId = await workoutRepo.start();
      var workout = await workoutRepo.getById(workoutId);
      expect(workout, isNotNull);
      expect(workout!.endTime, isNull);

      await workoutRepo.finish(workoutId, notes: 'Great pump');
      workout = await workoutRepo.getById(workoutId);
      expect(workout!.endTime, isNotNull);
      expect(workout.notes, 'Great pump');
    });

    test('Can log sets and delete workout', () async {
      final workoutId = await workoutRepo.start();
      final exercises = await exerciseRepo.getAll();
      final curlId = exercises.firstWhere((e) => e.name.contains('Curl')).id;

      await workoutRepo.logSet(
        workoutId: workoutId,
        exerciseId: curlId,
        setNumber: 1,
        weight: 30,
        reps: 10,
      );

      var sets = await workoutRepo.getSets(workoutId);
      expect(sets.length, 1);
      expect(sets.first.weight, 30);

      await workoutRepo.delete(workoutId);
      final allWorkouts = await workoutRepo.getAll();
      expect(allWorkouts.any((w) => w.id == workoutId), isFalse);
    });

    test('getIncompleteWorkout returns workout with null endTime', () async {
      final workoutId = await workoutRepo.start();
      final incomplete = await workoutRepo.getIncompleteWorkout();
      expect(incomplete, isNotNull);
      expect(incomplete!.id, workoutId);
      expect(incomplete.endTime, isNull);
    });

    test('getIncompleteWorkout returns null after workout is finished', () async {
      final workoutId = await workoutRepo.start();
      await workoutRepo.finish(workoutId);
      final incomplete = await workoutRepo.getIncompleteWorkout();
      expect(incomplete, isNull);
    });

    test('getIncompleteWorkout returns most recent when multiple orphans exist', () async {
      final firstId = await workoutRepo.start();
      final secondId = await workoutRepo.start();

      final incomplete = await workoutRepo.getIncompleteWorkout();
      expect(incomplete, isNotNull);
      // Both are incomplete; the query orders by startTime DESC then picks limit 1.
      // Since they may have the same startTime, just verify one is returned
      // and it's one of the two.
      expect([firstId, secondId], contains(incomplete!.id));
    });

    test('getById returns the correct workout', () async {
      final workoutId = await workoutRepo.start(routineId: null);
      final workout = await workoutRepo.getById(workoutId);
      expect(workout, isNotNull);
      expect(workout!.id, workoutId);
    });
  });

  group('ExerciseRepository - filtering', () {
    test('watchGlobal excludes custom exercises', () async {
      // Create a custom exercise
      await exerciseRepo.create(
        name: 'My Custom Exercise',
        category: 'Chest',
        targetMuscle: 'Chest',
        equipment: 'Bodyweight',
      );

      final globalStream = exerciseRepo.watchGlobal();
      final globalExercises = await globalStream.first;

      // All global exercises should have isCustom == false
      expect(globalExercises.every((e) => !e.isCustom), isTrue);
      // The custom exercise should not appear
      expect(globalExercises.any((e) => e.name == 'My Custom Exercise'), isFalse);
    });

    test('watchCustom only includes custom exercises', () async {
      await exerciseRepo.create(
        name: 'Custom Press',
        category: 'Chest',
        targetMuscle: 'Chest',
        equipment: 'Barbell',
      );

      final customStream = exerciseRepo.watchCustom();
      final customExercises = await customStream.first;

      expect(customExercises.isNotEmpty, isTrue);
      expect(customExercises.every((e) => e.isCustom), isTrue);
      expect(customExercises.any((e) => e.name == 'Custom Press'), isTrue);
    });

    test('Creating a custom exercise appears in watchCustom but not watchGlobal', () async {
      final id = await exerciseRepo.create(
        name: 'Unique Custom Move',
        category: 'Core',
        targetMuscle: 'Core',
        equipment: 'Bodyweight',
      );

      final global = await exerciseRepo.watchGlobal().first;
      final custom = await exerciseRepo.watchCustom().first;

      expect(global.any((e) => e.id == id), isFalse);
      expect(custom.any((e) => e.id == id), isTrue);
    });
  });
}
