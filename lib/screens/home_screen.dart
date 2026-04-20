import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../theme/app_theme.dart';
import '../providers/providers.dart';
import '../database/app_database.dart';
import '../utils/formatters.dart';
import '../widgets/consistency_heatmap.dart';
import 'workout/active_workout_screen.dart';
import 'history/workout_detail_screen.dart';

/// Homepage — greeting, Start Workout, consistency heatmap, last session, routines.
class HomeScreen extends ConsumerWidget {
  final void Function(int tabIndex) onNavigate;

  const HomeScreen({super.key, required this.onNavigate});

  static const _routinesTabIndex = 2;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final routinesAsync = ref.watch(routinesProvider);
    final sessionsThisMonth = ref.watch(workoutsThisMonthCountProvider);
    final email = ref.watch(userEmailProvider);
    final firstName = _firstNameFromEmail(email);

    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _TopBar(),
            const SizedBox(height: 20),
            _Greeting(
              firstName: firstName,
              sessionsThisMonth: sessionsThisMonth,
            ),
            const SizedBox(height: 20),
            _StartWorkoutButton(
              onTap: () => onNavigate(_routinesTabIndex),
            ),
            const SizedBox(height: 20),
            _ConsistencyMapCard(),
            const SizedBox(height: 20),
            _LastSessionCard(),
            const SizedBox(height: 28),
            _SavedRoutinesSection(
              routinesAsync: routinesAsync,
              onTapRoutine: (r) => _showStartRoutineSheet(context, ref, r),
              onExplore: () => onNavigate(_routinesTabIndex),
            ),
          ],
        ),
      ),
    );
  }

  static String _firstNameFromEmail(String email) {
    if (!email.contains('@')) return 'there';
    final local = email.split('@').first;
    if (local.isEmpty) return 'there';
    final base = local.split(RegExp(r'[._\-+]')).first;
    if (base.isEmpty) return 'there';
    return base[0].toUpperCase() + base.substring(1).toLowerCase();
  }
}

// ─── Top bar ─────────────────────────────────────────────────────────────────

class _TopBar extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: AppColors.surfaceBright,
            border: Border.all(
              color: AppColors.primary.withValues(alpha: 0.4),
              width: 1.5,
            ),
          ),
          child: const Icon(Icons.person_rounded,
              size: 20, color: AppColors.textSecondary),
        ),
        const SizedBox(width: 12),
        const Text(
          'TRACKER',
          style: TextStyle(
            color: AppColors.textPrimary,
            fontWeight: FontWeight.w800,
            letterSpacing: 2,
            fontSize: 14,
          ),
        ),
        const Spacer(),
        Icon(Icons.notifications_none_rounded,
            size: 22, color: AppColors.textSecondary),
      ],
    );
  }
}

// ─── Greeting ────────────────────────────────────────────────────────────────

class _Greeting extends StatelessWidget {
  final String firstName;
  final int sessionsThisMonth;

  const _Greeting({
    required this.firstName,
    required this.sessionsThisMonth,
  });

  @override
  Widget build(BuildContext context) {
    final hour = DateTime.now().hour;
    final tod = hour < 12
        ? 'Morning'
        : hour < 17
            ? 'Afternoon'
            : 'Evening';

    final subtitle = sessionsThisMonth == 0
        ? "Let's get your first session in this month."
        : "Your momentum is building. You've completed "
            "$sessionsThisMonth session${sessionsThisMonth == 1 ? '' : 's'} this month.";

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        RichText(
          text: TextSpan(
            style: const TextStyle(
              color: AppColors.textPrimary,
              fontSize: 32,
              fontWeight: FontWeight.w800,
              height: 1.1,
            ),
            children: [
              TextSpan(text: '$tod, '),
              TextSpan(
                text: '$firstName.',
                style: const TextStyle(color: AppColors.primary),
              ),
            ],
          ),
        ),
        const SizedBox(height: 8),
        Text(
          subtitle,
          style: const TextStyle(
            color: AppColors.textSecondary,
            fontSize: 14,
          ),
        ),
      ],
    );
  }
}

// ─── Start Workout button ────────────────────────────────────────────────────

class _StartWorkoutButton extends StatelessWidget {
  final VoidCallback onTap;

