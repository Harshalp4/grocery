import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/theme_ext.dart';
import '../../providers/cart_controller.dart';

/// Hosts the 6 bottom-nav tabs. Uses the go_router [StatefulNavigationShell]
/// so each tab preserves its own navigation stack (best practice for tabbed
/// apps). The Cart tab shows a live badge from [cartCountProvider].
class MainShell extends StatelessWidget {
  const MainShell({super.key, required this.shell});

  final StatefulNavigationShell shell;

  // Only these branches appear in the bottom bar. Kirana (branch 2) and AI
  // (branch 3) still exist as routes (Auto Kirana is opened from the Home
  // quick action) but are intentionally hidden from navigation.
  static const _tabs = <_TabSpec>[
    _TabSpec(Icons.home_rounded, 'Home', 0),
    _TabSpec(Icons.grid_view_rounded, 'Categories', 1),
    _TabSpec(Icons.shopping_cart_rounded, 'Cart', 4),
    _TabSpec(Icons.person_rounded, 'Profile', 5),
  ];

  void _onTap(int branchIndex) {
    // Tapping the active tab pops it back to its root.
    shell.goBranch(branchIndex, initialLocation: branchIndex == shell.currentIndex);
  }

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Scaffold(
      body: shell,
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: c.surface,
          border: Border(top: BorderSide(color: c.line)),
          boxShadow: [
            BoxShadow(
              color: c.green.withValues(alpha: context.isDark ? 0.2 : 0.06),
              blurRadius: 18,
              offset: const Offset(0, -6),
            ),
          ],
        ),
        child: SafeArea(
          top: false,
          child: SizedBox(
            height: 64,
            child: Row(
              children: [
                for (final tab in _tabs)
                  Expanded(
                    child: _NavItem(
                      spec: tab,
                      active: shell.currentIndex == tab.branchIndex,
                      isCart: tab.branchIndex == 4,
                      onTap: () => _onTap(tab.branchIndex),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _TabSpec {
  const _TabSpec(this.icon, this.label, this.branchIndex);
  final IconData icon;
  final String label;
  final int branchIndex;
}

class _NavItem extends ConsumerWidget {
  const _NavItem({
    required this.spec,
    required this.active,
    required this.isCart,
    required this.onTap,
  });

  final _TabSpec spec;
  final bool active;
  final bool isCart;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = context.colors;
    final color = active ? c.green : c.muted;
    final count = isCart ? ref.watch(cartCountProvider) : 0;
    return InkWell(
      onTap: onTap,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Badge(
            isLabelVisible: isCart && count > 0,
            label: Text('$count'),
            backgroundColor: c.gold,
            textColor: const Color(0xFF231D0C),
            child: Icon(spec.icon, size: 22, color: color),
          ),
          const SizedBox(height: 3),
          Text(
            spec.label,
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w600,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}
