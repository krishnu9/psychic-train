import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../theme/app_theme.dart';
import '../../providers/providers.dart';
import '../../database/app_database.dart';
import '../../models/tables.dart';

class ExerciseListScreen extends ConsumerStatefulWidget {
  const ExerciseListScreen({super.key});

  @override
  ConsumerState<ExerciseListScreen> createState() => _ExerciseListScreenState();
}

class _ExerciseListScreenState extends ConsumerState<ExerciseListScreen> {
  String _searchQuery = '';
  String? _selectedCategory;

  @override
  Widget build(BuildContext context) {
    final exercisesAsync = ref.watch(exercisesProvider);

    return SafeArea(
      child: Column(
        children: [
          // ─── Header ────────────────────────────────
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 24, 20, 12),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Exercises',
                  style: Theme.of(context).textTheme.headlineLarge?.copyWith(
                        fontWeight: FontWeight.w800,
                      ),
                ),
                IconButton(
                  onPressed: () => _showAddExerciseDialog(context, ref),
                  icon: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(Icons.add_rounded,
                        color: AppColors.primary, size: 22),
                  ),
                ),
              ],
            ),
          ),

          // ─── Search bar ────────────────────────────
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: TextField(
              onChanged: (v) => setState(() => _searchQuery = v),
              decoration: InputDecoration(
                hintText: 'Search exercises...',
                prefixIcon: const Icon(Icons.search_rounded,
                    color: AppColors.textMuted),
                suffixIcon: _searchQuery.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear_rounded,
                            color: AppColors.textMuted),
                        onPressed: () =>
                            setState(() => _searchQuery = ''),
                      )
                    : null,
              ),
            ),
          ),
          const SizedBox(height: 12),

          // ─── Category chips ────────────────────────
          SizedBox(
            height: 40,
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              children: [
                _CategoryChip(
                  label: 'All',
                  selected: _selectedCategory == null,
                  onTap: () => setState(() => _selectedCategory = null),
                ),
                ...ExerciseCategories.all.map((cat) => _CategoryChip(
                      label: cat,
                      selected: _selectedCategory == cat,
                      onTap: () =>
                          setState(() => _selectedCategory = cat),
                    )),
              ],
            ),
          ),
          const SizedBox(height: 8),

          // ─── Exercise list ─────────────────────────
          Expanded(
            child: exercisesAsync.when(
              data: (exercises) {
                var filtered = exercises;
                if (_searchQuery.isNotEmpty) {
                  filtered = filtered
                      .where((e) => e.name
                          .toLowerCase()
                          .contains(_searchQuery.toLowerCase()))
                      .toList();
                }
                if (_selectedCategory != null) {
                  filtered = filtered
                      .where((e) => e.category == _selectedCategory)
                      .toList();
                }

                if (filtered.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.search_off_rounded,
                            size: 48, color: AppColors.textMuted),
                        const SizedBox(height: 12),
                        Text('No exercises found',
                            style: TextStyle(color: AppColors.textMuted)),
                      ],
                    ),
                  );
                }

                // Group by category
                final grouped = <String, List<Exercise>>{};
                for (final ex in filtered) {
                  grouped.putIfAbsent(ex.category, () => []).add(ex);
                }

                return ListView.builder(
                  padding: const EdgeInsets.only(bottom: 80),
                  itemCount: grouped.length,
                  itemBuilder: (context, index) {
                    final category = grouped.keys.elementAt(index);
                    final items = grouped[category]!;
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Padding(
                          padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
                          child: Text(
                            category,
                            style: Theme.of(context)
                                .textTheme
                                .titleSmall
                                ?.copyWith(
                                  color: AppColors.primary,
                                  fontWeight: FontWeight.w700,
                                  letterSpacing: 0.5,
                                ),
                          ),
                        ),
                        ...items.map((ex) => _ExerciseTile(exercise: ex)),
                      ],
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

  void _showAddExerciseDialog(BuildContext context, WidgetRef ref) {
    final nameController = TextEditingController();
    String category = ExerciseCategories.chest;
    String equipment = EquipmentTypes.barbell;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setSheetState) => Padding(
          padding: EdgeInsets.fromLTRB(
              20, 24, 20, MediaQuery.of(ctx).viewInsets.bottom + 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Add Custom Exercise',
                  style: Theme.of(ctx).textTheme.titleLarge),
              const SizedBox(height: 20),
              TextField(
                controller: nameController,
                decoration: const InputDecoration(hintText: 'Exercise name'),
                autofocus: true,
                textCapitalization: TextCapitalization.words,
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                initialValue: category,
                decoration: const InputDecoration(labelText: 'Category'),
                dropdownColor: AppColors.surfaceLight,
                items: ExerciseCategories.all
                    .map((c) =>
                        DropdownMenuItem(value: c, child: Text(c)))
                    .toList(),
                onChanged: (v) {
                  if (v != null) setSheetState(() => category = v);
                },
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                initialValue: equipment,
                decoration: const InputDecoration(labelText: 'Equipment'),
                dropdownColor: AppColors.surfaceLight,
                items: EquipmentTypes.all
                    .map((e) =>
                        DropdownMenuItem(value: e, child: Text(e)))
                    .toList(),
                onChanged: (v) {
                  if (v != null) setSheetState(() => equipment = v);
                },
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () async {
                    final name = nameController.text.trim();
                    if (name.isEmpty) return;
                    await ref.read(exerciseRepositoryProvider).create(
                          name: name,
                          category: category,
                          targetMuscle: category,
                          equipment: equipment,
                        );
                    if (ctx.mounted) Navigator.pop(ctx);
                  },
                  child: const Text('Add Exercise'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _CategoryChip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _CategoryChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(
            color: selected
                ? AppColors.primary.withValues(alpha: 0.2)
                : AppColors.surfaceLight,
            borderRadius: BorderRadius.circular(20),
            border: selected
                ? Border.all(color: AppColors.primary, width: 1)
                : null,
          ),
          child: Text(
            label,
            style: TextStyle(
              color: selected ? AppColors.primary : AppColors.textSecondary,
              fontWeight: selected ? FontWeight.w600 : FontWeight.w400,
              fontSize: 13,
            ),
          ),
        ),
      ),
    );
  }
}

class _ExerciseTile extends StatelessWidget {
  final Exercise exercise;
  const _ExerciseTile({required this.exercise});

  IconData _equipmentIcon(String equipment) {
    switch (equipment) {
      case 'Barbell':
        return Icons.fitness_center_rounded;
      case 'Dumbbell':
        return Icons.fitness_center_rounded;
      case 'Machine':
        return Icons.precision_manufacturing_rounded;
      case 'Cable':
        return Icons.cable_rounded;
      case 'Bodyweight':
        return Icons.accessibility_new_rounded;
      default:
        return Icons.sports_gymnastics_rounded;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 3),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
      ),
      child: ListTile(
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        leading: Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: AppColors.surfaceLight,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(
            _equipmentIcon(exercise.equipment),
            color: AppColors.textSecondary,
            size: 20,
          ),
        ),
        title: Text(
          exercise.name,
          style: const TextStyle(
            fontWeight: FontWeight.w500,
            color: AppColors.textPrimary,
          ),
        ),
        subtitle: Text(
          '${exercise.equipment} · ${exercise.targetMuscle}',
          style: const TextStyle(
            color: AppColors.textMuted,
            fontSize: 12,
          ),
        ),
        trailing: exercise.isCustom
            ? Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: const Text(
                  'Custom',
                  style: TextStyle(
                      color: AppColors.primary, fontSize: 11),
                ),
              )
            : null,
      ),
    );
  }
}
