# GymApp Architecture & Context

This document provides essential context for future development and AI agents working on the GymApp codebase. It outlines the foundational decisions, tech stack, data architecture, and UI/UX paradigms implemented in the MVP phase.

## Tech Stack Overview

*   **Framework:** Flutter
*   **Local Database:** Drift (SQLite wrapper offering compile-time safety)
*   **State Management:** Riverpod (`flutter_riverpod` & code generation)
*   **Design/Typography:** Material Design 3 (Dark Theme default) + Google Fonts ('Inter')
*   **Key Utilities:** `uuid` for local ID generation, `intl` for formatting.

---

## Directory Structure
The `lib/` directory is organized by feature layer (not purely by screen):

```
lib/
├── app.dart              # Root MaterialApp and theme injection
├── database/             # AppDatabase (Drift database instance and connections)
├── models/               # Drift table definitions & domain Enums
├── providers/            # Riverpod providers (state, streams, repositories)
├── repositories/         # Abstraction layer between Providers and Database
├── screens/              # UI screens categorized by feature (exercises, routines, etc.)
├── theme/                # Global AppTheme and AppColors definitions
└── utils/                # Pure logic utilities (formatters, 1RM calculator)
```

---

## Data Architecture (Offline-First to Cloud-Ready)

A critical goal of the MVP was to build an offline-first local database that is **sync-ready** for future migration to Supabase or Firebase.

1.  **Drift Tables (`lib/models/tables.dart`)**:
    *   `Exercises`: Core library (pre-seeded on initial install).
    *   `Routines`: User-created workout templates.
    *   `RoutineExercises`: Mapping of exercises to a routine, including target sets/reps/weights.
    *   `Workouts`: Individual workout sessions (`startTime`, `endTime`, `routineId`).
    *   `LoggedSets`: Individual sets logged during a workout (`weight`, `reps`, `setType`).

2.  **Sync-Ready Columns**: Every table includes columns designed to resolve sync conflicts when cloud persistence is added:
    *   `clientId` (`TextColumn` / UUID): Unique identifier generated locally on the device.
    *   `lastModifiedAt` (`DateTimeColumn`): Timestamp of the last local change.
    *   `syncStatus` (`IntColumn`): Enum representing 0: synced, 1: pending, 2: conflict.
    *   `isDeleted` (`BoolColumn`): To support soft deletes locally before syncing the deletion to the cloud.

3.  **Repository Pattern (`lib/repositories/repositories.dart`)**:
    Widgets and Riverpod Providers **never** interact directly with the `AppDatabase`. They strictly call methods on `ExerciseRepository`, `RoutineRepository`, and `WorkoutRepository`. 
    *   *Why?* When cloud sync is implemented, these repositories will act as the orchestrators: writing locally to SQLite first, then queuing the network request, without requiring any UI code modifications.

---

## UI/UX & Theming (`lib/theme/app_theme.dart`)

The app is built around a "Premium Dark" aesthetic and one-handed "thumb-zone" ergonomics.

*   **Colors**: Deep navy/black backgrounds (`AppColors.background` = `0xFF0F172A`) with vibrant electric green/teal accents (`AppColors.primary` = `0xFF10B981`).
*   **Shapes**: Heavy use of rounded corners (16px - 24px) to create softer, glassmorphism-inspired cards and bottom sheets.
*   **Ergonomics**: The `ActiveWorkoutScreen` (Gym Mode) has oversized increment/decrement and completion buttons to allow sweaty, shaking hands to accurately log sets midway through a workout.

---

## State Management Approach

Riverpod is used heavily to glue the Data Layer and UI together (`lib/providers/providers.dart`).

*   **Singletons**: `databaseProvider` and repository providers are initialized once.
*   **Streams**: `exercisesProvider`, `routinesProvider`, and `workoutsProvider` emit `List<T>` streams that are drawn from Drift `.watch()` queries. UI screens use `ref.watch(provider).when(...)` to instantly react to database insertions/deletions.
*   **UI State**: Smaller providers (`activeWorkoutIdProvider`, `restTimerDurationProvider`, `useLbsProvider`) handle transient or settings-based state.

---

## Extending the App: Guidelines for Agents

When building new features, follow these patterns:

1.  **Modifying Schema**: 
    *   Add columns to `lib/models/tables.dart`.
    *   Increment validation schema version in `lib/database/app_database.dart` and handle the migration in the `onUpgrade` strategy.
    *   Run code generation: `dart run build_runner build -d`.
2.  **Adding UI State**: Do not use `StatefulWidget` for complex data lifting. Use Riverpod's `StateProvider` or `@riverpod` annotations to expose state globally or cleanly manage asynchronous logic.
3.  **Cloud Sync Implementation**: The database is ready. When doing sync, inject an HTTP/Supabase client into the `Repositories`, adjust the write methods to hit both local/remote, and modify the read streams if remote synchronization is needed on launch.
4.  **Logging**: The app uses standard print/debug logic. For a production feature, integrate a logging wrapper.
