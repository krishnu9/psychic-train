import 'package:flutter/material.dart';

import '../extensions/context_extensions.dart';

/// Shows a branded toast — DESIGN.md ex-toast spec.
///
/// Use instead of raw [SnackBar] with inline styling.
void showAppToast(
  BuildContext context, {
  required String message,
  Duration duration = const Duration(seconds: 3),
  String? actionLabel,
  VoidCallback? onAction,
}) {
  final messenger = ScaffoldMessenger.maybeOf(context);
  if (messenger == null) return;

  messenger.hideCurrentSnackBar();
  messenger.showSnackBar(
    SnackBar(
      content: Text(
        message,
        style: context.ds.typography.bodySm,
      ),
      duration: duration,
      action: actionLabel != null && onAction != null
          ? SnackBarAction(
              label: actionLabel,
              onPressed: onAction,
            )
          : null,
    ),
  );
}
