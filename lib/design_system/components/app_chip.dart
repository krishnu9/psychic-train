import 'package:flutter/material.dart';

import '../extensions/context_extensions.dart';
import '../tokens/borders.dart';
import '../tokens/radii.dart';
import '../tokens/spacing.dart';
import 'app_text.dart';

/// Pill outline chip — use for filters and tags.
///
/// Forbidden: raw [Chip] with inline styling.
class AppChip extends StatelessWidget {
  const AppChip({
    super.key,
    required this.label,
    this.selected = false,
    this.onTap,
    this.onDeleted,
  });

  final String label;
  final bool selected;
  final VoidCallback? onTap;
  final VoidCallback? onDeleted;

  @override
  Widget build(BuildContext context) {
    final colors = context.ds.colors;
    final typography = context.ds.typography;

    return Material(
      color: selected ? colors.canvasSoft : colors.canvas,
      shape: RoundedRectangleBorder(
        borderRadius: AppRadii.pillRadius,
        side: AppBorders.outlinePillSide(),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: AppRadii.pillRadius,
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.md,
            vertical: AppSpacing.xs,
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              AppText(
                label,
                style: typography.bodySm,
                color: selected ? colors.ink : colors.body,
              ),
              if (onDeleted != null) ...[
                const SizedBox(width: AppSpacing.xs),
                GestureDetector(
                  onTap: onDeleted,
                  child: Icon(
                    Icons.close,
                    size: 14,
                    color: colors.mute,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
