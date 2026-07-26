import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../core/theme.dart';
import '../domain/models.dart';
import '../providers.dart';

class OrdersPage extends ConsumerStatefulWidget {
  const OrdersPage({super.key});

  @override
  ConsumerState<OrdersPage> createState() => _OrdersPageState();
}

class _OrdersPageState extends ConsumerState<OrdersPage> {
  Timer? _poll;

  @override
  void initState() {
    super.initState();
    _poll = Timer.periodic(const Duration(seconds: 30),
        (_) => ref.invalidate(ordersProvider('active')));
  }

  @override
  void dispose() {
    _poll?.cancel();
    super.dispose();
  }

  void _toggleDuty(bool v) {
    ref.read(authControllerProvider.notifier).setDuty(v);
  }

  @override
  Widget build(BuildContext context) {
    final onDuty = ref.watch(authControllerProvider).partner?.onDuty ?? false;
    final async = ref.watch(ordersProvider('active'));

    return Scaffold(
      appBar: AppBar(
        title: const Text('My deliveries'),
        actions: [
          Text(onDuty ? 'On duty' : 'Off duty',
              style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: onDuty ? riderGreen : Theme.of(context).colorScheme.onSurfaceVariant)),
          Switch(value: onDuty, onChanged: _toggleDuty),
          const SizedBox(width: 6),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          ref.invalidate(ordersProvider('active'));
          await ref.read(ordersProvider('active').future);
        },
        child: async.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (e, _) => ListView(children: [
            const SizedBox(height: 120),
            Center(child: Text('Could not load: $e')),
          ]),
          data: (list) {
            final pickup = list.where((o) => o.status == 'packed').toList();
            final transit = list
                .where((o) => o.status == 'picked_up' || o.status == 'out_for_delivery')
                .toList();
            final retry = list.where((o) => o.status == 'failed').toList();
            return ListView(
              padding: const EdgeInsets.all(14),
              physics: const AlwaysScrollableScrollPhysics(),
              children: [
                if (!onDuty)
                  Card(
                    color: riderGold.withValues(alpha: 0.12),
                    child: const Padding(
                      padding: EdgeInsets.all(12),
                      child: Text(
                          "You're off duty — go on duty to receive new orders.",
                          style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w600)),
                    ),
                  ),
                if (list.isEmpty)
                  const Padding(
                    padding: EdgeInsets.only(top: 100),
                    child: Center(child: Text('No active deliveries right now.')),
                  ),
                _Section(title: 'To pick up', orders: pickup),
                _Section(title: 'In transit', orders: transit),
                _Section(title: 'Retry', orders: retry),
              ],
            );
          },
        ),
      ),
    );
  }
}

class _Section extends StatelessWidget {
  const _Section({required this.title, required this.orders});
  final String title;
  final List<DeliveryOrder> orders;

  @override
  Widget build(BuildContext context) {
    if (orders.isEmpty) return const SizedBox.shrink();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(4, 14, 4, 6),
          child: Text('$title · ${orders.length}',
              style: const TextStyle(
                  fontSize: 12, fontWeight: FontWeight.w700, letterSpacing: 0.4)),
        ),
        for (final o in orders) _OrderCard(order: o),
      ],
    );
  }
}

class _OrderCard extends StatelessWidget {
  const _OrderCard({required this.order});
  final DeliveryOrder order;

  @override
  Widget build(BuildContext context) {
    final muted = Theme.of(context).colorScheme.onSurfaceVariant;
    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () => context.push('/orders/${order.id}'),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Text(order.code,
                      style: const TextStyle(fontWeight: FontWeight.w800)),
                  const Spacer(),
                  if (order.isCod && order.codToCollect > 0)
                    _Pill('Collect ₹${order.codToCollect}', riderGold),
                ],
              ),
              const SizedBox(height: 4),
              Text('${order.customerName} · ${order.itemCount} item(s)',
                  style: TextStyle(fontSize: 12.5, color: muted)),
              const SizedBox(height: 2),
              Text(order.address,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(fontSize: 12.5, color: muted)),
            ],
          ),
        ),
      ),
    );
  }
}

class _Pill extends StatelessWidget {
  const _Pill(this.text, this.color);
  final String text;
  final Color color;

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 3),
        decoration: BoxDecoration(
            color: color.withValues(alpha: 0.15),
            borderRadius: BorderRadius.circular(999)),
        child: Text(text,
            style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: color)),
      );
}
