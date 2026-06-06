import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gymapp/database/app_database.dart';
import 'package:gymapp/providers/providers.dart';
import 'package:gymapp/repositories/repositories.dart';
import 'package:gymapp/screens/workout/active_workout_screen.dart';
import 'package:gymapp/services/notification_service.dart';
import 'package:gymapp/services/sync_service.dart';
import 'package:mocktail/mocktail.dart';
import '../helpers/pump_app.dart';

class FakeSyncService extends SyncService {
  FakeSyncService(super.db);
  @override Future<bool> pushExercise(Exercise e) async => true;
  @override Future<bool> pushRoutine(Routine r) async => true;
  @override Future<bool> pushRoutineExercise(RoutineExerciseEntry re) async => true;
  @override Future<bool> pushWorkout(Workout w) async => true;
  @override Future<bool> pushLoggedSet(LoggedSet s) async => true;
  @override Future<void> syncAll() async {}
}

class MockNotificationService extends Mock implements NotificationService {}

void main() {
  late AppDatabase db;
  late FakeSyncService sync;
  late ExerciseRepository exerciseRepo;
  late RoutineRepository routineRepo;
  late WorkoutRepository workoutRepo;
  late MockNotificationService notifications;

  setUp(() {
    db = AppDatabase(NativeDatabase.memory());
    sync = FakeSyncService(db);
    notifications = MockNotificationService();
    when(() => notifications.scheduleWorkoutOverdueAlert(
          any(),
          startTime: any(named: 'startTime'),
        )).thenAnswer((_) async {});
    when(() => notifications.cancelWorkoutAlert(any()))
        .thenAnswer((_) async {});
    exerciseRepo = ExerciseRepository(db, sync);
    routineRepo = RoutineRepository(db, sync);
    workoutRepo = WorkoutRepository(db, sync, notificationService: notifications);
  });

  tearDown(() async => db.close());

  group('RoutineRepository — createFromWorkout', () {
    test('creates routine with exercises from logged sets', () async {
      final workoutId = await workoutRepo.start();
      final exercises = await exerciseRepo.getAll();
      final bench = exercises.firstWhere((e) => e.name.contains('Bench'));

      await workoutRepo.upsertWorkoutExercise(
        workoutId: workoutId,
        exerciseId: bench.id,
        displayOrder: 0,
        notes: 'Heavy day',
      );
      await workoutRepo.logSet(
        workoutId: workoutId,
        exerciseId: bench.id,
        setNumber: 1,
        weight: 80,
        reps: 8,
      );
      await workoutRepo.logSet(
        workoutId: workoutId,
        exerciseId: bench.id,
        setNumber: 2,
        weight: 82,
        reps: 6,
      );

      final routineId =
          await routineRepo.createFromWorkout(workoutId, name: 'My Push');

      final routine = await routineRepo.getById(routineId);
      expect(routine, isNotNull);
      expect(routine!.name, 'My Push');

      final entries = await routineRepo.getExercises(routineId);
      expect(entries.length, 1);
      expect(entries.first.exerciseId, bench.id);
      expect(entries.first.targetSets, 2);
      expect(entries.first.targetReps, 7);
      expect(entries.first.targetWeight, 81.0);
      expect(entries.first.notes, 'Heavy day');
      expect(entries.first.syncStatus, 0);
    });

    test('creates routine from unlogged workout exercises with defaults', () async {
      final workoutId = await workoutRepo.start();
      final exercises = await exerciseRepo.getAll();
      final squat = exercises.firstWhere((e) => e.name.contains('Squat'));

      await workoutRepo.upsertWorkoutExercise(
        workoutId: workoutId,
        exerciseId: squat.id,
        displayOrder: 0,
      );

      final routineId =
          await routineRepo.createFromWorkout(workoutId, name: 'Leg Day');

      final entries = await routineRepo.getExercises(routineId);
      expect(entries.length, 1);
      expect(entries.first.exerciseId, squat.id);
      expect(entries.first.targetSets, 3);
      expect(entries.first.targetReps, 10);
      expect(entries.first.targetWeight, 0.0);
    });
  });

  group('ActiveWorkoutScreen — resume empty workout', () {
    testWidgets('loads exercises added without logged sets', (tester) async {
      final workoutId = await workoutRepo.start();
      final exercises = await exerciseRepo.getAll();
      final bench = exercises.firstWhere((e) => e.name.contains('Bench'));

      await workoutRepo.upsertWorkoutExercise(
        workoutId: workoutId,
        exerciseId: bench.id,
        displayOrder: 0,
      );

      await tester.pumpApp(
        ActiveWorkoutScreen(workoutId: workoutId),
        overrides: [
          syncServiceProvider.overrideWithValue(sync),
          notificationServiceProvider.overrideWithValue(notifications),
          exerciseRepositoryProvider.overrideWithValue(exerciseRepo),
          routineRepositoryProvider.overrideWithValue(routineRepo),
          workoutRepositoryProvider.overrideWithValue(workoutRepo),
          incompleteWorkoutProvider.overrideWith((ref) => const Stream.empty()),
        ],
      );

      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));
      await tester.pump(const Duration(milliseconds: 100));

      expect(find.text(bench.name), findsOneWidget);
      expect(find.byTooltip('Save as Routine'), findsOneWidget);
    });

    testWidgets('finish dialog shows Save as Routine for free workout',
        (tester) async {
      final workoutId = await workoutRepo.start();
      final exercises = await exerciseRepo.getAll();
      final bench = exercises.firstWhere((e) => e.name.contains('Bench'));

      await workoutRepo.upsertWorkoutExercise(
        workoutId: workoutId,
        exerciseId: bench.id,
        displayOrder: 0,
      );
      await workoutRepo.logSet(
        workoutId: workoutId,
        exerciseId: bench.id,
        setNumber: 1,
        weight: 80,
        reps: 8,
      );

      await tester.pumpApp(
        ActiveWorkoutScreen(workoutId: workoutId),
        overrides: [
          syncServiceProvider.overrideWithValue(sync),
          notificationServiceProvider.overrideWithValue(notifications),
          exerciseRepositoryProvider.overrideWithValue(exerciseRepo),
          routineRepositoryProvider.overrideWithValue(routineRepo),
          workoutRepositoryProvider.overrideWithValue(workoutRepo),
          incompleteWorkoutProvider.overrideWith((ref) => const Stream.empty()),
        ],
      );

      await tester.pump();
      await tester.pump(const Duration(milliseconds: 200));
      await tester.pump(const Duration(milliseconds: 200));

      await tester.tap(find.text('Finish'));
      await tester.pump();
      await tester.pump();

      expect(find.text('Save as Routine'), findsOneWidget);
    });
  });
}
