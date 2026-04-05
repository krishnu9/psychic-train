import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../theme/app_theme.dart';
import '../../providers/providers.dart';
import '../../database/app_database.dart';
import '../../utils/formatters.dart';
import '../exercises/exercise_picker.dart';

/// The "Gym Mode" – active workout logging screen.
/// Optimised for one-handed thumb-zone use.
class ActiveWorkoutScreen extends ConsumerStatefulWidget {
  final int workoutId;
  final int? routineId;

  const ActiveWorkoutScreen({
    super.key,
    required this.workoutId,
    this.routineId,
  });

  @override
  ConsumerState<ActiveWorkoutScreen> createState() =>
      _ActiveWorkoutScreenState();
}

class _ActiveWorkoutScreenState extends ConsumerState<ActiveWorkoutScreen> {
  // Elapsed timer
  late final Stopwatch _stopwatch;
  Timer? _elapsedTimer;
  String _elapsed = '00:00';
  Duration _elapsedOffset = Duration.zero;

  // Rest timer
  Timer? _restTimer;
  int _restRemaining = 0;
  bool _showRestTimer = false;

  // Workout exercise data
  final List<_WorkoutExerciseData> _exerciseDataList = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _stopwatch = Stopwatch()..start();
    _elapsedTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) {
        setState(() {
          _elapsed = Formatters.duration(_stopwatch.elapsed + _elapsedOffset);
        });
      }
    });
    _loadWorkoutStartTime();
    _loadExistingSetsOrRoutine();
  }

  Future<void> _loadWorkoutStartTime() async {
    final workout = await ref.read(workoutRepositoryProvider).getById(widget.workoutId);
    if (workout != null && mounted) {
      setState(() {
        _elapsedOffset = DateTime.now().difference(workout.startTime);
      });
    }
  }

  Future<void> _loadExistingSetsOrRoutine() async {
    final existingSets = await ref.read(workoutRepositoryProvider).getSets(widget.workoutId);
    if (existingSets.isNotEmpty && widget.routineId != null) {
      // Resuming a routine-based workout: merge routine template with logged sets
      await _restoreRoutineWithProgress(existingSets);
    } else if (existingSets.isNotEmpty) {
      // Resuming an empty workout (no routine): only logged sets available
      await _restoreFromLoggedSets(existingSets);
    } else {
      await _loadRoutineExercises();
    }
  }

  Future<void> _restoreRoutineWithProgress(List<LoggedSet> loggedSets) async {
    final exerciseRepo = ref.read(exerciseRepositoryProvider);
    final routineRepo = ref.read(routineRepositoryProvider);
    final workoutRepo = ref.read(workoutRepositoryProvider);

    // Build lookup: exerciseId → logged sets for this workout
    final loggedByExercise = <int, List<LoggedSet>>{};
    for (final s in loggedSets) {
      loggedByExercise.putIfAbsent(s.exerciseId, () => []).add(s);
    }

    // Load routine exercises in displayOrder
    final routineExercises = await routineRepo.getExercises(widget.routineId!);
    final routineExerciseIds = <int>{};

    for (final re in routineExercises) {
      routineExerciseIds.add(re.exerciseId);
      final exercise = await exerciseRepo.getById(re.exerciseId);
      if (exercise == null) continue;

      final logged = loggedByExercise[re.exerciseId] ?? [];
      final lastSets = await workoutRepo.getLastSetsForExercise(re.exerciseId);

      final sets = <_SetData>[];

      // Completed sets from the current workout
      for (final s in logged) {
        sets.add(_SetData(
          setNumber: s.setNumber,
          weight: s.weight,
          reps: s.reps,
          setType: s.setType,
          isCompleted: true,
          loggedSetId: s.id,
        ));
      }

      // Remaining sets up to targetSets (editable, pre-filled)
      for (var i = logged.length; i < re.targetSets; i++) {
        final setNum = i + 1;
        final lastSet = lastSets.where((s) => s.setNumber == setNum).firstOrNull;
        sets.add(_SetData(
          setNumber: setNum,
          weight: lastSet?.weight ?? re.targetWeight,
          reps: lastSet?.reps ?? re.targetReps,
        ));
      }

      _exerciseDataList.add(_WorkoutExerciseData(
        exercise: exercise,
        sets: sets,
        lastSets: lastSets,
        sectionName: re.sectionName,
      ));
    }

    // Append any exercises added mid-workout that aren't part of the routine
    for (final entry in loggedByExercise.entries) {
      if (routineExerciseIds.contains(entry.key)) continue;
      final exercise = await exerciseRepo.getById(entry.key);
      if (exercise == null) continue;
      final lastSets = await workoutRepo.getLastSetsForExercise(entry.key);
      _exerciseDataList.add(_WorkoutExerciseData(
        exercise: exercise,
        sets: entry.value
            .map((s) => _SetData(
                  setNumber: s.setNumber,
                  weight: s.weight,
                  reps: s.reps,
                  setType: s.setType,
                  isCompleted: true,
                  loggedSetId: s.id,
                ))
            .toList(),
        lastSets: lastSets,
      ));
    }

    setState(() => _isLoading = false);
  }

  Future<void> _restoreFromLoggedSets(List<LoggedSet> loggedSets) async {
    final exerciseRepo = ref.read(exerciseRepositoryProvider);
    final grouped = <int, List<LoggedSet>>{};
    for (final set in loggedSets) {
      grouped.putIfAbsent(set.exerciseId, () => []).add(set);
    }

    for (final entry in grouped.entries) {
      final exercise = await exerciseRepo.getById(entry.key);
      if (exercise == null) continue;

      final lastSets = await ref
          .read(workoutRepositoryProvider)
          .getLastSetsForExercise(entry.key);

      _exerciseDataList.add(_WorkoutExerciseData(
        exercise: exercise,
        sets: entry.value
            .map((s) => _SetData(
                  setNumber: s.setNumber,
                  weight: s.weight,
                  reps: s.reps,
                  setType: s.setType,
                  isCompleted: true,
                  loggedSetId: s.id,
                ))
            .toList(),
        lastSets: lastSets,
      ));
    }
    setState(() => _isLoading = false);
  }

  Future<void> _loadRoutineExercises() async {
    if (widget.routineId != null) {
      final routineExercises = await ref
          .read(routineRepositoryProvider)
          .getExercises(widget.routineId!);
      final exercises = await ref.read(exerciseRepositoryProvider).getAll();

      for (final re in routineExercises) {
        final exercise =
            exercises.where((e) => e.id == re.exerciseId).firstOrNull;
        if (exercise == null) continue;

        // Get last-session data for pre-fill reference
        final lastSets = await ref
            .read(workoutRepositoryProvider)
            .getLastSetsForExercise(re.exerciseId);

        final sets = <_SetData>[];
        for (var i = 0; i < re.targetSets; i++) {
          final lastSet =
              lastSets.where((s) => s.setNumber == i + 1).firstOrNull;
          sets.add(_SetData(
            setNumber: i + 1,
            weight: lastSet?.weight ?? re.targetWeight,
            reps: lastSet?.reps ?? re.targetReps,
          ));
        }

        _exerciseDataList.add(_WorkoutExerciseData(
          exercise: exercise,
          sets: sets,
          lastSets: lastSets,
          sectionName: re.sectionName,
        ));
      }
    }
    setState(() => _isLoading = false);
  }

  @override
  void dispose() {
    _elapsedTimer?.cancel();
    _restTimer?.cancel();
    _stopwatch.stop();
    super.dispose();
  }

  void _startRestTimer() {
    final duration = ref.read(restTimerDurationProvider);
    setState(() {
      _restRemaining = duration;
      _showRestTimer = true;
    });
    _restTimer?.cancel();
    _restTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_restRemaining <= 1) {
        timer.cancel();
        HapticFeedback.heavyImpact();
        if (mounted) setState(() => _showRestTimer = false);
      } else {
        if (mounted) setState(() => _restRemaining--);
      }
    });
  }

  void _dismissRestTimer() {
    _restTimer?.cancel();
    setState(() => _showRestTimer = false);
  }

  Future<void> _completeSet(int exerciseIndex, int setIndex) async {
    final exData = _exerciseDataList[exerciseIndex];
    final setData = exData.sets[setIndex];

    if (setData.isCompleted) return;

    // Log to database
    final id = await ref.read(workoutRepositoryProvider).logSet(
          workoutId: widget.workoutId,
          exerciseId: exData.exercise.id,
          setNumber: setData.setNumber,
          weight: setData.weight,
          reps: setData.reps,
          setType: setData.setType,
        );

    setState(() {
      setData.isCompleted = true;
      setData.loggedSetId = id;
    });

    HapticFeedback.mediumImpact();
    _startRestTimer();
  }

  Future<void> _uncompleteSet(int exerciseIndex, int setIndex) async {
    final exData = _exerciseDataList[exerciseIndex];
    final setData = exData.sets[setIndex];

    if (!setData.isCompleted) return;

    if (setData.loggedSetId != null) {
      await ref.read(workoutRepositoryProvider).deleteSet(setData.loggedSetId!);
    }

    setState(() {
      setData.isCompleted = false;
      setData.loggedSetId = null;
    });
  }

  Future<void> _updateSet(int exerciseIndex, int setIndex) async {
    final exData = _exerciseDataList[exerciseIndex];
    final setData = exData.sets[setIndex];
    if (setData.loggedSetId == null) return;
    await ref.read(workoutRepositoryProvider).updateSet(
          setData.loggedSetId!,
          weight: setData.weight,
          reps: setData.reps,
        );
  }

  void _addSetToExercise(int exerciseIndex) {
    setState(() {
      final exData = _exerciseDataList[exerciseIndex];
      final lastSet = exData.sets.isNotEmpty ? exData.sets.last : null;
      exData.sets.add(_SetData(
        setNumber: exData.sets.length + 1,
        weight: lastSet?.weight ?? 0,
        reps: lastSet?.reps ?? 10,
      ));
    });
  }

  Future<void> _addExercise() async {
    final selected = await showModalBottomSheet<Exercise>(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) => const ExercisePickerSheet(),
    );

    if (selected != null) {
      final lastSets = await ref
          .read(workoutRepositoryProvider)
          .getLastSetsForExercise(selected.id);

      setState(() {
        _exerciseDataList.add(_WorkoutExerciseData(
          exercise: selected,
          sets: List.generate(
            3,
            (i) {
              final last =
                  lastSets.where((s) => s.setNumber == i + 1).firstOrNull;
              return _SetData(
                setNumber: i + 1,
                weight: last?.weight ?? 0,
                reps: last?.reps ?? 10,
              );
            },
          ),
          lastSets: lastSets,
        ));
      });
    }
  }

  Future<void> _cancelWorkout() async {
    final discard = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surface,
        title: const Text('Discard Workout?'),
        content: const Text(
            'Your progress will be lost if you cancel.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Stay'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Discard',
                style: TextStyle(color: AppColors.error)),
          ),
        ],
      ),
    );
    if (discard == true && mounted) {
      await ref
          .read(workoutRepositoryProvider)
          .delete(widget.workoutId);
      if (mounted) Navigator.pop(context);
    }
  }

  Future<void> _finishWorkout() async {
    final totalSets = _exerciseDataList.fold<int>(
        0, (sum, ex) => sum + ex.sets.where((s) => s.isCompleted).length);
    final totalVolume = _exerciseDataList.fold<double>(
      0,
      (sum, ex) =>
          sum +
          ex.sets
              .where((s) => s.isCompleted)
              .fold<double>(0, (s, set) => s + set.weight * set.reps),
    );

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surface,
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20)),
        title: const Text('Finish Workout?'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _SummaryRow(label: 'Duration', value: _elapsed),
            _SummaryRow(label: 'Total Sets', value: '$totalSets'),
            _SummaryRow(
              label: 'Total Volume',
              value: Formatters.volume(totalVolume),
            ),
            _SummaryRow(
              label: 'Exercises',
              value: '${_exerciseDataList.length}',
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Continue'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Finish'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await ref.read(workoutRepositoryProvider).finish(widget.workoutId);
      // Invalidate stats
      ref.invalidate(workoutsThisWeekProvider);
      ref.invalidate(totalWorkoutsProvider);
      if (mounted) Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    final useLbs = ref.watch(useLbsProvider);

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) async {
        if (didPop) return;
        await _cancelWorkout();
      },
      child: Scaffold(
        backgroundColor: AppColors.background,
        body: Stack(
          children: [
            SafeArea(
              child: Column(
                children: [
                  // ─── Header ─────────────────────────────
                  _WorkoutHeader(
                    elapsed: _elapsed,
                    onFinish: _finishWorkout,
                    onCancel: _cancelWorkout,
                  ),

                  // ─── Exercise cards ─────────────────────
                  Expanded(
                    child: _isLoading
                        ? const Center(child: CircularProgressIndicator())
                        : _exerciseDataList.isEmpty
                            ? Center(
                                child: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(Icons.add_circle_outline_rounded,
                                        size: 48,
                                        color: AppColors.textMuted),
                                    const SizedBox(height: 12),
                                    Text('No exercises yet',
                                        style: TextStyle(
                                            color: AppColors.textMuted)),
                                    const SizedBox(height: 16),
                                    ElevatedButton.icon(
                                      onPressed: _addExercise,
                                      icon:
                                          const Icon(Icons.add_rounded),
                                      label: const Text('Add Exercise'),
                                    ),
                                  ],
                                ),
                              )
                            : ListView.builder(
                                padding: const EdgeInsets.only(
                                    bottom: 160, top: 8),
                                itemCount:
                                    _exerciseDataList.length + 1, // +1 for add button
                                itemBuilder: (ctx, index) {
                                  if (index ==
                                      _exerciseDataList.length) {
                                    return Padding(
                                      padding:
                                          const EdgeInsets.symmetric(
                                              horizontal: 16,
                                              vertical: 8),
                                      child: OutlinedButton.icon(
                                        onPressed: _addExercise,
                                        icon: const Icon(
                                            Icons.add_rounded),
                                        label: const Text(
                                            'Add Exercise'),
                                      ),
                                    );
                                  }
                                  final data = _exerciseDataList[index];
                                  final prevSection = index > 0
                                      ? _exerciseDataList[index - 1].sectionName
                                      : '';
                                  final showHeader = data.sectionName.isNotEmpty &&
                                      data.sectionName != prevSection;
                                  return Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      if (showHeader)
                                        Padding(
                                          padding: const EdgeInsets.fromLTRB(20, 12, 20, 4),
                                          child: Row(
                                            children: [
                                              Container(
                                                width: 4,
                                                height: 16,
                                                decoration: BoxDecoration(
                                                  color: AppColors.primary,
                                                  borderRadius: BorderRadius.circular(2),
                                                ),
                                              ),
                                              const SizedBox(width: 8),
                                              Text(
                                                data.sectionName,
                                                style: const TextStyle(
                                                  color: AppColors.primary,
                                                  fontWeight: FontWeight.w700,
                                                  fontSize: 13,
                                                  letterSpacing: 0.3,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      _ExerciseCard(
                                        data: data,
                                        exerciseIndex: index,
                                        useLbs: useLbs,
                                        onCompleteSet: _completeSet,
                                        onUncompleteSet: _uncompleteSet,
                                        onUpdateSet: _updateSet,
                                        onAddSet: _addSetToExercise,
                                        onRemove: () {
                                          setState(() {
                                            _exerciseDataList.removeAt(index);
                                          });
                                        },
                                      ),
                                    ],
                                  );
                                },
                              ),
                  ),
                ],
              ),
            ),

            // ─── Rest timer overlay ────────────────────
            if (_showRestTimer)
              Positioned(
                left: 0,
                right: 0,
                bottom: 0,
                child: _RestTimerOverlay(
                  remaining: _restRemaining,
                  onDismiss: _dismissRestTimer,
                ),
              ),
          ],
        ),
      ),
    );
  }
}

