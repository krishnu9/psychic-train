import 'package:flutter/material.dart';

import '../extensions/context_extensions.dart';
import 'app_button.dart';
import 'app_text.dart';

/// Branded dialog — maps to DESIGN.md ex-modal-card (hairline, no shadow).
///
/// Use [showAppDialog] instead of raw [showDialog] + [AlertDialog].
class AppDialog extends StatelessWidget {
  const AppDialog({
    super.key,
    required this.title,
    this.content,
    this.actions,
    this.barrierDismissible = true,
  });

  final String title;
  final Widget? content;
  final List<Widget>? actions;
  final bool barrierDismissible;

  @override
  Widget build(BuildContext context) {
    final typography = context.ds.typography;

    return AlertDialog(
      title: AppText(title, style: typography.displayXs),
      content: content is String
          ? AppText(
              content! as String,
              style: typography.bodyMdMuted(),
            )
          : content,
      actions: actions,
    );
  }
}

/// Shows a branded confirm dialog. Returns `true` for confirm, `false` for cancel.
Future<bool?> showAppConfirmDialog({
  required BuildContext context,
  required String title,
  required String message,
  String confirmLabel = 'Confirm',
  String cancelLabel = 'Cancel',
  AppButtonVariant confirmVariant = AppButtonVariant.primary,
  bool destructive = false,
  bool barrierDismissible = true,
}) {
  return showAppDialog<bool>(
    context: context,
    barrierDismissible: barrierDismissible,
    builder: (ctx) => AppDialog(
      title: title,
      content: AppText(
        message,
        style: ctx.ds.typography.bodyMdMuted(),
      ),
      actions: [
        AppButton(
          label: cancelLabel,
          variant: AppButtonVariant.outlineSm,
          onPressed: () => Navigator.pop(ctx, false),
        ),
        AppButton(
          label: confirmLabel,
          variant: destructive
              ? AppButtonVariant.destructive
              : confirmVariant,
          onPressed: () => Navigator.pop(ctx, true),
        ),
      ],
    ),
  );
}

/// Shows a branded dialog.
Future<T?> showAppDialog<T>({
  required BuildContext context,
  required WidgetBuilder builder,
  bool barrierDismissible = true,
}) {
  return showDialog<T>(
    context: context,
    barrierDismissible: barrierDismissible,
    builder: builder,
  );
}

/// Alert with a single dismiss action.
Future<void> showAppAlert({
  required BuildContext context,
  required String title,
  required String message,
  String dismissLabel = 'OK',
}) {
  return showAppDialog<void>(
    context: context,
    builder: (ctx) => AppDialog(
      title: title,
      content: AppText(
        message,
        style: ctx.ds.typography.bodyMdMuted(),
      ),
      actions: [
        AppButton(
          label: dismissLabel,
          variant: AppButtonVariant.primary,
          onPressed: () => Navigator.pop(ctx),
        ),
      ],
    ),
  );
}
