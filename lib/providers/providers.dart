import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../database/app_database.dart';
import '../database/connection/connection.dart';
import '../repositories/repositories.dart';
import '../services/sync_service.dart';
import '../services/supabase_service.dart';
import '../services/notification_service.dart';
import '../services/workout_overdue_service.dart';
import '../utils/one_rm_calculator.dart';

// Overridden in `main.dart` at app startup with the real SharedPreferences
// instance. Tests that exercise code reading this provider must override it too.
final sharedPreferencesProvider = Provider<SharedPreferences>((ref) {
  throw UnimplementedError(
      'sharedPreferencesProvider must be overridden in ProviderScope.');
});


// ─── Database ────────────────────────────────────────────────────────────────

final databaseProvider = Provider<AppDatabase>((ref) {
  final db = AppDatabase(openDatabaseConnection());
  ref.onDispose(() => db.close());
  return db;
});

// ─── Sync ────────────────────────────────────────────────────────────────────

final syncServiceProvider = Provider<SyncService>((ref) {
  return SyncService(ref.watch(databaseProvider));
});

// ─── Notifications ───────────────────────────────────────────────────────────

final notificationServiceProvider = Provider<NotificationService>((ref) {
  return LocalNotificationService();
});

// ─── Repositories ────────────────────────────────────────────────────────────

final exerciseRepositoryProvider = Provider<ExerciseRepository>((ref) {
  return ExerciseRepository(ref.watch(databaseProvider), ref.watch(syncServiceProvider));
});

final routineRepositoryProvider = Provider<RoutineRepository>((ref) {
  return RoutineRepository(ref.watch(databaseProvider), ref.watch(syncServiceProvider));
});

final workoutRepositoryProvider = Provider<WorkoutRepository>((ref) {
  return WorkoutRepository(
    ref.watch(databaseProvider),
    ref.watch(syncServiceProvider),
    notificationService: ref.watch(notificationServiceProvider),
  );
});

final workoutOverdueServiceProvider = Provider<WorkoutOverdueService>((ref) {
  final service = WorkoutOverdueService(
    ref.watch(workoutRepositoryProvider),
    ref.watch(notificationServiceProvider),
  );
  ref.onDispose(service.stopWatching);
  return service;
});

// ─── Exercise providers ──────────────────────────────────────────────────────

final exercisesProvider = StreamProvider<List<Exercise>>((ref) {
  return ref.watch(exerciseRepositoryProvider).watchAll();
});

final exerciseSearchProvider = FutureProvider.family<List<Exercise>, String>((ref, query) {
  if (query.isEmpty) return ref.watch(exerciseRepositoryProvider).getAll();
  return ref.watch(exerciseRepositoryProvider).search(query);
});

// ─── Routine providers ───────────────────────────────────────────────────────

final routinesProvider = StreamProvider<List<Routine>>((ref) {
  return ref.watch(routineRepositoryProvider).watchAll();
});

final routineExercisesProvider =
    StreamProvider.family<List<RoutineExerciseEntry>, int>((ref, routineId) {
  return ref.watch(routineRepositoryProvider).watchExercises(routineId);
});

/// Stream of the currently in-progress routine draft (null if none).
/// Used to auto-resume routine creation after app restart.
final routineDraftProvider = StreamProvider<Routine?>((ref) {
  return ref.watch(routineRepositoryProvider).watchDraft();
});

// ─── Workout providers ───────────────────────────────────────────────────────

final workoutsProvider = StreamProvider<List<Workout>>((ref) {
  return ref.watch(workoutRepositoryProvider).watchAll();
});

final workoutSetsProvider =
    StreamProvider.family<List<LoggedSet>, int>((ref, workoutId) {
  return ref.watch(workoutRepositoryProvider).watchSets(workoutId);
});

final workoutExercisesProvider =
    StreamProvider.family<List<WorkoutExerciseEntry>, int>((ref, workoutId) {
  return ref.watch(workoutRepositoryProvider).watchWorkoutExercises(workoutId);
});

// ─── Stats providers ─────────────────────────────────────────────────────────

