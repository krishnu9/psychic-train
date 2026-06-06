import 'package:flutter/material.dart';

import 'colors.dart';

/// App-layer semantic colors derived from brand accent palette.
///
/// These are **not** marketing-brand tokens. Use for destructive actions,
/// info highlights, etc. — never introduce bright Material reds/greens.
@immutable
class AppSemanticColors {
  const AppSemanticColors();

  Color get destructive => AppPalette.accentSunset;
  Color get destructiveMuted => AppPalette.accentSunsetSoft;
  Color get info => AppPalette.accentBreeze;
  Color get highlight => AppPalette.accentDusk;

  AppSemanticColors copyWith() => const AppSemanticColors();

  AppSemanticColors lerp(AppSemanticColors? other, double t) =>
      const AppSemanticColors();
}

/// Static access for theme definitions and non-widget code.
abstract final class AppSemantic {
  static const Color destructive = AppPalette.accentSunset;
  static const Color destructiveMuted = AppPalette.accentSunsetSoft;
  static const Color info = AppPalette.accentBreeze;
  static const Color highlight = AppPalette.accentDusk;
}
