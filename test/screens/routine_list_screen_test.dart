import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gymapp/screens/routines/routine_list_screen.dart';
import 'package:gymapp/providers/providers.dart';
import 'package:gymapp/database/app_database.dart';
import '../helpers/pump_app.dart';

void main() {
  testWidgets('RoutineListScreen shows empty state', (tester) async {
    await tester.pumpApp(
      const Scaffold(body: RoutineListScreen()),
      overrides: [
        routinesProvider.overrideWith((ref) => Stream.value([])),
      ],
    );

    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));

    expect(find.text('No routines yet'), findsOneWidget);
  });

  testWidgets('RoutineListScreen shows routines', (tester) async {
    final fakeRoutine = Routine(
      id: 1,
      clientId: 'a',
      name: 'Push Day',
      description: 'Test description',
      colorHex: 'FF6366F1',
      createdAt: DateTime.now(),
      lastModifiedAt: DateTime.now(),
      isDraft: false,
      syncStatus: 0,
      isDeleted: false,
    );

    await tester.pumpApp(
      const Scaffold(body: RoutineListScreen()),
      overrides: [
        routinesProvider.overrideWith((ref) => Stream.value([fakeRoutine])),
      ],
    );

    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));

    expect(find.text('Push Day'), findsOneWidget);
    expect(find.text('Test description'), findsOneWidget);
  });
}
