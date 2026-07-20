import 'package:flutter/material.dart';

import '../../../../core/theme/dimens.dart';
import '../../../../core/theme/theme_ext.dart';

/// The green gradient hero banner with a gold "Shop Now" CTA.
class HomeHero extends StatelessWidget {
  const HomeHero({super.key, required this.onShop});

  final VoidCallback onShop;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        borderRadius: AppRadius.mdAll,
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [c.green, c.greenDark],
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Premium Farm Groceries at Fair Prices',
            style: TextStyle(
              fontSize: 18,
              height: 1.3,
              fontWeight: FontWeight.w700,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Own-label • Direct sourced • Quality checked',
            style: TextStyle(
              fontSize: 12,
              color: Colors.white.withValues(alpha: 0.9),
            ),
          ),
          const SizedBox(height: 12),
          ElevatedButton(
            onPressed: onShop,
            style: ElevatedButton.styleFrom(
              backgroundColor: c.gold,
              foregroundColor: const Color(0xFF231D0C),
              minimumSize: const Size(0, 38),
              padding: const EdgeInsets.symmetric(horizontal: 18),
              textStyle:
                  const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
            ),
            child: const Text('Shop Now'),
          ),
        ],
      ),
    );
  }
}
