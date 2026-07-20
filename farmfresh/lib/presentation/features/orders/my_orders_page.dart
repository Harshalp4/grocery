import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/dimens.dart';
import '../../../core/theme/theme_ext.dart';
import '../../../core/widgets/app_card.dart';
import '../../../core/widgets/app_tag.dart';
import '../../../domain/entities/customer_order.dart';
import '../../providers/auth_controller.dart';
import '../../providers/repository_providers.dart';

/// My Orders — the signed-in user's order history (GET /auth/orders).
class MyOrdersPage extends ConsumerWidget {
  const MyOrdersPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = context.colors;
    final signedIn = ref.watch(authControllerProvider).isAuthenticated;

    if (!signedIn) {
      return Scaffold(
        appBar: AppBar(title: const Text('My Orders')),
        body: _CenteredMessage(
          icon: Icons.lock_outline,
          text: 'Sign in to see your orders',
          action: FilledButton(
            onPressed: () => context.go('/login'),
            child: const Text('Sign in'),
          ),
        ),
      );
    }

    final orders = ref.watch(myOrdersProvider);
    return Scaffold(
      appBar: AppBar(title: const Text('My Orders')),
      body: RefreshIndicator(
        onRefresh: () async {
          ref.invalidate(myOrdersProvider);
          await ref.read(myOrdersProvider.future);
        },
        color: c.green,
        child: orders.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (e, _) => const _CenteredMessage(
            icon: Icons.error_outline,
            text: 'Could not load orders',
          ),
          data: (list) {
            if (list.isEmpty) {
              return _CenteredMessage(
                icon: Icons.receipt_long_outlined,
                text: 'No orders yet',
                action: FilledButton(
                  onPressed: () => context.go('/home'),
                  child: const Text('Start shopping'),
                ),
              );
            }
            return ListView.separated(
              padding: AppSpacing.page,
              physics: const AlwaysScrollableScrollPhysics(),
              itemCount: list.length,
              separatorBuilder: (_, __) => const SizedBox(height: 12),
              itemBuilder: (_, i) => _OrderCard(
                order: list[i],
                onTap: () => context.go('/profile/orders/${list[i].id}'),
              ),
            );
          },
        ),
      ),
    );
  }
}

class _OrderCard extends StatelessWidget {
  const _OrderCard({required this.order, required this.onTap});
  final CustomerOrder order;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final delivered = order.status == 'delivered';
    final cancelled = order.status == 'cancelled';
    return AppCard(
      onTap: onTap,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(order.code,
                  style: const TextStyle(
                      fontSize: 14, fontWeight: FontWeight.w800)),
              AppTag(
                order.statusLabel,
                variant: delivered
                    ? TagVariant.green
                    : cancelled
                        ? TagVariant.save
                        : TagVariant.gold,
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text('${order.items.length} items · ${order.slot}',
              style: TextStyle(fontSize: 12, color: c.muted)),
          const SizedBox(height: 8),
          Text(
            order.items.map((i) => i.name).take(4).join(', '),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(fontSize: 12.5, color: c.muted),
          ),
          const Divider(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '${order.paymentMethod.toUpperCase()} · '
                '${order.paymentStatus == 'paid' ? 'Paid' : 'Pay on delivery'}',
                style: TextStyle(fontSize: 11.5, color: c.muted),
              ),
              Text('₹${order.total}',
                  style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w800,
                      color: c.green)),
            ],
          ),
        ],
      ),
    );
  }
}

class _CenteredMessage extends StatelessWidget {
  const _CenteredMessage({required this.icon, required this.text, this.action});
  final IconData icon;
  final String text;
  final Widget? action;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return ListView(
      // ListView so RefreshIndicator/pull works even when empty.
      physics: const AlwaysScrollableScrollPhysics(),
      children: [
        SizedBox(height: MediaQuery.of(context).size.height * 0.3),
        Icon(icon, size: 56, color: c.muted),
        const SizedBox(height: 12),
        Center(child: Text(text, style: context.text.titleMedium)),
        if (action != null) ...[
          const SizedBox(height: 16),
          Center(child: action!),
        ],
      ],
    );
  }
}
