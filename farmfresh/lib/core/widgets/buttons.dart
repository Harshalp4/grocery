import 'package:flutter/material.dart';

import '../theme/dimens.dart';
import '../theme/theme_ext.dart';

/// Full-width gold call-to-action button (`.btn-gold`).
class GoldButton extends StatelessWidget {
  const GoldButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.icon,
  });

  final String label;
  final VoidCallback? onPressed;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return SizedBox(
      height: 50,
      width: double.infinity,
      child: ElevatedButton.icon(
        onPressed: onPressed,
        icon: icon == null ? const SizedBox.shrink() : Icon(icon, size: 18),
        label: Text(label),
        style: ElevatedButton.styleFrom(
          backgroundColor: c.gold,
          foregroundColor: const Color(0xFF231D0C),
          elevation: 0,
          shape: const RoundedRectangleBorder(borderRadius: AppRadius.pillAll),
          textStyle: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15),
        ),
      ),
    );
  }
}

/// Soft green "ghost" button (`.btn-ghost`) — tinted background, green text.
class GhostButton extends StatelessWidget {
  const GhostButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.expand = true,
  });

  final String label;
  final VoidCallback? onPressed;
  final bool expand;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final button = TextButton(
      onPressed: onPressed,
      style: TextButton.styleFrom(
        backgroundColor: c.greenSoft,
        foregroundColor: c.green,
        minimumSize: const Size.fromHeight(46),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        shape: const RoundedRectangleBorder(borderRadius: AppRadius.pillAll),
        textStyle: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
      ),
      child: Text(label),
    );
    return expand ? SizedBox(width: double.infinity, child: button) : button;
  }
}
