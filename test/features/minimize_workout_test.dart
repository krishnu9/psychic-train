import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gymapp/database/app_database.dart';
import 'package:gymapp/providers/providers.dart';
import 'package:gymapp/repositories/repositories.dart';
import 'package:gymapp/screens/app_shell.dart';
import 'package:gymapp/services/sync_service.dart';
import 'package:mocktail/mocktail.dart';
import '../helpers/pump_app.dart';

// ─── Mocks ───────────────────────────────────────────────────────────────────

class MockSyncService extends Mock implements SyncService {}

class MockWorkoutRepository extends Mock implements WorkoutRepository {}

// ─── Helpers ─────────────────────────────────────────────────────────────────

Workout _activeWorkout() => Workout(
  id: 42,
  clientId: 'active-workout',
  routineId: null,
  startTime: DateTime.now().subtract(const Duration(minutes: 20)),
  endTime: null,
  notes: '',
  lastModifiedAt: DateTime.now(),
  syncStatus: 1,
  isDeleted: false,
);

List<Override> _baseOverrides({
  required Workout? activeWorkout,
  required bool minimized,
}) => [
  routinesProvider.overrideWith((ref) => Stream.value([])),
  exercisesProvider.overrideWith((ref) => Stream.value([])),
  workoutsThisWeekProvider.overrideWith((ref) => Stream.value(0)),
  totalWorkoutsProvider.overrideWith((ref) => Stream.value(0)),
  isAuthenticatedProvider.overrideWith((ref) => true),
  authStateProvider.overrideWith((ref) => const Stream.empty()),
  syncServiceProvider.overrideWithValue(MockSyncService()),
  incompleteWorkoutProvider.overrideWith((ref) => Stream.value(activeWorkout)),
  workoutMinimizedProvider.overrideWith((ref) => minimized),
];

// ─── Provider unit tests ──────────────────────────────────────────────────────

void main() {
  group('workoutMinimizedProvider', () {
    test('defaults to false', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      expect(container.read(workoutMinimizedProvider), isFalse);
    });

    test('can be set to true', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      container.read(workoutMinimizedProvider.notifier).state = true;
      expect(container.read(workoutMinimizedProvider), isTrue);
    });

    test('resets to false when set back', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      container.read(workoutMinimizedProvider.notifier).state = true;
      container.read(workoutMinimizedProvider.notifier).state = false;
      expect(container.read(workoutMinimizedProvider), isFalse);
    });
  });

  // ── Widget tests: minimized bar visibility ────────────────────────────────

  group('AppShell — minimized workout bar', () {
    testWidgets('minimized bar is hidden when workout is not minimized', (
      tester,
    ) async {
      await tester.pumpApp(
        const AppShell(),
        overrides: _baseOverrides(
          activeWorkout: _activeWorkout(),
          minimized: false,
        ),
      );

      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      expect(find.byKey(const Key('minimized_workout_bar')), findsNothing);
    });

    testWidgets('minimized bar appears when workout is minimized', (
      tester,
    ) async {
      await tester.pumpApp(
        const AppShell(),
        overrides: _baseOverrides(
          activeWorkout: _activeWorkout(),
          minimized: true,
        ),
      );

      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      expect(find.byKey(const Key('minimized_workout_bar')), findsOneWidget);
    });

    testWidgets('minimized bar is docked above the bottom nav', (tester) async {
      await tester.pumpApp(
        const AppShell(),
        overrides: _baseOverrides(
          activeWorkout: _activeWorkout(),
          minimized: true,
        ),
      );

      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      final barTop = tester
          .getTopLeft(find.byKey(const Key('minimized_workout_bar')))
          .dy;
      final navTop = tester
          .getTopLeft(find.byKey(const Key('floating_nav_bar')))
          .dy;

      expect(barTop, lessThan(navTop));
    });

    testWidgets('minimized bar is hidden when there is no active workout', (
      tester,
    ) async {
      await tester.pumpApp(
        const AppShell(),
        overrides: _baseOverrides(activeWorkout: null, minimized: true),
      );

      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      // Even if minimized=true, no bar without an active workout
      expect(find.byKey(const Key('minimized_workout_bar')), findsNothing);
    });

    testWidgets(
      'tapping minimized bar navigates to active workout and hides the bar',
      (tester) async {
        final mockRepo = MockWorkoutRepository();
        when(
          () => mockRepo.watchWorkoutExercises(any()),
        ).thenAnswer((_) => Stream.value([]));
        when(
          () => mockRepo.watchSets(any()),
        ).thenAnswer((_) => Stream.value([]));
        when(() => mockRepo.getById(any())).thenAnswer((_) async => null);
        when(() => mockRepo.getSets(any())).thenAnswer((_) async => []);
        when(
          () => mockRepo.getWorkoutExercises(any()),
        ).thenAnswer((_) async => []);

        await tester.pumpApp(
          const AppShell(),
          overrides: [
            ..._baseOverrides(activeWorkout: _activeWorkout(), minimized: true),
            workoutRepositoryProvider.overrideWithValue(mockRepo),
            workoutsProvider.overrideWith((ref) => Stream.value([])),
          ],
        );

        await tester.pump();
        await tester.pump(const Duration(milliseconds: 100));

        await tester.tap(find.byKey(const Key('minimized_workout_bar')));
        await tester.pumpAndSettle();

        // After navigation the bar should be gone (minimized state resets to false)
        expect(find.byKey(const Key('minimized_workout_bar')), findsNothing);
      },
    );

    testWidgets('minimized bar disappears when workout is finished', (
      tester,
    ) async {
      final workoutController = StreamController<Workout?>.broadcast();
      workoutController.add(_activeWorkout());

      await tester.pumpApp(
        const AppShell(),
        overrides: [
          routinesProvider.overrideWith((ref) => Stream.value([])),
          exercisesProvider.overrideWith((ref) => Stream.value([])),
          workoutsThisWeekProvider.overrideWith((ref) => Stream.value(0)),
          totalWorkoutsProvider.overrideWith((ref) => Stream.value(0)),
          isAuthenticatedProvider.overrideWith((ref) => true),
          authStateProvider.overrideWith((ref) => const Stream.empty()),
          syncServiceProvider.overrideWithValue(MockSyncService()),
          incompleteWorkoutProvider.overrideWith(
            (ref) => workoutController.stream,
          ),
          workoutMinimizedProvider.overrideWith((ref) => true),
        ],
      );

      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));
      expect(find.byKey(const Key('minimized_workout_bar')), findsOneWidget);

      // Workout finishes → incompleteWorkoutProvider emits null
      workoutController.add(null);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      expect(find.byKey(const Key('minimized_workout_bar')), findsNothing);

      await workoutController.close();
    });
  });
}
