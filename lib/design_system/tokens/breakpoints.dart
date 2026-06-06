import 'package:flutter/material.dart';

/// Responsive breakpoints from DESIGN.md.
abstract final class AppBreakpoints {
  static const double mobileMax = 767;
  static const double desktopMin = 768;

  static bool isMobile(BuildContext context) =>
      MediaQuery.sizeOf(context).width <= mobileMax;

  static bool isDesktop(BuildContext context) =>
      MediaQuery.sizeOf(context).width >= desktopMin;

  /// Returns [mobile] below 768px, [desktop] otherwise.
  static T responsive<T>(
    BuildContext context, {
    required T mobile,
    required T desktop,
  }) =>
      isMobile(context) ? mobile : desktop;
}
