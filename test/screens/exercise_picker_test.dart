import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gymapp/screens/exercises/exercise_picker.dart';
import 'package:gymapp/providers/providers.dart';
import 'package:gymapp/database/app_database.dart';
import '../helpers/pump_app.dart';

void main() {
  final fakeExercises = [
    Exercise(
      id: 1,
      clientId: 'a',
      name: 'Bench Press',
      category: 'Chest',
      targetMuscle: 'Chest',
      equipment: 'Barbell',
      description: '',
      isCustom: false,
      lastModifiedAt: DateTime.now(),
      syncStatus: 0,
      isDeleted: false,
    ),
    Exercise(
      id: 2,
      clientId: 'b',
      name: 'My Custom Curl',
      category: 'Biceps',
      targetMuscle: 'Biceps',
      equipment: 'Dumbbell',
      description: '',
      isCustom: true,
      lastModifiedAt: DateTime.now(),
      syncStatus: 0,
      isDeleted: false,
    ),
  ];

  testWidgets('ExercisePickerSheet shows Create New Exercise button',
      (tester) async {
    await tester.pumpApp(
      Scaffold(
        body: Builder(
          builder: (context) => ElevatedButton(
            onPressed: () {
              showModalBottomSheet(
                context: context,
                isScrollControlled: true,
                builder: (_) => const ExercisePickerSheet(),
              );
            },
            child: const Text('Open Picker'),
          ),
        ),
      ),
      overrides: [
        exercisesProvider.overrideWith((ref) => Stream.value(fakeExercises)),
        globalExercisesProvider.overrideWith((ref) => Stream.value(
            fakeExercises.where((e) => !e.isCustom).toList())),
        personalExercisesProvider.overrideWith((ref) => Stream.value(
            fakeExercises.where((e) => e.isCustom).toList())),
      ],
    );

    await tester.tap(find.text('Open Picker'));
    await tester.pumpAndSettle();

    expect(find.text('Create New Exercise'), findsOneWidget);
  });

  testWidgets('ExercisePickerSheet shows filter toggle options',
      (tester) async {
    await tester.pumpApp(
      Scaffold(
        body: Builder(
          builder: (context) => ElevatedButton(
            onPressed: () {
              showModalBottomSheet(
                context: context,
                isScrollControlled: true,
                builder: (_) => const ExercisePickerSheet(),
              );
            },
            child: const Text('Open Picker'),
          ),
        ),
      ),
      overrides: [
        exercisesProvider.overrideWith((ref) => Stream.value(fakeExercises)),
        globalExercisesProvider.overrideWith((ref) => Stream.value(
            fakeExercises.where((e) => !e.isCustom).toList())),
        personalExercisesProvider.overrideWith((ref) => Stream.value(
            fakeExercises.where((e) => e.isCustom).toList())),
      ],
    );

    await tester.tap(find.text('Open Picker'));
    await tester.pumpAndSettle();

    // Verify filter toggle options exist
    expect(find.text('Global'), findsOneWidget);
    expect(find.text('My Exercises'), findsOneWidget);
  });
}
