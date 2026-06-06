import 'package:flutter/material.dart';

import '../../tokens/borders.dart';
import '../../tokens/colors.dart';
import '../../tokens/radii.dart';
import '../../tokens/spacing.dart';
import '../../tokens/typography.dart';

/// Chip theme — pill outline pattern inferred from button-outline-on-dark.
abstract final class AppChipTheme {
  static ChipThemeData data() => ChipThemeData(
        backgroundColor: AppPalette.canvas,
        selectedColor: AppPalette.canvasSoft,
        disabledColor: AppPalette.canvasMid,
        labelStyle: const AppTypography().bodySm,
        secondaryLabelStyle: const AppTypography().bodySm,
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md,
          vertical: AppSpacing.xs,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: AppRadii.pillRadius,
          side: AppBorders.outlinePillSide(),
        ),
        side: AppBorders.outlinePillSide(),
        showCheckmark: false,
        elevation: 0,
        pressElevation: 0,
      );
}
