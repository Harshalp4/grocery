import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../core/widgets/buttons.dart';

/// Screen 1 — Splash / Welcome. Brand-green gradient, logo, tagline and CTA.
class SplashPage extends StatelessWidget {
  const SplashPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFF2F6B46), Color(0xFF1F4A30)],
          ),
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(28),
            child: Column(
              children: [
                const Spacer(),
                Container(
                  width: 96,
                  height: 96,
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.14),
                    borderRadius: BorderRadius.circular(28),
                  ),
                  alignment: Alignment.center,
                  child: const Icon(Icons.eco, size: 48, color: Colors.white),
                ),
                const SizedBox(height: 18),
                const Text(
                  'FarmFresh',
                  style: TextStyle(
                    fontSize: 26,
                    fontWeight: FontWeight.w800,
                    color: Colors.white,
                    letterSpacing: 0.5,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  '[ brand name = placeholder ]',
                  style: TextStyle(
                    fontSize: 11,
                    color: Colors.white.withValues(alpha: 0.7),
                  ),
                ),
                const SizedBox(height: 14),
                Text(
                  'Farm Fresh Essentials Delivered Home',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 15,
                    color: Colors.white.withValues(alpha: 0.92),
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  'Premium own-label groceries at fair prices — across '
                  'Mumbai, Navi Mumbai & suburbs.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.white.withValues(alpha: 0.75),
                  ),
                ),
                const Spacer(),
                GoldButton(
                  label: 'Get Started  →',
                  onPressed: () => context.go('/login'),
                ),
                const SizedBox(height: 10),
                Text(
                  'Trusted by 50+ families',
                  style: TextStyle(
                    fontSize: 11,
                    color: Colors.white.withValues(alpha: 0.7),
                  ),
                ),
                const SizedBox(height: 8),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
