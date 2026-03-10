import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gymapp/screens/exercises/exercise_list_screen.dart';
import 'package:gymapp/providers/providers.dart';
import 'package:gymapp/database/app_database.dart';
import '../helpers/pump_app.dart';

void main() {
  testWidgets('ExerciseListScreen shows exercises', (tester) async {
    final fakeExercise = Exercise(
      id: 1, 
      clientId: 'a', 
      name: 'Custom Curl', 
      category: 'Biceps', 
      targetMuscle: 'Biceps', 
      equipment: 'Dumbbell', 
      isCustom: true, 
      lastModifiedAt: DateTime.now(), 
      syncStatus: 0, 
      isDeleted: false
    );

    await tester.pumpApp(
      const Scaffold(body: ExerciseListScreen()),
      overrides: [
        exercisesProvider.overrideWith((ref) => Stream.value([fakeExercise])),
      ],
    );

    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));

    // Verify it renders the custom exercise name
    expect(find.text('Custom Curl'), findsOneWidget);
  });
}
