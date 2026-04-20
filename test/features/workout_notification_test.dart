import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gymapp/database/app_database.dart';
import 'package:gymapp/repositories/repositories.dart';
import 'package:gymapp/services/notification_service.dart';
import 'package:gymapp/services/sync_service.dart';
import 'package:mocktail/mocktail.dart';

// ─── Mocks ───────────────────────────────────────────────────────────────────

class MockNotificationService extends Mock implements NotificationService {}

class FakeSyncService extends SyncService {
  FakeSyncService(super.db);
  @override Future<bool> pushExercise(Exercise e) async => true;
  @override Future<bool> pushRoutine(Routine r) async => true;
  @override Future<bool> pushRoutineExercise(RoutineExerciseEntry re) async => true;
  @override Future<bool> pushWorkout(Workout w) async => true;
  @override Future<bool> pushLoggedSet(LoggedSet s) async => true;
  @override Future<void> syncAll() async {}
}

// ─── Helpers ─────────────────────────────────────────────────────────────────

/// Returns a [WorkoutRepository] wired to an in-memory DB and the given
/// [NotificationService] so we can verify scheduling calls.
WorkoutRepository _makeRepo(
  AppDatabase db,
  FakeSyncService sync,
  NotificationService notifications,
) =>
    WorkoutRepository(db, sync, notificationService: notifications);

// ─── Tests ───────────────────────────────────────────────────────────────────

void main() {
  late AppDatabase db;
  late FakeSyncService sync;
  late MockNotificationService notifications;
  late WorkoutRepository workoutRepo;

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

    workoutRepo = _makeRepo(db, sync, notifications);
  });

  tearDown(() async => db.close());

  group('Workout 90-minute notification — scheduling', () {
    test('scheduleWorkoutOverdueAlert is called when a workout starts', () async {
      final workoutId = await workoutRepo.start();

      verify(() => notifications.scheduleWorkoutOverdueAlert(
            workoutId,
            startTime: any(named: 'startTime'),
          )).called(1);
    });

    test('notification is scheduled with the workoutId as the notification ID',
        () async {
      int? capturedId;
      when(() => notifications.scheduleWorkoutOverdueAlert(
            any(),
            startTime: any(named: 'startTime'),
          )).thenAnswer((inv) async {
        capturedId = inv.positionalArguments.first as int;
      });

      final workoutId = await workoutRepo.start();

      expect(capturedId, workoutId);
    });

    test('scheduleWorkoutOverdueAlert is called with startTime close to now',
        () async {
      DateTime? capturedStart;
      when(() => notifications.scheduleWorkoutOverdueAlert(
            any(),
            startTime: any(named: 'startTime'),
          )).thenAnswer((inv) async {
        capturedStart = inv.namedArguments[#startTime] as DateTime;
      });

      final before = DateTime.now();
      await workoutRepo.start();
      final after = DateTime.now();

      expect(capturedStart, isNotNull);
      // startTime should be within the test execution window
      expect(
        capturedStart!.isAfter(before.subtract(const Duration(seconds: 1))),
        isTrue,
      );
      expect(capturedStart!.isBefore(after.add(const Duration(seconds: 1))), isTrue);
    });
  });

  group('Workout 90-minute notification — cancellation', () {
    test('cancelWorkoutAlert is called when a workout is finished', () async {
      final workoutId = await workoutRepo.start();
      await workoutRepo.finish(workoutId);

      verify(() => notifications.cancelWorkoutAlert(workoutId)).called(1);
    });

    test('cancelWorkoutAlert is called with the correct workoutId', () async {
      int? cancelledId;
      when(() => notifications.cancelWorkoutAlert(any()))
          .thenAnswer((inv) async {
        cancelledId = inv.positionalArguments.first as int;
      });

      final workoutId = await workoutRepo.start();
      await workoutRepo.finish(workoutId);

      expect(cancelledId, workoutId);
    });

    test('cancelWorkoutAlert is called when a workout is deleted (discarded)',
        () async {
      final workoutId = await workoutRepo.start();
      await workoutRepo.delete(workoutId);

      verify(() => notifications.cancelWorkoutAlert(workoutId)).called(1);
    });
  });

  group('NotificationService — contract', () {
    // These tests document the expected API surface of NotificationService.
    // They pass because MockNotificationService satisfies the interface.

    test('MockNotificationService responds to scheduleWorkoutOverdueAlert',
        () async {
      final svc = MockNotificationService();
      when(() => svc.scheduleWorkoutOverdueAlert(1, startTime: any(named: 'startTime')))
          .thenAnswer((_) async {});

      await expectLater(
        svc.scheduleWorkoutOverdueAlert(1, startTime: DateTime.now()),
        completes,
      );
    });

    test('MockNotificationService responds to cancelWorkoutAlert', () async {
      final svc = MockNotificationService();
      when(() => svc.cancelWorkoutAlert(1)).thenAnswer((_) async {});

      await expectLater(svc.cancelWorkoutAlert(1), completes);
    });
  });
}