  const _StartWorkoutButton({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 18),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(18),
            gradient: const LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [AppColors.primary, AppColors.primaryDark],
            ),
            boxShadow: [
              BoxShadow(
                color: AppColors.primary.withValues(alpha: 0.35),
                blurRadius: 18,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: const Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.play_circle_fill_rounded,
                  color: AppColors.background, size: 22),
              SizedBox(width: 10),
              Text(
                'Start Workout',
                style: TextStyle(
                  color: AppColors.background,
                  fontWeight: FontWeight.w800,
                  fontSize: 16,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─── Consistency Map card ────────────────────────────────────────────────────

class _ConsistencyMapCard extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final data = ref.watch(workoutHeatmapProvider);

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppColors.bentoRadius),
        border: Border.all(color: AppColors.divider),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const Expanded(
                child: Text(
                  'Consistency Map',
                  style: TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              const ConsistencyHeatmapLegend(),
            ],
          ),
          const SizedBox(height: 16),
          ConsistencyHeatmap(data: data),
          const SizedBox(height: 14),
          const Text(
            'Consistency is the bridge between goals and accomplishment.',
            style: TextStyle(
              color: AppColors.textMuted,
              fontStyle: FontStyle.italic,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Last Session card ───────────────────────────────────────────────────────

class _LastSessionCard extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final statsAsync = ref.watch(lastSessionStatsProvider);
    final routinesAsync = ref.watch(routinesProvider);
    final useLbs = ref.watch(useLbsProvider);

    return statsAsync.when(
      loading: () => const _LastSessionShell(
        child: Center(
          child: Padding(
            padding: EdgeInsets.symmetric(vertical: 24),
            child: CircularProgressIndicator(),
          ),
        ),
      ),
      error: (e, _) => _LastSessionShell(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 24),
          child: Text('Couldn\'t load last session: $e',
              style: const TextStyle(color: AppColors.textMuted)),
        ),
      ),
      data: (stats) {
        if (stats == null) {
          return _LastSessionShell(
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'LATEST SESSION',
                    style: TextStyle(
                      color: AppColors.textMuted,
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 1.5,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'No sessions yet',
                    style: TextStyle(
                      color: AppColors.textPrimary,
                      fontSize: 22,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    'Start a workout to see your stats here.',
                    style: TextStyle(color: AppColors.textMuted, fontSize: 13),
                  ),
                ],
              ),
            ),
          );
        }

        final routineName = stats.workout.routineId != null
            ? routinesAsync.valueOrNull
                ?.where((r) => r.id == stats.workout.routineId)
                .firstOrNull
                ?.name
            : null;

        return _LastSessionShell(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Expanded(
                    child: Text(
                      'LATEST SESSION',
                      style: TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 1.5,
                      ),
                    ),
                  ),
                  Icon(Icons.bolt_rounded,
                      color: AppColors.primary, size: 20),
                ],
              ),
              const SizedBox(height: 6),
              Text(
                routineName ?? 'Free Workout',
                style: const TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 24,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 18),
              _StatRow(
                label: 'Duration',
                value: Formatters.duration(stats.duration),
              ),
              const SizedBox(height: 8),
              _StatRow(
                label: 'Volume',
                value: Formatters.volume(stats.volume, useLbs: useLbs),
              ),
              const SizedBox(height: 8),
              _StatRow(
                label: 'New PRs',
                value: '★ ${stats.newPrs}',
                accent: true,
              ),
              const SizedBox(height: 18),
              SizedBox(
                width: double.infinity,
                child: TextButton(
                  onPressed: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) =>
                            WorkoutDetailScreen(workoutId: stats.workout.id),
                      ),
                    );
                  },
                  style: TextButton.styleFrom(
                    backgroundColor: Colors.white.withValues(alpha: 0.08),
                    foregroundColor: AppColors.textPrimary,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text(
                    'View Analysis',
                    style: TextStyle(fontWeight: FontWeight.w700),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _LastSessionShell extends StatelessWidget {
  final Widget child;
  const _LastSessionShell({required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(AppColors.bentoRadius),
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF1E3A5F), Color(0xFF15283F)],
        ),
        border: Border.all(color: AppColors.secondary.withValues(alpha: 0.25)),
      ),
      child: child,
    );
  }
}

class _StatRow extends StatelessWidget {
  final String label;
  final String value;
  final bool accent;

  const _StatRow({
    required this.label,
    required this.value,
    this.accent = false,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: const TextStyle(
            color: AppColors.textSecondary,
            fontSize: 14,
          ),
        ),
        Text(
          value,
          style: TextStyle(
            color: accent ? AppColors.primary : AppColors.textPrimary,
            fontSize: 16,
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    );
  }
}

// ─── Saved Routines section ──────────────────────────────────────────────────

class _SavedRoutinesSection extends StatelessWidget {
  final AsyncValue<List<Routine>> routinesAsync;
  final void Function(Routine) onTapRoutine;
  final VoidCallback onExplore;

  const _SavedRoutinesSection({
    required this.routinesAsync,
    required this.onTapRoutine,
    required this.onExplore,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Saved Routines',
                    style: TextStyle(
                      color: AppColors.textPrimary,
                      fontSize: 20,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  SizedBox(height: 2),
                  Text(
                    'Jump back into your custom programs',
                    style: TextStyle(
                      color: AppColors.textMuted,
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
            ),
            TextButton(
              onPressed: onExplore,
              style: TextButton.styleFrom(
                foregroundColor: AppColors.primary,
                padding: const EdgeInsets.symmetric(horizontal: 4),
              ),
              child: const Text(
                'Explore\nLibrary',
                textAlign: TextAlign.right,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        routinesAsync.when(
          loading: () => const Padding(
            padding: EdgeInsets.all(24),
            child: Center(child: CircularProgressIndicator()),
          ),
          error: (e, _) => Padding(
            padding: const EdgeInsets.all(16),
            child: Text('Error: $e',
                style: const TextStyle(color: AppColors.textMuted)),
          ),
          data: (routines) {
            if (routines.isEmpty) {
              return Container(
                padding: const EdgeInsets.all(28),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(AppColors.bentoRadius),
                  border: Border.all(color: AppColors.divider),
                ),
                child: const Center(
                  child: Text(
                    'No routines yet.\nCreate one from the Routines tab.',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: AppColors.textMuted),
                  ),
                ),
              );
            }
            return Column(
              children: [
                for (final r in routines) ...[
                  _RoutineCard(routine: r, onTap: () => onTapRoutine(r)),
                  const SizedBox(height: 12),
                ],
              ],
            );
          },
        ),
      ],
    );
  }
}

class _RoutineCard extends ConsumerWidget {
  final Routine routine;
  final VoidCallback onTap;

