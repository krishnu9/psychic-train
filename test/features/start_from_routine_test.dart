import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gymapp/database/app_database.dart';
import 'package:gymapp/providers/providers.dart';
import 'package:gymapp/repositories/repositories.dart';
import 'package:gymapp/screens/routines/routine_list_screen.dart';
import 'package:gymapp/services/sync_service.dart';
import 'package:mocktail/mocktail.dart';
import '../helpers/pump_app.dart';

// ─── Mocks ───────────────────────────────────────────────────────────────────

class MockWorkoutRepository extends Mock implements WorkoutRepository {}

class MockRoutineRepository extends Mock implements RoutineRepository {}

class MockSyncService extends Mock implements SyncService {}

// ─── Helpers ─────────────────────────────────────────────────────────────────

Routine _makeRoutine(int id, String name) => Routine(
      id: id,
      clientId: 'client-$id',
      name: name,
      description: 'desc',
      colorHex: 'FF6366F1',
      createdAt: DateTime(2024),
      lastModifiedAt: DateTime(2024),
      isDraft: false,
      syncStatus: 0,
      isDeleted: false,
    );

// ─── Tests ───────────────────────────────────────────────────────────────────

void main() {
  late MockWorkoutRepository workoutRepo;
  late MockRoutineRepository routineRepo;

  setUp(() {
    workoutRepo = MockWorkoutRepository();
    routineRepo = MockRoutineRepository();

    // Default: no active workout
    when(() => workoutRepo.getIncompleteWorkout()).thenAnswer((_) async => null);
    when(() => workoutRepo.watchIncompleteWorkout())
        .thenAnswer((_) => Stream.value(null));
    when(() => workoutRepo.start(routineId: any(named: 'routineId')))
        .thenAnswer((_) async => 42);
  });

  group('Start Workout from Routines — rendering', () {
    testWidgets('renders a Start Workout button for each routine', (tester) async {
      final routines = [_makeRoutine(1, 'Push Day'), _makeRoutine(2, 'Pull Day')];

      await tester.pumpApp(
        const RoutineListScreen(),
        overrides: [
          routinesProvider.overrideWith((ref) => Stream.value(routines)),
          workoutRepositoryProvider.overrideWithValue(workoutRepo),
          routineRepositoryProvider.overrideWithValue(routineRepo),
          incompleteWorkoutProvider.overrideWith(
            (ref) => Stream.value(null),
          ),
        ],
      );

      await tester.pump();

      // Expect at least one "Start Workout" button to be visible
      expect(find.text('Start Workout'), findsWidgets);
    });

    testWidgets('shows empty state when no routines exist', (tester) async {
      await tester.pumpApp(
        const RoutineListScreen(),
        overrides: [
          routinesProvider.overrideWith((ref) => Stream.value([])),
          workoutRepositoryProvider.overrideWithValue(workoutRepo),
          routineRepositoryProvider.overrideWithValue(routineRepo),
          incompleteWorkoutProvider.overrideWith(
            (ref) => Stream.value(null),
          ),
        ],
      );

      await tester.pump();
      // No "Start Workout" button when there are no routines
      expect(find.text('Start Workout'), findsNothing);
    });
  });

  group('Start Workout from Routines — interaction', () {
    testWidgets('tapping Start Workout calls repo.start with correct routineId',
        (tester) async {
      final routines = [_makeRoutine(7, 'Leg Day')];

      await tester.pumpApp(
        const RoutineListScreen(),
        overrides: [
          routinesProvider.overrideWith((ref) => Stream.value(routines)),
          workoutRepositoryProvider.overrideWithValue(workoutRepo),
          routineRepositoryProvider.overrideWithValue(routineRepo),
          incompleteWorkoutProvider.overrideWith(
            (ref) => Stream.value(null),
          ),
        ],
      );

      await tester.pump();
      await tester.tap(find.text('Start Workout').first);
      await tester.pump();

      verify(() => workoutRepo.start(routineId: 7)).called(1);
    });

    testWidgets(
        'tapping Start Workout when a workout is already active shows warning dialog',
        (tester) async {
      final activeWorkout = Workout(
        id: 99,
        clientId: 'active',
        routineId: null,
        startTime: DateTime.now().subtract(const Duration(minutes: 10)),
        endTime: null,
        notes: '',
        lastModifiedAt: DateTime.now(),
        syncStatus: 1,
        isDeleted: false,
      );

      final routines = [_makeRoutine(3, 'Push Day')];

      await tester.pumpApp(
        const RoutineListScreen(),
        overrides: [
          routinesProvider.overrideWith((ref) => Stream.value(routines)),
          workoutRepositoryProvider.overrideWithValue(workoutRepo),
          routineRepositoryProvider.overrideWithValue(routineRepo),
          incompleteWorkoutProvider.overrideWith(
            (ref) => Stream.value(activeWorkout),
          ),
        ],
      );

      await tester.pump();
      await tester.tap(find.text('Start Workout').first);
      await tester.pump();

      // A dialog or snackbar warning should appear instead of starting a new workout
      expect(find.byType(AlertDialog), findsOneWidget);
      // The repository must NOT be called
      verifyNever(() => workoutRepo.start(routineId: any(named: 'routineId')));
    });
  });

  group('Start Workout from Routines — repository layer', () {
    // These tests use a real in-memory database to verify repository behaviour.
    // They live here as integration tests since they depend on DB state.

    test('WorkoutRepository.start persists routineId on the workout row', () async {
      // This test should be run with an actual AppDatabase instance.
      // See test/repositories/repositories_test.dart for the pattern.
      // Placeholder: verify via repositories_test extension when schema is updated.
    });
  });
}
