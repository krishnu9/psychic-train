import 'package:flutter/material.dart';

import '../extensions/context_extensions.dart';
import 'app_text.dart';

/// Branded app bar — maps to DESIGN.md nav-bar spec.
///
/// Use on inner screens. Shell navigation uses [AppBottomNav].
class AppAppBar extends StatelessWidget implements PreferredSizeWidget {
  const AppAppBar({
    super.key,
    this.title,
    this.leading,
    this.actions,
    this.centerTitle = false,
    this.automaticallyImplyLeading = true,
  });

  final String? title;
  final Widget? leading;
  final List<Widget>? actions;
  final bool centerTitle;
  final bool automaticallyImplyLeading;

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);

  @override
  Widget build(BuildContext context) {
    final colors = context.ds.colors;
    final typography = context.ds.typography;

    return AppBar(
      backgroundColor: colors.canvas,
      foregroundColor: colors.ink,
      elevation: 0,
      scrolledUnderElevation: 0,
      centerTitle: centerTitle,
      automaticallyImplyLeading: automaticallyImplyLeading,
      leading: leading,
      title: title != null
          ? AppText(title!, style: typography.bodySm)
          : null,
      actions: actions,
    );
  }
}
