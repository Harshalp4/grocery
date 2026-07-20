import 'package:flutter/material.dart';

import '../theme/theme_ext.dart';

/// Standard rounded bottom-sheet container with a grab handle, optional title
/// and subtitle. Matches the wireframe's `.modal` (slides up from the bottom).
class BottomSheetShell extends StatelessWidget {
  const BottomSheetShell({
    super.key,
    required this.child,
    this.title,
    this.subtitle,
  });

  final Widget child;
  final String? title;
  final String? subtitle;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Container(
      decoration: BoxDecoration(
        color: c.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: EdgeInsets.only(
        left: 18,
        right: 18,
        top: 12,
        bottom: MediaQuery.of(context).viewInsets.bottom + 24,
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 42,
                height: 5,
                margin: const EdgeInsets.only(bottom: 14),
                decoration: BoxDecoration(
                  color: c.line,
                  borderRadius: BorderRadius.circular(99),
                ),
              ),
            ),
            if (title != null)
              Text(title!, style: context.text.headlineSmall),
            if (subtitle != null) ...[
              const SizedBox(height: 4),
              Text(subtitle!, style: TextStyle(fontSize: 12, color: c.muted)),
            ],
            const SizedBox(height: 12),
            child,
          ],
        ),
      ),
    );
  }
}
