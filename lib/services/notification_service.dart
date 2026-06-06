import 'package:flutter/foundation.dart' show debugPrint;
import 'package:flutter/services.dart' show PlatformException;
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest_all.dart' as tz_data;

import '../utils/workout_duration.dart';

abstract class NotificationService {
  Future<void> initialize();
  Future<void> scheduleWorkoutOverdueAlert(
    int workoutId, {
    required DateTime startTime,
  });
  Future<void> cancelWorkoutAlert(int workoutId);
}

/// No-op implementation used when notifications are unavailable (e.g. tests).
class NullNotificationService implements NotificationService {
  const NullNotificationService();

  @override
  Future<void> initialize() async {}

  @override
  Future<void> scheduleWorkoutOverdueAlert(
    int workoutId, {
    required DateTime startTime,
  }) async {}

  @override
  Future<void> cancelWorkoutAlert(int workoutId) async {}
}

/// Real implementation backed by flutter_local_notifications.
class LocalNotificationService implements NotificationService {
  static const _channelId = 'workout_alerts';
  static const _channelName = 'Workout Alerts';

  final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();

  bool _recoveryAttempted = false;

  @override
  Future<void> initialize() async {
    tz_data.initializeTimeZones();

    const android = AndroidInitializationSettings('@mipmap/launcher_icon');
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
          AndroidFlutterLocalNotificationsPlugin
        >()
        ?.requestNotificationsPermission();

    await _plugin
        .resolvePlatformSpecificImplementation<
          IOSFlutterLocalNotificationsPlugin
        >()
        ?.requestPermissions(alert: true, sound: true);
  }

  @override
  Future<void> scheduleWorkoutOverdueAlert(
    int workoutId, {
    required DateTime startTime,
  }) async {
    final fireAt = startTime.add(kWorkoutMaxDuration);
    if (fireAt.isBefore(DateTime.now())) return;

    final tzFire = tz.TZDateTime.from(fireAt, tz.local);
    final details = NotificationDetails(
      android: AndroidNotificationDetails(
        _channelId,
        _channelName,
        importance: Importance.high,
        priority: Priority.high,
      ),
      iOS: const DarwinNotificationDetails(),
    );

    try {
      await _plugin.zonedSchedule(
        workoutId,
        'Workout time limit reached',
        'Your workout hit the ${kWorkoutMaxDuration.inMinutes}-minute limit and was saved automatically.',
        tzFire,
        details,
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
        uiLocalNotificationDateInterpretation:
            UILocalNotificationDateInterpretation.absoluteTime,
        payload: workoutId.toString(),
      );
    } on PlatformException catch (e, st) {
      debugPrint('zonedSchedule failed: ${e.message}\n$st');
      // Known issue: corrupt scheduled-notification state in SharedPreferences
      // causes "Missing type parameter" on Android. Try a one-shot reset.
      if (_recoveryAttempted) return;
      _recoveryAttempted = true;
      try {
        await _plugin.cancelAll();
        await _plugin.zonedSchedule(
          workoutId,
          'Workout time limit reached',
          'Your workout hit the ${kWorkoutMaxDuration.inMinutes}-minute limit and was saved automatically.',
          tzFire,
          details,
          androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
          uiLocalNotificationDateInterpretation:
              UILocalNotificationDateInterpretation.absoluteTime,
          payload: workoutId.toString(),
        );
      } catch (e2, st2) {
        debugPrint('zonedSchedule recovery failed: $e2\n$st2');
      }
    }
  }

  @override
  Future<void> cancelWorkoutAlert(int workoutId) async {
    try {
      await _plugin.cancel(workoutId);
    } on PlatformException catch (e, st) {
      debugPrint('cancel notification failed: ${e.message}\n$st');
    }
  }
}
