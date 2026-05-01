import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gymapp/screens/routines/routine_list_screen.dart';
import 'package:gymapp/screens/routines/routine_edit_screen.dart';
import 'package:gymapp/providers/providers.dart';
import 'package:gymapp/database/app_database.dart';
import 'package:gymapp/repositories/repositories.dart';
import 'package:gymapp/services/sync_service.dart';
import '../helpers/pump_app.dart';

class FakeSyncService extends SyncService {
  FakeSyncService(super.db);
  @override
  Future<bool> pushExercise(Exercise e) async => true;
  @override
  Future<bool> pushRoutine(Routine r) async => true;
  @override
  Future<bool> pushRoutineExercise(RoutineExerciseEntry re) async => true;
  @override
  Future<bool> pushWorkout(Workout w) async => true;
  @override
  Future<bool> pushLoggedSet(LoggedSet s) async => true;
  @override
  Future<void> syncAll() async {}
}

void main() {
  testWidgets('RoutineListScreen shows empty state', (tester) async {
    await tester.pumpApp(
      const Scaffold(body: RoutineListScreen()),
      overrides: [routinesProvider.overrideWith((ref) => Stream.value([]))],
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

  testWidgets('RoutineEditScreen hides add actions when keyboard is open', (
    tester,
  ) async {
    final db = AppDatabase(NativeDatabase.memory());
    final sync = FakeSyncService(db);
    final routineRepo = RoutineRepository(db, sync);
    final routineId = await routineRepo.create(name: 'Push Day');

    await tester.pumpApp(
      MediaQuery(
        data: const MediaQueryData(
          size: Size(390, 844),
          viewInsets: EdgeInsets.only(bottom: 320),
        ),
        child: RoutineEditScreen(routineId: routineId),
      ),
      overrides: [
        databaseProvider.overrideWithValue(db),
        syncServiceProvider.overrideWithValue(sync),
        routineRepositoryProvider.overrideWithValue(routineRepo),
      ],
    );
    await tester.pumpAndSettle();

    expect(find.text('Exercises'), findsOneWidget);
    expect(find.text('Section'), findsNothing);
    expect(find.text('Add'), findsNothing);

    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump(Duration.zero);
    await db.close();
  });
}
