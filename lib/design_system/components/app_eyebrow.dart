import 'package:flutter/material.dart';

import '../extensions/context_extensions.dart';
import 'app_text.dart';

/// Uppercase tracked mono label — DESIGN.md eyebrow-mono signature.
///
/// Pair with display headlines in content bands.
class AppEyebrow extends StatelessWidget {
  const AppEyebrow(this.label, {super.key});

  final String label;

  @override
  Widget build(BuildContext context) {
    return AppText(
      label,
      style: context.ds.typography.captionMono,
      uppercase: true,
    );
  }
}
