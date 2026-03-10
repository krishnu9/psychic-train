
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../theme/app_theme.dart';
import '../providers/providers.dart';
import '../database/app_database.dart';
import 'workout/active_workout_screen.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  @override
  Widget build(BuildContext context) {
    final routinesAsync = ref.watch(routinesProvider);
    final weekCountAsync = ref.watch(workoutsThisWeekProvider);
    final totalAsync = ref.watch(totalWorkoutsProvider);

    return SafeArea(
      child: CustomScrollView(
        slivers: [
          // ─── Header ─────────────────────────────────────
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 24, 20, 0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Tracker',
                        style:
                            Theme.of(context).textTheme.headlineLarge?.copyWith(
                                  color: AppColors.primary,
                                  fontWeight: FontWeight.w800,
                                  fontSize: 30,
                                ),
                      ),
                      Text(
                        'Ready to train?',
                        style:
                            Theme.of(context).textTheme.bodyMedium?.copyWith(
                                  color: AppColors.textSecondary,
                                ),
                      ),
                    ],
                  ),
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withValues(alpha: 0.12),
                      borderRadius:
                          BorderRadius.circular(AppColors.bentoRadius),
                    ),
                    child: const Icon(Icons.bolt_rounded,
                        color: AppColors.primary, size: 24),
                  ),
                ],
              ),
            ),
          ),

          // ─── Bento Grid ──────────────────────────────────
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 20, 16, 0),
              child: Column(
                children: [
                  // ── Row 1: Stats + Start Workout ──────────
                  SizedBox(
                    height: 260,
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        // Stat cards column
                        Expanded(
                          flex: 5,
                          child: Column(
                            children: [
                              _BentoStatCard(
                                label: 'This Week',
                                value: weekCountAsync.when(
                                  data: (v) => '$v',
                                  loading: () => '–',
                                  error: (_, e2) => '-',
                                ),
                                icon: Icons.calendar_today_rounded,
                                color: AppColors.primary,
                              ),
                              const SizedBox(height: 10),
                              _BentoStatCard(
                                label: 'Total',
                                value: totalAsync.when(
                                  data: (v) => '$v',
                                  loading: () => '–',
                                  error: (_, e2) => '-',
                                ),
                                icon: Icons.emoji_events_rounded,
                                color: AppColors.secondary,
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 10),
                        // Start Empty Workout hero card
                        Expanded(
                          flex: 7,
                          child: _StartEmptyWorkoutBento(ref: ref),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 10),

                  // ── Row 2: Motivational card ───────────────
                  _MotivationalBentoCard(),

                  const SizedBox(height: 20),

                  // ── Quick Start heading ────────────────────
                  Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      'Quick Start',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.w700,
                          ),
                    ),
                  ),
                  const SizedBox(height: 10),
                ],
              ),
            ),
          ),

          // ─── Routine Bento Grid ───────────────────────────
          routinesAsync.when(
            data: (routines) {
              if (routines.isEmpty) {
                return SliverToBoxAdapter(
                  child: Padding(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
                    child: Container(
                      padding: const EdgeInsets.all(32),
                      decoration: BoxDecoration(
                        color: AppColors.surface,
                        borderRadius:
                            BorderRadius.circular(AppColors.bentoRadius),
                        border: Border.all(
                            color: AppColors.divider.withValues(alpha: 0.5)),
                      ),
                      child: Center(
                        child: Column(
                          children: [
                            Icon(Icons.add_circle_outline_rounded,
                                size: 48, color: AppColors.textMuted),
                            const SizedBox(height: 12),
                            Text(
                              'No routines yet.\nGo to the Routines tab to create one!',
                              textAlign: TextAlign.center,
                              style: TextStyle(color: AppColors.textMuted),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                );
              }
              return SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 32),
                  child: _BentoRoutineGrid(
                    routines: routines,
                    onTap: (r) => _showStartRoutineConfirmation(r),
                  ),
                ),
              );
            },
            loading: () => const SliverToBoxAdapter(
              child: Center(child: CircularProgressIndicator()),
            ),
            error: (e, _) => SliverToBoxAdapter(
              child: Center(child: Text('Error: $e')),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _startWorkout(int routineId) async {
    final repo = ref.read(workoutRepositoryProvider);
    final workoutId = await repo.start(routineId: routineId);
    ref.read(activeWorkoutIdProvider.notifier).state = workoutId;
    if (mounted) {
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => ActiveWorkoutScreen(
            workoutId: workoutId,
            routineId: routineId,
          ),
        ),
      );
    }
  }

  Future<void> _showStartRoutineConfirmation(Routine routine) async {
    final color = Color(int.parse('0x${routine.colorHex}'));
    final exercises =
        await ref.read(routineRepositoryProvider).getExercises(routine.id);
    final allExercises = await ref.read(exerciseRepositoryProvider).getAll();

    if (!mounted) return;

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
                          Text(
                            routine.description,
                            style: const TextStyle(
                              color: AppColors.textMuted,
                              fontSize: 13,
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
                  final ex =
                      allExercises.where((e) => e.id == re.exerciseId).firstOrNull;
                  if (ex == null) return const SizedBox.shrink();
                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 3),
                    child: Row(
                      children: [
                        const Icon(Icons.circle, size: 5, color: AppColors.textMuted),
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
                      style:
                          const TextStyle(color: AppColors.textMuted, fontSize: 13),
                    ),
                  ),
                const SizedBox(height: 20),
              ],
              const Divider(color: AppColors.divider),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () {
                    Navigator.pop(ctx);
                    _startWorkout(routine.id);
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
}

// ─────────────────────────────────────────────────────────────────────────────
// Bento: Stat Card
// ─────────────────────────────────────────────────────────────────────────────

class _BentoStatCard extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color color;

  const _BentoStatCard({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(AppColors.bentoRadius),
          border: Border.all(color: color.withValues(alpha: 0.18), width: 1),
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              color.withValues(alpha: 0.08),
              AppColors.surface,
            ],
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(7),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, color: color, size: 16),
            ),
            const SizedBox(height: 10),
            Text(
              value,
              style: const TextStyle(
                color: AppColors.textPrimary,
                fontWeight: FontWeight.w800,
                fontSize: 28,
                height: 1,
              ),
            ),
            const SizedBox(height: 2),
            Text(label,
                style: const TextStyle(color: AppColors.textMuted, fontSize: 11)),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Bento: Start Empty Workout Hero Card
// ─────────────────────────────────────────────────────────────────────────────

class _StartEmptyWorkoutBento extends StatelessWidget {
  final WidgetRef ref;
  const _StartEmptyWorkoutBento({required this.ref});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(AppColors.bentoRadius),
        onTap: () async {
          final repo = ref.read(workoutRepositoryProvider);
          final workoutId = await repo.start();
          ref.read(activeWorkoutIdProvider.notifier).state = workoutId;
          if (context.mounted) {
            Navigator.of(context).push(
              MaterialPageRoute(
                builder: (_) => ActiveWorkoutScreen(
                  workoutId: workoutId,
                  routineId: null,
                ),
              ),
            );
          }
        },
        child: Container(
          width: double.infinity,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(AppColors.bentoRadius),
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                AppColors.primary.withValues(alpha: 0.9),
                AppColors.primaryDark,
              ],
            ),
          ),
          child: Stack(
            children: [
              // Decorative circles
              Positioned(
                top: -20,
                right: -20,
                child: Container(
                  width: 90,
                  height: 90,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.white.withValues(alpha: 0.08),
                  ),
                ),
              ),
              Positioned(
                bottom: -30,
                left: -10,
                child: Container(
                  width: 70,
                  height: 70,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.white.withValues(alpha: 0.05),
                  ),
                ),
              ),
              // Content
              Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(Icons.play_arrow_rounded,
                          color: Colors.white, size: 22),
                    ),
                    const SizedBox(height: 24),
                    const Text(
                      'Start\nEmpty\nWorkout',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w800,
                        fontSize: 18,
                        height: 1.2,
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Freestyle session',
                      style: TextStyle(
                        color: Colors.white70,
                        fontSize: 11,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Bento: Motivational Card
// ─────────────────────────────────────────────────────────────────────────────

class _MotivationalBentoCard extends StatelessWidget {
  static const _quotes = [
    'Push beyond\nyour limits.',
    'Every rep\ncounts.',
    'Stronger than\nyesterday.',
    'No excuses.\nJust results.',
    'Progress, not\nperfection.',
  ];

  @override
  Widget build(BuildContext context) {
    final idx = DateTime.now().day % _quotes.length;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(AppColors.bentoRadius),
        color: AppColors.surfaceLight,
        border:
            Border.all(color: AppColors.primary.withValues(alpha: 0.12), width: 1),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Daily Motivation',
                  style: TextStyle(
                    color: AppColors.primary,
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.8,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  _quotes[idx],
                  style: const TextStyle(
                    color: AppColors.textPrimary,
                    fontWeight: FontWeight.w700,
                    fontSize: 20,
                    height: 1.25,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 16),
          Icon(
            Icons.format_quote_rounded,
            color: AppColors.primary.withValues(alpha: 0.25),
            size: 56,
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Bento: Routine Grid (asymmetric bento layout)
// ─────────────────────────────────────────────────────────────────────────────

class _BentoRoutineGrid extends StatelessWidget {
  final List<Routine> routines;
  final void Function(Routine) onTap;

  const _BentoRoutineGrid({required this.routines, required this.onTap});

  @override
  Widget build(BuildContext context) {
    // Build rows: first row has a wide featured card + a normal card,
    // then subsequent rows have 2 normal cards.
    final items = <Widget>[];

    if (routines.isEmpty) return const SizedBox.shrink();

    int i = 0;

    // First row: featured (flex 3) + regular (flex 2)
    if (routines.length == 1) {
      items.add(_RoutineBentoCard(
        routine: routines[0],
        color: Color(int.parse('0x${routines[0].colorHex}')),
        onTap: () => onTap(routines[0]),
        featured: true,
        fullWidth: true,
      ));
    } else {
      items.add(
        IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Expanded(
                flex: 3,
                child: _RoutineBentoCard(
                  routine: routines[0],
                  color: Color(int.parse('0x${routines[0].colorHex}')),
                  onTap: () => onTap(routines[0]),
                  featured: true,
                  fullWidth: false,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                flex: 2,
                child: _RoutineBentoCard(
                  routine: routines[1],
                  color: Color(int.parse('0x${routines[1].colorHex}')),
                  onTap: () => onTap(routines[1]),
                  featured: false,
                  fullWidth: false,
                ),
              ),
            ],
          ),
        ),
      );
      i = 2;
    }

    // Remaining rows: pairs of 2
    while (i < routines.length) {
      items.add(const SizedBox(height: 10));
      if (i + 1 >= routines.length) {
        // Last single card – full width
        final routine = routines[i];
        items.add(_RoutineBentoCard(
          routine: routine,
          color: Color(int.parse('0x${routine.colorHex}')),
          onTap: () => onTap(routine),
          featured: false,
          fullWidth: true,
        ));
        i++;
      } else {
        final r1 = routines[i];
        final r2 = routines[i + 1];
        items.add(
          IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Expanded(
                  child: _RoutineBentoCard(
                    routine: r1,
                    color: Color(int.parse('0x${r1.colorHex}')),
                    onTap: () => onTap(r1),
                    featured: false,
                    fullWidth: false,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _RoutineBentoCard(
                    routine: r2,
                    color: Color(int.parse('0x${r2.colorHex}')),
                    onTap: () => onTap(r2),
                    featured: false,
                    fullWidth: false,
                  ),
                ),
              ],
            ),
          ),
        );
        i += 2;
      }
    }

    return Column(children: items);
  }
}

class _RoutineBentoCard extends StatelessWidget {
  final dynamic routine;
  final Color color;
  final VoidCallback onTap;
  final bool featured;
  final bool fullWidth;

  const _RoutineBentoCard({
    required this.routine,
    required this.color,
    required this.onTap,
    required this.featured,
    required this.fullWidth,
  });

  @override
  Widget build(BuildContext context) {
    final double minHeight = featured ? 150 : 120;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(AppColors.bentoRadius),
        onTap: onTap,
        child: Container(
          width: double.infinity,
          constraints: BoxConstraints(minHeight: minHeight),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(AppColors.bentoRadius),
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                color.withValues(alpha: 0.28),
                color.withValues(alpha: 0.07),
              ],
            ),
            border: Border.all(color: color.withValues(alpha: 0.3), width: 1),
          ),
          child: Stack(
            children: [
              // Subtle background icon
              if (featured)
                Positioned(
                  right: -8,
                  bottom: -8,
                  child: Icon(
                    Icons.fitness_center_rounded,
                    size: 72,
                    color: color.withValues(alpha: 0.08),
                  ),
                ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // Icon chip
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: color.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(Icons.fitness_center_rounded,
                        color: color, size: featured ? 20 : 16),
                  ),
                  const SizedBox(height: 12),
                  // Name
                  Text(
                    routine.name,
                    style: TextStyle(
                      fontWeight: FontWeight.w700,
                      fontSize: featured ? 16 : 14,
                      color: AppColors.textPrimary,
                      height: 1.2,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  if (routine.description.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(top: 3),
                      child: Text(
                        routine.description,
                        style: TextStyle(
                            color: AppColors.textMuted, fontSize: 11),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
