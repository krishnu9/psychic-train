import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../theme/app_theme.dart';
import '../../providers/providers.dart';
import '../../database/app_database.dart';

import '../exercises/exercise_picker.dart';

class RoutineEditScreen extends ConsumerStatefulWidget {
  final int? routineId;
  const RoutineEditScreen({super.key, this.routineId});

  @override
  ConsumerState<RoutineEditScreen> createState() => _RoutineEditScreenState();
}

class _RoutineEditScreenState extends ConsumerState<RoutineEditScreen> {
  final _nameController = TextEditingController();
  final _descController = TextEditingController();
  String _selectedColor = 'FF6366F1';
  bool _isLoading = true;
  bool _isNew = true;

  @override
  void initState() {
    super.initState();
    if (widget.routineId != null) {
      _isNew = false;
      _loadRoutine();
    } else {
      _isLoading = false;
    }
  }

  Future<void> _loadRoutine() async {
    final routine =
        await ref.read(routineRepositoryProvider).getById(widget.routineId!);
    if (routine != null) {
      _nameController.text = routine.name;
      _descController.text = routine.description;
      _selectedColor = routine.colorHex;
    }
    setState(() => _isLoading = false);
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final exercisesAsync = widget.routineId != null
        ? ref.watch(routineExercisesProvider(widget.routineId!))
        : null;

    return Scaffold(
      appBar: AppBar(
        title: Text(_isNew ? 'New Routine' : 'Edit Routine'),
        actions: [
          TextButton(
            onPressed: _saveRoutine,
            child: const Text('Save',
                style: TextStyle(
                    color: AppColors.primary, fontWeight: FontWeight.w600)),
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // ─── Name ──────────────────────────────
                  TextField(
                    controller: _nameController,
                    decoration: const InputDecoration(
                      hintText: 'Routine name',
                      labelText: 'Name',
                    ),
                    textCapitalization: TextCapitalization.words,
                    style: const TextStyle(
                        fontSize: 18, fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 16),

                  // ─── Description ───────────────────────
                  TextField(
                    controller: _descController,
                    decoration: const InputDecoration(
                      hintText: 'Description (optional)',
                      labelText: 'Description',
                    ),
                    maxLines: 2,
                  ),
                  const SizedBox(height: 20),

                  // ─── Color picker ──────────────────────
                  Text('Color',
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                            color: AppColors.textSecondary,
                          )),
                  const SizedBox(height: 10),
                  Wrap(
                    spacing: 10,
                    children: AppColors.routineColors.map((c) {
                      final hex = c.toARGB32()
                          .toRadixString(16)
                          .toUpperCase()
                          .padLeft(8, '0');
                      final isSelected = _selectedColor == hex;
                      return GestureDetector(
                        onTap: () => setState(() => _selectedColor = hex),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          width: 36,
                          height: 36,
                          decoration: BoxDecoration(
                            color: c,
                            shape: BoxShape.circle,
                            border: isSelected
                                ? Border.all(color: Colors.white, width: 3)
                                : null,
                            boxShadow: isSelected
                                ? [
                                    BoxShadow(
                                      color: c.withValues(alpha: 0.5),
                                      blurRadius: 8,
                                    ),
                                  ]
                                : null,
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 28),

                  // ─── Exercises in routine ──────────────
                  if (!_isNew) ...[
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('Exercises',
                            style: Theme.of(context).textTheme.titleMedium),
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            TextButton.icon(
                              onPressed: () => _addSection(context),
                              icon: const Icon(Icons.label_outline_rounded, size: 18),
                              label: const Text('Section'),
                            ),
                            TextButton.icon(
                              onPressed: () => _addExercise(context),
                              icon: const Icon(Icons.add_rounded, size: 18),
                              label: const Text('Add'),
                            ),
                          ],
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    if (exercisesAsync != null)
                      exercisesAsync.when(
                        data: (entries) {
                          if (entries.isEmpty) {
                            return Container(
                              width: double.infinity,
                              padding: const EdgeInsets.all(32),
                              decoration: BoxDecoration(
                                color: AppColors.surfaceLight,
                                borderRadius: BorderRadius.circular(16),
                              ),
                              child: Column(
                                children: [
                                  Icon(Icons.add_circle_outline_rounded,
                                      size: 40, color: AppColors.textMuted),
                                  const SizedBox(height: 8),
                                  Text('No exercises added yet',
                                      style: TextStyle(
                                          color: AppColors.textMuted)),
                                ],
                              ),
                            );
                          }

                          return ReorderableListView.builder(
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            itemCount: entries.length,
                            onReorder: (oldIdx, newIdx) {
                              if (newIdx > oldIdx) newIdx--;
                              final ids =
                                  entries.map((e) => e.id).toList();
                              final item = ids.removeAt(oldIdx);
                              ids.insert(newIdx, item);
                              ref
                                  .read(routineRepositoryProvider)
                                  .reorderExercises(
                                      widget.routineId!, ids);
                            },
                            itemBuilder: (ctx, index) {
                              final entry = entries[index];
                              final prevSection = index > 0
                                  ? entries[index - 1].sectionName
                                  : '';
                              final showHeader =
                                  entry.sectionName.isNotEmpty &&
                                      entry.sectionName != prevSection;
                              return _RoutineExerciseItem(
                                key: ValueKey(entry.id),
                                entry: entry,
                                showSectionHeader: showHeader,
                                onDelete: () async {
                                  await ref
                                      .read(routineRepositoryProvider)
                                      .removeExercise(entry.id);
                                },
                                onUpdate: (sets, reps, weight) async {
                                  await ref
                                      .read(routineRepositoryProvider)
                                      .updateExercise(entry.id,
                                          sets: sets,
                                          reps: reps,
                                          weight: weight);
                                },
                                onSectionChanged: (section) async {
                                  await ref
                                      .read(routineRepositoryProvider)
                                      .updateExercise(entry.id,
                                          sectionName: section);
                                },
                              );
                            },
                          );
                        },
                        loading: () => const Center(
                            child: CircularProgressIndicator()),
                        error: (e, _) => Text('Error: $e'),
                      ),
                  ] else
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(24),
                      decoration: BoxDecoration(
                        color: AppColors.surfaceLight,
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Text(
                        'Save the routine first, then add exercises.',
                        style: TextStyle(color: AppColors.textMuted),
                        textAlign: TextAlign.center,
                      ),
                    ),
                ],
              ),
            ),
    );
  }

  Future<void> _saveRoutine() async {
    final name = _nameController.text.trim();
    if (name.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a routine name')),
      );
      return;
    }

    final repo = ref.read(routineRepositoryProvider);
    if (_isNew) {
      final id = await repo.create(
        name: name,
        description: _descController.text.trim(),
        colorHex: _selectedColor,
      );
      if (mounted) {
        // Navigate to edit mode so user can add exercises
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (_) => RoutineEditScreen(routineId: id),
          ),
        );
      }
    } else {
      await repo.update(
        widget.routineId!,
        name: name,
        description: _descController.text.trim(),
        colorHex: _selectedColor,
      );
      if (mounted) Navigator.pop(context);
    }
  }

