import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../tokens/colors.dart';
import '../../tokens/spacing.dart';
import '../../tokens/typography.dart';

/// App bar theme for DESIGN.md nav-bar spec.
abstract final class AppAppBarTheme {
  static AppBarTheme data() => AppBarTheme(
        backgroundColor: AppPalette.canvas,
        foregroundColor: AppPalette.ink,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
        systemOverlayStyle: SystemUiOverlayStyle.light,
        titleTextStyle: const AppTypography().bodySm,
        toolbarHeight: kToolbarHeight,
        iconTheme: const IconThemeData(
          color: AppPalette.ink,
          size: 24,
        ),
        actionsIconTheme: const IconThemeData(
          color: AppPalette.ink,
          size: 24,
        ),
      );

  static EdgeInsets navPadding() => AppSpacing.navBar;
}
