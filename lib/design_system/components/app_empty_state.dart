import 'package:flutter/material.dart';

import '../extensions/context_extensions.dart';
import '../tokens/spacing.dart';
import 'app_button.dart';
import 'app_card.dart';
import 'app_text.dart';

/// Empty state frame — DESIGN.md ex-empty-state-card.
///
/// Use when a list or section has no data to display.
class AppEmptyState extends StatelessWidget {
  const AppEmptyState({
    super.key,
    required this.title,
    this.description,
    this.icon,
    this.actionLabel,
    this.onAction,
  });

  final String title;
  final String? description;
  final IconData? icon;
  final String? actionLabel;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    final colors = context.ds.colors;
    final typography = context.ds.typography;

    return AppCard(
      variant: AppCardVariant.soft,
      padding: AppSpacing.emptyState,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 48, color: colors.mute),
            const SizedBox(height: AppSpacing.lg),
          ],
          AppText(
            title,
            style: typography.displayXs,
            textAlign: TextAlign.center,
          ),
          if (description != null) ...[
            const SizedBox(height: AppSpacing.sm),
            AppText(
              description!,
              style: typography.bodyMdMuted(),
              textAlign: TextAlign.center,
            ),
          ],
          if (actionLabel != null && onAction != null) ...[
            const SizedBox(height: AppSpacing.xl),
            AppButton(
              label: actionLabel!,
              variant: AppButtonVariant.outline,
              onPressed: onAction,
            ),
          ],
        ],
      ),
    );
  }
}