// ─── Data models ──────────────────────────────────────────────────────────────

class _WorkoutExerciseData {
  final Exercise exercise;
  final List<_SetData> sets;
  final List<LoggedSet> lastSets;
  final String sectionName;

  _WorkoutExerciseData({
    required this.exercise,
    required this.sets,
    required this.lastSets,
    this.sectionName = '',
  });
}

class _SetData {
  int setNumber;
  double weight;
  int reps;
  int setType;
  bool isCompleted;
  int? loggedSetId;

  _SetData({
    required this.setNumber,
    required this.weight,
    required this.reps,
    this.setType = 0,
    this.isCompleted = false,
    this.loggedSetId,
  });
}

// ─── Sub-widgets ──────────────────────────────────────────────────────────────

class _WorkoutHeader extends StatelessWidget {
  final String elapsed;
  final VoidCallback onFinish;
  final VoidCallback onCancel;

  const _WorkoutHeader({
    required this.elapsed,
    required this.onFinish,
    required this.onCancel,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(4, 8, 12, 8),
      child: Row(
        children: [
          // Cancel button
          IconButton(
            onPressed: onCancel,
            tooltip: 'Cancel Workout',
            icon: Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: AppColors.error.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(Icons.close_rounded,
                  color: AppColors.error, size: 20),
            ),
          ),
          const SizedBox(width: 4),
          // Elapsed time pill
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: AppColors.surfaceLight,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.timer_outlined,
                    color: AppColors.primary, size: 16),
                const SizedBox(width: 6),
                Text(
                  elapsed,
                  style: const TextStyle(
                    color: AppColors.primary,
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
          const Spacer(),
          // Finish button
          ElevatedButton(
            onPressed: onFinish,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: AppColors.background,
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: const Text('Finish',
                style: TextStyle(fontWeight: FontWeight.w700)),
          ),
        ],
      ),
    );
  }
}