  void _addExercise(BuildContext context) async {
    final selected = await showModalBottomSheet<Exercise>(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) => const ExercisePickerSheet(),
    );

    if (selected != null && widget.routineId != null) {
      final entries =
          await ref.read(routineRepositoryProvider).getExercises(widget.routineId!);
      final section = _pendingSection.isNotEmpty
          ? _pendingSection
          : entries.isNotEmpty ? entries.last.sectionName : '';
      await ref.read(routineRepositoryProvider).addExercise(
            widget.routineId!,
            selected.id,
            entries.length,
            sectionName: section,
          );
    }
  }

  void _addSection(BuildContext context) async {
    final controller = TextEditingController();
    final name = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surface,
        title: const Text('New Section'),
        content: TextField(
          controller: controller,
          autofocus: true,
          decoration: const InputDecoration(hintText: 'Section name'),
          textCapitalization: TextCapitalization.words,
          onSubmitted: (v) => Navigator.pop(ctx, v.trim()),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, controller.text.trim()),
            child: const Text('Add'),
          ),
        ],
      ),
    );
    controller.dispose();
    if (name == null || name.isEmpty || widget.routineId == null) return;

    // Update the next added exercise to use this section,
    // or if there are existing exercises, set the last one's section
    // to create a visible section break
    final entries =
        await ref.read(routineRepositoryProvider).getExercises(widget.routineId!);
    if (entries.isNotEmpty) {
      // Set section on the last exercise so the next added exercise inherits it
      await ref.read(routineRepositoryProvider).updateExercise(
            entries.last.id,
            sectionName: name,
          );
    }
    // Store the section name for next exercise additions
    setState(() => _pendingSection = name);
  }

  String _pendingSection = '';
}

