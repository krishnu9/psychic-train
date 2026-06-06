import 'package:flutter/material.dart';

import '../extensions/context_extensions.dart';

/// Typography-aware text widget.
///
/// Use instead of raw [Text] with inline [TextStyle].
/// Set [uppercase] for mono eyebrow labels (DESIGN.md caption-mono).
class AppText extends StatelessWidget {
  const AppText(
    this.data, {
    super.key,
    required this.style,
    this.uppercase = false,
    this.color,
    this.textAlign,
    this.maxLines,
    this.overflow,
  });

  final String data;
  final TextStyle style;
  final bool uppercase;
  final Color? color;
  final TextAlign? textAlign;
  final int? maxLines;
  final TextOverflow? overflow;

  @override
  Widget build(BuildContext context) {
    final resolved = context.ds.typography.resolved(context, style);
    final display = uppercase ? data.toUpperCase() : data;

    return Text(
      display,
      style: color != null ? resolved.copyWith(color: color) : resolved,
      textAlign: textAlign,
      maxLines: maxLines,
      overflow: overflow,
    );
  }
}
