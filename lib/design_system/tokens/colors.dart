import 'package:flutter/material.dart';

/// Brand color tokens from DESIGN.md.
///
/// All UI colors must come from [AppColorTokens] — never hardcode hex values
/// in screens or components.
@immutable
class AppColorTokens {
  const AppColorTokens();

  Color get primary => const Color(0xFFFFFFFF);
  Color get onPrimary => const Color(0xFF0A0A0A);
  Color get ink => const Color(0xFFFFFFFF);
  Color get inkHover => const Color(0xFFFAFAF7);
  Color get body => const Color(0xFFDADBDF);
  Color get bodyMid => const Color(0xFF7D8187);
  Color get mute => const Color(0xFF7D8187);
  Color get hairline => const Color(0xFF212327);

  Color get canvas => const Color(0xFF0A0A0A);
  Color get canvasSoft => const Color(0xFF1A1C20);
  Color get canvasCard => const Color(0xFF191919);
  Color get canvasMid => const Color(0xFF363A3F);

  Color get accentSunset => const Color(0xFFFF7A17);
  Color get accentSunsetSoft => const Color(0xFFFFC285);
  Color get accentDusk => const Color(0xFF7C3AED);
  Color get accentTwilight => const Color(0xFFC4B5FD);
  Color get accentBreeze => const Color(0xFFA0C3EC);
  Color get accentMidnight => const Color(0xFF0D1726);

  List<Color> get accentPalette => const [
        Color(0xFFFF7A17),
        Color(0xFF7C3AED),
        Color(0xFFC4B5FD),
        Color(0xFFA0C3EC),
        Color(0xFFFFC285),
        Color(0xFF0D1726),
      ];

  ColorScheme get colorScheme => ColorScheme.dark(
        brightness: Brightness.dark,
        primary: primary,
        onPrimary: onPrimary,
        secondary: accentDusk,
        onSecondary: ink,
        surface: canvasCard,
        onSurface: ink,
        error: accentSunset,
        onError: onPrimary,
        outline: hairline,
      );

  AppColorTokens copyWith() => const AppColorTokens();

  AppColorTokens lerp(AppColorTokens? other, double t) =>
      const AppColorTokens();
}

/// Static color constants for theme definitions and legacy shim.
abstract final class AppPalette {
  static const Color primary = Color(0xFFFFFFFF);
  static const Color onPrimary = Color(0xFF0A0A0A);
  static const Color ink = Color(0xFFFFFFFF);
  static const Color body = Color(0xFFDADBDF);
  static const Color mute = Color(0xFF7D8187);
  static const Color hairline = Color(0xFF212327);
  static const Color canvas = Color(0xFF0A0A0A);
  static const Color canvasSoft = Color(0xFF1A1C20);
  static const Color canvasCard = Color(0xFF191919);
  static const Color canvasMid = Color(0xFF363A3F);
  static const Color accentSunset = Color(0xFFFF7A17);
  static const Color accentSunsetSoft = Color(0xFFFFC285);
  static const Color accentDusk = Color(0xFF7C3AED);
  static const Color accentTwilight = Color(0xFFC4B5FD);
  static const Color accentBreeze = Color(0xFFA0C3EC);
  static const Color accentMidnight = Color(0xFF0D1726);

  static const List<Color> accentPalette = [
    accentSunset,
    accentDusk,
    accentTwilight,
    accentBreeze,
    accentSunsetSoft,
    accentMidnight,
  ];

  static ColorScheme get colorScheme => const ColorScheme.dark(
        brightness: Brightness.dark,
        primary: primary,
        onPrimary: onPrimary,
        secondary: accentDusk,
        onSecondary: ink,
        surface: canvasCard,
        onSurface: ink,
        error: accentSunset,
        onError: onPrimary,
        outline: hairline,
      );
}