  const _RoutineCard({required this.routine, required this.onTap});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final color = Color(int.parse('0x${routine.colorHex}'));
    final exercisesAsync = ref.watch(routineExercisesProvider(routine.id));

    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: AppColors.divider),
          ),
          child: Row(
            children: [
              Container(
                width: 4,
                height: 44,
                decoration: BoxDecoration(
                  color: color,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      routine.name,
                      style: const TextStyle(
                        color: AppColors.textPrimary,
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    exercisesAsync.when(
                      loading: () => const Text('…',
                          style: TextStyle(
                              color: AppColors.textMuted, fontSize: 12)),
                      error: (_, _) => const SizedBox.shrink(),
                      data: (list) {
                        final count = list.length;
                        return Text(
                          '$count exercise${count == 1 ? '' : 's'}',
                          style: const TextStyle(
                            color: AppColors.textMuted,
                            fontSize: 12,
                          ),
                        );
                      },
                    ),
                  ],
                ),
              ),
              Icon(Icons.play_arrow_rounded, color: color, size: 24),
            ],
          ),
        ),
      ),
    );
  }
}

// ─── Start-routine bottom sheet ──────────────────────────────────────────────

Future<void> _showStartRoutineSheet(
    BuildContext context, WidgetRef ref, Routine routine) async {
  final color = Color(int.parse('0x${routine.colorHex}'));
  final exercises =
      await ref.read(routineRepositoryProvider).getExercises(routine.id);
  final allExercises = await ref.read(exerciseRepositoryProvider).getAll();

  if (!context.mounted) return;

  await showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: AppColors.surface,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
    ),
    builder: (ctx) {
      return Padding(
        padding: EdgeInsets.only(
          left: 24,
          right: 24,
          top: 24,
          bottom: MediaQuery.of(ctx).viewInsets.bottom + 32,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                margin: const EdgeInsets.only(bottom: 24),
                decoration: BoxDecoration(
                  color: AppColors.divider,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Icon(Icons.fitness_center_rounded,
                      color: color, size: 24),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        routine.name,
                        style: const TextStyle(
                          fontWeight: FontWeight.w800,
                          fontSize: 20,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      if (routine.description.isNotEmpty)
                        MarkdownBody(
                          data: routine.description,
                          shrinkWrap: true,
                          styleSheet: MarkdownStyleSheet(
                            p: const TextStyle(
                              color: AppColors.textMuted,
                              fontSize: 13,
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            if (exercises.isNotEmpty) ...[
              Text(
                '${exercises.length} Exercise${exercises.length == 1 ? '' : 's'}',
                style: const TextStyle(
                  color: AppColors.textMuted,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 0.5,
                ),
              ),
              const SizedBox(height: 8),
              ...exercises.take(5).map((re) {
                final ex = allExercises
                    .where((e) => e.id == re.exerciseId)
                    .firstOrNull;
                if (ex == null) return const SizedBox.shrink();
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 3),
                  child: Row(
                    children: [
                      const Icon(Icons.circle,
                          size: 5, color: AppColors.textMuted),
                      const SizedBox(width: 8),
                      Text(
                        '${ex.name}  ·  ${re.targetSets}×${re.targetReps}',
                        style: const TextStyle(
                            color: AppColors.textSecondary, fontSize: 14),
                      ),
                    ],
                  ),
                );
              }),
              if (exercises.length > 5)
                Padding(
                  padding: const EdgeInsets.only(top: 4, left: 13),
                  child: Text(
                    '+ ${exercises.length - 5} more',
                    style: const TextStyle(
                        color: AppColors.textMuted, fontSize: 13),
                  ),
                ),
              const SizedBox(height: 20),
            ],
            const Divider(color: AppColors.divider),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () async {
                  Navigator.pop(ctx);
                  final repo = ref.read(workoutRepositoryProvider);
                  final workoutId = await repo.start(routineId: routine.id);
                  if (context.mounted) {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => ActiveWorkoutScreen(
                          workoutId: workoutId,
                          routineId: routine.id,
                        ),
                      ),
                    );
                  }
                },
                icon: const Icon(Icons.play_arrow_rounded),
                label: const Text('Start Workout',
                    style: TextStyle(fontWeight: FontWeight.w700)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: AppColors.background,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 10),
            SizedBox(
              width: double.infinity,
              child: TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text('Cancel',
                    style: TextStyle(color: AppColors.textMuted)),
              ),
            ),
          ],
        ),
      );
    },
  );
}
