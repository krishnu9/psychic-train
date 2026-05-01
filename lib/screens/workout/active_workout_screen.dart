import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../theme/app_theme.dart';
import '../../providers/providers.dart';
import '../../database/app_database.dart';
import '../../utils/formatters.dart';
import '../../utils/weight_conversions.dart';
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
  // Elapsed timer — always computed from the DB-stored start time so the
  // display stays accurate even when the screen is off or the app is backgrounded.
  DateTime? _workoutStartTime;
  Timer? _elapsedTimer;
  String _elapsed = '00:00';

  // Rest timer
  Timer? _restTimer;
  int _restRemaining = 0;
  bool _showRestTimer = false;
  bool _restTimerMinimized = false;

  // Workout exercise data
  final List<_WorkoutExerciseData> _exerciseDataList = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadWorkoutStartTime();
    _loadExistingSetsOrRoutine();
  }

  Future<void> _loadWorkoutStartTime() async {
    Workout? workout;
    try {
      workout = await ref
          .read(workoutRepositoryProvider)
          .getById(widget.workoutId);
    } catch (_) {
      // Workout lookup failed — timer will not start (graceful degradation)
    }
    if (!mounted) return;
    if (workout != null) {
      _workoutStartTime = workout.startTime;
      _elapsedTimer = Timer.periodic(const Duration(seconds: 1), (_) {
        if (mounted) {
          setState(() {
            _elapsed = Formatters.duration(
              DateTime.now().difference(_workoutStartTime!),
            );
          });
        }
      });
    }
  }

  Future<void> _loadExistingSetsOrRoutine() async {
    try {
      final workoutRepo = ref.read(workoutRepositoryProvider);
      final existingSets = await workoutRepo.getSets(widget.workoutId);
      final workoutExercises = await workoutRepo.getWorkoutExercises(
        widget.workoutId,
      );
      final weMap = <int, WorkoutExerciseEntry>{
        for (final we in workoutExercises) we.exerciseId: we,
      };

      if (existingSets.isNotEmpty && widget.routineId != null) {
        await _restoreRoutineWithProgress(existingSets, weMap);
      } else if (existingSets.isNotEmpty) {
        await _restoreFromLoggedSets(existingSets, weMap);
      } else {
        await _loadRoutineExercises(weMap);
      }
    } catch (_) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _restoreRoutineWithProgress(
    List<LoggedSet> loggedSets,
    Map<int, WorkoutExerciseEntry> weMap,
  ) async {
    final exerciseRepo = ref.read(exerciseRepositoryProvider);
    final routineRepo = ref.read(routineRepositoryProvider);
    final workoutRepo = ref.read(workoutRepositoryProvider);

    final loggedByExercise = <int, List<LoggedSet>>{};
    for (final s in loggedSets) {
      loggedByExercise.putIfAbsent(s.exerciseId, () => []).add(s);
    }

    final routineExercises = await routineRepo.getExercises(widget.routineId!);
    final routineExerciseIds = <int>{};

    for (final re in routineExercises) {
      routineExerciseIds.add(re.exerciseId);
      final exercise = await exerciseRepo.getById(re.exerciseId);
      if (exercise == null) continue;

      final logged = loggedByExercise[re.exerciseId] ?? [];
      final lastSets = await workoutRepo.getLastSetsForExercise(re.exerciseId);
      final we = weMap[re.exerciseId];

      final sets = <_SetData>[];
      for (final s in logged) {
        sets.add(
          _SetData(
            setNumber: s.setNumber,
            weight: s.weight,
            reps: s.reps,
            setType: s.setType,
            isCompleted: true,
            loggedSetId: s.id,
          ),
        );
      }
      for (var i = logged.length; i < re.targetSets; i++) {
        final setNum = i + 1;
        final lastSet = lastSets
            .where((s) => s.setNumber == setNum)
            .firstOrNull;
        sets.add(
          _SetData(
            setNumber: setNum,
            weight: lastSet?.weight ?? re.targetWeight,
            reps: lastSet?.reps ?? re.targetReps,
          ),
        );
      }

      _exerciseDataList.add(
        _WorkoutExerciseData(
          exercise: exercise,
          sets: sets,
          lastSets: lastSets,
          sectionName: re.sectionName,
          workoutExerciseId: we?.id,
          notes: we?.notes ?? '',
          useLbsOverride: we?.useLbs ?? re.useLbs,
        ),
      );
    }

    for (final entry in loggedByExercise.entries) {
      if (routineExerciseIds.contains(entry.key)) continue;
      final exercise = await exerciseRepo.getById(entry.key);
      if (exercise == null) continue;
      final lastSets = await workoutRepo.getLastSetsForExercise(entry.key);
      final we = weMap[entry.key];
      _exerciseDataList.add(
        _WorkoutExerciseData(
          exercise: exercise,
          sets: entry.value
              .map(
                (s) => _SetData(
                  setNumber: s.setNumber,
                  weight: s.weight,
                  reps: s.reps,
                  setType: s.setType,
                  isCompleted: true,
                  loggedSetId: s.id,
                ),
              )
              .toList(),
          lastSets: lastSets,
          workoutExerciseId: we?.id,
          notes: we?.notes ?? '',
          useLbsOverride: we?.useLbs,
        ),
      );
    }

    if (weMap.isNotEmpty) {
      _exerciseDataList.sort((a, b) {
        final aOrder = weMap[a.exercise.id]?.displayOrder ?? 0;
        final bOrder = weMap[b.exercise.id]?.displayOrder ?? 0;
        return aOrder.compareTo(bOrder);
      });
    }

    setState(() => _isLoading = false);
  }

  Future<void> _restoreFromLoggedSets(
    List<LoggedSet> loggedSets,
    Map<int, WorkoutExerciseEntry> weMap,
  ) async {
    final exerciseRepo = ref.read(exerciseRepositoryProvider);
    final workoutRepo = ref.read(workoutRepositoryProvider);
    final grouped = <int, List<LoggedSet>>{};
    for (final set in loggedSets) {
      grouped.putIfAbsent(set.exerciseId, () => []).add(set);
    }

    for (final entry in grouped.entries) {
      final exercise = await exerciseRepo.getById(entry.key);
      if (exercise == null) continue;

      final lastSets = await workoutRepo.getLastSetsForExercise(entry.key);
      final we = weMap[entry.key];

      _exerciseDataList.add(
        _WorkoutExerciseData(
          exercise: exercise,
          sets: entry.value
              .map(
                (s) => _SetData(
                  setNumber: s.setNumber,
                  weight: s.weight,
                  reps: s.reps,
                  setType: s.setType,
                  isCompleted: true,
                  loggedSetId: s.id,
                ),
              )
              .toList(),
          lastSets: lastSets,
          workoutExerciseId: we?.id,
          notes: we?.notes ?? '',
          useLbsOverride: we?.useLbs,
        ),
      );
    }

    if (weMap.isNotEmpty) {
      _exerciseDataList.sort((a, b) {
        final aOrder = weMap[a.exercise.id]?.displayOrder ?? 0;
        final bOrder = weMap[b.exercise.id]?.displayOrder ?? 0;
        return aOrder.compareTo(bOrder);
      });
    }

    setState(() => _isLoading = false);
  }

  Future<void> _loadRoutineExercises(
    Map<int, WorkoutExerciseEntry> weMap,
  ) async {
    if (widget.routineId != null) {
      final routineExercises = await ref
          .read(routineRepositoryProvider)
          .getExercises(widget.routineId!);
      final exercises = await ref.read(exerciseRepositoryProvider).getAll();

      for (final re in routineExercises) {
        final exercise = exercises
            .where((e) => e.id == re.exerciseId)
            .firstOrNull;
        if (exercise == null) continue;

        final lastSets = await ref
            .read(workoutRepositoryProvider)
            .getLastSetsForExercise(re.exerciseId);
        final we = weMap[re.exerciseId];

        final sets = <_SetData>[];
        for (var i = 0; i < re.targetSets; i++) {
          final lastSet = lastSets
              .where((s) => s.setNumber == i + 1)
              .firstOrNull;
          sets.add(
            _SetData(
              setNumber: i + 1,
              weight: lastSet?.weight ?? re.targetWeight,
              reps: lastSet?.reps ?? re.targetReps,
            ),
          );
        }

        _exerciseDataList.add(
          _WorkoutExerciseData(
            exercise: exercise,
            sets: sets,
            lastSets: lastSets,
            sectionName: re.sectionName,
            workoutExerciseId: we?.id,
            notes: we?.notes ?? '',
            useLbsOverride: we?.useLbs ?? re.useLbs,
          ),
        );
      }

      if (weMap.isNotEmpty) {
        _exerciseDataList.sort((a, b) {
          final aOrder = weMap[a.exercise.id]?.displayOrder ?? 0;
          final bOrder = weMap[b.exercise.id]?.displayOrder ?? 0;
          return aOrder.compareTo(bOrder);
        });
      }
    }
    setState(() => _isLoading = false);
  }

  @override
  void dispose() {
    _elapsedTimer?.cancel();
    _restTimer?.cancel();
    super.dispose();
  }

  void _startRestTimer() {
    if (!ref.read(restTimerEnabledProvider)) return;
    final duration = ref.read(restTimerDurationProvider);
    setState(() {
      _restRemaining = duration;
      _showRestTimer = true;
      _restTimerMinimized = false;
    });
    _restTimer?.cancel();
    _restTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_restRemaining <= 1) {
        timer.cancel();
        HapticFeedback.heavyImpact();
        if (mounted) {
          setState(() {
            _showRestTimer = false;
            _restTimerMinimized = false;
          });
        }
      } else {
        if (mounted) setState(() => _restRemaining--);
      }
    });
  }

  void _dismissRestTimer() {
    _restTimer?.cancel();
    setState(() {
      _showRestTimer = false;
      _restTimerMinimized = false;
    });
  }

  void _minimizeRestTimer() {
    setState(() => _restTimerMinimized = true);
  }

  void _expandRestTimer() {
    setState(() => _restTimerMinimized = false);
  }

  Future<void> _completeSet(int exerciseIndex, int setIndex) async {
    final exData = _exerciseDataList[exerciseIndex];
    final setData = exData.sets[setIndex];

    if (setData.isCompleted) return;

    // Log to database
    final id = await ref
        .read(workoutRepositoryProvider)
        .logSet(
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
    await ref
        .read(workoutRepositoryProvider)
        .updateSet(
          setData.loggedSetId!,
          weight: setData.weight,
          reps: setData.reps,
        );
  }

  Future<void> _toggleExerciseUnit(int exerciseIndex, bool useLbs) async {
    final data = _exerciseDataList[exerciseIndex];
    final weId = data.workoutExerciseId;
    setState(() => data.useLbsOverride = useLbs);
    if (weId != null) {
      await ref
          .read(workoutRepositoryProvider)
          .setWorkoutExerciseUseLbs(weId, useLbs);
    }
  }

  void _addSetToExercise(int exerciseIndex) {
    setState(() {
      final exData = _exerciseDataList[exerciseIndex];
      final lastSet = exData.sets.isNotEmpty ? exData.sets.last : null;
      exData.sets.add(
        _SetData(
          setNumber: exData.sets.length + 1,
          weight: lastSet?.weight ?? 0,
          reps: lastSet?.reps ?? 10,
        ),
      );
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
      final workoutRepo = ref.read(workoutRepositoryProvider);
      final lastSets = await workoutRepo.getLastSetsForExercise(selected.id);
      final weId = await workoutRepo.upsertWorkoutExercise(
        workoutId: widget.workoutId,
        exerciseId: selected.id,
        displayOrder: _exerciseDataList.length,
      );

      setState(() {
        _exerciseDataList.add(
          _WorkoutExerciseData(
            exercise: selected,
            sets: List.generate(3, (i) {
              final last = lastSets
                  .where((s) => s.setNumber == i + 1)
                  .firstOrNull;
              return _SetData(
                setNumber: i + 1,
                weight: last?.weight ?? 0,
                reps: last?.reps ?? 10,
              );
            }),
            lastSets: lastSets,
            workoutExerciseId: weId,
          ),
        );
      });
    }
  }

  void _reorderExercises(int oldIndex, int newIndex) {
    if (oldIndex >= _exerciseDataList.length) {
      return;
    }
    if (newIndex > _exerciseDataList.length) {
      newIndex = _exerciseDataList.length;
    }
    if (newIndex > oldIndex) newIndex--;
    setState(() {
      final item = _exerciseDataList.removeAt(oldIndex);
      _exerciseDataList.insert(newIndex, item);
    });
    final exerciseIds = _exerciseDataList.map((d) => d.exercise.id).toList();
    ref
        .read(workoutRepositoryProvider)
        .reorderWorkoutExercises(widget.workoutId, exerciseIds);
  }

  void _minimizeWorkout() {
    ref.read(workoutMinimizedProvider.notifier).state = true;
    Navigator.pop(context);
  }

  Future<void> _cancelWorkout() async {
    final discard = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surface,
        title: const Text('Discard Workout?'),
        content: const Text('Your progress will be lost if you cancel.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Stay'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text(
              'Discard',
              style: TextStyle(color: AppColors.error),
            ),
          ),
        ],
      ),
    );
    if (discard == true && mounted) {
      await ref.read(workoutRepositoryProvider).delete(widget.workoutId);
      if (mounted) Navigator.pop(context);
    }
  }

  Future<void> _saveAsRoutine() async {
    if (_exerciseDataList.isEmpty) return;
    final nameCtrl = TextEditingController();
    final name = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Save as Routine'),
        content: TextField(
          controller: nameCtrl,
          autofocus: true,
          decoration: const InputDecoration(hintText: 'Routine name'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              final v = nameCtrl.text.trim();
              if (v.isNotEmpty) Navigator.pop(ctx, v);
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
    nameCtrl.dispose();
    if (name == null || !mounted) return;

    final routineRepo = ref.read(routineRepositoryProvider);
    final routineId = await routineRepo.create(name: name);
    for (var i = 0; i < _exerciseDataList.length; i++) {
      final ex = _exerciseDataList[i];
      final completedSets = ex.sets.where((s) => s.isCompleted).toList();
      final targetSets = ex.sets.length;
      final targetReps = completedSets.isNotEmpty
          ? (completedSets.map((s) => s.reps).reduce((a, b) => a + b) ~/
                completedSets.length)
          : 10;
      final targetWeight = completedSets.isNotEmpty
          ? completedSets.map((s) => s.weight).reduce((a, b) => a + b) /
                completedSets.length
          : 0.0;
      await routineRepo.addExercise(
        routineId,
        ex.exercise.id,
        i,
        sets: targetSets,
        reps: targetReps,
        weight: targetWeight,
        sectionName: ex.sectionName,
        notes: ex.notes,
        useLbs: ex.useLbsOverride,
      );
    }
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Saved as routine "$name"'),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  Future<void> _finishWorkout() async {
    final totalSets = _exerciseDataList.fold<int>(
      0,
      (sum, ex) => sum + ex.sets.where((s) => s.isCompleted).length,
    );
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
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Finish Workout?'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _SummaryRow(label: 'Duration', value: _elapsed),
            _SummaryRow(label: 'Total Sets', value: '$totalSets'),
            _SummaryRow(
              label: 'Total Volume',
              value: Formatters.volume(
                totalVolume,
                useLbs: ref.read(useLbsProvider),
              ),
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
    final keyboardOpen = MediaQuery.viewInsetsOf(context).bottom > 0;

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
                    onMinimize: _minimizeWorkout,
                    onSaveAsRoutine: _saveAsRoutine,
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
                                Icon(
                                  Icons.add_circle_outline_rounded,
                                  size: 48,
                                  color: AppColors.textMuted,
                                ),
                                const SizedBox(height: 12),
                                Text(
                                  'No exercises yet',
                                  style: TextStyle(color: AppColors.textMuted),
                                ),
                                const SizedBox(height: 16),
                                ElevatedButton.icon(
                                  onPressed: _addExercise,
                                  icon: const Icon(Icons.add_rounded),
                                  label: const Text('Add Exercise'),
                                ),
                              ],
                            ),
                          )
                        : ReorderableListView.builder(
                            padding: EdgeInsets.only(
                              top: 8,
                              bottom: keyboardOpen ? 16 : 80,
                            ),
                            itemCount:
                                _exerciseDataList.length +
                                (keyboardOpen ? 0 : 1),
                            onReorder: _reorderExercises,
                            itemBuilder: (ctx, index) {
                              if (index == _exerciseDataList.length) {
                                return _AddExerciseFooter(
                                  key: const ValueKey('add_exercise_footer'),
                                  onAddExercise: _addExercise,
                                );
                              }

                              final data = _exerciseDataList[index];
                              final prevSection = index > 0
                                  ? _exerciseDataList[index - 1].sectionName
                                  : '';
                              final showHeader =
                                  data.sectionName.isNotEmpty &&
                                  data.sectionName != prevSection;
                              return Column(
                                key: ValueKey(data.exercise.id),
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  if (showHeader)
                                    Padding(
                                      padding: const EdgeInsets.fromLTRB(
                                        20,
                                        12,
                                        20,
                                        4,
                                      ),
                                      child: Row(
                                        children: [
                                          Container(
                                            width: 4,
                                            height: 16,
                                            decoration: BoxDecoration(
                                              color: AppColors.primary,
                                              borderRadius:
                                                  BorderRadius.circular(2),
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
                                    useLbs: resolveUseLbs(
                                      workoutExercise: data.useLbsOverride,
                                      global: useLbs,
                                    ),
                                    onCompleteSet: _completeSet,
                                    onUncompleteSet: _uncompleteSet,
                                    onUpdateSet: _updateSet,
                                    onAddSet: _addSetToExercise,
                                    onToggleUnit: (v) =>
                                        _toggleExerciseUnit(index, v),
                                    onNotesChanged: (weId, notes) {
                                      data.notes = notes;
                                      ref
                                          .read(workoutRepositoryProvider)
                                          .updateWorkoutExerciseNotes(
                                            weId,
                                            notes,
                                          );
                                    },
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
            if (_showRestTimer && !_restTimerMinimized)
              Positioned(
                left: 0,
                right: 0,
                bottom: 0,
                child: _RestTimerOverlay(
                  remaining: _restRemaining,
                  onDismiss: _dismissRestTimer,
                  onMinimize: _minimizeRestTimer,
                ),
              ),
            // ─── Minimized rest timer chip ─────────────
            if (_showRestTimer && _restTimerMinimized)
              Positioned(
                top: 12,
                right: 12,
                child: GestureDetector(
                  onTap: _expandRestTimer,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.primary,
                      borderRadius: BorderRadius.circular(24),
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.primary.withValues(alpha: 0.4),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          Icons.timer_rounded,
                          color: AppColors.background,
                          size: 14,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          Formatters.restTimer(_restRemaining),
                          style: const TextStyle(
                            color: AppColors.background,
                            fontWeight: FontWeight.w700,
                            fontSize: 13,
                          ),
                        ),
                        const SizedBox(width: 8),
                        GestureDetector(
                          onTap: _dismissRestTimer,
                          child: const Icon(
                            Icons.close_rounded,
                            color: AppColors.background,
                            size: 14,
                          ),
                        ),
                      ],
                    ),
                  ),
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
  final int? workoutExerciseId;
  String notes;
  // Per-exercise unit override: null = follow global toggle, true = lbs, false = kg.
  bool? useLbsOverride;

  _WorkoutExerciseData({
    required this.exercise,
    required this.sets,
    required this.lastSets,
    this.sectionName = '',
    this.workoutExerciseId,
    this.notes = '',
    this.useLbsOverride,
  });
}

class _SetData {
  int setNumber;
  // Always stored in kg (canonical). Display conversion happens in the UI.
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
  final VoidCallback onMinimize;
  final VoidCallback onSaveAsRoutine;

  const _WorkoutHeader({
    required this.elapsed,
    required this.onFinish,
    required this.onCancel,
    required this.onMinimize,
    required this.onSaveAsRoutine,
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
              child: const Icon(
                Icons.close_rounded,
                color: AppColors.error,
                size: 20,
              ),
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
                const Icon(
                  Icons.timer_outlined,
                  color: AppColors.primary,
                  size: 16,
                ),
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
          // Minimize button
          IconButton(
            onPressed: onMinimize,
            tooltip: 'Minimize',
            icon: const Icon(
              Icons.keyboard_arrow_down_rounded,
              color: AppColors.textMuted,
              size: 24,
            ),
          ),
          // Save as Routine
          PopupMenuButton<String>(
            icon: const Icon(
              Icons.more_vert_rounded,
              color: AppColors.textMuted,
              size: 22,
            ),
            color: AppColors.surface,
            onSelected: (v) {
              if (v == 'save_routine') onSaveAsRoutine();
            },
            itemBuilder: (_) => const [
              PopupMenuItem(
                value: 'save_routine',
                child: Row(
                  children: [
                    Icon(
                      Icons.bookmark_add_outlined,
                      size: 18,
                      color: AppColors.textSecondary,
                    ),
                    SizedBox(width: 10),
                    Text('Save as Routine'),
                  ],
                ),
              ),
            ],
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
            child: const Text(
              'Finish',
              style: TextStyle(fontWeight: FontWeight.w700),
            ),
          ),
        ],
      ),
    );
  }
}

class _AddExerciseFooter extends StatelessWidget {
  final VoidCallback onAddExercise;

  const _AddExerciseFooter({super.key, required this.onAddExercise});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 0),
      child: OutlinedButton.icon(
        onPressed: onAddExercise,
        icon: const Icon(Icons.add_rounded),
        label: const Text('Add Exercise'),
      ),
    );
  }
}

class _ExerciseCard extends StatefulWidget {
  final _WorkoutExerciseData data;
  final int exerciseIndex;
  final bool useLbs;
  final Future<void> Function(int, int) onCompleteSet;
  final Future<void> Function(int, int) onUncompleteSet;
  final Future<void> Function(int, int) onUpdateSet;
  final void Function(int) onAddSet;
  final ValueChanged<bool> onToggleUnit;
  final void Function(int weId, String notes)? onNotesChanged;
  final VoidCallback onRemove;

  const _ExerciseCard({
    required this.data,
    required this.exerciseIndex,
    required this.useLbs,
    required this.onCompleteSet,
    required this.onUncompleteSet,
    required this.onUpdateSet,
    required this.onAddSet,
    required this.onToggleUnit,
    this.onNotesChanged,
    required this.onRemove,
  });

  @override
  State<_ExerciseCard> createState() => _ExerciseCardState();
}

class _ExerciseCardState extends State<_ExerciseCard> {
  late final TextEditingController _notesController;

  @override
  void initState() {
    super.initState();
    _notesController = TextEditingController(text: widget.data.notes);
  }

  @override
  void didUpdateWidget(_ExerciseCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.data != widget.data &&
        _notesController.text != widget.data.notes) {
      _notesController.text = widget.data.notes;
    }
  }

  @override
  void dispose() {
    _notesController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final data = widget.data;
    final useLbs = widget.useLbs;
    final exerciseIndex = widget.exerciseIndex;

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
                            'Last: ${data.lastSets.map((s) => '${_displayWeight(s.weight, useLbs)}×${s.reps}').join(', ')}',
                            style: const TextStyle(
                              color: AppColors.textMuted,
                              fontSize: 11,
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
                _UnitToggle(useLbs: useLbs, onChanged: widget.onToggleUnit),
                IconButton(
                  icon: const Icon(
                    Icons.close_rounded,
                    color: AppColors.textMuted,
                    size: 18,
                  ),
                  onPressed: widget.onRemove,
                  visualDensity: VisualDensity.compact,
                ),
              ],
            ),
          ),

          // Notes field
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
            child: TextField(
              controller: _notesController,
              decoration: InputDecoration(
                filled: true,
                fillColor: AppColors.surfaceLight,
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 8,
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide.none,
                ),
                hintText: 'Notes...',
                hintStyle: const TextStyle(
                  color: AppColors.textMuted,
                  fontSize: 13,
                ),
                isDense: true,
                prefixIcon: const Icon(
                  Icons.notes_rounded,
                  color: AppColors.textMuted,
                  size: 16,
                ),
              ),
              style: const TextStyle(
                fontSize: 13,
                color: AppColors.textPrimary,
              ),
              maxLines: 1,
              onChanged: (v) {
                final weId = data.workoutExerciseId;
                if (weId != null) widget.onNotesChanged?.call(weId, v);
              },
            ),
          ),

          // Column headers
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                const SizedBox(
                  width: 36,
                  child: Text('SET', style: _headerStyle),
                ),
                Expanded(
                  child: Text(
                    useLbs ? 'LBS' : 'KG',
                    style: _headerStyle,
                    textAlign: TextAlign.center,
                  ),
                ),
                const Expanded(
                  child: Text(
                    'REPS',
                    style: _headerStyle,
                    textAlign: TextAlign.center,
                  ),
                ),
                const SizedBox(width: 52),
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
              onComplete: () => widget.onCompleteSet(exerciseIndex, setIndex),
              onUncomplete: () =>
                  widget.onUncompleteSet(exerciseIndex, setIndex),
              onUpdateSet: () => widget.onUpdateSet(exerciseIndex, setIndex),
              onWeightChanged: (v) => setData.weight = v,
              onRepsChanged: (v) => setData.reps = v,
            );
          }),

          // Add set button
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 4, 16, 12),
            child: GestureDetector(
              onTap: () => widget.onAddSet(exerciseIndex),
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
                    Icon(
                      Icons.add_rounded,
                      color: AppColors.textMuted,
                      size: 16,
                    ),
                    SizedBox(width: 4),
                    Text(
                      'Add Set',
                      style: TextStyle(
                        color: AppColors.textMuted,
                        fontSize: 13,
                      ),
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

String _displayWeight(double kg, bool useLbs) {
  final v = useLbs ? kgToLbs(kg) : kg;
  if (v == v.roundToDouble()) return v.toInt().toString();
  return v.toStringAsFixed(1);
}

class _UnitToggle extends StatelessWidget {
  final bool useLbs;
  final ValueChanged<bool> onChanged;

  const _UnitToggle({required this.useLbs, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => onChanged(!useLbs),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration: BoxDecoration(
          color: AppColors.surfaceLight,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Text(
          useLbs ? 'LBS' : 'KG',
          style: const TextStyle(
            color: AppColors.primary,
            fontSize: 11,
            fontWeight: FontWeight.w700,
            letterSpacing: 0.5,
          ),
        ),
      ),
    );
  }
}

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
      text: _formatWeight(widget.setData.weight),
    );
    _repsCtrl = TextEditingController(
      text: widget.setData.reps > 0 ? widget.setData.reps.toString() : '',
    );
  }

  @override
  void didUpdateWidget(_SetRow oldWidget) {
    super.didUpdateWidget(oldWidget);
    // When the unit flips, re-render the field with the converted value. We
    // only repopulate on unit change (not on every rebuild) so we don't clobber
    // what the user is currently typing.
    if (oldWidget.useLbs != widget.useLbs) {
      _weightCtrl.text = _formatWeight(widget.setData.weight);
    }
  }

  String _formatWeight(double kg) {
    if (kg <= 0) return '';
    final display = widget.useLbs ? kgToLbs(kg) : kg;
    if (display == display.roundToDouble()) return display.toInt().toString();
    return display.toStringAsFixed(1);
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
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
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
                    horizontal: 8,
                    vertical: 8,
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide.none,
                  ),
                  hintText: '0',
                  hintStyle: const TextStyle(color: AppColors.textMuted),
                ),
                onChanged: (v) {
                  final typed = double.tryParse(v) ?? 0;
                  final kg = widget.useLbs ? lbsToKg(typed) : typed;
                  widget.onWeightChanged(kg);
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
                    horizontal: 8,
                    vertical: 8,
                  ),
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
  final VoidCallback onMinimize;

  const _RestTimerOverlay({
    required this.remaining,
    required this.onDismiss,
    required this.onMinimize,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(24, 16, 24, 40),
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
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Rest Timer',
                style: TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
              IconButton(
                onPressed: onMinimize,
                icon: const Icon(
                  Icons.minimize_rounded,
                  color: AppColors.textMuted,
                  size: 20,
                ),
                tooltip: 'Minimize',
                visualDensity: VisualDensity.compact,
              ),
            ],
          ),
          const SizedBox(height: 4),
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
          Text(label, style: const TextStyle(color: AppColors.textSecondary)),
          Text(
            value,
            style: const TextStyle(
              color: AppColors.textPrimary,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}
