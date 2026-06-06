import 'dart:async';

import '../database/app_database.dart';
import '../repositories/repositories.dart';
import '../utils/workout_duration.dart';
import 'notification_service.dart';

/// Coordinates 90-minute workout limits: notification scheduling and auto-finish.
class WorkoutOverdueService {
  WorkoutOverdueService(this._workouts, this._notifications);

  final WorkoutRepository _workouts;
  final NotificationService _notifications;

  Timer? _watcher;

  /// If overdue, auto-finish. Otherwise (re)schedule the OS notification.
  /// Returns `true` when the workout was auto-finished.
  Future<bool> ensureScheduled(Workout workout) async {
    if (isWorkoutOverdue(workout.startTime)) {
      return checkAndFinish(workout);
    }
    await _notifications.scheduleWorkoutOverdueAlert(
      workout.id,
      startTime: workout.startTime,
    );
    return false;
  }

  /// Auto-finish when the workout has exceeded the max duration.
  /// Returns `true` when the workout was auto-finished.
  Future<bool> checkAndFinish(Workout workout) async {
    return _workouts.finishIfOverdue(
      workout.id,
      startTime: workout.startTime,
    );
  }

  /// While the app process is alive, finish exactly at the 90-minute mark.
  void startWatching(Workout workout, void Function() onFinished) {
    stopWatching();
    final remaining = workoutTimeRemaining(workout.startTime);
    if (remaining == Duration.zero) {
      unawaited(_finishAndNotify(workout, onFinished));
      return;
    }
    _watcher = Timer(remaining, () {
      unawaited(_finishAndNotify(workout, onFinished));
    });
  }

  void stopWatching() {
    _watcher?.cancel();
    _watcher = null;
  }

  Future<void> _finishAndNotify(
    Workout workout,
    void Function() onFinished,
  ) async {
    final finished = await checkAndFinish(workout);
    if (finished) onFinished();
  }
}
