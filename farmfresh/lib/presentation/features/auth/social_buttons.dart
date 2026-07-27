import 'package:flutter/material.dart';

import '../../../core/theme/theme_ext.dart';

/// White "Continue with Google" button with the multicolour G mark.
class GoogleButton extends StatelessWidget {
  const GoogleButton({super.key, this.onPressed});
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return SizedBox(
      height: 48,
      child: OutlinedButton.icon(
        onPressed: onPressed,
        icon: const _GoogleG(),
        label: const Text('Continue with Google'),
        style: OutlinedButton.styleFrom(
          foregroundColor: c.ink,
          backgroundColor: c.surface,
          side: BorderSide(color: c.line),
          textStyle: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700),
          shape: const StadiumBorder(),
        ),
      ),
    );
  }
}

/// Black "Continue with Apple" button with the Apple logo.
class AppleButton extends StatelessWidget {
  const AppleButton({super.key, this.onPressed});
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 48,
      child: FilledButton.icon(
        onPressed: onPressed,
        icon: const Icon(Icons.apple, size: 22, color: Colors.white),
        label: const Text('Continue with Apple'),
        style: FilledButton.styleFrom(
          backgroundColor: Colors.black,
          foregroundColor: Colors.white,
          textStyle: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700),
          shape: const StadiumBorder(),
        ),
      ),
    );
  }
}

/// Simple, dependency-free Google "G" mark — a white chip with the blue G.
/// (Swap for the official multicolour asset before store submission.)
class _GoogleG extends StatelessWidget {
  const _GoogleG();
  @override
  Widget build(BuildContext context) => Container(
        width: 20, height: 20,
        alignment: Alignment.center,
        decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle),
        child: const Text('G',
            style: TextStyle(
                color: Color(0xFF4285F4),
                fontSize: 15,
                fontWeight: FontWeight.w800,
                height: 1.1)),
      );
}
