import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gymapp/database/app_database.dart';
import 'package:gymapp/providers/providers.dart';
import 'package:gymapp/repositories/repositories.dart';
import 'package:mocktail/mocktail.dart';

class MockExerciseRepository extends Mock implements ExerciseRepository {}
class MockRoutineRepository extends Mock implements RoutineRepository {}
class MockWorkoutRepository extends Mock implements WorkoutRepository {}

void main() {
  late MockExerciseRepository mockExerciseRepo;
  late MockRoutineRepository mockRoutineRepo;
  late MockWorkoutRepository mockWorkoutRepo;

  setUp(() {
    mockExerciseRepo = MockExerciseRepository();
    mockRoutineRepo = MockRoutineRepository();
    mockWorkoutRepo = MockWorkoutRepository();
  });

  ProviderContainer makeContainer() {
    final container = ProviderContainer(
      overrides: [
        exerciseRepositoryProvider.overrideWithValue(mockExerciseRepo),
        routineRepositoryProvider.overrideWithValue(mockRoutineRepo),
        workoutRepositoryProvider.overrideWithValue(mockWorkoutRepo),
      ],
    );
    addTearDown(container.dispose);
    return container;
  }

  group('StateProviders', () {
    test('activeWorkoutIdProvider is null when no incomplete workout', () {
      when(() => mockWorkoutRepo.watchIncompleteWorkout())
          .thenAnswer((_) => Stream.value(null));

      final container = makeContainer();
      container.listen(incompleteWorkoutProvider, (_, __) {});
      expect(container.read(activeWorkoutIdProvider), isNull);
    });

    test('activeWorkoutIdProvider derives from incompleteWorkoutProvider', () async {
      final fakeWorkout = Workout(
        id: 42,
        clientId: 'abc',
        routineId: null,
        startTime: DateTime.now(),
        endTime: null,
        notes: '',
        lastModifiedAt: DateTime.now(),
        syncStatus: 1,
        isDeleted: false,
      );
      when(() => mockWorkoutRepo.watchIncompleteWorkout())
          .thenAnswer((_) => Stream.value(fakeWorkout));

      final container = makeContainer();
      container.listen(incompleteWorkoutProvider, (_, __) {});

      await container.read(incompleteWorkoutProvider.future);
      expect(container.read(activeWorkoutIdProvider), 42);
    });

    test('restTimerDurationProvider defaults to 90 and can be updated', () {
      final container = makeContainer();
      expect(container.read(restTimerDurationProvider), 90);
      container.read(restTimerDurationProvider.notifier).state = 60;
      expect(container.read(restTimerDurationProvider), 60);
    });

    test('useLbsProvider defaults to false and can be updated', () {
      final container = makeContainer();
      expect(container.read(useLbsProvider), isFalse);
      container.read(useLbsProvider.notifier).state = true;
      expect(container.read(useLbsProvider), isTrue);
    });
  });

  group('StreamProviders', () {
    test('exercisesProvider emits list from repository', () async {
      final fakeExercises = [
        Exercise(
          id: 1, 
          clientId: 'a', 
          name: 'Bench', 
          category: 'Chest', 
          targetMuscle: 'Chest', 
          equipment: 'Barbell', 
          isCustom: false, 
          lastModifiedAt: DateTime.now(), 
          syncStatus: 0, 
          isDeleted: false
        )
      ];
      
      when(() => mockExerciseRepo.watchAll())
          .thenAnswer((_) => Stream.value(fakeExercises));

      final container = makeContainer();
      
      // Wait for the provider to emit the first value
      final subscription = container.listen(exercisesProvider, (_, __) {});
      
      await expectLater(
        container.read(exercisesProvider.future),
        completion(fakeExercises),
      );
      
      subscription.close();
    });
  });

  group('ExerciseFilterProviders', () {
    test('exerciseFilterModeProvider defaults to all', () {
      final container = makeContainer();
      expect(container.read(exerciseFilterModeProvider), ExerciseFilterMode.all);
    });

    test('filteredExercisesProvider uses globalExercisesProvider when set to global', () async {
      final globalExercises = [
        Exercise(
          id: 1,
          clientId: 'a',
          name: 'Bench Press',
          category: 'Chest',
          targetMuscle: 'Chest',
          equipment: 'Barbell',
          isCustom: false,
          lastModifiedAt: DateTime.now(),
          syncStatus: 0,
          isDeleted: false,
        )
      ];

      when(() => mockExerciseRepo.watchGlobal())
          .thenAnswer((_) => Stream.value(globalExercises));
      when(() => mockExerciseRepo.watchAll())
          .thenAnswer((_) => Stream.value(globalExercises));

      final container = makeContainer();
      container.read(exerciseFilterModeProvider.notifier).state =
          ExerciseFilterMode.global;

      container.listen(globalExercisesProvider, (_, __) {});
      await container.read(globalExercisesProvider.future);

      final filtered = container.read(filteredExercisesProvider);
      expect(filtered.valueOrNull, globalExercises);
    });

    test('filteredExercisesProvider uses personalExercisesProvider when set to personal', () async {
      final customExercises = [
        Exercise(
          id: 100,
          clientId: 'b',
          name: 'My Custom Curl',
          category: 'Biceps',
          targetMuscle: 'Biceps',
          equipment: 'Dumbbell',
          isCustom: true,
          lastModifiedAt: DateTime.now(),
          syncStatus: 0,
          isDeleted: false,
        )
      ];

      when(() => mockExerciseRepo.watchCustom())
          .thenAnswer((_) => Stream.value(customExercises));
      when(() => mockExerciseRepo.watchAll())
          .thenAnswer((_) => Stream.value(customExercises));

      final container = makeContainer();
      container.read(exerciseFilterModeProvider.notifier).state =
          ExerciseFilterMode.personal;

      container.listen(personalExercisesProvider, (_, __) {});
      await container.read(personalExercisesProvider.future);

      final filtered = container.read(filteredExercisesProvider);
      expect(filtered.valueOrNull, customExercises);
    });
  });
}
