import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../theme/app_theme.dart';
import '../../providers/providers.dart';
import '../../database/app_database.dart';
import 'routine_edit_screen.dart';

class RoutineListScreen extends ConsumerWidget {
  const RoutineListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final routinesAsync = ref.watch(routinesProvider);

    return SafeArea(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ─── Header ─────────────────────────────────
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 24, 20, 16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Routines',
                  style: Theme.of(context).textTheme.headlineLarge?.copyWith(
                        fontWeight: FontWeight.w800,
                      ),
                ),
                IconButton(
                  onPressed: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const RoutineEditScreen(),
                    ),
                  ),
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

          // ─── Routine list ───────────────────────────
          Expanded(
            child: routinesAsync.when(
              data: (routines) {
                if (routines.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.list_alt_rounded,
                            size: 64, color: AppColors.textMuted),
                        const SizedBox(height: 16),
                        Text(
                          'No routines yet',
                          style: Theme.of(context)
                              .textTheme
                              .titleMedium
                              ?.copyWith(color: AppColors.textMuted),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Create your first routine\nto start tracking workouts!',
                          textAlign: TextAlign.center,
                          style: TextStyle(color: AppColors.textMuted),
                        ),
                        const SizedBox(height: 24),
                        ElevatedButton.icon(
                          onPressed: () => Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => const RoutineEditScreen(),
                            ),
                          ),
                          icon: const Icon(Icons.add_rounded),
                          label: const Text('Create Routine'),
                        ),
                      ],
                    ),
                  );
                }

                return ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: routines.length,
                  itemBuilder: (context, index) {
                    final routine = routines[index];
                    return _RoutineListTile(routine: routine);
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

class _RoutineListTile extends ConsumerWidget {
  final Routine routine;
  const _RoutineListTile({required this.routine});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final color = Color(int.parse('0x${routine.colorHex}'));

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: color.withValues(alpha: 0.2),
          width: 1,
        ),
      ),
      child: ListTile(
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        leading: Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.15),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(Icons.fitness_center_rounded, color: color, size: 22),
        ),
        title: Text(
          routine.name,
          style: const TextStyle(
            fontWeight: FontWeight.w600,
            color: AppColors.textPrimary,
          ),
        ),
        subtitle: routine.description.isNotEmpty
            ? Text(
                routine.description,
                style: const TextStyle(
                  color: AppColors.textMuted,
                  fontSize: 13,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              )
            : null,
        trailing: PopupMenuButton<String>(
          color: AppColors.surfaceLight,
          icon: const Icon(Icons.more_vert_rounded,
              color: AppColors.textMuted),
          itemBuilder: (ctx) => [
            const PopupMenuItem(value: 'edit', child: Text('Edit')),
            const PopupMenuItem(
                value: 'duplicate', child: Text('Duplicate')),
            const PopupMenuItem(
              value: 'delete',
              child: Text('Delete', style: TextStyle(color: AppColors.error)),
            ),
          ],
          onSelected: (action) async {
            switch (action) {
              case 'edit':
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) =>
                        RoutineEditScreen(routineId: routine.id),
                  ),
                );
              case 'duplicate':
                await ref.read(routineRepositoryProvider).duplicate(
                      routine.id,
                      '${routine.name} (Copy)',
                    );
              case 'delete':
                final confirm = await showDialog<bool>(
                  context: context,
                  builder: (ctx) => AlertDialog(
                    backgroundColor: AppColors.surface,
                    title: const Text('Delete Routine?'),
                    content: Text(
                        'Are you sure you want to delete "${routine.name}"?'),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(ctx, false),
                        child: const Text('Cancel'),
                      ),
                      TextButton(
                        onPressed: () => Navigator.pop(ctx, true),
                        child: const Text('Delete',
                            style: TextStyle(color: AppColors.error)),
                      ),
                    ],
                  ),
                );
                if (confirm == true) {
                  await ref
                      .read(routineRepositoryProvider)
                      .delete(routine.id);
                }
            }
          },
        ),
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) =>
                RoutineEditScreen(routineId: routine.id),
          ),
        ),
      ),
    );
  }
}
