import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../database/app_database.dart';
import '../../providers/providers.dart';
import '../../theme/app_theme.dart';
import '../../utils/formatters.dart';
import '../../utils/weight_conversions.dart';

/// Breakdown of a single workout's sets, grouped by exercise.
/// Used both as an inline expandable panel in HistoryScreen and as the body
/// of [WorkoutDetailScreen].
class WorkoutDetails extends ConsumerStatefulWidget {
  final int workoutId;
  final bool useLbs;
  final bool isEditing;
  final VoidCallback onEditDone;
  final Map<int, String> exerciseNames;

  const WorkoutDetails({
    super.key,
    required this.workoutId,
    required this.useLbs,
    this.isEditing = false,
    this.onEditDone = _noop,
    this.exerciseNames = const {},
  });

  static void _noop() {}

  @override
  ConsumerState<WorkoutDetails> createState() => _WorkoutDetailsState();
}

class _WorkoutDetailsState extends ConsumerState<WorkoutDetails> {
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

/// Full-screen view of a single workout's analysis.
class WorkoutDetailScreen extends ConsumerWidget {
  final int workoutId;

  const WorkoutDetailScreen({super.key, required this.workoutId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final useLbs = ref.watch(useLbsProvider);
    final workoutsAsync = ref.watch(workoutsProvider);
    final routinesAsync = ref.watch(routinesProvider);
    final exercisesAsync = ref.watch(exercisesProvider);

    final workout = workoutsAsync.valueOrNull
        ?.where((w) => w.id == workoutId)
        .firstOrNull;

    final exerciseNames = <int, String>{
      for (final e in exercisesAsync.valueOrNull ?? const <Exercise>[])
        e.id: e.name,
    };

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
        child: WorkoutDetails(
          workoutId: workoutId,
          useLbs: useLbs,
          exerciseNames: exerciseNames,
        ),
      ),
    );
  }
}
