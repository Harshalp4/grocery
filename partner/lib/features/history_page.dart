import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/theme.dart';
import '../providers.dart';

class HistoryPage extends ConsumerWidget {
  const HistoryPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final summary = ref.watch(summaryProvider);
    final history = ref.watch(ordersProvider('history'));
    final muted = Theme.of(context).colorScheme.onSurfaceVariant;

    return Scaffold(
      appBar: AppBar(title: const Text('History')),
      body: RefreshIndicator(
        onRefresh: () async {
          ref.invalidate(summaryProvider);
          ref.invalidate(ordersProvider('history'));
          await ref.read(ordersProvider('history').future);
        },
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            summary.when(
              loading: () => const SizedBox(
                  height: 90, child: Center(child: CircularProgressIndicator())),
              error: (e, _) => const SizedBox.shrink(),
              data: (s) => Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: [
                      _Stat(label: 'Delivered', value: '${s.delivered}', color: riderGreen),
                      _Stat(label: 'Failed', value: '${s.failed}', color: riderRed),
                      _Stat(label: 'COD ₹', value: '${s.codCollected}', color: riderGold),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(height: 14),
            const Padding(
              padding: EdgeInsets.only(left: 4, bottom: 6),
              child: Text('Recent', style: TextStyle(fontWeight: FontWeight.w700)),
            ),
            history.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, _) => Text('Could not load: $e'),
              data: (list) => list.isEmpty
                  ? Padding(
                      padding: const EdgeInsets.only(top: 40),
                      child: Center(
                          child: Text('No deliveries yet.', style: TextStyle(color: muted))),
                    )
                  : Column(
                      children: [
                        for (final o in list)
                          Card(
                            margin: const EdgeInsets.only(bottom: 8),
                            child: ListTile(
                              title: Text(o.code,
                                  style: const TextStyle(fontWeight: FontWeight.w700)),
                              subtitle: Text('${o.customerName} · ${o.address}',
                                  maxLines: 1, overflow: TextOverflow.ellipsis),
                              trailing: Text(
                                o.status == 'delivered' ? 'Delivered' : 'Failed',
                                style: TextStyle(
                                    color: o.status == 'delivered' ? riderGreen : riderRed,
                                    fontWeight: FontWeight.w700,
                                    fontSize: 12),
                              ),
                            ),
                          ),
                      ],
                    ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Stat extends StatelessWidget {
  const _Stat({required this.label, required this.value, required this.color});
  final String label;
  final String value;
  final Color color;

  @override
  Widget build(BuildContext context) => Expanded(
        child: Column(
          children: [
            Text(value,
                style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800, color: color)),
            const SizedBox(height: 2),
            Text(label,
                style: TextStyle(
                    fontSize: 11, color: Theme.of(context).colorScheme.onSurfaceVariant)),
          ],
        ),
      );
}
