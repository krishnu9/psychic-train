/// One-Rep Max (1RM) estimator using scientifically validated formulas.
class OneRmCalculator {
  /// Brzycki formula – optimal for 1-7 reps.
  /// 1RM = w / (1.0278 − 0.0278 × r)
  static double brzycki(double weight, int reps) {
    if (reps <= 0) return 0;
    if (reps == 1) return weight;
    return weight / (1.0278 - 0.0278 * reps);
  }

  /// Epley formula – optimal for 8-15 reps.
  /// 1RM = w × (1 + r / 30)
  static double epley(double weight, int reps) {
    if (reps <= 0) return 0;
    if (reps == 1) return weight;
    return weight * (1 + reps / 30.0);
  }

  /// Averaged estimate using both formulas for a more robust result.
  static double estimate(double weight, int reps) {
    if (reps <= 0) return 0;
    if (reps == 1) return weight;
    return (brzycki(weight, reps) + epley(weight, reps)) / 2.0;
  }

  /// Suggest weight for a target RPE given current estimated 1RM.
  /// Uses % of 1RM approximation from RPE chart.
  static double suggestWeight(double estimated1rm, int targetReps, double targetRpe) {
    // Approximate percentage of 1RM based on reps and RPE
    // RPE 10 = max effort, RPE 7 = 3 reps in reserve
    final repsInReserve = 10.0 - targetRpe;
    final effectiveReps = targetReps + repsInReserve;
    if (effectiveReps <= 0) return estimated1rm;
    // Use Brzycki inverse
    final percentage = 1.0278 - 0.0278 * effectiveReps;
    if (percentage <= 0) return 0;
    return estimated1rm * percentage;
  }
}
