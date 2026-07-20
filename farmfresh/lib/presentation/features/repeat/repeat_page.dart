import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/dimens.dart';
import '../../../core/theme/theme_ext.dart';
import '../../../core/widgets/app_card.dart';
import '../../../core/widgets/basket_line_tile.dart';
import '../../../domain/entities/basket_line.dart';
import '../../providers/cart_controller.dart';
import '../../providers/repository_providers.dart';

/// Loads last month's basket via the kirana repository.
final lastMonthProvider = FutureProvider<List<BasketLine>>(
  (ref) => ref.watch(kiranaRepositoryProvider).lastMonthBasket(),
);

/// Screen 11 — Repeat Last Month. One-tap reorder of the previous basket.
class RepeatPage extends ConsumerWidget {
  const RepeatPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = context.colors;
    final basket = ref.watch(lastMonthProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Repeat Last Month')),
      body: RefreshIndicator(
        onRefresh: () async {
          ref.invalidate(lastMonthProvider);
          await ref.read(lastMonthProvider.future);
        },
        color: c.green,
        child: basket.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Failed to load: $e')),
        data: (lines) {
          final total = lines.fold<int>(0, (s, l) {
            final digits = l.priceLabel.replaceAll(RegExp(r'[^0-9]'), '');
            return s + (digits.isEmpty ? 0 : int.parse(digits));
          });
          return ListView(
            padding: AppSpacing.page,
            physics: const AlwaysScrollableScrollPhysics(),
            children: [
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  borderRadius: AppRadius.mdAll,
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [c.gold, const Color(0xFFB3852F)],
                  ),
                ),
                child: const Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text("Your last month's grocery basket is ready",
                        style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w700,
                            color: Color(0xFF231D0C))),
                    SizedBox(height: 4),
                    Text('Delivered 18 May 2026 · 9 items',
                        style: TextStyle(
                            fontSize: 12, color: Color(0xFF3A2F10))),
                  ],
                ),
              ),
              const SizedBox(height: 14),
              AppCard(
                child: Column(
                  children: [
                    for (var i = 0; i < lines.length; i++)
                      BasketLineTile(
                        title: '${lines[i].name} · ${lines[i].quantity}',
                        trailing: lines[i].priceLabel,
                        showDivider: i != lines.length - 1,
                      ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Last total (approx)',
                      style:
                          TextStyle(fontSize: 15, fontWeight: FontWeight.w800)),
                  Text('₹$total*',
                      style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w800,
                          color: c.green)),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => context.go('/products'),
                      child: const Text('Modify'),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () {
                        ref
                            .read(cartControllerProvider.notifier)
                            .addLines(lines);
                        context.go('/cart');
                      },
                      child: const Text('Reorder'),
                    ),
                  ),
                ],
              ),
            ],
          );
        },
      ),
      ),
    );
  }
}