class _RoutineExerciseItem extends ConsumerStatefulWidget {
  final RoutineExerciseEntry entry;
  final bool showSectionHeader;
  final VoidCallback onDelete;
  final void Function(int? sets, int? reps, double? weight) onUpdate;
  final void Function(String section) onSectionChanged;

  const _RoutineExerciseItem({
    super.key,
    required this.entry,
    this.showSectionHeader = false,
    required this.onDelete,
    required this.onUpdate,
    required this.onSectionChanged,
  });

  @override
  ConsumerState<_RoutineExerciseItem> createState() =>
      _RoutineExerciseItemState();
}

class _RoutineExerciseItemState extends ConsumerState<_RoutineExerciseItem> {
  bool _expanded = false;
  late List<_RoutineSetData> _sets;

  @override
  void initState() {
    super.initState();
    // Initialize per-set data from the existing entry defaults
    _sets = List.generate(
      widget.entry.targetSets,
      (_) => _RoutineSetData(
        weight: widget.entry.targetWeight,
        reps: widget.entry.targetReps,
      ),
    );
  }

  void _addSet() {
    setState(() {
      final last = _sets.isNotEmpty ? _sets.last : null;
      _sets.add(_RoutineSetData(
        weight: last?.weight ?? 0,
        reps: last?.reps ?? 10,
      ));
    });
    _persistChanges();
  }

  void _removeSet(int index) {
    if (_sets.length <= 1) return;
    setState(() => _sets.removeAt(index));
    _persistChanges();
  }

  void _persistChanges() {
    // Use the first set's values as the template defaults
    final firstSet = _sets.isNotEmpty ? _sets.first : null;
    widget.onUpdate(
      _sets.length,
      firstSet?.reps ?? 10,
      firstSet?.weight ?? 0,
    );
  }

  @override
  Widget build(BuildContext context) {
    final exercisesAsync = ref.watch(exercisesProvider);
    final exerciseName = exercisesAsync.when(
      data: (list) =>
          list.where((e) => e.id == widget.entry.exerciseId).firstOrNull?.name ??
          'Unknown',
      loading: () => '...',
      error: (_, _) => 'Error',
    );

    return Column(
      children: [
        if (widget.showSectionHeader)
          Padding(
            padding: const EdgeInsets.only(bottom: 6, top: 8),
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
                  widget.entry.sectionName,
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
        Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.divider),
      ),
      child: Column(
        children: [
          // ─── Header row (always visible) ──────────────
          InkWell(
            borderRadius: BorderRadius.circular(14),
            onTap: () => setState(() => _expanded = !_expanded),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              child: Row(
                children: [
                  const Icon(Icons.drag_handle_rounded,
                      color: AppColors.textMuted, size: 20),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          exerciseName,
                          style: const TextStyle(
                            fontWeight: FontWeight.w600,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        const SizedBox(height: 3),
                        Text(
                          '${_sets.length} sets × ${_sets.isNotEmpty ? _sets.first.reps : 0} reps'
                          '${_sets.isNotEmpty && _sets.first.weight > 0 ? ' @ ${_sets.first.weight} kg' : ''}',
                          style: const TextStyle(
                            color: AppColors.textMuted,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                  AnimatedRotation(
                    turns: _expanded ? 0.5 : 0,
                    duration: const Duration(milliseconds: 200),
                    child: const Icon(Icons.expand_more_rounded,
                        color: AppColors.textMuted, size: 22),
                  ),
                  IconButton(
                    onPressed: widget.onDelete,
                    icon: const Icon(Icons.close_rounded,
                        color: AppColors.textMuted, size: 18),
                    visualDensity: VisualDensity.compact,
                  ),
                ],
              ),
            ),
          ),

          // ─── Expanded per-set editing ────────────────
          AnimatedCrossFade(
            firstChild: const SizedBox.shrink(),
            secondChild: _buildSetEditor(),
            crossFadeState:
                _expanded ? CrossFadeState.showSecond : CrossFadeState.showFirst,
            duration: const Duration(milliseconds: 250),
          ),
        ],
      ),
    ),
      ],
    );
  }

