import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/dimens.dart';
import '../../../core/theme/theme_ext.dart';
import '../../../core/widgets/app_card.dart';
import '../../../domain/entities/app_notification.dart';
import '../../providers/repository_providers.dart';

/// The customer's notification inbox (order updates + promos).
class NotificationsPage extends ConsumerWidget {
  const NotificationsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = context.colors;
    final async = ref.watch(notificationsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Notifications'),
        actions: [
          TextButton(
            onPressed: () async {
              await ref.read(notificationRepositoryProvider).markAllRead();
              ref.invalidate(notificationsProvider);
              ref.invalidate(unreadCountProvider);
            },
            child: const Text('Mark all read'),
          ),
        ],
      ),
      body: RefreshIndicator(
        color: c.green,
        onRefresh: () async {
          ref.invalidate(notificationsProvider);
          await ref.read(notificationsProvider.future);
        },
        child: async.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (e, _) => ListView(
            children: [
              const SizedBox(height: 120),
              Center(child: Text('Could not load: $e')),
            ],
          ),
          data: (list) => list.isEmpty
              ? ListView(
                  children: [
                    const SizedBox(height: 140),
                    Icon(Icons.notifications_off_outlined,
                        size: 48, color: c.muted),
                    const SizedBox(height: 10),
                    Center(
                        child: Text('No notifications yet',
                            style: TextStyle(color: c.muted))),
                  ],
                )
              : ListView.separated(
                  padding: AppSpacing.page,
                  physics: const AlwaysScrollableScrollPhysics(),
                  itemCount: list.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 8),
                  itemBuilder: (_, i) => _NotifTile(n: list[i]),
                ),
        ),
      ),
    );
  }
}

class _NotifTile extends StatelessWidget {
  const _NotifTile({required this.n});
  final AppNotification n;

  IconData get _icon => switch (n.type) {
        'order' => Icons.local_shipping_outlined,
        'promo' => Icons.local_offer_outlined,
        _ => Icons.notifications_outlined,
      };

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return AppCard(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(_icon, color: n.read ? c.muted : c.green),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(n.title,
                    style: TextStyle(
                        fontWeight:
                            n.read ? FontWeight.w600 : FontWeight.w800)),
                const SizedBox(height: 2),
                Text(n.body,
                    style: TextStyle(fontSize: 12.5, color: c.muted)),
              ],
            ),
          ),
          if (!n.read)
            Container(
              margin: const EdgeInsets.only(top: 4, left: 6),
              width: 8,
              height: 8,
              decoration: BoxDecoration(color: c.gold, shape: BoxShape.circle),
            ),
        ],
      ),
    );
  }
}
