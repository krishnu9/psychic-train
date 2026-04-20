import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gymapp/screens/app_shell.dart';
import 'package:gymapp/providers/providers.dart';
import 'package:mocktail/mocktail.dart';
import 'package:gymapp/services/sync_service.dart';
import '../helpers/pump_app.dart';

class MockSyncService extends Mock implements SyncService {}

void main() {
  testWidgets('AppShell navigates between tabs', (tester) async {
    final mockSync = MockSyncService();
    // In AppShell, syncAll and syncDown might be called.
    when(() => mockSync.syncAll()).thenAnswer((_) async {});
    when(() => mockSync.syncDown()).thenAnswer((_) async {});

    await tester.pumpApp(
      const AppShell(),
      overrides: [
        routinesProvider.overrideWith((ref) => Stream.value([])),
        exercisesProvider.overrideWith((ref) => Stream.value([])),
        workoutsProvider.overrideWith((ref) => Stream.value([])),
        workoutsThisWeekProvider.overrideWith((ref) => Stream.value(0)),
        totalWorkoutsProvider.overrideWith((ref) => Stream.value(0)),
        isAuthenticatedProvider.overrideWith((ref) => true),
        authStateProvider.overrideWith((ref) => const Stream.empty()),
        syncServiceProvider.overrideWithValue(mockSync),
        incompleteWorkoutProvider.overrideWith((ref) => Stream.value(null)),
      ],
    );

    // Initial is Home
    await tester.pump();
    expect(find.text('TRACKER'), findsOneWidget);

    // Tap Exercises tab (icon-based nav bar, second icon is fitness_center)
    await tester.tap(find.byIcon(Icons.fitness_center_rounded));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));
    expect(find.text('Search exercises...'), findsOneWidget);
  });
}
