import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../theme/app_theme.dart';

import '../database/app_database.dart';
import '../providers/providers.dart';
import 'auth/auth_screen.dart';
import 'home_screen.dart';
import 'exercises/exercise_list_screen.dart';
import 'routines/routine_list_screen.dart';
import 'history/history_screen.dart';
import 'settings_screen.dart';
import 'workout/active_workout_screen.dart';

class AppShell extends ConsumerStatefulWidget {
  const AppShell({super.key});

  @override
  ConsumerState<AppShell> createState() => _AppShellState();
}

class _AppShellState extends ConsumerState<AppShell> {
  int _currentIndex = 0;
  bool _hasPromptedResume = false;

  late final List<Widget> _screens = [
    HomeScreen(onNavigate: _navigateToTab),
    const ExerciseListScreen(),
    const RoutineListScreen(),
    const HistoryScreen(),
    const SettingsScreen(),
  ];

  void _navigateToTab(int index) {
    if (!mounted) return;
    setState(() => _currentIndex = index);
  }

  static const _navItems = [
    _NavItem(icon: Icons.home_rounded, label: 'Home'),
    _NavItem(icon: Icons.fitness_center_rounded, label: 'Exercises'),
    _NavItem(icon: Icons.list_alt_rounded, label: 'Routines'),
    _NavItem(icon: Icons.history_rounded, label: 'History'),
    _NavItem(icon: Icons.settings_rounded, label: 'Settings'),
  ];

  Future<void> _showResumeWorkoutDialog(Workout workout) async {
    if (!mounted) return;
    final result = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        title: const Text('Incomplete Workout'),
        content: const Text(
          'You have an unfinished workout. Would you like to resume or discard it?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text('Discard',
                style: TextStyle(color: AppColors.error)),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Resume'),
          ),
        ],
      ),
    );

    if (!mounted) return;
    if (result == true) {
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => ActiveWorkoutScreen(
            workoutId: workout.id,
            routineId: workout.routineId,
          ),
        ),
      );
    } else {
      await ref.read(workoutRepositoryProvider).delete(workout.id);
    }
  }

  @override
  Widget build(BuildContext context) {
    ref.listen(authStateProvider, (prev, next) {
      if (next.valueOrNull?.session != null) {
          final syncService = ref.read(syncServiceProvider);
          syncService.syncDown().then((_) {
            syncService.syncAll();
          });
        }
      },
    );
    // Listen for incomplete workouts to prompt resume
    ref.listen<AsyncValue<Workout?>>(incompleteWorkoutProvider, (prev, next) {
      final workout = next.valueOrNull;
      if (workout != null && !_hasPromptedResume && prev?.isLoading == true) {
        _hasPromptedResume = true;
        WidgetsBinding.instance.addPostFrameCallback((_) {
          _showResumeWorkoutDialog(workout);
        });
      }
    });

    final isAuthenticated = ref.watch(isAuthenticatedProvider);
    if (!isAuthenticated) return const AuthScreen();

    return Scaffold(
      body: IndexedStack(
        index: _currentIndex,
        children: _screens,
      ),
      bottomNavigationBar: _FloatingNavBar(
        currentIndex: _currentIndex,
        items: _navItems,
        onTap: (i) => setState(() => _currentIndex = i),
      ),
    );
  }
}

class _NavItem {
  final IconData icon;
  final String label;
  const _NavItem({required this.icon, required this.label});
}

class _FloatingNavBar extends StatelessWidget {
  final int currentIndex;
  final List<_NavItem> items;
  final ValueChanged<int> onTap;

  const _FloatingNavBar({
    required this.currentIndex,
    required this.items,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 12),
        child: Container(
          height: 64,
          decoration: BoxDecoration(
            color: AppColors.surfaceBright,
            borderRadius: BorderRadius.circular(32),
            border: Border.all(
              color: AppColors.divider.withValues(alpha: 0.8),
              width: 1,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.35),
                blurRadius: 24,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Row(
            children: List.generate(items.length, (i) {
              final item = items[i];
              final selected = i == currentIndex;
              return Expanded(
                child: GestureDetector(
                  onTap: () => onTap(i),
                  behavior: HitTestBehavior.opaque,
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    curve: Curves.easeInOut,
                    margin: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
                    decoration: BoxDecoration(
                      color: selected
                          ? AppColors.primary.withValues(alpha: 0.15)
                          : Colors.transparent,
                      borderRadius: BorderRadius.circular(24),
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        AnimatedScale(
                          scale: selected ? 1.15 : 1.0,
                          duration: const Duration(milliseconds: 200),
                          child: Icon(
                            item.icon,
                            size: 22,
                            color: selected
                                ? AppColors.primary
                                : AppColors.textMuted,
                          ),
                        ),
                        if (selected) ...[
                          const SizedBox(height: 2),
                          Container(
                            width: 4,
                            height: 4,
                            decoration: BoxDecoration(
                              color: AppColors.primary,
                              shape: BoxShape.circle,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
              );
            }),
          ),
        ),
      ),
    );
  }
}
