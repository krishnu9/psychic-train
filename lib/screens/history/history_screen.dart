import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../theme/app_theme.dart';
import '../../providers/providers.dart';
import '../../database/app_database.dart';
import '../../utils/formatters.dart';
import '../../utils/weight_conversions.dart';

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
    final dateStr = DateFormat('EEE, MMM d').format(workout.startTime);
    final timeStr = DateFormat('h:mm a').format(workout.startTime);

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
            _WorkoutDetails(
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

class _WorkoutDetails extends ConsumerStatefulWidget {
  final int workoutId;
  final bool useLbs;
  final bool isEditing;
  final VoidCallback onEditDone;
  final Map<int, String> exerciseNames;

  const _WorkoutDetails({
    required this.workoutId,
    required this.useLbs,
    required this.isEditing,
    required this.onEditDone,
    this.exerciseNames = const {},
  });

  @override
  ConsumerState<_WorkoutDetails> createState() => _WorkoutDetailsState();
}

class _WorkoutDetailsState extends ConsumerState<_WorkoutDetails> {
  final Map<int, TextEditingController> _weightCtrls = {};
  final Map<int, TextEditingController> _repsCtrls = {};

  @override
  void dispose() {
    for (final c in _weightCtrls.values) {
      c.dispose();
    }
    for (final c in _repsCtrls.values) {
      c.dispose();
    }
    super.dispose();
  }

  void _initControllers(List<LoggedSet> sets, Map<int, bool> unitByExercise) {
    for (final s in sets) {
      final useLbs = unitByExercise[s.exerciseId] ?? widget.useLbs;
      final display = useLbs ? kgToLbs(s.weight) : s.weight;
      _weightCtrls.putIfAbsent(
          s.id, () => TextEditingController(text: _fmt(display)));
      _repsCtrls.putIfAbsent(
          s.id, () => TextEditingController(text: s.reps.toString()));
    }
  }

  static String _fmt(double v) {
    if (v == v.roundToDouble()) return v.toInt().toString();
    return v.toStringAsFixed(1);
  }

  Future<void> _saveEdits(
      List<LoggedSet> sets, Map<int, bool> unitByExercise) async {
    final workoutRepo = ref.read(workoutRepositoryProvider);
    for (final s in sets) {
      final typed = double.tryParse(_weightCtrls[s.id]?.text ?? '');
      final reps = int.tryParse(_repsCtrls[s.id]?.text ?? '');
      if (typed != null && reps != null) {
        final useLbs = unitByExercise[s.exerciseId] ?? widget.useLbs;
        final kg = useLbs ? lbsToKg(typed) : typed;
        await workoutRepo.updateSet(s.id, weight: kg, reps: reps);
      }
    }
    widget.onEditDone();
  }

  @override
  Widget build(BuildContext context) {
    final setsAsync = ref.watch(workoutSetsProvider(widget.workoutId));
    final weAsync = ref.watch(workoutExercisesProvider(widget.workoutId));

    return setsAsync.when(
      data: (sets) {
        if (sets.isEmpty) {
          return const Padding(
            padding: EdgeInsets.all(16),
            child: Text('No sets logged',
                style: TextStyle(color: AppColors.textMuted)),
          );
        }

        // Resolve per-exercise unit preference from the WorkoutExercise row.
        final weList = weAsync.valueOrNull ?? const <WorkoutExerciseEntry>[];
        final unitByExercise = <int, bool>{
          for (final we in weList)
            we.exerciseId: resolveUseLbs(
              workoutExercise: we.useLbs,
              global: widget.useLbs,
            ),
        };

        _initControllers(sets, unitByExercise);

        final grouped = <int, List<LoggedSet>>{};
        for (final s in sets) {
          grouped.putIfAbsent(s.exerciseId, () => []).add(s);
        }

        final exerciseNames = widget.exerciseNames;

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
                    'Total Volume: ${Formatters.volume(totalVolume, useLbs: widget.useLbs)}',
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
              final exUseLbs =
                  unitByExercise[entry.key] ?? widget.useLbs;
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
                    ...exSets.map((s) => widget.isEditing
                        ? Padding(
                            padding: const EdgeInsets.only(
                                left: 8, bottom: 4),
                            child: Row(
                              children: [
                                Text('Set ${s.setNumber}: ',
                                    style: const TextStyle(
                                        color: AppColors.textMuted,
                                        fontSize: 12)),
                                SizedBox(
                                  width: 64,
                                  child: TextFormField(
                                    controller: _weightCtrls[s.id],
                                    keyboardType:
                                        const TextInputType.numberWithOptions(
                                            decimal: true),
                                    style: const TextStyle(fontSize: 12),
                                    decoration: InputDecoration(
                                      isDense: true,
                                      contentPadding:
                                          const EdgeInsets.symmetric(
                                              horizontal: 6, vertical: 4),
                                      border: OutlineInputBorder(
                                        borderRadius:
                                            BorderRadius.circular(6),
                                      ),
                                      hintText: exUseLbs ? 'lbs' : 'kg',
                                    ),
                                  ),
                                ),
                                const Text(' × ',
                                    style: TextStyle(
                                        color: AppColors.textMuted,
                                        fontSize: 12)),
                                SizedBox(
                                  width: 48,
                                  child: TextFormField(
                                    controller: _repsCtrls[s.id],
                                    keyboardType: TextInputType.number,
                                    style: const TextStyle(fontSize: 12),
                                    decoration: InputDecoration(
                                      isDense: true,
                                      contentPadding:
                                          const EdgeInsets.symmetric(
                                              horizontal: 6, vertical: 4),
                                      border: OutlineInputBorder(
                                        borderRadius:
                                            BorderRadius.circular(6),
                                      ),
                                      hintText: 'reps',
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          )
                        : Padding(
                            padding: const EdgeInsets.only(left: 8),
                            child: Text(
                              'Set ${s.setNumber}: ${Formatters.weight(s.weight, useLbs: exUseLbs)} × ${s.reps} reps',
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
            if (widget.isEditing)
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 4, 16, 12),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton(
                      onPressed: widget.onEditDone,
                      child: const Text('Cancel'),
                    ),
                    const SizedBox(width: 8),
                    ElevatedButton(
                      onPressed: () => _saveEdits(sets, unitByExercise),
                      child: const Text('Save'),
                    ),
                  ],
                ),
              ),
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