final workoutsThisWeekProvider = StreamProvider<int>((ref) {
  return ref.watch(workoutRepositoryProvider).watchWorkoutsThisWeek();
});

final totalWorkoutsProvider = StreamProvider<int>((ref) {
  return ref.watch(workoutRepositoryProvider).watchWorkoutCount();
});

/// Workouts completed since the 1st of the current month.
final workoutsThisMonthCountProvider = Provider<int>((ref) {
  final workoutsAsync = ref.watch(workoutsProvider);
  final list = workoutsAsync.valueOrNull;
  if (list == null) return 0;
  final now = DateTime.now();
  final start = DateTime(now.year, now.month, 1);
  return list
      .where((w) => w.endTime != null && !w.startTime.isBefore(start))
      .length;
});

/// The most recent completed workout, or null.
final lastCompletedWorkoutProvider = Provider<Workout?>((ref) {
  final workoutsAsync = ref.watch(workoutsProvider);
  final list = workoutsAsync.valueOrNull;
  if (list == null || list.isEmpty) return null;
  final finished = list.where((w) => w.endTime != null).toList()
    ..sort((a, b) => b.startTime.compareTo(a.startTime));
  return finished.isEmpty ? null : finished.first;
});

/// Map of local-midnight date → completed workout count, for the last 105 days.
final workoutHeatmapProvider = Provider<Map<DateTime, int>>((ref) {
  final workoutsAsync = ref.watch(workoutsProvider);
  final list = workoutsAsync.valueOrNull ?? const <Workout>[];
  final now = DateTime.now();
  final today = DateTime(now.year, now.month, now.day);
  final start = today.subtract(const Duration(days: 104));
  final map = <DateTime, int>{};
  for (final w in list) {
    if (w.endTime == null) continue;
    final d = DateTime(w.startTime.year, w.startTime.month, w.startTime.day);
    if (d.isBefore(start) || d.isAfter(today)) continue;
    map[d] = (map[d] ?? 0) + 1;
  }
  return map;
});

/// Stats for the most recent completed workout.
class LastSessionStats {
  final Workout workout;
  final Duration duration;
  final double volume;
  final int newPrs;
  const LastSessionStats({
    required this.workout,
    required this.duration,
    required this.volume,
    required this.newPrs,
  });
}

/// Computes duration / volume / new-PR count for the latest completed workout.
/// Returns null if there is no completed workout yet.
final lastSessionStatsProvider =
    FutureProvider<LastSessionStats?>((ref) async {
  final last = ref.watch(lastCompletedWorkoutProvider);
  if (last == null) return null;
  final repo = ref.watch(workoutRepositoryProvider);
  final allSets = await repo.getAllSets();

  // Current session's sets
  final currentSets = allSets.where((s) => s.workoutId == last.id).toList();

  final duration =
      last.endTime != null ? last.endTime!.difference(last.startTime) : Duration.zero;

  double volume = 0;
  for (final s in currentSets) {
    volume += s.weight * s.reps;
  }

  // Best estimated 1RM per exercise in this session
  final currentBest = <int, double>{};
  for (final s in currentSets) {
    final est = OneRmCalculator.estimate(s.weight, s.reps);
    final prev = currentBest[s.exerciseId] ?? 0;
    if (est > prev) currentBest[s.exerciseId] = est;
  }

  // Best estimated 1RM per exercise from all prior sessions
  final priorBest = <int, double>{};
  for (final s in allSets) {
    if (s.workoutId == last.id) continue;
    final est = OneRmCalculator.estimate(s.weight, s.reps);
    final prev = priorBest[s.exerciseId] ?? 0;
    if (est > prev) priorBest[s.exerciseId] = est;
  }

  int newPrs = 0;
  for (final entry in currentBest.entries) {
    final prior = priorBest[entry.key] ?? 0;
    if (entry.value > prior) newPrs++;
  }

  return LastSessionStats(
    workout: last,
    duration: duration,
    volume: volume,
    newPrs: newPrs,
  );
});

// ─── UI state providers ──────────────────────────────────────────────────────

