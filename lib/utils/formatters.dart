/// Formatting helpers for weights, durations, and dates.
class Formatters {
  /// Format weight value with unit suffix. E.g. "100 kg" or "225 lbs".
  static String weight(double value, {bool useLbs = false}) {
    final unit = useLbs ? 'lbs' : 'kg';
    // Show decimal only if fractional part is non-zero
    if (value == value.roundToDouble()) {
      return '${value.toInt()} $unit';
    }
    return '${value.toStringAsFixed(1)} $unit';
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

  /// Format total volume (weight × reps summed). E.g. "12,450 kg".
  static String volume(double totalVolume, {bool useLbs = false}) {
    final unit = useLbs ? 'lbs' : 'kg';
    if (totalVolume >= 1000) {
      // Add comma separator
      final formatted = totalVolume.toInt().toString().replaceAllMapped(
        RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
        (m) => '${m[1]},',
      );
      return '$formatted $unit';
    }
    return '${totalVolume.toInt()} $unit';
  }

  /// Format rest timer countdown. E.g. "1:30" for 90 seconds.
  static String restTimer(int totalSeconds) {
    final minutes = totalSeconds ~/ 60;
    final seconds = totalSeconds % 60;
    return '$minutes:${seconds.toString().padLeft(2, '0')}';
  }
}
