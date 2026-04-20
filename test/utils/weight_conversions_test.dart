import 'package:flutter_test/flutter_test.dart';
import 'package:gymapp/utils/weight_conversions.dart';
import 'package:gymapp/utils/formatters.dart';

void main() {
  group('weight_conversions', () {
    test('kgToLbs uses the exact IAU factor', () {
      expect(kgToLbs(100).toStringAsFixed(2), '220.46');
      expect(kgToLbs(0), 0);
    });

    test('lbsToKg is the inverse of kgToLbs', () {
      for (final v in [0.0, 1.0, 42.5, 225.0, 1000.0]) {
        final roundTrip = lbsToKg(kgToLbs(v));
        expect((roundTrip - v).abs() < 1e-9, isTrue,
            reason: 'round-trip failed for $v → got $roundTrip');
      }
    });

    test('resolveUseLbs prefers workoutExercise then routineExercise then global', () {
      expect(
          resolveUseLbs(
              workoutExercise: true, routineExercise: false, global: false),
          isTrue);
      expect(
          resolveUseLbs(
              workoutExercise: null, routineExercise: true, global: false),
          isTrue);
      expect(resolveUseLbs(global: true), isTrue);
      expect(resolveUseLbs(global: false), isFalse);
    });
  });

  group('Formatters.weight with useLbs', () {
    test('100 kg → "220.5 lbs" (not "100 lbs")', () {
      // Regression guard for the previous bug where the formatter
      // only swapped the unit label without converting the value.
      expect(Formatters.weight(100, useLbs: true), '220.5 lbs');
    });

    test('kg unchanged when useLbs is false', () {
      expect(Formatters.weight(100), '100 kg');
      expect(Formatters.weight(42.5), '42.5 kg');
    });

    test('volume converts kg·reps → lbs·reps', () {
      expect(Formatters.volume(1000, useLbs: true), '2,204 lbs');
      expect(Formatters.volume(500), '500 kg');
    });
  });
}
