import 'package:flutter/material.dart';

import '../../tokens/borders.dart';
import '../../tokens/colors.dart';
import '../../tokens/radii.dart';
import '../../tokens/spacing.dart';
import '../../tokens/typography.dart';

/// Input decoration theme for DESIGN.md text-input spec.
abstract final class AppInputTheme {
  static InputDecorationTheme data() => InputDecorationTheme(
        filled: true,
        fillColor: AppPalette.canvasSoft,
        contentPadding: AppSpacing.textInput,
        hintStyle: const AppTypography().bodyMdMuted(),
        labelStyle: const AppTypography().bodySm,
        errorStyle: const AppTypography().bodySm.copyWith(
              color: AppPalette.accentSunset,
            ),
        border: OutlineInputBorder(
          borderRadius: AppRadii.smRadius,
          borderSide: AppBorders.hairlineSide(),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: AppRadii.smRadius,
          borderSide: AppBorders.hairlineSide(),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: AppRadii.smRadius,
          borderSide: AppBorders.outlinePillSide(),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: AppRadii.smRadius,
          borderSide: const BorderSide(
            color: AppPalette.accentSunset,
            width: AppBorders.hairlineWidth,
          ),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: AppRadii.smRadius,
          borderSide: const BorderSide(
            color: AppPalette.accentSunset,
            width: AppBorders.hairlineWidth,
          ),
        ),
      );
}
