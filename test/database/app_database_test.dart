import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gymapp/database/app_database.dart';

void main() {
  late AppDatabase db;

  setUp(() {
    db = AppDatabase(NativeDatabase.memory());
  });

  tearDown(() async {
    await db.close();
  });

  test('Database is created and seeded with default exercises', () async {
    final exercises = await db.getAllExercises();
    expect(exercises.isNotEmpty, isTrue);
    expect(exercises.any((e) => e.name == 'Barbell Bench Press'), isTrue);
    expect(exercises.any((e) => e.name == 'Barbell Squat'), isTrue);
  });
}
