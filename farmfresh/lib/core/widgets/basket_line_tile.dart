import 'package:flutter/material.dart';

import '../theme/theme_ext.dart';

/// A "Name · qty ............ ₹price" row with a dashed divider (`.kitem`).
class BasketLineTile extends StatelessWidget {
  const BasketLineTile({
    super.key,
    required this.title,
    required this.trailing,
    this.showDivider = true,
    this.onRemove,
  });

  final String title;
  final String trailing;
  final bool showDivider;
  final VoidCallback? onRemove;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 9),
      decoration: BoxDecoration(
        border: showDivider
            ? Border(bottom: BorderSide(color: c.line))
            : const Border(),
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(title, style: const TextStyle(fontSize: 13)),
          ),
          Text(
            trailing,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: c.green,
            ),
          ),
          if (onRemove != null)
            IconButton(
              onPressed: onRemove,
              visualDensity: VisualDensity.compact,
              icon: Icon(Icons.close, size: 16, color: c.muted),
            ),
        ],
      ),
    );
  }
}
