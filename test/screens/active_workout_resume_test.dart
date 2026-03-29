import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gymapp/screens/app_shell.dart';
import 'package:gymapp/providers/providers.dart';
import 'package:gymapp/database/app_database.dart';
import 'package:gymapp/repositories/repositories.dart';
import 'package:gymapp/services/sync_service.dart';
import 'package:mocktail/mocktail.dart';
import '../helpers/pump_app.dart';

class MockSyncService extends Mock implements SyncService {}
class MockWorkoutRepository extends Mock implements WorkoutRepository {}

void main() {
  testWidgets('AppShell shows resume dialog when incomplete workout exists',
      (tester) async {
    final mockSync = MockSyncService();
    final incompleteWorkout = Workout(
      id: 99,
      clientId: 'xyz',
      routineId: null,
      startTime: DateTime.now().subtract(const Duration(minutes: 30)),
      endTime: null,
      notes: '',
      lastModifiedAt: DateTime.now(),
      syncStatus: 1,
      isDeleted: false,
    );

    await tester.pumpApp(
      const AppShell(),
      overrides: [
        routinesProvider.overrideWith((ref) => Stream.value([])),
        exercisesProvider.overrideWith((ref) => Stream.value([])),
        workoutsThisWeekProvider.overrideWith((ref) => Stream.value(0)),
        totalWorkoutsProvider.overrideWith((ref) => Stream.value(0)),
        isAuthenticatedProvider.overrideWith((ref) => true),
        authStateProvider.overrideWith((ref) => const Stream.empty()),
        syncServiceProvider.overrideWithValue(mockSync),
        incompleteWorkoutProvider
            .overrideWith((ref) => Stream.value(incompleteWorkout)),
      ],
    );

    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));
    await tester.pump(const Duration(milliseconds: 100));

    expect(find.text('Incomplete Workout'), findsOneWidget);
    expect(find.text('Resume'), findsOneWidget);
    expect(find.text('Discard'), findsOneWidget);
  });
}
