import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/dimens.dart';
import '../../../core/theme/theme_ext.dart';
import '../../../core/widgets/app_card.dart';
import '../../../core/widgets/app_tag.dart';
import '../../../core/widgets/basket_line_tile.dart';
import '../../../domain/entities/customer_order.dart';
import '../../providers/repository_providers.dart';

/// Order detail with the tracking timeline, delivery partner, and
/// cancel / report-issue actions.
class OrderDetailPage extends ConsumerWidget {
  const OrderDetailPage({super.key, required this.orderId});
  final String orderId;

  static const _flow = [
    'placed',
    'confirmed',
    'packed',
    'out_for_delivery',
    'delivered',
  ];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = context.colors;
    final async = ref.watch(orderDetailProvider(orderId));

    return Scaffold(
      appBar: AppBar(title: const Text('Order details')),
      body: async.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Could not load: $e')),
        data: (o) => RefreshIndicator(
          color: c.green,
          onRefresh: () async {
            ref.invalidate(orderDetailProvider(orderId));
            await ref.read(orderDetailProvider(orderId).future);
          },
          child: ListView(
            padding: AppSpacing.page,
            physics: const AlwaysScrollableScrollPhysics(),
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(o.code,
                      style: const TextStyle(
                          fontSize: 16, fontWeight: FontWeight.w800)),
                  AppTag(o.statusLabel,
                      variant: o.status == 'delivered'
                          ? TagVariant.green
                          : o.status == 'cancelled'
                              ? TagVariant.save
                              : TagVariant.gold),
                ],
              ),
              if (o.eta != null && o.status != 'cancelled') ...[
                const SizedBox(height: 4),
                Text(o.eta!, style: TextStyle(fontSize: 13, color: c.muted)),
              ],
              const SizedBox(height: 16),

              // Timeline
              if (o.status != 'cancelled')
                AppCard(child: _Timeline(order: o))
              else
                AppCard(
                  child: Row(
                    children: [
                      const Icon(Icons.cancel, color: Colors.red),
                      const SizedBox(width: 10),
                      Text('Order cancelled',
                          style: TextStyle(
                              fontWeight: FontWeight.w600, color: c.ink)),
                    ],
                  ),
                ),

              if (o.partnerName != null) ...[
                const SizedBox(height: 12),
                AppCard(
                  child: Row(
                    children: [
                      Icon(Icons.delivery_dining, color: c.green),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Delivery partner',
                                style: TextStyle(
                                    fontSize: 11, color: c.muted)),
                            Text(o.partnerName!,
                                style: const TextStyle(
                                    fontWeight: FontWeight.w700)),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ],

              const SizedBox(height: 16),
              Text('Items', style: context.text.titleSmall),
              const SizedBox(height: 6),
              AppCard(
                child: Column(
                  children: [
                    for (var i = 0; i < o.items.length; i++)
                      BasketLineTile(
                        title: '${o.items[i].name} · ${o.items[i].quantity}',
                        trailing: o.items[i].priceLabel,
                        showDivider: i != o.items.length - 1,
                      ),
                    const Divider(height: 18),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('Total',
                            style: TextStyle(fontWeight: FontWeight.w800)),
                        Text('₹${o.total}',
                            style: TextStyle(
                                fontWeight: FontWeight.w800, color: c.green)),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        '${o.paymentMethod.toUpperCase()} · '
                        '${o.paymentStatus == 'paid' ? 'Paid' : o.paymentStatus == 'refunded' ? 'Refunded' : 'Pay on delivery'}',
                        style: TextStyle(fontSize: 11.5, color: c.muted),
                      ),
                    ),
                  ],
                ),
              ),

              if (o.returnStatus != null) ...[
                const SizedBox(height: 12),
                AppCard(
                  child: Row(
                    children: [
                      Icon(Icons.assignment_return, color: c.gold),
                      const SizedBox(width: 10),
                      Text('Return: ${o.returnStatus}',
                          style: const TextStyle(fontWeight: FontWeight.w600)),
                    ],
                  ),
                ),
              ],

              const SizedBox(height: 20),
              if (o.isCancellable)
                OutlinedButton.icon(
                  onPressed: () => _cancel(context, ref, o),
                  style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.red,
                      side: const BorderSide(color: Colors.red)),
                  icon: const Icon(Icons.close),
                  label: const Text('Cancel order'),
                ),
              if (o.canReport)
                OutlinedButton.icon(
                  onPressed: () => _report(context, ref, o),
                  icon: const Icon(Icons.report_gmailerrorred_outlined),
                  label: const Text('Report an issue'),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _cancel(
      BuildContext context, WidgetRef ref, CustomerOrder o) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Cancel this order?'),
        content: Text('${o.code} will be cancelled.'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Keep')),
          TextButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Cancel order')),
        ],
      ),
    );
    if (ok != true) return;
    try {
      await ref.read(orderRepositoryProvider).cancelOrder(o.id);
      ref.invalidate(orderDetailProvider(orderId));
      ref.invalidate(myOrdersProvider);
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('$e')));
      }
    }
  }

  Future<void> _report(
      BuildContext context, WidgetRef ref, CustomerOrder o) async {
    final ctl = TextEditingController();
    final reason = await showDialog<String>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Report an issue'),
        content: TextField(
          controller: ctl,
          maxLines: 3,
          decoration: const InputDecoration(
              hintText: 'What went wrong? (e.g. item missing/damaged)'),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel')),
          TextButton(
              onPressed: () => Navigator.pop(context, ctl.text.trim()),
              child: const Text('Submit')),
        ],
      ),
    );
    if (reason == null || reason.length < 3) return;
    try {
      await ref.read(orderRepositoryProvider).requestReturn(o.id, reason);
      ref.invalidate(orderDetailProvider(orderId));
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Issue reported — we\'ll be in touch')));
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('$e')));
      }
    }
  }
}

class _Timeline extends StatelessWidget {
  const _Timeline({required this.order});
  final CustomerOrder order;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final reached = {for (final e in order.events) e.status};
    return Column(
      children: [
        for (var i = 0; i < OrderDetailPage._flow.length; i++)
          _step(
            context,
            label: orderStatusLabel(OrderDetailPage._flow[i]),
            done: reached.contains(OrderDetailPage._flow[i]),
            current: order.status == OrderDetailPage._flow[i],
            last: i == OrderDetailPage._flow.length - 1,
            green: c.green,
            muted: c.muted,
            line: c.line,
          ),
      ],
    );
  }

  Widget _step(BuildContext context,
      {required String label,
      required bool done,
      required bool current,
      required bool last,
      required Color green,
      required Color muted,
      required Color line}) {
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Column(
            children: [
              Icon(
                done ? Icons.check_circle : Icons.radio_button_unchecked,
                size: 20,
                color: done ? green : line,
              ),
              if (!last)
                Expanded(
                  child: Container(
                    width: 2,
                    color: done ? green : line,
                  ),
                ),
            ],
          ),
          const SizedBox(width: 12),
          Padding(
            padding: EdgeInsets.only(bottom: last ? 0 : 16, top: 1),
            child: Text(
              label,
              style: TextStyle(
                fontSize: 13.5,
                fontWeight: current ? FontWeight.w800 : FontWeight.w500,
                color: done ? context.colors.ink : muted,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
