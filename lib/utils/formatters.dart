import 'package:intl/intl.dart';

import 'weight_conversions.dart';

/// Formatting helpers for weights, durations, and dates.
class Formatters {
  /// Format a [DateTime] in the device's local timezone using [pattern].
  static String dateTime(DateTime dt, String pattern) =>
      DateFormat(pattern).format(dt.toLocal());


  /// Format a weight value (stored in kg) with unit suffix.
  /// When `useLbs` is true, the value is converted from kg to lbs.
  static String weight(double kgValue, {bool useLbs = false}) {
    final display = useLbs ? kgToLbs(kgValue) : kgValue;
    final unit = useLbs ? 'lbs' : 'kg';
    if (display == display.roundToDouble()) {
      return '${display.toInt()} $unit';
    }
    return '${display.toStringAsFixed(1)} $unit';
  }

  /// Format a Duration as "HH:MM:SS" or "MM:SS" if under an hour.
  static String duration(Duration d) {
    if (d.isNegative) d = Duration.zero;
    final hours = d.inHours;
    final minutes = d.inMinutes.remainder(60);
    final seconds = d.inSeconds.remainder(60);

    if (hours > 0) {
      return '${hours.toString().padLeft(2, '0')}:'
          '${minutes.toString().padLeft(2, '0')}:'
          '${seconds.toString().padLeft(2, '0')}';
    }
    return '${minutes.toString().padLeft(2, '0')}:'
        '${seconds.toString().padLeft(2, '0')}';
  }

  /// Format total volume (weight × reps summed, in kg·reps).
  /// When `useLbs` is true, the volume is converted to lbs·reps.
  static String volume(double totalVolumeKg, {bool useLbs = false}) {
    final display = useLbs ? kgToLbs(totalVolumeKg) : totalVolumeKg;
    final unit = useLbs ? 'lbs' : 'kg';
    if (display >= 1000) {
      final formatted = display.toInt().toString().replaceAllMapped(
        RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
        (m) => '${m[1]},',
      );
      return '$formatted $unit';
    }
    return '${display.toInt()} $unit';
  }

  /// Format rest timer countdown. E.g. "1:30" for 90 seconds.
  static String restTimer(int totalSeconds) {
    final minutes = totalSeconds ~/ 60;
    final seconds = totalSeconds % 60;
    return '$minutes:${seconds.toString().padLeft(2, '0')}';
  }
}
