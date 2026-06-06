import 'package:flutter/material.dart';

import '../theme/app_tokens.dart';
import '../tokens/breakpoints.dart';
import '../tokens/radii.dart';
import '../tokens/spacing.dart';

/// Shorthand access to the design system from any [BuildContext].
///
/// ```dart
/// Text('Hello', style: context.ds.typography.bodyMd);
/// Container(color: context.ds.colors.canvas);
/// ```
extension DesignSystem on BuildContext {
  AppTokens get ds => Theme.of(this).extension<AppTokens>()!;

  bool get isMobile => AppBreakpoints.isMobile(this);

  bool get isDesktop => AppBreakpoints.isDesktop(this);

  T responsive<T>({required T mobile, required T desktop}) =>
      AppBreakpoints.responsive(this, mobile: mobile, desktop: desktop);
}

/// Static token access for non-widget code (tests, themes).
abstract final class AppTokensStatic {
  static const spacing = AppSpacing;
  static const radii = AppRadii;
}
