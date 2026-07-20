import 'package:flutter/material.dart';

import '../theme/theme_ext.dart';

enum TagVariant { gold, green, save }

/// Small rounded label, e.g. "Premium Grade A", "Auto-generated", "Save ~19%".
/// Mirrors `.tag` / `.tag-gold` / `.tag-green` / `.tag-save`.
class AppTag extends StatelessWidget {
  const AppTag(this.label, {super.key, this.variant = TagVariant.green});

  final String label;
  final TagVariant variant;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    late final Color bg;
    late final Color fg;
    switch (variant) {
      case TagVariant.gold:
        bg = c.goldSoft;
        fg = context.isDark ? const Color(0xFFE8C779) : const Color(0xFF8A6A16);
      case TagVariant.green:
        bg = c.greenSoft;
        fg = c.green;
      case TagVariant.save:
        bg = c.tagSaveBg;
        fg = c.tagSaveFg;
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 10.5,
          fontWeight: FontWeight.w700,
          color: fg,
          letterSpacing: 0.3,
        ),
      ),
    );
  }
}
