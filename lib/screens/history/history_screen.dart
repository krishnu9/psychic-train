import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../theme/app_theme.dart';
import '../../providers/providers.dart';
import '../../database/app_database.dart';
import '../../utils/formatters.dart';
import 'workout_detail_screen.dart';

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
  bool _isEditing = false;

  @override
  Widget build(BuildContext context) {
    final workout = widget.workout;
    final duration = workout.endTime != null
        ? workout.endTime!.difference(workout.startTime)
        : Duration.zero;
    final dateStr = Formatters.dateTime(workout.startTime, 'EEE, MMM d');
    final timeStr = Formatters.dateTime(workout.startTime, 'h:mm a');

    // Eagerly subscribe so sets are loaded before expansion
    ref.watch(workoutSetsProvider(workout.id));

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
          ListTile(
            contentPadding: const EdgeInsets.fromLTRB(16, 8, 4, 8),
            onTap: () => setState(() => _isExpanded = !_isExpanded),
            leading: Container(
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
                    Formatters.dateTime(workout.startTime, 'd'),
                    style: const TextStyle(
                      color: AppColors.primary,
                      fontWeight: FontWeight.w700,
                      fontSize: 16,
                      height: 1,
                    ),
                  ),
                  Text(
                    Formatters.dateTime(workout.startTime, 'MMM'),
                    style: const TextStyle(
                      color: AppColors.primary,
                      fontSize: 10,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
            title: Text(
              routineName ?? 'Free Workout',
              style: const TextStyle(
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary,
              ),
            ),
            subtitle: Text(
              '$dateStr · $timeStr · ${Formatters.duration(duration)}',
              style: const TextStyle(
                color: AppColors.textMuted,
                fontSize: 12,
              ),
            ),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  icon: Icon(
                    _isEditing
                        ? Icons.edit_off_rounded
                        : Icons.edit_outlined,
                    color: _isEditing
                        ? AppColors.primary
                        : AppColors.textMuted,
                    size: 20,
                  ),
                  onPressed: () => setState(() {
                    if (!_isEditing) _isExpanded = true;
                    _isEditing = !_isEditing;
                  }),
                  visualDensity: VisualDensity.compact,
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

          // Expanded details
          if (_isExpanded)
            WorkoutDetails(
              workoutId: workout.id,
              useLbs: widget.useLbs,
              isEditing: _isEditing,
              onEditDone: () => setState(() => _isEditing = false),
            ),
        ],
      ),
    );
  }
}
