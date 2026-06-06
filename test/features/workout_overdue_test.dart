import 'package:drift/drift.dart' show Value;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gymapp/database/app_database.dart';
import 'package:gymapp/repositories/repositories.dart';
import 'package:gymapp/services/notification_service.dart';
import 'package:gymapp/services/sync_service.dart';
import 'package:gymapp/services/workout_overdue_service.dart';
import 'package:mocktail/mocktail.dart';

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

WorkoutRepository _makeRepo(
  AppDatabase db,
  FakeSyncService sync,
  NotificationService notifications,
) =>
    WorkoutRepository(db, sync, notificationService: notifications);

void main() {
  late AppDatabase db;
  late FakeSyncService sync;
  late MockNotificationService notifications;
  late WorkoutRepository workoutRepo;
  late WorkoutOverdueService overdueService;

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
    overdueService = WorkoutOverdueService(workoutRepo, notifications);
  });

  tearDown(() async {
    overdueService.stopWatching();
    await db.close();
  });

  Future<Workout> _insertIncompleteWorkout({required DateTime startTime}) async {
    final id = await db.insertWorkout(
      WorkoutsCompanion(startTime: Value(startTime)),
    );
    final workout = await workoutRepo.getById(id);
    return workout!;
  }

  group('WorkoutRepository.finishIfOverdue', () {
    test('finishes workout when startTime is 91 minutes ago', () async {
      final workout = await _insertIncompleteWorkout(
        startTime: DateTime.now().subtract(const Duration(minutes: 91)),
      );

      final finished = await workoutRepo.finishIfOverdue(
        workout.id,
        startTime: workout.startTime,
      );

      expect(finished, isTrue);
      final updated = await workoutRepo.getById(workout.id);
      expect(updated!.endTime, isNotNull);
      expect(updated.notes, 'Auto-finished after 90 minutes');
      verify(() => notifications.cancelWorkoutAlert(workout.id)).called(1);
    });

    test('does not finish workout when startTime is 30 minutes ago', () async {
      final workout = await _insertIncompleteWorkout(
        startTime: DateTime.now().subtract(const Duration(minutes: 30)),
      );

      final finished = await workoutRepo.finishIfOverdue(
        workout.id,
        startTime: workout.startTime,
      );

      expect(finished, isFalse);
      final updated = await workoutRepo.getById(workout.id);
      expect(updated!.endTime, isNull);
      verifyNever(() => notifications.cancelWorkoutAlert(any()));
    });
  });

  group('WorkoutOverdueService.ensureScheduled', () {
    test('auto-finishes instead of scheduling when overdue', () async {
      final workout = await _insertIncompleteWorkout(
        startTime: DateTime.now().subtract(const Duration(minutes: 91)),
      );

      final autoFinished = await overdueService.ensureScheduled(workout);

      expect(autoFinished, isTrue);
      verifyNever(() => notifications.scheduleWorkoutOverdueAlert(
            any(),
            startTime: any(named: 'startTime'),
          ));
      verify(() => notifications.cancelWorkoutAlert(workout.id)).called(1);
    });

    test('schedules notification when workout is still within limit', () async {
      final workout = await _insertIncompleteWorkout(
        startTime: DateTime.now().subtract(const Duration(minutes: 30)),
      );

      final autoFinished = await overdueService.ensureScheduled(workout);

      expect(autoFinished, isFalse);
      verify(() => notifications.scheduleWorkoutOverdueAlert(
            workout.id,
            startTime: workout.startTime,
          )).called(1);
    });
  });

  group('WorkoutOverdueService.startWatching', () {
    test('calls onFinished when timer fires at max duration', () async {
      final workout = await _insertIncompleteWorkout(
        startTime: DateTime.now().subtract(const Duration(minutes: 89, seconds: 59)),
      );

      var finished = false;
      overdueService.startWatching(workout, () => finished = true);

      await Future<void>.delayed(const Duration(seconds: 2));

      expect(finished, isTrue);
      final updated = await workoutRepo.getById(workout.id);
      expect(updated!.endTime, isNotNull);
    });
  });
}
