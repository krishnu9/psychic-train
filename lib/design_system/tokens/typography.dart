import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'breakpoints.dart';
import 'colors.dart';

/// Typography ladder from DESIGN.md.
///
/// Weight 400 everywhere — size and tracking create hierarchy, not bold.
/// Use [AppTypography.resolved] for responsive display scaling.
@immutable
class AppTypography {
  const AppTypography();

  static TextStyle _inter({
    required double fontSize,
    required double height,
    double letterSpacing = 0,
    Color color = AppPalette.ink,
  }) =>
      GoogleFonts.inter(
        fontSize: fontSize,
        fontWeight: FontWeight.w400,
        height: height / fontSize,
        letterSpacing: letterSpacing,
        color: color,
      );

  static TextStyle _geistMono({
    required double fontSize,
    required double height,
    required double letterSpacing,
    Color color = AppPalette.ink,
  }) =>
      GoogleFonts.jetBrainsMono(
        fontSize: fontSize,
        fontWeight: FontWeight.w400,
        height: height / fontSize,
        letterSpacing: letterSpacing,
        color: color,
      );

  TextStyle get displayXl => _inter(
        fontSize: 96,
        height: 96,
        letterSpacing: -2.4,
      );

  TextStyle get displayLg => _inter(
        fontSize: 72,
        height: 72,
        letterSpacing: -1.8,
      );

  TextStyle get displayMd => _inter(
        fontSize: 48,
        height: 48,
        letterSpacing: -1.2,
      );

  TextStyle get displaySm => _inter(
        fontSize: 32,
        height: 36,
        letterSpacing: -0.6,
      );

  TextStyle get displayXs => _inter(
        fontSize: 20,
        height: 28,
      );

  TextStyle get bodyLg => _inter(
        fontSize: 18,
        height: 28,
      );

  TextStyle get bodyMd => _inter(
        fontSize: 16,
        height: 24,
      );

  TextStyle get bodySm => _inter(
        fontSize: 14,
        height: 20,
      );

  TextStyle get captionMono => _geistMono(
        fontSize: 14,
        height: 20,
        letterSpacing: 1.4,
      );

  TextStyle get captionMonoSm => _geistMono(
        fontSize: 12,
        height: 16,
        letterSpacing: 1.2,
      );

  TextStyle get buttonMd => _inter(
        fontSize: 14,
        height: 20,
      );

  /// Secondary body copy color.
  TextStyle bodyLgMuted() => bodyLg.copyWith(color: AppPalette.body);

  TextStyle bodyMdMuted() => bodyMd.copyWith(color: AppPalette.body);

  TextStyle bodySmMuted() => bodySm.copyWith(color: AppPalette.mute);

  /// Scales display sizes on mobile (display-xl 96→48 per DESIGN.md).
  TextStyle resolved(BuildContext context, TextStyle style) {
    if (!AppBreakpoints.isMobile(context)) return style;

    final size = style.fontSize;
    if (size == null) return style;

    if (size >= 96) {
      return style.copyWith(
        fontSize: 48,
        height: 48 / 48,
        letterSpacing: -1.2,
      );
    }
    if (size >= 72) {
      return style.copyWith(
        fontSize: 40,
        height: 40 / 40,
        letterSpacing: -1.0,
      );
    }
    if (size >= 48) {
      return style.copyWith(
        fontSize: 32,
        height: 36 / 32,
        letterSpacing: -0.8,
      );
    }
    return style;
  }

  /// Builds a full [TextTheme] for Material integration.
  TextTheme toTextTheme() {
    return TextTheme(
      displayLarge: displayXl,
      displayMedium: displayLg,
      displaySmall: displayMd,
      headlineLarge: displaySm,
      headlineMedium: displayXs,
      headlineSmall: bodyLg,
      titleLarge: displayXs,
      titleMedium: bodyMd,
      titleSmall: bodySm,
      bodyLarge: bodyLg,
      bodyMedium: bodyMd,
      bodySmall: bodySm,
      labelLarge: buttonMd,
      labelMedium: bodySm,
      labelSmall: captionMonoSm,
    );
  }

  AppTypography copyWith() => const AppTypography();

  AppTypography lerp(AppTypography? other, double t) => const AppTypography();
}
