import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../core/theme.dart';
import '../providers.dart';

class ProfilePage extends ConsumerWidget {
  const ProfilePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final partner = ref.watch(authControllerProvider).partner;
    final muted = Theme.of(context).colorScheme.onSurfaceVariant;
    if (partner == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Profile')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 26,
                    backgroundColor: riderBlue.withValues(alpha: 0.15),
                    child: const Icon(Icons.person, color: riderBlue),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(partner.name,
                            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800)),
                        Text('+91 ${partner.phone}', style: TextStyle(color: muted)),
                        if (partner.vehicleType != null)
                          Text(
                              '${partner.vehicleType}'
                              '${partner.vehicleNumber != null ? ' · ${partner.vehicleNumber}' : ''}',
                              style: TextStyle(fontSize: 12, color: muted)),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),
          Card(
            child: SwitchListTile(
              value: partner.onDuty,
              onChanged: (v) => ref.read(authControllerProvider.notifier).setDuty(v),
              title: const Text('On duty'),
              subtitle: Text(partner.onDuty
                  ? 'Receiving new orders'
                  : 'Not receiving new orders'),
            ),
          ),
          const SizedBox(height: 12),
          Card(
            child: Column(
              children: [
                ListTile(
                  leading: const Icon(Icons.lock_outline),
                  title: const Text('Change password'),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () => context.push('/set-password'),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          OutlinedButton.icon(
            style: OutlinedButton.styleFrom(
                foregroundColor: riderRed, minimumSize: const Size.fromHeight(48)),
            icon: const Icon(Icons.logout),
            label: const Text('Log out'),
            onPressed: () async {
              await ref.read(authControllerProvider.notifier).logout();
              if (context.mounted) context.go('/login');
            },
          ),
          const SizedBox(height: 14),
          Center(
            child: Text('FarmFresh Partner · v0.1.0',
                style: TextStyle(fontSize: 11, color: muted)),
          ),
        ],
      ),
    );
  }
}
