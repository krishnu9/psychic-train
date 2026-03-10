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
    test('activeWorkoutIdProvider defaults to null and can be updated', () {
      final container = makeContainer();
      expect(container.read(activeWorkoutIdProvider), isNull);
      container.read(activeWorkoutIdProvider.notifier).state = 1;
      expect(container.read(activeWorkoutIdProvider), 1);
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
}
