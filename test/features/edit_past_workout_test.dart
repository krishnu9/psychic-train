import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gymapp/database/app_database.dart';
import 'package:gymapp/providers/providers.dart';
import 'package:gymapp/repositories/repositories.dart';
import 'package:gymapp/screens/history/history_screen.dart';
import 'package:gymapp/services/sync_service.dart';
import 'package:mocktail/mocktail.dart';
import '../helpers/pump_app.dart';

// ─── Fakes / Mocks ───────────────────────────────────────────────────────────

class FakeSyncService extends SyncService {
  FakeSyncService(super.db);
  @override Future<bool> pushExercise(Exercise e) async => true;
  @override Future<bool> pushRoutine(Routine r) async => true;
  @override Future<bool> pushRoutineExercise(RoutineExerciseEntry re) async => true;
  @override Future<bool> pushWorkout(Workout w) async => true;
  @override Future<bool> pushLoggedSet(LoggedSet s) async => true;
  @override Future<void> syncAll() async {}
}

class MockWorkoutRepository extends Mock implements WorkoutRepository {}

// ─── Helpers ─────────────────────────────────────────────────────────────────

Workout _completedWorkout({int id = 1, String notes = ''}) => Workout(
      id: id,
      clientId: 'client-$id',
      routineId: null,
      startTime: DateTime(2024, 1, 10, 9, 0),
      endTime: DateTime(2024, 1, 10, 10, 0),
      notes: notes,
      lastModifiedAt: DateTime(2024, 1, 10, 10, 0),
      syncStatus: 0,
      isDeleted: false,
    );

LoggedSet _loggedSet({int id = 1, double weight = 80, int reps = 8}) => LoggedSet(
      id: id,
      clientId: 'set-client-$id',
      workoutId: 1,
      exerciseId: 1,
      setNumber: 1,
      weight: weight,
      reps: reps,
      rpe: null,
      setType: 0,
      restSeconds: 0,
      completedAt: DateTime(2024, 1, 10, 9, 10),
      lastModifiedAt: DateTime(2024, 1, 10, 9, 10),
      syncStatus: 0,
      isDeleted: false,
    );

// ─── Repository-level tests ───────────────────────────────────────────────────

