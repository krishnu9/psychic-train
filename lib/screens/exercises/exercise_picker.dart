import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../theme/app_theme.dart';
import '../../providers/providers.dart';

import '../../models/tables.dart';

/// Bottom sheet for picking an exercise to add to a routine or workout.
class ExercisePickerSheet extends ConsumerStatefulWidget {
  const ExercisePickerSheet({super.key});

  @override
  ConsumerState<ExercisePickerSheet> createState() =>
      _ExercisePickerSheetState();
}

class _ExercisePickerSheetState extends ConsumerState<ExercisePickerSheet> {
  String _search = '';

  @override
  Widget build(BuildContext context) {
    final exercisesAsync = ref.watch(exercisesProvider);
    final _categoryFilter = ref.watch(exercisePickerFilterProvider);

    return DraggableScrollableSheet(
      initialChildSize: 0.85,
      minChildSize: 0.5,
      maxChildSize: 0.95,
      expand: false,
      builder: (ctx, scrollController) => Column(
        children: [
          // Handle bar
          Padding(
            padding: const EdgeInsets.only(top: 12, bottom: 8),
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: AppColors.textMuted,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Text('Select Exercise',
                style: Theme.of(ctx).textTheme.titleLarge),
          ),
          const SizedBox(height: 12),

          // Search
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: TextField(
              onChanged: (v) => setState(() => _search = v),
              decoration: const InputDecoration(
                hintText: 'Search...',
                prefixIcon:
                    Icon(Icons.search_rounded, color: AppColors.textMuted),
              ),
            ),
          ),
          const SizedBox(height: 8),

          // Category chips
          SizedBox(
            height: 36,
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              children: [
                _chip('All', _categoryFilter == null,
                    () => ref.read(exercisePickerFilterProvider.notifier).state = null),
                ...ExerciseCategories.all.map((c) => _chip(
                    c,
                    _categoryFilter == c,
                    () => ref.read(exercisePickerFilterProvider.notifier).state = c)),
              ],
            ),
          ),
          const SizedBox(height: 8),

          // List
          Expanded(
            child: exercisesAsync.when(
              data: (exercises) {
                var filtered = exercises;
                if (_search.isNotEmpty) {
                  filtered = filtered
                      .where((e) => e.name
                          .toLowerCase()
                          .contains(_search.toLowerCase()))
                      .toList();
                }
                if (_categoryFilter != null) {
                  filtered = filtered
                      .where((e) => e.category == _categoryFilter)
                      .toList();
                }

                return ListView.builder(
                  controller: scrollController,
                  itemCount: filtered.length,
                  itemBuilder: (ctx, i) {
                    final ex = filtered[i];
                    return ListTile(
                      title: Text(ex.name,
                          style: const TextStyle(
                              color: AppColors.textPrimary)),
                      subtitle: Text(
                        '${ex.equipment} · ${ex.targetMuscle}',
                        style: const TextStyle(
                            color: AppColors.textMuted, fontSize: 12),
                      ),
                      onTap: () => Navigator.pop(ctx, ex),
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

  Widget _chip(String label, bool selected, VoidCallback onTap) {
    return Padding(
      padding: const EdgeInsets.only(right: 6),
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: selected
                ? AppColors.primary.withValues(alpha: 0.2)
                : AppColors.surfaceLight,
            borderRadius: BorderRadius.circular(16),
            border:
                selected ? Border.all(color: AppColors.primary, width: 1) : null,
          ),
          child: Text(
            label,
            style: TextStyle(
              color: selected ? AppColors.primary : AppColors.textSecondary,
              fontWeight: selected ? FontWeight.w600 : FontWeight.w400,
              fontSize: 12,
            ),
          ),
        ),
      ),
    );
  }
}
