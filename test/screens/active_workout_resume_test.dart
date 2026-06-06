import 'package:flutter_test/flutter_test.dart';
import 'package:gymapp/database/app_database.dart';
import 'package:gymapp/providers/providers.dart';
import 'package:gymapp/screens/app_shell.dart';
import 'package:gymapp/services/workout_overdue_service.dart';
import 'package:gymapp/services/sync_service.dart';
import 'package:mocktail/mocktail.dart';
import '../helpers/pump_app.dart';

class MockSyncService extends Mock implements SyncService {}

class MockWorkoutOverdueService extends Mock implements WorkoutOverdueService {}

Workout _sampleWorkout({required DateTime startTime, int id = 99}) => Workout(
      id: id,
      clientId: 'xyz',
      routineId: null,
      startTime: startTime,
      endTime: null,
      notes: '',
      lastModifiedAt: DateTime.now(),
      syncStatus: 1,
      isDeleted: false,
    );

void main() {
  setUpAll(() {
    registerFallbackValue(_sampleWorkout(startTime: DateTime.now()));
  });

  testWidgets('AppShell shows resume dialog when incomplete workout exists',
      (tester) async {
    final mockSync = MockSyncService();
    final mockOverdue = MockWorkoutOverdueService();
    when(() => mockOverdue.ensureScheduled(any())).thenAnswer((_) async => false);
    when(() => mockOverdue.startWatching(any(), any())).thenReturn(null);
    when(() => mockOverdue.stopWatching()).thenReturn(null);

    final incompleteWorkout = _sampleWorkout(
      startTime: DateTime.now().subtract(const Duration(minutes: 30)),
    );

    await tester.pumpApp(
      const AppShell(),
      overrides: [
        syncServiceProvider.overrideWithValue(mockSync),
        workoutOverdueServiceProvider.overrideWithValue(mockOverdue),
        routinesProvider.overrideWith((ref) => Stream.value([])),
        exercisesProvider.overrideWith((ref) => Stream.value([])),
        workoutsThisWeekProvider.overrideWith((ref) => Stream.value(0)),
        totalWorkoutsProvider.overrideWith((ref) => Stream.value(0)),
        isAuthenticatedProvider.overrideWith((ref) => true),
        authStateProvider.overrideWith((ref) => const Stream.empty()),
        incompleteWorkoutProvider.overrideWith(
          (ref) => Stream.value(incompleteWorkout),
        ),
      ],
    );

    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));
    await tester.pump(const Duration(milliseconds: 100));

    expect(find.text('Incomplete Workout'), findsOneWidget);
    expect(find.text('Resume'), findsOneWidget);
    expect(find.text('Discard'), findsOneWidget);
  });

  testWidgets('AppShell auto-finishes overdue workout without resume dialog',
      (tester) async {
    final mockSync = MockSyncService();
    final mockOverdue = MockWorkoutOverdueService();
    when(() => mockOverdue.ensureScheduled(any())).thenAnswer((_) async => true);
    when(() => mockOverdue.stopWatching()).thenReturn(null);

    final overdueWorkout = _sampleWorkout(
      startTime: DateTime.now().subtract(const Duration(minutes: 91)),
    );

    await tester.pumpApp(
      const AppShell(),
      overrides: [
        syncServiceProvider.overrideWithValue(mockSync),
        workoutOverdueServiceProvider.overrideWithValue(mockOverdue),
        routinesProvider.overrideWith((ref) => Stream.value([])),
        exercisesProvider.overrideWith((ref) => Stream.value([])),
        workoutsThisWeekProvider.overrideWith((ref) => Stream.value(0)),
        totalWorkoutsProvider.overrideWith((ref) => Stream.value(0)),
        isAuthenticatedProvider.overrideWith((ref) => true),
        authStateProvider.overrideWith((ref) => const Stream.empty()),
        incompleteWorkoutProvider.overrideWith(
          (ref) => Stream.value(overdueWorkout),
        ),
      ],
    );

    await tester.pump();
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));

    expect(find.text('Incomplete Workout'), findsNothing);
    expect(
      find.text('Workout auto-finished after 90 minutes'),
      findsOneWidget,
    );
    verify(() => mockOverdue.ensureScheduled(overdueWorkout)).called(1);
    verifyNever(() => mockOverdue.startWatching(any(), any()));
  });
}
