import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest_all.dart' as tz_data;

abstract class NotificationService {
  Future<void> initialize();
  Future<void> scheduleWorkoutOverdueAlert(int workoutId,
      {required DateTime startTime});
  Future<void> cancelWorkoutAlert(int workoutId);
}

/// No-op implementation used when notifications are unavailable (e.g. tests).
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

/// Real implementation backed by flutter_local_notifications.
class LocalNotificationService implements NotificationService {
  static const _channelId = 'workout_alerts';
  static const _channelName = 'Workout Alerts';
  static const _overdueMinutes = 90;

  final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();

  @override
  Future<void> initialize() async {
    tz_data.initializeTimeZones();

    const android = AndroidInitializationSettings('@mipmap/ic_launcher');
    const ios = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: false,
      requestSoundPermission: true,
    );
    await _plugin.initialize(
      const InitializationSettings(android: android, iOS: ios),
    );

    // Request permissions on Android 13+
    await _plugin
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.requestNotificationsPermission();
  }

  @override
  Future<void> scheduleWorkoutOverdueAlert(int workoutId,
      {required DateTime startTime}) async {
    final fireAt = startTime.add(const Duration(minutes: _overdueMinutes));
    if (fireAt.isBefore(DateTime.now())) return;

    final tzFire = tz.TZDateTime.from(fireAt, tz.local);

    await _plugin.zonedSchedule(
      workoutId,
      'Still at it? 💪',
      'Your workout has been running for $_overdueMinutes minutes. Time to wrap up!',
      tzFire,
      NotificationDetails(
        android: AndroidNotificationDetails(
          _channelId,
          _channelName,
          importance: Importance.high,
          priority: Priority.high,
        ),
        iOS: const DarwinNotificationDetails(),
      ),
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
    );
  }

  @override
  Future<void> cancelWorkoutAlert(int workoutId) async {
    await _plugin.cancel(workoutId);
  }
}
