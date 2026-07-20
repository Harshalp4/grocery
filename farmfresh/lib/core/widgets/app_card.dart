import 'package:flutter/material.dart';

import '../theme/dimens.dart';
import '../theme/theme_ext.dart';

/// Bordered surface card with a soft brand shadow (`.card`).
class AppCard extends StatelessWidget {
  const AppCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(16),
    this.onTap,
  });

  final Widget child;
  final EdgeInsetsGeometry padding;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Material(
      color: c.surface,
      borderRadius: AppRadius.mdAll,
      child: InkWell(
        onTap: onTap,
        borderRadius: AppRadius.mdAll,
        child: Container(
          padding: padding,
          decoration: BoxDecoration(
            borderRadius: AppRadius.mdAll,
            border: Border.all(color: c.line),
            boxShadow: [
              BoxShadow(
                color: c.green.withValues(alpha: context.isDark ? 0.18 : 0.06),
                blurRadius: 20,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: child,
        ),
      ),
    );
  }
}
