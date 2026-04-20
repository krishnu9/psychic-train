abstract class NotificationService {
  Future<void> initialize();
  Future<void> scheduleWorkoutOverdueAlert(int workoutId,
      {required DateTime startTime});
  Future<void> cancelWorkoutAlert(int workoutId);
}

/// No-op implementation used until flutter_local_notifications is wired in.
class NullNotificationService implements NotificationService {
  const NullNotificationService();

  @override
  Future<void> initialize() async {}

  @override
  Future<void> scheduleWorkoutOverdueAlert(int workoutId,
      {required DateTime startTime}) async {}

  @override
  Future<void> cancelWorkoutAlert(int workoutId) async {}
}
