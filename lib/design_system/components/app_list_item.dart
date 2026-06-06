import 'package:flutter/material.dart';

import '../extensions/context_extensions.dart';
import '../tokens/radii.dart';
import '../tokens/spacing.dart';
import 'app_eyebrow.dart';
import 'app_text.dart';

/// Branded list row — maps to ex-app-shell-row / ex-data-table-cell.
///
/// Use instead of raw [ListTile] with inline colors.
class AppListItem extends StatelessWidget {
  const AppListItem({
    super.key,
    required this.title,
    this.subtitle,
    this.leading,
    this.trailing,
    this.monoHeader,
    this.selected = false,
    this.onTap,
    this.showActiveIndicator = false,
  });

  final String title;
  final String? subtitle;
  final Widget? leading;
  final Widget? trailing;
  final String? monoHeader;
  final bool selected;
  final VoidCallback? onTap;
  final bool showActiveIndicator;

  @override
  Widget build(BuildContext context) {
    final colors = context.ds.colors;
    final typography = context.ds.typography;

    return Material(
      color: selected ? colors.canvasSoft : colors.canvas,
      borderRadius: AppRadii.smRadius,
      child: InkWell(
        onTap: onTap,
        borderRadius: AppRadii.smRadius,
        child: Padding(
          padding: AppSpacing.listItem,
          child: Row(
            children: [
              if (showActiveIndicator && selected)
                Container(
                  width: 2,
                  height: 24,
                  margin: const EdgeInsets.only(right: AppSpacing.md),
                  decoration: BoxDecoration(
                    color: colors.primary,
                    borderRadius: AppRadii.smRadius,
                  ),
                ),
              if (leading != null) ...[
                leading!,
                const SizedBox(width: AppSpacing.md),
              ],
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (monoHeader != null) ...[
                      AppEyebrow(monoHeader!),
                      const SizedBox(height: AppSpacing.xs),
                    ],
                    AppText(
                      title,
                      style: typography.bodySm,
                      color: selected ? colors.ink : colors.body,
                    ),
                    if (subtitle != null) ...[
                      const SizedBox(height: AppSpacing.xxs),
                      AppText(
                        subtitle!,
                        style: typography.bodySmMuted(),
                      ),
                    ],
                  ],
                ),
              ),
              if (trailing != null) trailing!,
            ],
          ),
        ),
      ),
    );
  }
}
