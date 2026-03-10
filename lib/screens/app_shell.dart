import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../theme/app_theme.dart';
import '../services/supabase_service.dart';
import '../providers/providers.dart';
import 'auth/auth_screen.dart';
import 'home_screen.dart';
import 'exercises/exercise_list_screen.dart';
import 'routines/routine_list_screen.dart';
import 'history/history_screen.dart';
import 'settings_screen.dart';

class AppShell extends ConsumerStatefulWidget {
  const AppShell({super.key});

  @override
  ConsumerState<AppShell> createState() => _AppShellState();
}

class _AppShellState extends ConsumerState<AppShell> {
  int _currentIndex = 0;

  final _screens = const [
    HomeScreen(),
    ExerciseListScreen(),
    RoutineListScreen(),
    HistoryScreen(),
    SettingsScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    // Trigger bulk sync whenever the auth state changes to signed-in
    ref.listen(authStateProvider, (prev, next) {
      if (next.valueOrNull?.session != null) {
        final syncService = ref.read(syncServiceProvider);
        // Pull data down from Supabase first
        syncService.syncDown().then((_) {
          // Then push local pending data up
          syncService.syncAll();
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
      bottomNavigationBar: Container(
        decoration: const BoxDecoration(
          border: Border(
            top: BorderSide(color: AppColors.divider, width: 0.5),
          ),
        ),
        child: BottomNavigationBar(
          currentIndex: _currentIndex,
          onTap: (i) => setState(() => _currentIndex = i),
          items: const [
            BottomNavigationBarItem(
              icon: Icon(Icons.home_rounded),
              label: 'Home',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.fitness_center_rounded),
              label: 'Exercises',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.list_alt_rounded),
              label: 'Routines',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.history_rounded),
              label: 'History',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.settings_rounded),
              label: 'Settings',
            ),
          ],
        ),
      ),
    );
  }
}

