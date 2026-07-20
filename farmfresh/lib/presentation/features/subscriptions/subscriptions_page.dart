import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/dimens.dart';
import '../../../core/theme/theme_ext.dart';
import '../../../core/widgets/app_card.dart';
import '../../../core/widgets/app_tag.dart';
import '../../providers/repository_providers.dart';

/// Screen 10 — Subscriptions. Benefits grid + selectable monthly plans.
class SubscriptionsPage extends ConsumerWidget {
  const SubscriptionsPage({super.key});

  static const _benefits = <(IconData, String)>[
    (Icons.autorenew, 'Auto monthly delivery'),
    (Icons.edit_outlined, 'Editable cart'),
    (Icons.pause_circle_outline, 'Pause anytime'),
    (Icons.savings_outlined, 'Extra savings'),
  ];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = context.colors;
    final plans = ref.watch(subscriptionsProvider);
    return Scaffold(
      appBar: AppBar(title: const Text('Subscriptions')),
      body: RefreshIndicator(
        onRefresh: () async {
          ref.invalidate(subscriptionsProvider);
          await ref.read(subscriptionsProvider.future);
        },
        color: c.green,
        child: ListView(
        padding: AppSpacing.page,
        physics: const AlwaysScrollableScrollPhysics(),
        children: [
          Text('Set it once. Your groceries arrive every month.',
              style: TextStyle(fontSize: 13, color: c.muted)),
          const SizedBox(height: 12),
          GridView.count(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisCount: 2,
            mainAxisSpacing: 10,
            crossAxisSpacing: 10,
            childAspectRatio: 3.4,
            children: [
              for (final b in _benefits)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  decoration: BoxDecoration(
                    color: c.greenSoft,
                    borderRadius: AppRadius.smAll,
                  ),
                  child: Row(
                    children: [
                      Icon(b.$1, size: 22, color: c.green),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(b.$2,
                            style: const TextStyle(
                                fontSize: 12, fontWeight: FontWeight.w600)),
                      ),
                    ],
                  ),
                ),
            ],
          ),
          const SizedBox(height: 14),
          plans.when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (e, _) => Text('Failed to load: $e'),
            data: (list) => Column(
              children: [
                for (final plan in list)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: AppCard(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Expanded(
                                child: Text(plan.name,
                                    style: const TextStyle(
                                        fontSize: 15,
                                        fontWeight: FontWeight.w700)),
                              ),
                              AppTag(plan.priceLabel, variant: TagVariant.gold),
                            ],
                          ),
                          const SizedBox(height: 6),
                          Text(plan.description,
                              style: TextStyle(fontSize: 12.5, color: c.muted)),
                          const SizedBox(height: 10),
                          SizedBox(
                            width: double.infinity,
                            child: ElevatedButton(
                              onPressed: () => ScaffoldMessenger.of(context)
                                  .showSnackBar(SnackBar(
                                      content: Text(
                                          'Subscribed to ${plan.name} (placeholder)'),
                                      duration:
                                          const Duration(milliseconds: 900))),
                              style: ElevatedButton.styleFrom(
                                  minimumSize: const Size.fromHeight(42)),
                              child: const Text('Choose Plan'),
                            ),
                          ),
                        ],
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
