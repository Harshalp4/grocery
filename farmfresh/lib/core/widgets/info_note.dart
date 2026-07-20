import 'package:flutter/material.dart';

import '../theme/theme_ext.dart';

/// Dashed gold "placeholder / review" banner (`.banner-note`).
class InfoNote extends StatelessWidget {
  const InfoNote(this.text, {super.key, this.center = true});

  final String text;
  final bool center;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: c.goldSoft,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: c.gold, style: BorderStyle.solid),
      ),
      child: Text(
        text,
        textAlign: center ? TextAlign.center : TextAlign.start,
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w600,
          color: context.isDark ? const Color(0xFFE8C779) : const Color(0xFF7A5D12),
        ),
      ),
    );
  }
}
