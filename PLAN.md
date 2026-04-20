# Plan
This document maintains future upcoming plan features for the application.

## 1. ~~Add markdown support for routine description~~ ✓ Done

## 2. ~~Add description for exercises~~ ✓ Done

## 3. ~~Make sure current ongoing workout is not lost when app is closed or refreshed~~ ✓ Done

## 4. ~~Categories / Sections in routine exercises~~ ✓ Done

## 5. ~~New Exercise Addition option in Select Exercise view while creating a routine.~~ ✓ Done

## 6. ~~Global database of exercises versus personal list of exercises.~~ ✓ Done

## 7. Start workout from routines section
Add a "Start Workout" button directly on each routine card/detail screen so users can launch an active workout pre-loaded with the routine's exercises without going through the workout tab.

## 8. Notes entry for every exercise
Add a per-exercise notes field in both the active workout screen and the routine edit screen. Requires a schema migration to add a `notes` column to the relevant tables (exercise entries in workouts and routines). Do this before later features build on the exercise data model.

## 9. Edit exercises in past workouts
Allow users to edit sets, reps, weight, and notes for exercises in already-completed workouts. Requires unlocking the read-only workout log view and wiring save logic back to the DB.

## 10. Drag and rearrange exercises in active workout
Let users drag to reorder exercises within an active workout session. Requires adding a `sortOrder` / `position` column to the workout exercise entries table and updating it on reorder.

## 11. Minimize active workout (floating persistent bar)
Add an option to minimize the current workout into a compact floating bar at the bottom of the screen, allowing navigation to other parts of the app while keeping the workout timer running. Tapping the bar returns to the active workout. Build after exercise ordering (item 10) is stable.

## 12. Notification when workout exceeds 1.5 hours
Send a local push notification prompting the user to finish or cancel their workout if it has been running for more than 90 minutes. Requires setting up Flutter local notifications and a background timer/alarm. Best implemented last as it depends on a stable active workout flow.

## 13. Hide add-exercise button when keyboard is open
Hide the "Add exercise" button in the active workout / routine edit screens while the user is typing a value (weight, reps, notes) and the on-screen keyboard is visible. Button should reappear once the keyboard is dismissed. Prevents the button from overlapping input fields and reduces mis-taps.

## 14. Stick resume-workout bar to bottom navigation
The minimized "Resume Workout" bar currently floats and does not stick to the bottom navigation / tab bar. Dock it directly above the bottom nav so it behaves as a persistent strip across screens instead of overlapping content.
