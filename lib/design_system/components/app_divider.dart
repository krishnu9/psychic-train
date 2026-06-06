import 'package:flutter/material.dart';

import '../extensions/context_extensions.dart';
import '../tokens/borders.dart';

/// Hairline divider — DESIGN.md divider-hairline.
///
/// Use instead of raw [Divider] with inline colors.
class AppDivider extends StatelessWidget {
  const AppDivider({super.key, this.indent, this.endIndent});

  final double? indent;
  final double? endIndent;

  @override
  Widget build(BuildContext context) {
    return Divider(
      color: context.ds.colors.hairline,
      thickness: AppBorders.hairlineWidth,
      height: AppBorders.hairlineWidth,
      indent: indent,
      endIndent: endIndent,
    );
  }
}
