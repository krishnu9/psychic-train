import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../database/app_database.dart';
import '../../providers/providers.dart';
import '../../theme/app_theme.dart';
import '../../utils/formatters.dart';

/// Breakdown of a single workout's sets, grouped by exercise.
/// Used both as an inline expandable panel in HistoryScreen and as the body
/// of [WorkoutDetailScreen].
class WorkoutDetails extends ConsumerWidget {
  final int workoutId;
  final bool useLbs;

  const WorkoutDetails({
    super.key,
    required this.workoutId,
    required this.useLbs,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final setsAsync = ref.watch(workoutSetsProvider(workoutId));
    final exercisesAsync = ref.watch(exercisesProvider);

    return setsAsync.when(
      data: (sets) {
        if (sets.isEmpty) {
          return const Padding(
            padding: EdgeInsets.all(16),
            child: Text('No sets logged',
                style: TextStyle(color: AppColors.textMuted)),
          );
        }

        final grouped = <int, List<LoggedSet>>{};
        for (final s in sets) {
          grouped.putIfAbsent(s.exerciseId, () => []).add(s);
        }

        final exerciseNames = exercisesAsync.when(
          data: (list) => {for (final e in list) e.id: e.name},
          loading: () => <int, String>{},
          error: (_, _) => <int, String>{},
        );

        double totalVolume = 0;
        for (final s in sets) {
          totalVolume += s.weight * s.reps;
        }

        return Column(
          children: [
            const Divider(height: 1),
            Padding(
              padding:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              child: Row(
                children: [
                  Text(
                    'Total Volume: ${Formatters.volume(totalVolume, useLbs: useLbs)}',
                    style: const TextStyle(
                      color: AppColors.primary,
                      fontWeight: FontWeight.w600,
                      fontSize: 13,
                    ),
                  ),
                  const Spacer(),
                  Text(
                    '${sets.length} sets',
                    style: const TextStyle(
                      color: AppColors.textMuted,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
            ...grouped.entries.map((entry) {
              final exName =
                  exerciseNames[entry.key] ?? 'Exercise #${entry.key}';
              final exSets = entry.value;
              return Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 10),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      exName,
                      style: const TextStyle(
                        color: AppColors.textSecondary,
                        fontWeight: FontWeight.w500,
                        fontSize: 13,
                      ),
                    ),
                    const SizedBox(height: 4),
                    ...exSets.map((s) => Padding(
                          padding: const EdgeInsets.only(left: 8),
                          child: Text(
                            'Set ${s.setNumber}: ${Formatters.weight(s.weight, useLbs: useLbs)} × ${s.reps} reps',
                            style: const TextStyle(
                              color: AppColors.textMuted,
                              fontSize: 12,
                            ),
                          ),
                        )),
                  ],
                ),
              );
            }),
            const SizedBox(height: 8),
          ],
        );
      },
      loading: () => const Padding(
        padding: EdgeInsets.all(16),
        child: Center(child: CircularProgressIndicator()),
      ),
      error: (e, _) => Text('Error: $e'),
    );
  }
}

/// Full-screen view of a single workout's analysis.
class WorkoutDetailScreen extends ConsumerWidget {
  final int workoutId;

  const WorkoutDetailScreen({super.key, required this.workoutId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final useLbs = ref.watch(useLbsProvider);
    final workoutsAsync = ref.watch(workoutsProvider);
    final routinesAsync = ref.watch(routinesProvider);

    final workout = workoutsAsync.valueOrNull
        ?.where((w) => w.id == workoutId)
        .firstOrNull;

    String title = 'Workout';
    String? subtitle;
    if (workout != null) {
      final routineName = workout.routineId != null
          ? routinesAsync.valueOrNull
              ?.where((r) => r.id == workout.routineId)
              .firstOrNull
              ?.name
          : null;
      title = routineName ?? 'Free Workout';
      final date = DateFormat('EEE, MMM d · h:mm a').format(workout.startTime);
      final duration = workout.endTime != null
          ? Formatters.duration(workout.endTime!.difference(workout.startTime))
          : '–';
      subtitle = '$date · $duration';
    }

    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(title,
                style: const TextStyle(
                  fontWeight: FontWeight.w700,
                  fontSize: 18,
                )),
            if (subtitle != null)
              Text(
                subtitle,
                style: const TextStyle(
                  color: AppColors.textMuted,
                  fontSize: 12,
                  fontWeight: FontWeight.w400,
                ),
              ),
          ],
        ),
      ),
      body: SingleChildScrollView(
        child: WorkoutDetails(workoutId: workoutId, useLbs: useLbs),
      ),
    );
  }
}
