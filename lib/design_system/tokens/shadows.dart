import 'package:flutter/material.dart';

import 'colors.dart';

/// Elevation system from DESIGN.md — hairline borders only, no drop shadows.
enum AppElevation {
  /// Level 0 — flat, no border.
  flat,

  /// Level 1 — 1px hairline border.
  hairline,
}

/// Shadow tokens — always empty per brand rules.
///
/// Do not use [BoxShadow] for elevation. Use [AppElevation.hairline] borders.
abstract final class AppShadows {
  static const List<BoxShadow> none = [];
}

/// Helpers for applying elevation via borders.
abstract final class AppElevationStyle {
  static BoxDecoration decoration({
    required AppElevation elevation,
    Color? backgroundColor,
    BorderRadius? borderRadius,
  }) {
    return BoxDecoration(
      color: backgroundColor,
      borderRadius: borderRadius,
      border: elevation == AppElevation.hairline
          ? Border.all(color: AppPalette.hairline, width: 1)
          : null,
      boxShadow: AppShadows.none,
    );
  }

  static BorderSide hairlineBorderSide({double width = 1}) => BorderSide(
        color: AppPalette.hairline,
        width: width,
      );
}
