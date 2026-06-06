import 'package:flutter/material.dart';

import '../../tokens/borders.dart';
import '../../tokens/colors.dart';
import '../../tokens/radii.dart';
import '../../tokens/spacing.dart';
import '../../tokens/typography.dart';

/// Dialog theme for DESIGN.md ex-modal-card spec (hairline, no shadow).
abstract final class AppDialogTheme {
  static DialogThemeData data() => DialogThemeData(
        backgroundColor: AppPalette.canvas,
        elevation: 0,
        shadowColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: AppRadii.smRadius,
          side: AppBorders.hairlineSide(),
        ),
        titleTextStyle: const AppTypography().displayXs,
        contentTextStyle: const AppTypography().bodyMd.copyWith(
              color: AppPalette.body,
            ),
        actionsPadding: AppSpacing.card,
        insetPadding: AppSpacing.screen,
      );
}
