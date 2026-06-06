import 'package:flutter/material.dart';

import '../extensions/context_extensions.dart';
import '../tokens/borders.dart';
import '../tokens/radii.dart';
import '../tokens/spacing.dart';
import 'app_text.dart';

/// Button variants from DESIGN.md.
enum AppButtonVariant {
  /// White-filled pill — rare primary CTA.
  primary,

  /// Canonical white-outline pill.
  outline,

  /// Smaller outline pill for card-cluster CTAs.
  outlineSm,

  /// Destructive outline — accent-sunset derived.
  destructive,
}

/// Button sizes — gym mode for active workout oversized targets.
enum AppButtonSize { md, lg, gym }

/// Brand pill button — use instead of [ElevatedButton] / [OutlinedButton].
///
/// Forbidden in screens: direct Material button usage with inline styles.
class AppButton extends StatelessWidget {
  const AppButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.variant = AppButtonVariant.outline,
    this.size = AppButtonSize.md,
    this.icon,
    this.isLoading = false,
    this.expand = false,
  });

  final String label;
  final VoidCallback? onPressed;
  final AppButtonVariant variant;
  final AppButtonSize size;
  final IconData? icon;
  final bool isLoading;
  final bool expand;

  EdgeInsets _padding() {
    return switch (size) {
      AppButtonSize.md => switch (variant) {
          AppButtonVariant.primary => AppSpacing.buttonPrimary,
          AppButtonVariant.outlineSm => AppSpacing.buttonOutlineSm,
          _ => AppSpacing.buttonOutline,
        },
      AppButtonSize.lg => AppSpacing.buttonOutline,
      AppButtonSize.gym => AppSpacing.buttonGym,
    };
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.ds.colors;
    final typography = context.ds.typography;

    final bool enabled = onPressed != null && !isLoading;

    Color background;
    Color foreground;
    BorderSide borderSide;

    switch (variant) {
      case AppButtonVariant.primary:
        background = colors.primary;
        foreground = colors.onPrimary;
        borderSide = BorderSide(color: colors.primary, width: 1);
      case AppButtonVariant.destructive:
        background = colors.canvas;
        foreground = context.ds.semantic.destructive;
        borderSide = BorderSide(
          color: context.ds.semantic.destructive.withValues(alpha: 0.5),
          width: AppBorders.hairlineWidth,
        );
      case AppButtonVariant.outline:
      case AppButtonVariant.outlineSm:
        background = colors.canvas;
        foreground = colors.ink;
        borderSide = AppBorders.outlinePillSide();
    }

    final child = isLoading
        ? SizedBox(
            width: typography.buttonMd.fontSize,
            height: typography.buttonMd.fontSize,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              color: foreground,
            ),
          )
        : Row(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (icon != null) ...[
                Icon(icon, size: 18, color: foreground),
                const SizedBox(width: AppSpacing.sm),
              ],
              AppText(label, style: typography.buttonMd, color: foreground),
            ],
          );

    final button = Material(
      color: enabled ? background : colors.canvasMid,
      shape: RoundedRectangleBorder(
        borderRadius: AppRadii.pillRadius,
        side: enabled
            ? borderSide
            : BorderSide(color: colors.hairline, width: 1),
      ),
      child: InkWell(
        onTap: enabled ? onPressed : null,
        borderRadius: AppRadii.pillRadius,
        child: Padding(
          padding: _padding(),
          child: ConstrainedBox(
            constraints: const BoxConstraints(minHeight: 44, minWidth: 44),
            child: Center(child: child),
          ),
        ),
      ),
    );

    if (expand) {
      return SizedBox(width: double.infinity, child: button);
    }
    return button;
  }
}
