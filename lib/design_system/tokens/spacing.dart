import 'package:flutter/material.dart';

/// Spacing scale from DESIGN.md (base unit 4px).
///
/// Use named [Insets] presets for component padding — never arbitrary numbers.
abstract final class AppSpacing {
  static const double xxs = 2;
  static const double xs = 4;
  static const double sm = 8;
  static const double md = 12;
  static const double lg = 16;
  static const double xl = 24;
  static const double x2l = 32;
  static const double x3l = 48;
  static const double x4l = 64;

  /// Standard screen horizontal padding with bottom breathing room.
  static const EdgeInsets screen = EdgeInsets.fromLTRB(xl, lg, xl, x2l);

  /// Hero / content band padding.
  static const EdgeInsets band = EdgeInsets.symmetric(
    vertical: x4l,
    horizontal: xl,
  );

  /// Card interior padding ({spacing.xl}).
  static const EdgeInsets card = EdgeInsets.all(xl);

  /// Empty-state frame padding ({spacing.3xl}).
  static const EdgeInsets emptyState = EdgeInsets.all(x3l);

  /// button-primary: {spacing.xs} {spacing.md}
  static const EdgeInsets buttonPrimary = EdgeInsets.symmetric(
    vertical: xs,
    horizontal: md,
  );

  /// button-outline-on-dark: {spacing.sm} {spacing.lg}
  static const EdgeInsets buttonOutline = EdgeInsets.symmetric(
    vertical: sm,
    horizontal: lg,
  );

  /// button-outline-sm: {spacing.xs} {spacing.md}
  static const EdgeInsets buttonOutlineSm = EdgeInsets.symmetric(
    vertical: xs,
    horizontal: md,
  );

  /// Gym-mode oversized button padding.
  static const EdgeInsets buttonGym = EdgeInsets.symmetric(
    vertical: lg,
    horizontal: x2l,
  );

  /// text-input: {spacing.md} {spacing.lg}
  static const EdgeInsets textInput = EdgeInsets.symmetric(
    vertical: md,
    horizontal: lg,
  );

  /// nav-bar: {spacing.md} {spacing.xl}
  static const EdgeInsets navBar = EdgeInsets.symmetric(
    vertical: md,
    horizontal: xl,
  );

  /// footer: {spacing.3xl} {spacing.xl}
  static const EdgeInsets footer = EdgeInsets.symmetric(
    vertical: x3l,
    horizontal: xl,
  );

  /// ex-app-shell-row / list item: {spacing.md} {spacing.lg}
  static const EdgeInsets listItem = EdgeInsets.symmetric(
    vertical: md,
    horizontal: lg,
  );

  /// ex-data-table-cell: {spacing.md} {spacing.lg}
  static const EdgeInsets tableCell = EdgeInsets.symmetric(
    vertical: md,
    horizontal: lg,
  );

  /// ex-toast: {spacing.md} {spacing.lg}
  static const EdgeInsets toast = EdgeInsets.symmetric(
    vertical: md,
    horizontal: lg,
  );

  /// Bottom nav outer padding.
  static const EdgeInsets bottomNavOuter = EdgeInsets.fromLTRB(xl, sm, xl, md);
}
