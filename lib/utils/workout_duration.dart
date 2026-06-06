const kWorkoutMaxDuration = Duration(minutes: 90);

bool isWorkoutOverdue(DateTime startTime) =>
    DateTime.now().difference(startTime) >= kWorkoutMaxDuration;

Duration workoutTimeRemaining(DateTime startTime) {
  final remaining = kWorkoutMaxDuration - DateTime.now().difference(startTime);
  return remaining.isNegative ? Duration.zero : remaining;
}
