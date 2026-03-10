import 'package:drift/drift.dart';

// ─── Sync-ready mixin ────────────────────────────────────────────────────────
// Every table includes these columns to future-proof for Supabase / Firebase
// cloud sync. clientId is the stable UUID shared with the remote DB.
// syncStatus: 0 = synced, 1 = pending, 2 = conflict.
// isDeleted: soft-delete so removals can replicate before hard-purge.
// ──────────────────────────────────────────────────────────────────────────────

/// Categories for exercises
class ExerciseCategories {
  static const String chest = 'Chest';
  static const String back = 'Back';
  static const String shoulders = 'Shoulders';
  static const String biceps = 'Biceps';
  static const String triceps = 'Triceps';
  static const String legs = 'Legs';
  static const String core = 'Core';
  static const String cardio = 'Cardio';
  static const String fullBody = 'Full Body';
  static const String other = 'Other';

  static const List<String> all = [
    chest, back, shoulders, biceps, triceps, legs, core, cardio, fullBody, other,
  ];
}

/// Equipment types
class EquipmentTypes {
  static const String barbell = 'Barbell';
  static const String dumbbell = 'Dumbbell';
  static const String machine = 'Machine';
  static const String cable = 'Cable';
  static const String bodyweight = 'Bodyweight';
  static const String kettlebell = 'Kettlebell';
  static const String band = 'Band';
  static const String other = 'Other';

  static const List<String> all = [
    barbell, dumbbell, machine, cable, bodyweight, kettlebell, band, other,
  ];
}

/// Set types for logging
class SetType {
  static const int normal = 0;
  static const int warmup = 1;
  static const int dropSet = 2;
  static const int failure = 3;

  static String label(int type) {
    switch (type) {
      case warmup:
        return 'Warm-up';
      case dropSet:
        return 'Drop Set';
      case failure:
        return 'Failure';
      default:
        return 'Normal';
    }
  }
}

/// Sync status values
class SyncStatus {
  static const int synced = 0;
  static const int pending = 1;
  static const int conflict = 2;
}

// ─── Tables ──────────────────────────────────────────────────────────────────

@DataClassName('Exercise')
class Exercises extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get clientId => text()();
  TextColumn get name => text().withLength(min: 1, max: 100)();
  TextColumn get category => text()();
  TextColumn get targetMuscle => text()();
  TextColumn get equipment => text()();
  BoolColumn get isCustom => boolean().withDefault(const Constant(false))();

  // Sync-ready columns
  DateTimeColumn get lastModifiedAt => dateTime()();
  IntColumn get syncStatus => integer().withDefault(const Constant(0))();
  BoolColumn get isDeleted => boolean().withDefault(const Constant(false))();
}

@DataClassName('Routine')
class Routines extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get clientId => text()();
  TextColumn get name => text().withLength(min: 1, max: 100)();
  TextColumn get description => text().withDefault(const Constant(''))();
  TextColumn get colorHex => text().withDefault(const Constant('FF6366F1'))();
  DateTimeColumn get createdAt => dateTime()();

  // Sync-ready columns
  DateTimeColumn get lastModifiedAt => dateTime()();
  IntColumn get syncStatus => integer().withDefault(const Constant(0))();
  BoolColumn get isDeleted => boolean().withDefault(const Constant(false))();
}

@DataClassName('RoutineExerciseEntry')
class RoutineExercises extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get clientId => text()();
  IntColumn get routineId => integer().references(Routines, #id)();
  IntColumn get exerciseId => integer().references(Exercises, #id)();
  IntColumn get displayOrder => integer().withDefault(const Constant(0))();
  IntColumn get targetSets => integer().withDefault(const Constant(3))();
  IntColumn get targetReps => integer().withDefault(const Constant(10))();
  RealColumn get targetWeight => real().withDefault(const Constant(0.0))();

  // Sync-ready columns
  DateTimeColumn get lastModifiedAt => dateTime()();
  IntColumn get syncStatus => integer().withDefault(const Constant(0))();
  BoolColumn get isDeleted => boolean().withDefault(const Constant(false))();
}

@DataClassName('Workout')
class Workouts extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get clientId => text()();
  IntColumn get routineId => integer().nullable()();
  DateTimeColumn get startTime => dateTime()();
  DateTimeColumn get endTime => dateTime().nullable()();
  TextColumn get notes => text().withDefault(const Constant(''))();

  // Sync-ready columns
  DateTimeColumn get lastModifiedAt => dateTime()();
  IntColumn get syncStatus => integer().withDefault(const Constant(0))();
  BoolColumn get isDeleted => boolean().withDefault(const Constant(false))();
}

@DataClassName('LoggedSet')
class LoggedSets extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get clientId => text()();
  IntColumn get workoutId => integer().references(Workouts, #id)();
  IntColumn get exerciseId => integer().references(Exercises, #id)();
  IntColumn get setNumber => integer()();
  RealColumn get weight => real().withDefault(const Constant(0.0))();
  IntColumn get reps => integer().withDefault(const Constant(0))();
  RealColumn get rpe => real().nullable()();
  IntColumn get setType => integer().withDefault(const Constant(0))();
  IntColumn get restSeconds => integer().withDefault(const Constant(0))();
  DateTimeColumn get completedAt => dateTime().nullable()();

  // Sync-ready columns
  DateTimeColumn get lastModifiedAt => dateTime()();
  IntColumn get syncStatus => integer().withDefault(const Constant(0))();
  BoolColumn get isDeleted => boolean().withDefault(const Constant(false))();
}