class _ExerciseCard extends StatelessWidget {
  final _WorkoutExerciseData data;
  final int exerciseIndex;
  final bool useLbs;
  final Future<void> Function(int, int) onCompleteSet;
  final Future<void> Function(int, int) onUncompleteSet;
  final Future<void> Function(int, int) onUpdateSet;
  final void Function(int) onAddSet;
  final VoidCallback onRemove;

  const _ExerciseCard({
    required this.data,
    required this.exerciseIndex,
    required this.useLbs,
    required this.onCompleteSet,
    required this.onUncompleteSet,
    required this.onUpdateSet,
    required this.onAddSet,
    required this.onRemove,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.divider),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Exercise header
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 8, 8),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        data.exercise.name,
                        style: const TextStyle(
                          fontWeight: FontWeight.w600,
                          color: AppColors.textPrimary,
                          fontSize: 16,
                        ),
                      ),
                      if (data.lastSets.isNotEmpty)
                        Padding(
                          padding: const EdgeInsets.only(top: 2),
                          child: Text(
                            'Last: ${data.lastSets.map((s) => '${s.weight}×${s.reps}').join(', ')}',
                            style: const TextStyle(
                              color: AppColors.textMuted,
                              fontSize: 11,
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close_rounded,
                      color: AppColors.textMuted, size: 18),
                  onPressed: onRemove,
                  visualDensity: VisualDensity.compact,
                ),
              ],
            ),
          ),

          // Column headers
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                SizedBox(width: 36, child: Text('SET', style: _headerStyle)),
                Expanded(child: Text('KG', style: _headerStyle, textAlign: TextAlign.center)),
                Expanded(child: Text('REPS', style: _headerStyle, textAlign: TextAlign.center)),
                SizedBox(width: 52),
              ],
            ),
          ),
          const SizedBox(height: 4),

          // Set rows
          ...data.sets.asMap().entries.map((entry) {
            final setIndex = entry.key;
            final setData = entry.value;
            return _SetRow(
              setData: setData,
              useLbs: useLbs,
              onComplete: () => onCompleteSet(exerciseIndex, setIndex),
              onUncomplete: () => onUncompleteSet(exerciseIndex, setIndex),
              onUpdateSet: () => onUpdateSet(exerciseIndex, setIndex),
              onWeightChanged: (v) => setData.weight = v,
              onRepsChanged: (v) => setData.reps = v,
            );
          }),

          // Add set button
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 4, 16, 12),
            child: GestureDetector(
              onTap: () => onAddSet(exerciseIndex),
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 10),
                decoration: BoxDecoration(
                  color: AppColors.surfaceLight,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.add_rounded,
                        color: AppColors.textMuted, size: 16),
                    SizedBox(width: 4),
                    Text(
                      'Add Set',
                      style: TextStyle(
                          color: AppColors.textMuted, fontSize: 13),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

const _headerStyle = TextStyle(
  color: AppColors.textMuted,
  fontSize: 11,
  fontWeight: FontWeight.w600,
  letterSpacing: 0.5,
);

class _SetRow extends StatefulWidget {
  final _SetData setData;
  final bool useLbs;
  final VoidCallback onComplete;
  final VoidCallback onUncomplete;
  final VoidCallback onUpdateSet;
  final ValueChanged<double> onWeightChanged;
  final ValueChanged<int> onRepsChanged;

  const _SetRow({
    required this.setData,
    required this.useLbs,
    required this.onComplete,
    required this.onUncomplete,
    required this.onUpdateSet,
    required this.onWeightChanged,
    required this.onRepsChanged,
  });

  @override
  State<_SetRow> createState() => _SetRowState();
}

class _SetRowState extends State<_SetRow> {
  late final TextEditingController _weightCtrl;
  late final TextEditingController _repsCtrl;

  @override
  void initState() {
    super.initState();
    _weightCtrl = TextEditingController(
      text: widget.setData.weight > 0
          ? widget.setData.weight.toString()
          : '',
    );
    _repsCtrl = TextEditingController(
      text: widget.setData.reps > 0
          ? widget.setData.reps.toString()
          : '',
    );
  }

  @override
  void dispose() {
    _weightCtrl.dispose();
    _repsCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isCompleted = widget.setData.isCompleted;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      color: isCompleted
          ? AppColors.primary.withValues(alpha: 0.08)
          : Colors.transparent,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      child: Row(
        children: [
          // Set number
          SizedBox(
            width: 36,
            child: Text(
              '${widget.setData.setNumber}',
              style: TextStyle(
                color: isCompleted
                    ? AppColors.primary
                    : AppColors.textSecondary,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),

          // Weight input
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4),
              child: TextField(
                controller: _weightCtrl,
                keyboardType:
                    const TextInputType.numberWithOptions(decimal: true),
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: isCompleted
                      ? AppColors.textMuted
                      : AppColors.textPrimary,
                  fontWeight: FontWeight.w500,
                ),
                decoration: InputDecoration(
                  filled: true,
                  fillColor: isCompleted
                      ? Colors.transparent
                      : AppColors.surfaceLight,
                  contentPadding: const EdgeInsets.symmetric(
                      horizontal: 8, vertical: 8),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide.none,
                  ),
                  hintText: '0',
                  hintStyle: const TextStyle(color: AppColors.textMuted),
                ),
                onChanged: (v) {
                  widget.onWeightChanged(double.tryParse(v) ?? 0);
                  if (isCompleted) widget.onUpdateSet();
                },
              ),
            ),
          ),

          // Reps input
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4),
              child: TextField(
                controller: _repsCtrl,
                keyboardType: TextInputType.number,
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: isCompleted
                      ? AppColors.textMuted
                      : AppColors.textPrimary,
                  fontWeight: FontWeight.w500,
                ),
                decoration: InputDecoration(
                  filled: true,
                  fillColor: isCompleted
                      ? Colors.transparent
                      : AppColors.surfaceLight,
                  contentPadding: const EdgeInsets.symmetric(
                      horizontal: 8, vertical: 8),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide.none,
                  ),
                  hintText: '0',
                  hintStyle: const TextStyle(color: AppColors.textMuted),
                ),
                onChanged: (v) {
                  widget.onRepsChanged(int.tryParse(v) ?? 0);
                  if (isCompleted) widget.onUpdateSet();
                },
              ),
            ),
          ),

          // Check button – tap to log; tap again to un-log
          SizedBox(
            width: 52,
            child: GestureDetector(
              onTap: isCompleted ? widget.onUncomplete : widget.onComplete,
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: isCompleted
                      ? AppColors.primary
                      : AppColors.surfaceLight,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  Icons.check_rounded,
                  color: isCompleted
                      ? AppColors.background
                      : AppColors.textMuted,
                  size: 22,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _RestTimerOverlay extends StatelessWidget {
  final int remaining;
  final VoidCallback onDismiss;

  const _RestTimerOverlay({
    required this.remaining,
    required this.onDismiss,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(24, 20, 24, 40),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.3),
            blurRadius: 20,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text(
            'Rest Timer',
            style: TextStyle(
              color: AppColors.textSecondary,
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            Formatters.restTimer(remaining),
            style: const TextStyle(
              color: AppColors.primary,
              fontSize: 48,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: onDismiss,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.surfaceLight,
                foregroundColor: AppColors.textPrimary,
              ),
              child: const Text('Skip'),
            ),
          ),
        ],
      ),
    );
  }
}

class _SummaryRow extends StatelessWidget {
  final String label;
  final String value;
  const _SummaryRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label,
              style: const TextStyle(color: AppColors.textSecondary)),
          Text(value,
              style: const TextStyle(
                  color: AppColors.textPrimary,
                  fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }
}