  Widget _buildSetEditor() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 0, 12, 10),
      child: Column(
        children: [
          const Divider(height: 1, color: AppColors.divider),
          const SizedBox(height: 8),

          // Section name field
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: TextField(
              controller: TextEditingController(text: widget.entry.sectionName),
              decoration: InputDecoration(
                filled: true,
                fillColor: AppColors.surfaceLight,
                contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide.none,
                ),
                hintText: 'Section (optional)',
                hintStyle: const TextStyle(color: AppColors.textMuted, fontSize: 13),
                prefixIcon: const Icon(Icons.label_outline_rounded,
                    color: AppColors.textMuted, size: 18),
                isDense: true,
              ),
              style: const TextStyle(fontSize: 13),
              onChanged: (v) => widget.onSectionChanged(v.trim()),
            ),
          ),

          // Column headers
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 4),
            child: Row(
              children: [
                SizedBox(
                    width: 36,
                    child: Text('SET',
                        style: _routineHeaderStyle)),
                Expanded(
                    child: Text('KG',
                        style: _routineHeaderStyle,
                        textAlign: TextAlign.center)),
                Expanded(
                    child: Text('REPS',
                        style: _routineHeaderStyle,
                        textAlign: TextAlign.center)),
                SizedBox(width: 36),
              ],
            ),
          ),
          const SizedBox(height: 6),

          // Set rows
          ..._sets.asMap().entries.map((entry) {
            final i = entry.key;
            final setData = entry.value;
            return _RoutineSetRow(
              index: i,
              setData: setData,
              canRemove: _sets.length > 1,
              onRemove: () => _removeSet(i),
              onWeightChanged: (v) {
                setData.weight = v;
                _persistChanges();
              },
              onRepsChanged: (v) {
                setData.reps = v;
                _persistChanges();
              },
            );
          }),

          // Add set button
          const SizedBox(height: 4),
          GestureDetector(
            onTap: _addSet,
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 8),
              decoration: BoxDecoration(
                color: AppColors.surfaceLight,
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.add_rounded, color: AppColors.textMuted, size: 16),
                  SizedBox(width: 4),
                  Text('Add Set',
                      style: TextStyle(color: AppColors.textMuted, fontSize: 13)),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Per-set data model ──────────────────────────────────────────────────────

class _RoutineSetData {
  double weight;
  int reps;
  _RoutineSetData({required this.weight, required this.reps});
}

// ─── Header style constant ──────────────────────────────────────────────────

const _routineHeaderStyle = TextStyle(
  color: AppColors.textMuted,
  fontSize: 11,
  fontWeight: FontWeight.w600,
  letterSpacing: 0.5,
);

// ─── Single set row widget ──────────────────────────────────────────────────

class _RoutineSetRow extends StatefulWidget {
  final int index;
  final _RoutineSetData setData;
  final bool canRemove;
  final VoidCallback onRemove;
  final ValueChanged<double> onWeightChanged;
  final ValueChanged<int> onRepsChanged;

  const _RoutineSetRow({
    required this.index,
    required this.setData,
    required this.canRemove,
    required this.onRemove,
    required this.onWeightChanged,
    required this.onRepsChanged,
  });

  @override
  State<_RoutineSetRow> createState() => _RoutineSetRowState();
}

class _RoutineSetRowState extends State<_RoutineSetRow> {
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
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3, horizontal: 4),
      child: Row(
        children: [
          // Set number
          SizedBox(
            width: 36,
            child: Text(
              '${widget.index + 1}',
              style: const TextStyle(
                color: AppColors.textSecondary,
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
                style: const TextStyle(
                  color: AppColors.textPrimary,
                  fontWeight: FontWeight.w500,
                  fontSize: 14,
                ),
                decoration: InputDecoration(
                  filled: true,
                  fillColor: AppColors.surfaceLight,
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
                style: const TextStyle(
                  color: AppColors.textPrimary,
                  fontWeight: FontWeight.w500,
                  fontSize: 14,
                ),
                decoration: InputDecoration(
                  filled: true,
                  fillColor: AppColors.surfaceLight,
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
                },
              ),
            ),
          ),

          // Remove set button
          SizedBox(
            width: 36,
            child: widget.canRemove
                ? GestureDetector(
                    onTap: widget.onRemove,
                    child: const Icon(Icons.remove_circle_outline_rounded,
                        color: AppColors.textMuted, size: 18),
                  )
                : const SizedBox.shrink(),
          ),
        ],
      ),
    );
  }
}

