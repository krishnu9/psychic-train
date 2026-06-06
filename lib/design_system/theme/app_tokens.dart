import 'package:flutter/material.dart';

import '../tokens/colors.dart';
import '../tokens/semantic_colors.dart';
import '../tokens/typography.dart';

/// Bundles all design tokens as a [ThemeExtension].
///
/// Access via `context.ds` — see [DesignSystem] extension.
@immutable
class AppTokens extends ThemeExtension<AppTokens> {
  const AppTokens({
    this.colors = const AppColorTokens(),
    this.semantic = const AppSemanticColors(),
    this.typography = const AppTypography(),
  });

  final AppColorTokens colors;
  final AppSemanticColors semantic;
  final AppTypography typography;

  @override
  AppTokens copyWith({
    AppColorTokens? colors,
    AppSemanticColors? semantic,
    AppTypography? typography,
  }) {
    return AppTokens(
      colors: colors ?? this.colors,
      semantic: semantic ?? this.semantic,
      typography: typography ?? this.typography,
    );
  }

  @override
  AppTokens lerp(ThemeExtension<AppTokens>? other, double t) {
    if (other is! AppTokens) return this;
    return AppTokens(
      colors: colors.lerp(other.colors, t),
      semantic: semantic.lerp(other.semantic, t),
      typography: typography.lerp(other.typography, t),
    );
  }

  static const AppTokens dark = AppTokens();
}
