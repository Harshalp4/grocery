import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/dimens.dart';
import '../../../../core/theme/theme_ext.dart';

/// The 2×2 quick-action grid: Auto Kirana, Combo Packs, Repeat, Subscriptions.
class QuickActions extends StatelessWidget {
  const QuickActions({super.key});

  @override
  Widget build(BuildContext context) {
    final actions = <_QA>[
      _QA(Icons.receipt_long_outlined, 'Auto Kirana List',
          () => context.go('/kirana')),
      _QA(Icons.inventory_2_outlined, 'Combo Packs',
          () => context.go('/home/combos')),
      _QA(Icons.autorenew, 'Repeat Last Month',
          () => context.go('/home/repeat')),
      _QA(Icons.subscriptions_outlined, 'Subscriptions',
          () => context.go('/home/subscriptions')),
    ];
    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: 2,
      mainAxisSpacing: 10,
      crossAxisSpacing: 10,
      childAspectRatio: 3.2,
      children: [
        for (final a in actions)
          _QuickActionTile(action: a),
      ],
    );
  }
}

class _QA {
  const _QA(this.icon, this.label, this.onTap);
  final IconData icon;
  final String label;
  final VoidCallback onTap;
}

class _QuickActionTile extends StatelessWidget {
  const _QuickActionTile({required this.action});
  final _QA action;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return InkWell(
      onTap: action.onTap,
      borderRadius: AppRadius.smAll,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12),
        decoration: BoxDecoration(
          color: c.beige,
          borderRadius: AppRadius.smAll,
          border: Border.all(color: c.beigeDeep),
        ),
        child: Row(
          children: [
            Icon(action.icon, size: 22, color: c.green),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                action.label,
                style: const TextStyle(
                    fontSize: 12.5, fontWeight: FontWeight.w700, height: 1.2),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
