import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../theme/app_theme.dart';
import '../../providers/providers.dart';
import '../../database/app_database.dart';
import '../../utils/formatters.dart';

class HistoryScreen extends ConsumerWidget {
  const HistoryScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final workoutsAsync = ref.watch(workoutsProvider);
    final useLbs = ref.watch(useLbsProvider);

    return SafeArea(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 24, 20, 16),
            child: Text(
              'History',
              style: Theme.of(context).textTheme.headlineLarge?.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
            ),
          ),
          Expanded(
            child: workoutsAsync.when(
              data: (workouts) {
                // Only show finished workouts
                final finished =
                    workouts.where((w) => w.endTime != null).toList();

                if (finished.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.history_rounded,
                            size: 64, color: AppColors.textMuted),
                        const SizedBox(height: 16),
                        Text(
                          'No workouts yet',
                          style: Theme.of(context)
                              .textTheme
                              .titleMedium
                              ?.copyWith(color: AppColors.textMuted),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Complete your first workout\nand it\'ll show up here!',
                          textAlign: TextAlign.center,
                          style: TextStyle(color: AppColors.textMuted),
                        ),
                      ],
                    ),
                  );
                }

                return ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: finished.length,
                  itemBuilder: (context, index) {
                    final workout = finished[index];
                    return _WorkoutHistoryTile(
                      workout: workout,
                      useLbs: useLbs,
                    );
                  },
                );
              },
              loading: () =>
                  const Center(child: CircularProgressIndicator()),
              error: (e, _) => Center(child: Text('Error: $e')),
            ),
          ),
        ],
      ),
    );
  }
}

class _WorkoutHistoryTile extends ConsumerStatefulWidget {
  final Workout workout;
  final bool useLbs;

  const _WorkoutHistoryTile({
    required this.workout,
    required this.useLbs,
  });

  @override
  ConsumerState<_WorkoutHistoryTile> createState() =>
      _WorkoutHistoryTileState();
}

class _WorkoutHistoryTileState extends ConsumerState<_WorkoutHistoryTile> {
  bool _isExpanded = false;

  @override
  Widget build(BuildContext context) {
    final workout = widget.workout;
    final duration = workout.endTime != null
        ? workout.endTime!.difference(workout.startTime)
        : Duration.zero;
    final dateStr = DateFormat('EEE, MMM d').format(workout.startTime);
    final timeStr = DateFormat('h:mm a').format(workout.startTime);

    // Get routine name if linked
    final routineData = workout.routineId != null
        ? ref.watch(routinesProvider).whenData(
              (routines) => routines
                  .where((r) => r.id == workout.routineId)
                  .firstOrNull
                  ?.name,
            )
        : null;
    final routineName = routineData?.value;

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.divider),
      ),
      child: Column(
        children: [
          // Main tile
          InkWell(
            borderRadius: BorderRadius.circular(16),
            onTap: () => setState(() => _isExpanded = !_isExpanded),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  // Date icon
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: AppColors.primary.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          DateFormat('d').format(workout.startTime),
                          style: const TextStyle(
                            color: AppColors.primary,
                            fontWeight: FontWeight.w700,
                            fontSize: 16,
                            height: 1,
                          ),
                        ),
                        Text(
                          DateFormat('MMM').format(workout.startTime),
                          style: const TextStyle(
                            color: AppColors.primary,
                            fontSize: 10,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          routineName ?? 'Free Workout',
                          style: const TextStyle(
                            fontWeight: FontWeight.w600,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          '$dateStr · $timeStr · ${Formatters.duration(duration)}',
                          style: const TextStyle(
                            color: AppColors.textMuted,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                  AnimatedRotation(
                    turns: _isExpanded ? 0.5 : 0,
                    duration: const Duration(milliseconds: 200),
                    child: const Icon(Icons.expand_more_rounded,
                        color: AppColors.textMuted),
                  ),
                ],
              ),
            ),
          ),

          // Expanded details
          if (_isExpanded)
            _WorkoutDetails(
              workoutId: workout.id,
              useLbs: widget.useLbs,
            ),
        ],
      ),
    );
  }
}

class _WorkoutDetails extends ConsumerWidget {
  final int workoutId;
  final bool useLbs;

  const _WorkoutDetails({
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

        // Group sets by exercise
        final grouped = <int, List<LoggedSet>>{};
        for (final s in sets) {
          grouped.putIfAbsent(s.exerciseId, () => []).add(s);
        }

        final exerciseNames = exercisesAsync.when(
          data: (list) => {for (final e in list) e.id: e.name},
          loading: () => <int, String>{},
          error: (_, __) => <int, String>{},
        );

        double totalVolume = 0;
        for (final s in sets) {
          totalVolume += s.weight * s.reps;
        }

        return Column(
          children: [
            const Divider(height: 1),
            // Volume summary
            Padding(
              padding: const EdgeInsets.symmetric(
                  horizontal: 16, vertical: 10),
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
            // Exercise breakdown
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
