import 'package:flutter/material.dart';

import '../design_system/tokens/colors.dart';
import '../design_system/tokens/radii.dart';
import '../design_system/theme/app_theme.dart' as ds;

export '../design_system/design_system.dart' show AppTheme;

/// @deprecated Legacy color aliases for gradual screen migration.
///
/// Maps old green/teal theme names to new DESIGN.md tokens.
/// See lib/design_system/MIGRATION.md for the full mapping table.
@Deprecated('Use context.ds.colors from design_system.dart')
abstract final class AppColors {
  static const Color background = AppPalette.canvas;
  static const Color surface = AppPalette.canvasCard;
  static const Color surfaceLight = AppPalette.canvasSoft;
  static const Color surfaceBright = AppPalette.canvasMid;
  static const Color primary = AppPalette.primary;
  static const Color primaryDark = AppPalette.accentSunset;
  static const Color primaryLight = AppPalette.accentSunsetSoft;
  static const Color secondary = AppPalette.accentDusk;
  static const Color secondaryLight = AppPalette.accentTwilight;
  static const Color success = AppPalette.accentBreeze;
  static const Color warning = AppPalette.accentSunsetSoft;
  static const Color error = AppPalette.accentSunset;
  static const Color info = AppPalette.accentBreeze;
  static const Color textPrimary = AppPalette.ink;
  static const Color textSecondary = AppPalette.body;
  static const Color textMuted = AppPalette.mute;
  static const Color divider = AppPalette.hairline;
  static const Color shimmer = AppPalette.canvasMid;
  static const double bentoRadius = AppRadii.sm;
  static const List<Color> routineColors = AppPalette.accentPalette;
}

/// @deprecated Use `AppTheme.dark` from design_system.dart
@Deprecated('Use AppTheme.dark from design_system.dart')
abstract final class LegacyAppTheme {
  static ThemeData get darkTheme => ds.AppTheme.dark;
}
