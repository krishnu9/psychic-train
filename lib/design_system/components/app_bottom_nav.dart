import 'package:flutter/material.dart';

import '../extensions/context_extensions.dart';
import '../tokens/borders.dart';
import '../tokens/radii.dart';
import '../tokens/spacing.dart';

/// Navigation item for [AppBottomNav].
class AppNavItem {
  const AppNavItem({
    required this.icon,
    required this.label,
    this.key,
  });

  final IconData icon;
  final String label;
  final Key? key;
}

/// Floating bottom navigation — hairline border, no shadow.
///
/// Replaces inline `_FloatingNavBar` implementations.
/// Active state uses white (primary) indicator per ex-app-shell-row.
class AppBottomNav extends StatelessWidget {
  const AppBottomNav({
    super.key,
    required this.currentIndex,
    required this.items,
    required this.onTap,
    this.navKey,
  });

  final int currentIndex;
  final List<AppNavItem> items;
  final ValueChanged<int> onTap;
  final Key? navKey;

  @override
  Widget build(BuildContext context) {
    final colors = context.ds.colors;

    return SafeArea(
      child: Padding(
        padding: AppSpacing.bottomNavOuter,
        child: Container(
          key: navKey,
          height: 64,
          decoration: BoxDecoration(
            color: colors.canvasCard,
            borderRadius: AppRadii.pillRadius,
            border: Border.all(
              color: AppBorders.hairline,
              width: AppBorders.hairlineWidth,
            ),
          ),
          child: Row(
            children: List.generate(items.length, (i) {
              final item = items[i];
              final selected = i == currentIndex;
              return Expanded(
                child: GestureDetector(
                  key: item.key,
                  onTap: () => onTap(i),
                  behavior: HitTestBehavior.opaque,
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    curve: Curves.easeInOut,
                    margin: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.xs,
                      vertical: AppSpacing.sm,
                    ),
                    decoration: BoxDecoration(
                      color: selected
                          ? colors.canvasSoft
                          : Colors.transparent,
                      borderRadius: AppRadii.pillRadius,
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        AnimatedScale(
                          scale: selected ? 1.15 : 1.0,
                          duration: const Duration(milliseconds: 200),
                          child: Icon(
                            item.icon,
                            size: 22,
                            color: selected ? colors.primary : colors.mute,
                            semanticLabel: item.label,
                          ),
                        ),
                        if (selected) ...[
                          const SizedBox(height: AppSpacing.xxs),
                          Container(
                            width: AppSpacing.xs,
                            height: AppSpacing.xs,
                            decoration: BoxDecoration(
                              color: colors.primary,
                              shape: BoxShape.circle,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
              );
            }),
          ),
        ),
      ),
    );
  }
}