void main() {
  group('WorkoutRepository — updateSet', () {
    late AppDatabase db;
    late FakeSyncService sync;
    late ExerciseRepository exerciseRepo;
    late WorkoutRepository workoutRepo;

    setUp(() {
      db = AppDatabase(NativeDatabase.memory());
      sync = FakeSyncService(db);
      exerciseRepo = ExerciseRepository(db, sync);
      workoutRepo = WorkoutRepository(db, sync);
    });

    tearDown(() async => db.close());

    test('updateSet persists new weight and reps', () async {
      final workoutId = await workoutRepo.start();
      final exercises = await exerciseRepo.getAll();
      final benchId = exercises.firstWhere((e) => e.name.contains('Bench')).id;

      final setId = await workoutRepo.logSet(
        workoutId: workoutId,
        exerciseId: benchId,
        setNumber: 1,
        weight: 80,
        reps: 8,
      );

      await workoutRepo.finish(workoutId);
      await workoutRepo.updateSet(setId, weight: 85, reps: 6);

      final sets = await workoutRepo.getSets(workoutId);
      final updated = sets.firstWhere((s) => s.id == setId);
      expect(updated.weight, 85.0);
      expect(updated.reps, 6);
    });

    test('updateSet marks row as syncStatus=pending', () async {
      final workoutId = await workoutRepo.start();
      final exercises = await exerciseRepo.getAll();
      final sqId = exercises.firstWhere((e) => e.name.contains('Squat')).id;

      final setId = await workoutRepo.logSet(
        workoutId: workoutId,
        exerciseId: sqId,
        setNumber: 1,
        weight: 100,
        reps: 5,
      );

      await workoutRepo.finish(workoutId);
      await workoutRepo.updateSet(setId, weight: 105, reps: 5);

      final sets = await workoutRepo.getSets(workoutId);
      final updated = sets.firstWhere((s) => s.id == setId);
      expect(updated.syncStatus, 1); // pending
    });

    test('Can delete a set from a completed workout', () async {
      final workoutId = await workoutRepo.start();
      final exercises = await exerciseRepo.getAll();
      final dlId = exercises.firstWhere((e) => e.name.contains('Deadlift')).id;

      final setId = await workoutRepo.logSet(
        workoutId: workoutId,
        exerciseId: dlId,
        setNumber: 1,
        weight: 140,
        reps: 3,
      );
      await workoutRepo.finish(workoutId);
      await workoutRepo.deleteSet(setId);

      final sets = await workoutRepo.getSets(workoutId);
      expect(sets.any((s) => s.id == setId), isFalse);
    });
  });

  // ── Widget tests ─────────────────────────────────────────────────────────

  group('History Screen — edit mode', () {
    late MockWorkoutRepository workoutRepo;

    setUp(() {
      workoutRepo = MockWorkoutRepository();
      when(() => workoutRepo.watchAll()).thenAnswer(
        (_) => Stream.value([_completedWorkout()]),
      );
      when(() => workoutRepo.watchSets(any())).thenAnswer(
        (_) => Stream.value([_loggedSet()]),
      );
      when(() => workoutRepo.watchWorkoutExercises(any())).thenAnswer(
        (_) => Stream.value([]),
      );
      when(() => workoutRepo.updateSet(
            any(),
            weight: any(named: 'weight'),
            reps: any(named: 'reps'),
          )).thenAnswer((_) async {});
      when(() => workoutRepo.updateWorkoutExerciseNotes(any(), any()))
          .thenAnswer((_) async {});
    });

    testWidgets('history screen renders completed workouts', (tester) async {
      await tester.pumpApp(
        const HistoryScreen(),
        overrides: [
          workoutsProvider.overrideWith(
            (ref) => Stream.value([_completedWorkout()]),
          ),
          workoutSetsProvider.overrideWith(
            (ref, id) => Stream.value([_loggedSet()]),
          ),
          workoutExercisesProvider.overrideWith(
            (ref, id) => Stream.value([]),
          ),
          exercisesProvider.overrideWith(
            (ref) => Stream.value([]),
          ),
          workoutRepositoryProvider.overrideWithValue(workoutRepo),
        ],
      );

      await tester.pump();
      // Workout date or name should be visible
      expect(find.byType(ListTile).first, findsOneWidget);
    });

    testWidgets('edit button appears on each workout card', (tester) async {
      await tester.pumpApp(
        const HistoryScreen(),
        overrides: [
          workoutsProvider.overrideWith(
            (ref) => Stream.value([_completedWorkout()]),
          ),
          workoutSetsProvider.overrideWith(
            (ref, id) => Stream.value([_loggedSet()]),
          ),
          workoutExercisesProvider.overrideWith(
            (ref, id) => Stream.value([]),
          ),
          exercisesProvider.overrideWith(
            (ref) => Stream.value([]),
          ),
          workoutRepositoryProvider.overrideWithValue(workoutRepo),
        ],
      );

      await tester.pump();
      expect(find.byIcon(Icons.edit_outlined), findsWidgets);
    });

    testWidgets('tapping edit shows editable fields for weight and reps',
        (tester) async {
      await tester.pumpApp(
        const HistoryScreen(),
        overrides: [
          workoutsProvider.overrideWith(
            (ref) => Stream.value([_completedWorkout()]),
          ),
          workoutSetsProvider.overrideWith(
            (ref, id) => Stream.value([_loggedSet()]),
          ),
          workoutExercisesProvider.overrideWith(
            (ref, id) => Stream.value([]),
          ),
          exercisesProvider.overrideWith(
            (ref) => Stream.value([]),
          ),
          workoutRepositoryProvider.overrideWithValue(workoutRepo),
        ],
      );

      await tester.pump();
      await tester.tap(find.byIcon(Icons.edit_outlined).first);
      await tester.pump();

      // TextFields for weight and reps should appear
      expect(find.byType(TextFormField), findsWidgets);
    });

    testWidgets('saving edit calls updateSet with new values', (tester) async {
      await tester.pumpApp(
        const HistoryScreen(),
        overrides: [
          workoutsProvider.overrideWith(
            (ref) => Stream.value([_completedWorkout()]),
          ),
          workoutSetsProvider.overrideWith(
            (ref, id) => Stream.value([_loggedSet(weight: 80, reps: 8)]),
          ),
          workoutExercisesProvider.overrideWith(
            (ref, id) => Stream.value([]),
          ),
          exercisesProvider.overrideWith(
            (ref) => Stream.value([]),
          ),
          workoutRepositoryProvider.overrideWithValue(workoutRepo),
        ],
      );

      await tester.pump();
      await tester.tap(find.byIcon(Icons.edit_outlined).first);
      await tester.pump();

      // Clear and type new weight
      final weightField = find.byType(TextFormField).first;
      await tester.enterText(weightField, '90');
      await tester.pump();

      await tester.tap(find.text('Save'));
      await tester.pump();

      verify(() => workoutRepo.updateSet(
            any(),
            weight: 90,
            reps: any(named: 'reps'),
          )).called(1);
    });

    testWidgets('cancel edit reverts to read-only display', (tester) async {
      await tester.pumpApp(
        const HistoryScreen(),
        overrides: [
          workoutsProvider.overrideWith(
            (ref) => Stream.value([_completedWorkout()]),
          ),
          workoutSetsProvider.overrideWith(
            (ref, id) => Stream.value([_loggedSet()]),
          ),
          workoutExercisesProvider.overrideWith(
            (ref, id) => Stream.value([]),
          ),
          exercisesProvider.overrideWith(
            (ref) => Stream.value([]),
          ),
          workoutRepositoryProvider.overrideWithValue(workoutRepo),
        ],
      );

      await tester.pump();
      await tester.tap(find.byIcon(Icons.edit_outlined).first);
      await tester.pump();

      // Should now have a cancel action
      expect(find.text('Cancel'), findsOneWidget);
      await tester.tap(find.text('Cancel'));
      await tester.pump();

      // TextFields gone; edit button back
      expect(find.byType(TextFormField), findsNothing);
      expect(find.byIcon(Icons.edit_outlined), findsWidgets);

      verifyNever(() => workoutRepo.updateSet(
            any(),
            weight: any(named: 'weight'),
            reps: any(named: 'reps'),
          ));
    });
  });
}
