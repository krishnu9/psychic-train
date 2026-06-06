import 'package:flutter/material.dart';

import '../theme/component_themes/card_theme.dart';
import '../tokens/radii.dart';
import '../tokens/spacing.dart';

/// Card surface variants from DESIGN.md.
enum AppCardVariant {
  /// canvas-card fill with hairline border.
  content,

  /// Same chrome as content — for product/feature blocks.
  feature,

  /// canvas-soft fill — auth forms, pricing tiers.
  soft,

  /// Auth form card — alias of soft with standard padding.
  auth,
}

/// Branded card container — use instead of one-off [Container] decorations.
///
/// Forbidden: inline `BoxDecoration` for card surfaces in screens.
class AppCard extends StatelessWidget {
  const AppCard({
    super.key,
    required this.child,
    this.variant = AppCardVariant.content,
    this.padding,
    this.onTap,
    this.margin,
  });

  final Widget child;
  final AppCardVariant variant;
  final EdgeInsetsGeometry? padding;
  final VoidCallback? onTap;
  final EdgeInsetsGeometry? margin;

  BoxDecoration _decoration() {
    return switch (variant) {
      AppCardVariant.content || AppCardVariant.feature => AppCardTheme.contentDecoration(),
      AppCardVariant.soft || AppCardVariant.auth => AppCardTheme.softDecoration(),
    };
  }

  @override
  Widget build(BuildContext context) {
    final content = Padding(
      padding: padding ?? AppSpacing.card,
      child: child,
    );

    final card = Container(
      margin: margin,
      decoration: _decoration(),
      child: onTap != null
          ? Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: onTap,
                borderRadius: AppRadii.smRadius,
                child: content,
              ),
            )
          : content,
    );

    return card;
  }
}
