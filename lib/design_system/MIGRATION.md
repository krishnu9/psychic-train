# Design System Migration Guide

Migrate existing screens from the legacy green/teal theme (`lib/theme/app_theme.dart`) to the DESIGN.md design system (`lib/design_system/`).

## 1. Update imports

```dart
// Before
import '../theme/app_theme.dart';

// After
import '../design_system/design_system.dart';
```

## 2. Color migration table

| Legacy `AppColors` | New token | Notes |
|---|---|---|
| `background` | `context.ds.colors.canvas` | `#0a0a0a` |
| `surface` | `context.ds.colors.canvasCard` | `#191919` |
| `surfaceLight` | `context.ds.colors.canvasSoft` | `#1a1c20` |
| `surfaceBright` | `context.ds.colors.canvasMid` | `#363a3f` |
| `primary` (green) | `context.ds.colors.primary` | **Breaking:** now white `#ffffff` |
| `primaryDark` | `context.ds.colors.accentSunset` | Accent-derived |
| `primaryLight` | `context.ds.colors.accentSunsetSoft` | Accent-derived |
| `secondary` | `context.ds.colors.accentDusk` | |
| `textPrimary` | `context.ds.colors.ink` | |
| `textSecondary` | `context.ds.colors.body` | |
| `textMuted` | `context.ds.colors.mute` | |
| `divider` | `context.ds.colors.hairline` | |
| `error` | `context.ds.semantic.destructive` | Sunset orange, not Material red |
| `success` | `AppSemanticColors.info` | Breeze blue |
| `routineColors` | `AppColorTokens.accentPalette` | |

## 3. Typography migration

```dart
// Before — forbidden
Text('Title', style: TextStyle(
  color: AppColors.textPrimary,
  fontWeight: FontWeight.w700,
  fontSize: 20,
))

// After
AppText('Title', style: context.ds.typography.displayXs)
```

| Old pattern | New token |
|---|---|
| Bold headlines (`w700+`) | `displayXs` / `displaySm` (weight 400) |
| Section labels with letter-spacing | `AppEyebrow('SECTION')` |
| Body copy | `context.ds.typography.bodyMd` |
| Muted captions | `context.ds.typography.bodySmMuted()` |
| Button labels | `context.ds.typography.buttonMd` |

## 4. Spacing migration

```dart
// Before — forbidden
padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),

// After
padding: AppSpacing.screen,
```

| Old value | New token |
|---|---|
| `4` | `AppSpacing.xs` |
| `8` | `AppSpacing.sm` |
| `12` | `AppSpacing.md` |
| `16` | `AppSpacing.lg` |
| `20` | Use `AppSpacing.xl` (24) or `AppSpacing.lg` (16) |
| `24` | `AppSpacing.xl` |
| `32` | `AppSpacing.x2l` |

## 5. Radius migration

| Old value | New token |
|---|---|
| `BorderRadius.circular(12/16/20)` | `AppRadii.sm` (8px) for cards |
| `BorderRadius.circular(32)` | `AppRadii.pill` for nav/buttons |
| `bentoRadius` (20) | `AppRadii.sm` |

## 6. Component replacements

| Before | After |
|---|---|
| `ElevatedButton(...)` | `AppButton(variant: AppButtonVariant.primary, ...)` |
| `OutlinedButton(...)` | `AppButton(variant: AppButtonVariant.outline, ...)` |
| `TextButton(...)` | `AppButton(variant: AppButtonVariant.outlineSm, ...)` |
| `TextField(...)` with inline decoration | `AppTextField(...)` |
| `Container` with card `BoxDecoration` | `AppCard(variant: AppCardVariant.content, ...)` |
| `AlertDialog(...)` | `showAppDialog(...)` / `showAppConfirmDialog(...)` |
| `SnackBar(...)` | `showAppToast(context, message: ...)` |
| `AppBar(...)` with inline colors | `AppAppBar(title: ...)` |
| `Chip(...)` | `AppChip(...)` |
| `ListTile(...)` | `AppListItem(...)` |
| `CircularProgressIndicator` | `AppLoader(...)` |
| Empty placeholder `Column` | `AppEmptyState(...)` |
| `Divider(...)` | `AppDivider()` |
| `_FloatingNavBar` | `AppBottomNav(...)` |

## 7. Per-screen checklist (priority order)

- [ ] `lib/screens/app_shell.dart` — nav bar + resume dialog
- [ ] `lib/screens/auth/auth_screen.dart` — auth form card
- [ ] `lib/screens/home_screen.dart` — highest inline-style density
- [ ] `lib/screens/workout/active_workout_screen.dart` — gym buttons (`AppButtonSize.gym`)
- [ ] `lib/screens/workout/minimized_workout_bar.dart`
- [ ] `lib/screens/routines/routine_list_screen.dart`
- [ ] `lib/screens/routines/routine_edit_screen.dart`
- [ ] `lib/screens/exercises/exercise_list_screen.dart`
- [ ] `lib/screens/exercises/exercise_picker.dart`
- [ ] `lib/screens/exercises/exercise_create_form.dart`
- [ ] `lib/screens/history/history_screen.dart`
- [ ] `lib/screens/history/workout_detail_screen.dart`
- [ ] `lib/screens/settings_screen.dart`
- [ ] `lib/widgets/consistency_heatmap.dart`

## 8. Theme wiring

`lib/app.dart` should use:

```dart
import 'design_system/design_system.dart';

MaterialApp(theme: AppTheme.dark, ...)
```

## 9. Verification

After migrating a screen, run:

```bash
./scripts/design_system_audit.sh
flutter analyze
flutter test
```
