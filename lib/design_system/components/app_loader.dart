import 'package:flutter/material.dart';

import '../extensions/context_extensions.dart';
import '../tokens/spacing.dart';
import 'app_text.dart';

/// Branded loading indicator — ink-colored, no custom inline colors.
class AppLoader extends StatelessWidget {
  const AppLoader({
    super.key,
    this.message,
    this.size = AppLoaderSize.md,
    this.inline = false,
  });

  final String? message;
  final AppLoaderSize size;
  final bool inline;

  double get _dimension => switch (size) {
        AppLoaderSize.sm => 20,
        AppLoaderSize.md => 32,
        AppLoaderSize.lg => 48,
      };

  @override
  Widget build(BuildContext context) {
    final colors = context.ds.colors;
    final typography = context.ds.typography;

    final indicator = SizedBox(
      width: _dimension,
      height: _dimension,
      child: CircularProgressIndicator(
        strokeWidth: size == AppLoaderSize.sm ? 2 : 3,
        color: colors.ink,
      ),
    );

    if (message == null) return indicator;

    final content = Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        indicator,
        const SizedBox(height: AppSpacing.md),
        AppText(message!, style: typography.bodySmMuted()),
      ],
    );

    if (inline) return content;

    return Center(child: content);
  }
}

enum AppLoaderSize { sm, md, lg }
