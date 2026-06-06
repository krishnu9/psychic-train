import 'package:flutter/material.dart';

import '../tokens/colors.dart';
import '../tokens/typography.dart';
import 'app_tokens.dart';
import 'component_themes/app_bar_theme.dart';
import 'component_themes/button_theme.dart';
import 'component_themes/card_theme.dart';
import 'component_themes/chip_theme.dart';
import 'component_themes/dialog_theme.dart';
import 'component_themes/input_theme.dart';
import 'component_themes/list_tile_theme.dart';
import 'component_themes/navigation_theme.dart';
import 'component_themes/snack_bar_theme.dart';

/// Root theme factory — dark canvas only per DESIGN.md.
///
/// ```dart
/// MaterialApp(theme: AppTheme.dark, ...);
/// ```
abstract final class AppTheme {
  static ThemeData get dark {
    const typography = AppTypography();
    final textTheme = typography.toTextTheme();

    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      scaffoldBackgroundColor: AppPalette.canvas,
      colorScheme: AppPalette.colorScheme,
      extensions: const [AppTokens.dark],
      textTheme: textTheme.apply(
        bodyColor: AppPalette.ink,
        displayColor: AppPalette.ink,
      ),
      primaryTextTheme: textTheme,
      appBarTheme: AppAppBarTheme.data(),
      bottomNavigationBarTheme: AppNavigationTheme.bottomNav(),
      navigationBarTheme: AppNavigationTheme.navigationBar(),
      cardTheme: AppCardTheme.data(),
      dialogTheme: AppDialogTheme.data(),
      dividerTheme: const DividerThemeData(
        color: AppPalette.hairline,
        thickness: 1,
        space: 0,
      ),
      inputDecorationTheme: AppInputTheme.data(),
      elevatedButtonTheme: AppButtonTheme.elevated(),
      outlinedButtonTheme: AppButtonTheme.outlined(),
      textButtonTheme: AppButtonTheme.text(),
      chipTheme: AppChipTheme.data(),
      listTileTheme: AppListTileTheme.data(),
      snackBarTheme: AppSnackBarTheme.data(),
      iconTheme: const IconThemeData(color: AppPalette.ink),
      splashColor: AppPalette.ink.withValues(alpha: 0.08),
      highlightColor: AppPalette.ink.withValues(alpha: 0.04),
      floatingActionButtonTheme: const FloatingActionButtonThemeData(
        backgroundColor: AppPalette.primary,
        foregroundColor: AppPalette.onPrimary,
        elevation: 0,
        highlightElevation: 0,
        shape: StadiumBorder(),
      ),
      progressIndicatorTheme: const ProgressIndicatorThemeData(
        color: AppPalette.ink,
        linearTrackColor: AppPalette.canvasMid,
        circularTrackColor: AppPalette.canvasMid,
      ),
      canvasColor: AppPalette.canvas,
      disabledColor: AppPalette.mute,
      hintColor: AppPalette.mute,
      splashFactory: InkRipple.splashFactory,
    );
  }
}
