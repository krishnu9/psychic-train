import 'package:flutter/material.dart';

import 'colors.dart';

/// Border tokens from DESIGN.md.
abstract final class AppBorders {
  /// Translucent white outline for pill buttons — never use solid white.
  static const Color outlinePill = Color.fromRGBO(255, 255, 255, 0.25);

  /// 1px hairline border color.
  static const Color hairline = AppPalette.hairline;

  static const double hairlineWidth = 1;

  static BorderSide outlinePillSide({double width = hairlineWidth}) =>
      BorderSide(color: outlinePill, width: width);

  static BorderSide hairlineSide({double width = hairlineWidth}) =>
      BorderSide(color: hairline, width: width);
}
