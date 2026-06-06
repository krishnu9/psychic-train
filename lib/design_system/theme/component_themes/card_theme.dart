import 'package:flutter/material.dart';

import '../../tokens/borders.dart';
import '../../tokens/colors.dart';
import '../../tokens/radii.dart';
import '../../tokens/spacing.dart';

/// Card theme for DESIGN.md card-content / card-feature-product specs.
abstract final class AppCardTheme {
  static CardThemeData data() => CardThemeData(
        color: AppPalette.canvasCard,
        elevation: 0,
        shadowColor: Colors.transparent,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: AppRadii.smRadius,
          side: AppBorders.hairlineSide(),
        ),
        clipBehavior: Clip.antiAlias,
      );

  static BoxDecoration contentDecoration() => BoxDecoration(
        color: AppPalette.canvasCard,
        borderRadius: AppRadii.smRadius,
        border: Border.all(
          color: AppBorders.hairline,
          width: AppBorders.hairlineWidth,
        ),
      );

  static BoxDecoration softDecoration() => BoxDecoration(
        color: AppPalette.canvasSoft,
        borderRadius: AppRadii.smRadius,
        border: Border.all(
          color: AppBorders.hairline,
          width: AppBorders.hairlineWidth,
        ),
      );

  static EdgeInsets contentPadding() => AppSpacing.card;
}
