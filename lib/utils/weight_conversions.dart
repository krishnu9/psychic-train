/// Weight unit conversion helpers. All storage is in kg; conversion happens
/// at the UI boundary only.
const double kgPerLb = 0.45359237;
const double lbsPerKg = 1 / kgPerLb; // 2.2046226218...

double kgToLbs(double kg) => kg * lbsPerKg;

double lbsToKg(double lbs) => lbs * kgPerLb;

/// Resolve the effective unit for a specific exercise context.
/// WorkoutExercise override beats RoutineExercise override beats global.
bool resolveUseLbs({
  bool? workoutExercise,
  bool? routineExercise,
  required bool global,
}) {
  if (workoutExercise != null) return workoutExercise;
  if (routineExercise != null) return routineExercise;
  return global;
}
