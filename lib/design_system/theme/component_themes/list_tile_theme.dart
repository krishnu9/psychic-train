import 'package:flutter/material.dart';

import '../../tokens/colors.dart';
import '../../tokens/spacing.dart';
import '../../tokens/typography.dart';

/// List tile theme for DESIGN.md ex-data-table-cell / ex-app-shell-row.
abstract final class AppListTileTheme {
  static ListTileThemeData data() => ListTileThemeData(
        tileColor: AppPalette.canvas,
        selectedTileColor: AppPalette.canvasSoft,
        iconColor: AppPalette.ink,
        textColor: AppPalette.ink,
        contentPadding: AppSpacing.listItem,
        minLeadingWidth: AppSpacing.lg,
        titleTextStyle: const AppTypography().bodySm,
        subtitleTextStyle: const AppTypography().bodySmMuted(),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
      );
}
