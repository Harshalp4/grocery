import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/dimens.dart';
import '../../../core/theme/theme_controller.dart';
import '../../../core/theme/theme_ext.dart';
import '../../../core/widgets/app_card.dart';
import '../../providers/auth_controller.dart';

/// Screen 13 — Profile. Account header, menu rows, theme toggle, log out.
class ProfilePage extends ConsumerWidget {
  const ProfilePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = context.colors;
    final mode = ref.watch(themeControllerProvider);
    final user = ref.watch(authControllerProvider).user;
    final displayName = user?.name?.isNotEmpty == true ? user!.name! : 'Guest';
    final displayPhone =
        user != null ? '+91 ${user.phone}' : 'Not signed in';
    final initials = _initials(displayName);

    final rows = <_Row>[
      _Row(Icons.inventory_2_outlined, 'My Orders', 'Track & reorder',
          () => context.go('/profile/orders')),
      _Row(Icons.subscriptions_outlined, 'My Subscriptions', '2 active plans',
          () => context.go('/home/subscriptions')),
      _Row(Icons.receipt_long_outlined, 'Saved Kirana Lists', '3 saved',
          () => context.go('/kirana')),
      _Row(Icons.location_on_outlined, 'Addresses', 'Manage delivery addresses',
          () => context.go('/profile/addresses')),
      _Row(Icons.card_giftcard_outlined, 'Referrals',
          'Refer a family, earn rewards', () => _toast(context, 'Referrals')),
      _Row(Icons.support_agent_outlined, 'Help & Support', 'WhatsApp / Call',
          () => _toast(context, 'Help & Support')),
    ];

    return Scaffold(
      appBar: AppBar(title: const Text('Profile')),
      body: ListView(
        padding: AppSpacing.page,
        children: [
          AppCard(
            child: Row(
              children: [
                CircleAvatar(
                  radius: 25,
                  backgroundColor: c.goldSoft,
                  child: Text(initials,
                      style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                          color: context.isDark
                              ? const Color(0xFFE8C779)
                              : const Color(0xFF8A6A16))),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(displayName,
                          style: const TextStyle(
                              fontSize: 15, fontWeight: FontWeight.w700)),
                      Text(displayPhone,
                          style: TextStyle(fontSize: 12, color: c.muted)),
                    ],
                  ),
                ),
                if (user != null)
                  IconButton(
                    tooltip: 'Edit name',
                    icon: Icon(Icons.edit_outlined, size: 20, color: c.muted),
                    onPressed: () => _editName(context, ref, user.name ?? ''),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 14),
          AppCard(
            padding: const EdgeInsets.symmetric(horizontal: 14),
            child: Column(
              children: [
                for (var i = 0; i < rows.length; i++)
                  _MenuRow(row: rows[i], last: i == rows.length - 1),
              ],
            ),
          ),
          const SizedBox(height: 14),
          AppCard(
            child: Row(
              children: [
                Icon(mode == ThemeMode.dark ? Icons.dark_mode : Icons.light_mode,
                    color: c.gold),
                const SizedBox(width: 12),
                const Expanded(
                  child: Text('Dark mode',
                      style: TextStyle(
                          fontSize: 14, fontWeight: FontWeight.w600)),
                ),
                Switch(
                  value: mode == ThemeMode.dark,
                  activeThumbColor: c.green,
                  onChanged: (_) =>
                      ref.read(themeControllerProvider.notifier).toggle(),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          OutlinedButton(
            onPressed: () async {
              await ref.read(authControllerProvider.notifier).logout();
              if (context.mounted) context.go('/login');
            },
            child: Text(user == null ? 'Sign in' : 'Log out'),
          ),
        ],
      ),
    );
  }

  Future<void> _editName(
      BuildContext context, WidgetRef ref, String current) async {
    final ctl = TextEditingController(text: current);
    final name = await showDialog<String>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Edit name'),
        content: TextField(
          controller: ctl,
          textCapitalization: TextCapitalization.words,
          decoration: const InputDecoration(hintText: 'Your name'),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel')),
          TextButton(
              onPressed: () => Navigator.pop(context, ctl.text.trim()),
              child: const Text('Save')),
        ],
      ),
    );
    if (name == null || name.isEmpty) return;
    try {
      await ref.read(authControllerProvider.notifier).updateName(name);
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('$e')));
      }
    }
  }

  static String _initials(String name) {
    final parts = name.trim().split(RegExp(r'\s+'));
    if (parts.isEmpty || parts.first.isEmpty) return 'G';
    if (parts.length == 1) {
      return parts.first.substring(0, 1).toUpperCase();
    }
    return (parts[0].substring(0, 1) + parts[1].substring(0, 1)).toUpperCase();
  }

  static void _toast(BuildContext context, String label) =>
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: Text('$label (placeholder)'),
            duration: const Duration(milliseconds: 900)),
      );
}

class _Row {
  const _Row(this.icon, this.title, this.subtitle, this.onTap);
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;
}

class _MenuRow extends StatelessWidget {
  const _MenuRow({required this.row, required this.last});
  final _Row row;
  final bool last;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return InkWell(
      onTap: row.onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 13),
        decoration: BoxDecoration(
          border: last
              ? const Border()
              : Border(bottom: BorderSide(color: c.line)),
        ),
        child: Row(
          children: [
            SizedBox(
              width: 26,
              child: Icon(row.icon, size: 22, color: c.green),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(row.title,
                      style: const TextStyle(
                          fontSize: 14, fontWeight: FontWeight.w600)),
                  Text(row.subtitle,
                      style: TextStyle(fontSize: 11, color: c.muted)),
                ],
              ),
            ),
            Icon(Icons.chevron_right, color: c.muted),
          ],
        ),
      ),
    );
  }
}
