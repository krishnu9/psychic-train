import 'package:flutter/material.dart';

import '../../tokens/borders.dart';
import '../../tokens/colors.dart';
import '../../tokens/radii.dart';
import '../../tokens/spacing.dart';
import '../../tokens/typography.dart';

/// SnackBar theme for DESIGN.md ex-toast spec.
abstract final class AppSnackBarTheme {
  static SnackBarThemeData data() => SnackBarThemeData(
        backgroundColor: AppPalette.canvas,
        contentTextStyle: const AppTypography().bodySm,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: AppRadii.smRadius,
          side: AppBorders.hairlineSide(),
        ),
        behavior: SnackBarBehavior.floating,
        insetPadding: AppSpacing.toast,
        actionTextColor: AppPalette.ink,
      );
}
