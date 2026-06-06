import 'package:flutter/material.dart';

import '../../tokens/borders.dart';
import '../../tokens/colors.dart';
import '../../tokens/radii.dart';
import '../../tokens/spacing.dart';
import '../../tokens/typography.dart';

/// Material button themes mapped to DESIGN.md button-* specs.
///
/// Screens should prefer [AppButton] over raw Material buttons.
abstract final class AppButtonTheme {
  static ButtonStyle primaryStyle() => ButtonStyle(
        backgroundColor: WidgetStatePropertyAll(AppPalette.primary),
        foregroundColor: WidgetStatePropertyAll(AppPalette.onPrimary),
        padding: WidgetStatePropertyAll(AppSpacing.buttonPrimary),
        minimumSize: WidgetStatePropertyAll(const Size(0, 44)),
        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
        elevation: WidgetStatePropertyAll(0),
        shadowColor: WidgetStatePropertyAll(Colors.transparent),
        shape: WidgetStatePropertyAll(
          RoundedRectangleBorder(
            borderRadius: AppRadii.pillRadius,
            side: BorderSide(color: AppPalette.primary, width: 1),
          ),
        ),
        textStyle: WidgetStatePropertyAll(
          const AppTypography().buttonMd,
        ),
      );

  static ButtonStyle outlineStyle() => ButtonStyle(
        backgroundColor: WidgetStatePropertyAll(AppPalette.canvas),
        foregroundColor: WidgetStatePropertyAll(AppPalette.ink),
        padding: WidgetStatePropertyAll(AppSpacing.buttonOutline),
        minimumSize: WidgetStatePropertyAll(const Size(0, 44)),
        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
        elevation: WidgetStatePropertyAll(0),
        shadowColor: WidgetStatePropertyAll(Colors.transparent),
        shape: WidgetStatePropertyAll(
          RoundedRectangleBorder(
            borderRadius: AppRadii.pillRadius,
            side: AppBorders.outlinePillSide(),
          ),
        ),
        textStyle: WidgetStatePropertyAll(
          const AppTypography().buttonMd,
        ),
      );

  static ButtonStyle outlineSmStyle() => ButtonStyle(
        backgroundColor: WidgetStatePropertyAll(AppPalette.canvas),
        foregroundColor: WidgetStatePropertyAll(AppPalette.ink),
        padding: WidgetStatePropertyAll(AppSpacing.buttonOutlineSm),
        minimumSize: WidgetStatePropertyAll(const Size(0, 44)),
        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
        elevation: WidgetStatePropertyAll(0),
        shadowColor: WidgetStatePropertyAll(Colors.transparent),
        shape: WidgetStatePropertyAll(
          RoundedRectangleBorder(
            borderRadius: AppRadii.pillRadius,
            side: AppBorders.outlinePillSide(),
          ),
        ),
        textStyle: WidgetStatePropertyAll(
          const AppTypography().buttonMd,
        ),
      );

  static ElevatedButtonThemeData elevated() => ElevatedButtonThemeData(
        style: primaryStyle(),
      );

  static OutlinedButtonThemeData outlined() => OutlinedButtonThemeData(
        style: outlineStyle(),
      );

  static TextButtonThemeData text() => TextButtonThemeData(
        style: ButtonStyle(
          foregroundColor: WidgetStatePropertyAll(AppPalette.ink),
          padding: WidgetStatePropertyAll(AppSpacing.buttonOutlineSm),
          minimumSize: WidgetStatePropertyAll(const Size(0, 44)),
          textStyle: WidgetStatePropertyAll(
            const AppTypography().buttonMd,
          ),
        ),
      );
}