/// Stream of the currently incomplete workout (null if none).
final incompleteWorkoutProvider = StreamProvider<Workout?>((ref) {
  return ref.watch(workoutRepositoryProvider).watchIncompleteWorkout();
});

/// Convenience: just the active workout ID, or null.
final activeWorkoutIdProvider = Provider<int?>((ref) {
  return ref.watch(incompleteWorkoutProvider).valueOrNull?.id;
});

/// Remembers the last selected category filter in the exercise picker
final exercisePickerFilterProvider = StateProvider<String?>((ref) => null);

/// Filter mode for exercise lists
enum ExerciseFilterMode { all, global, personal }

/// Current exercise filter mode
final exerciseFilterModeProvider = StateProvider<ExerciseFilterMode>(
  (ref) => ExerciseFilterMode.all,
);

/// Only global (pre-seeded) exercises
final globalExercisesProvider = StreamProvider<List<Exercise>>((ref) {
  return ref.watch(exerciseRepositoryProvider).watchGlobal();
});

/// Only personal (custom) exercises
final personalExercisesProvider = StreamProvider<List<Exercise>>((ref) {
  return ref.watch(exerciseRepositoryProvider).watchCustom();
});

/// Exercises filtered by the current filter mode
final filteredExercisesProvider = Provider<AsyncValue<List<Exercise>>>((ref) {
  final mode = ref.watch(exerciseFilterModeProvider);
  switch (mode) {
    case ExerciseFilterMode.all:
      return ref.watch(exercisesProvider);
    case ExerciseFilterMode.global:
      return ref.watch(globalExercisesProvider);
    case ExerciseFilterMode.personal:
      return ref.watch(personalExercisesProvider);
  }
});

/// Whether the active workout is minimized to the floating bar
final workoutMinimizedProvider = StateProvider<bool>((ref) => false);

/// Default rest timer duration in seconds
final restTimerDurationProvider = StateProvider<int>((ref) => 90);

/// Whether the rest timer should start automatically after completing a set
final restTimerEnabledProvider =
    NotifierProvider<RestTimerEnabledNotifier, bool>(
        RestTimerEnabledNotifier.new);

class RestTimerEnabledNotifier extends Notifier<bool> {
  static const _key = 'rest_timer_enabled';

  @override
  bool build() {
    final prefs = ref.watch(sharedPreferencesProvider);
    return prefs.getBool(_key) ?? true;
  }

  Future<void> set(bool value) async {
    state = value;
    await ref.read(sharedPreferencesProvider).setBool(_key, value);
  }
}

/// Global weight unit preference (false = kg, true = lbs).
/// Persisted to SharedPreferences. Individual exercises can override via
/// `RoutineExercises.useLbs` / `WorkoutExercises.useLbs`.
class UseLbsNotifier extends Notifier<bool> {
  static const _key = 'use_lbs';

  @override
  bool build() {
    final prefs = ref.watch(sharedPreferencesProvider);
    return prefs.getBool(_key) ?? false;
  }

  Future<void> set(bool value) async {
    state = value;
    await ref.read(sharedPreferencesProvider).setBool(_key, value);
  }
}

final useLbsProvider =
    NotifierProvider<UseLbsNotifier, bool>(UseLbsNotifier.new);

// ─── Auth providers ──────────────────────────────────────────────────────────

final authStateProvider = StreamProvider<AuthState>((ref) {
  try {
    return SupabaseService.onAuthStateChange;
  } catch (_) {
    return const Stream.empty(); // for tests
  }
});

final isAuthenticatedProvider = Provider<bool>((ref) {
  final authState = ref.watch(authStateProvider).valueOrNull;
  try {
    return authState?.session != null || SupabaseService.isAuthenticated;
  } catch (_) {
    return false; // for tests
  }
});

final userEmailProvider = Provider<String>((ref) {
  final session = ref.watch(authStateProvider).valueOrNull?.session;
  try {
    return session?.user.email ??
        SupabaseService.currentUser?.email ??
        'Not logged in';
  } catch (_) {
    return 'test@example.com'; // for tests
  }
});

