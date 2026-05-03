# Plan
This document maintains future upcoming plan features for the application.

## 1. ~~Add markdown support for routine description~~ ✅ Done

## 2. ~~Add description for exercises~~ ✅ Done

## 3. ~~Make sure current ongoing workout is not lost when app is closed or refreshed~~ ✅ Done

## 4. ~~Categories / Sections in routine exercises~~ ✅ Done

## 5. ~~New Exercise Addition option in Select Exercise view while creating a routine.~~ ✅ Done

## 6. ~~Global database of exercises versus personal list of exercises.~~ ✅ Done

## 7. ~~Start workout from routines section~~ ✅ Done
Add a "Start Workout" button directly on each routine card/detail screen so users can launch an active workout pre-loaded with the routine's exercises without going through the workout tab.

## 8. ~~Notes entry for every exercise~~ ✅ Done
Add a per-exercise notes field in both the active workout screen and the routine edit screen. Requires a schema migration to add a `notes` column to the relevant tables (exercise entries in workouts and routines). Do this before later features build on the exercise data model.

## 9. ~~Edit exercises in past workouts~~ ✅ Done
Allow users to edit sets, reps, weight, and notes for exercises in already-completed workouts. Requires unlocking the read-only workout log view and wiring save logic back to the DB.

## 10. ~~Drag and rearrange exercises in active workout~~ ✅ Done
Let users drag to reorder exercises within an active workout session. Requires adding a `sortOrder` / `position` column to the workout exercise entries table and updating it on reorder.

## 11. ~~Minimize active workout (floating persistent bar)~~ ✅ Done
Add an option to minimize the current workout into a compact floating bar at the bottom of the screen, allowing navigation to other parts of the app while keeping the workout timer running. Tapping the bar returns to the active workout. Build after exercise ordering (item 10) is stable.

## 12. ~~Notification when workout exceeds 1.5 hours~~ ✅ Done
Send a local push notification prompting the user to finish or cancel their workout if it has been running for more than 90 minutes. Requires setting up Flutter local notifications and a background timer/alarm. Best implemented last as it depends on a stable active workout flow.

## 13. ~~Hide add-exercise button when keyboard is open~~ ✅ Done
Hide the "Add exercise" button in the active workout / routine edit screens while the user is typing a value (weight, reps, notes) and the on-screen keyboard is visible. Button should reappear once the keyboard is dismissed. Prevents the button from overlapping input fields and reduces mis-taps.
Fixed by making the active workout and routine edit add controls keyboard-aware via `MediaQuery.viewInsets`.

## 14. ~~Stick resume-workout bar to bottom navigation~~ ✅ Done
The minimized "Resume Workout" bar currently floats and does not stick to the bottom navigation / tab bar. Dock it directly above the bottom nav so it behaves as a persistent strip across screens instead of overlapping content.
Fixed by moving the minimized workout bar into the bottom navigation layout above the nav bar.

## 15. ~~Quick Start (empty workout)~~ ✅ Done
Add option on the home screen "Start Workout" button to start a new empty workout (no routine) in addition to launching from a saved routine.

## 16. ~~Save active workout as a new routine~~ ✅ Done
In the active workout screen overflow menu, let users save the current exercise list as a named routine.

## 17. ~~Make rest timer optional~~ ✅ Done
Settings toggle to disable the automatic rest timer that starts after completing a set. When disabled, no overlay appears. Duration setting is hidden when rest timer is off.

## 18. ~~Minimize rest timer~~ ✅ Done
Add a minimize button on the rest timer overlay that collapses it to a small floating chip in the top-right corner. Tapping the chip expands it again; the × button dismisses it.

## 19. ~~History shows "Exercise 1", "Exercise 2" instead of actual exercise names~~ ✅ Done
Fixed in `6958bd4`: `WorkoutDetails` now resolves exercise names from `exercisesProvider` so history renders the actual exercise names instead of fallback labels.

## 20. ~~Double logging workouts in history~~ ✅ Done
Fixed in `6958bd4`: start-workout entry points now guard against rapid duplicate taps while a workout is being created, preventing duplicate workout rows from appearing in history.

## 21. ~~Typing issue in exercise notes~~ ✅ Done
Fixed in `6958bd4`: active workout exercise note controllers now sync correctly in `didUpdateWidget`, preventing note text from jumping or resetting while typing.

## 22. ~~Workout timer pauses when screen turns off~~ ✅ Done
Fixed in `6958bd4`: active workout elapsed time is now recalculated from the persisted workout start time using the current clock, so the displayed duration catches up after the app is backgrounded or the screen is off.

## 23. ~~Scroll up issue at bottom of current workout exercise list~~ ✅ Done
When the user is at the bottom of the active/current workout screen, the exercise list cannot reliably scroll upward. Investigate the active workout `ReorderableListView` plus footer/add-exercise layout and fix the scroll physics/gesture area so users can scroll back up normally from the bottom of the list.
Fixed by making the active workout `ReorderableListView` the only populated-state scrollable and moving the add-exercise footer into the list.

## 24. ~~Show times in the user's device local timezone~~ ✅ Done
All times displayed throughout the app (workout start/end, history timestamps, etc.) should be rendered in the device's local timezone. Audit every place that formats a `DateTime` and ensure values are converted with `.toLocal()` (or stored/displayed consistently) so users never see UTC or a stale timezone.
Fixed by adding `Formatters.dateTime(dt, pattern)` in `lib/utils/formatters.dart` (applies `.toLocal()`) and routing all `DateFormat` calls in `history_screen.dart` and `workout_detail_screen.dart` through it.

## 25. ~~Loading indicator on Finish workout button~~ ✅ Done
When the user taps Finish on the active workout, show a loading spinner on the button (and disable it) while the save/finish operation is in progress. Without feedback it's unclear whether the tap registered or an API call is happening.
Fixed by wrapping the confirmation dialog in `_finishWorkout` with a `StatefulBuilder` that owns an `isSaving` flag; the dialog's Finish button swaps to a `CircularProgressIndicator` and disables both actions while `WorkoutRepository.finish()` runs.
