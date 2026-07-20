import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/dimens.dart';
import '../../../core/theme/theme_ext.dart';
import '../../../core/widgets/app_card.dart';
import '../../../core/widgets/basket_line_tile.dart';
import '../../../core/widgets/section_header.dart';
import '../../providers/cart_controller.dart';
import '../../providers/repository_providers.dart';
import '../../widgets/product_card.dart';

/// Screen 8 — Cart. Line items, coupon, suggested add-ons, bill summary.
class CartPage extends ConsumerWidget {
  const CartPage({super.key});

  static const _deliveryFreeOver = 999;
  static const _comboSavings = 260;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = context.colors;
    final cart = ref.watch(cartControllerProvider);
    final products = ref.watch(productsProvider);

    final itemTotal = cart.itemTotal;
    final deliveryFee = itemTotal >= _deliveryFreeOver ? 0 : 40;
    final total = itemTotal - _comboSavings + deliveryFee;

    return Scaffold(
      appBar: AppBar(title: const Text('Your Cart')),
      body: cart.lines.isEmpty
          ? _EmptyCart(onShop: () => context.go('/products'))
          : ListView(
              padding: AppSpacing.page,
              children: [
                AppCard(
                  child: Column(
                    children: [
                      for (var i = 0; i < cart.lines.length; i++)
                        BasketLineTile(
                          title:
                              '${cart.lines[i].name} · ${cart.lines[i].quantity}',
                          trailing: cart.lines[i].priceLabel,
                          showDivider: i != cart.lines.length - 1,
                          onRemove: () => ref
                              .read(cartControllerProvider.notifier)
                              .removeAt(i),
                        ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    const Expanded(
                      child: TextField(
                        decoration: InputDecoration(
                            hintText: 'Coupon code (try FRESH50)'),
                      ),
                    ),
                    const SizedBox(width: 8),
                    TextButton(
                      onPressed: () => ScaffoldMessenger.of(context)
                          .showSnackBar(const SnackBar(
                              content: Text('Coupon applied: -₹50 (placeholder)'),
                              duration: Duration(milliseconds: 900))),
                      style: TextButton.styleFrom(
                        backgroundColor: c.greenSoft,
                        foregroundColor: c.green,
                        minimumSize: const Size(0, 48),
                        padding: const EdgeInsets.symmetric(horizontal: 18),
                        shape: const RoundedRectangleBorder(
                            borderRadius: AppRadius.pillAll),
                      ),
                      child: const Text('Apply'),
                    ),
                  ],
                ),
                const SectionHeader('You may also need'),
                products.maybeWhen(
                  data: (list) => SizedBox(
                    height: 244,
                    child: ListView.separated(
                      scrollDirection: Axis.horizontal,
                      itemCount: list.length > 5 ? 3 : 0,
                      separatorBuilder: (_, __) => const SizedBox(width: 12),
                      itemBuilder: (_, i) {
                        final p = list[5 + i];
                        return SizedBox(
                          width: 150,
                          child: ProductCard(
                            product: p,
                            onTap: () =>
                                context.go('/products/detail/${p.id}'),
                          ),
                        );
                      },
                    ),
                  ),
                  orElse: () => const SizedBox.shrink(),
                ),
                const SizedBox(height: 14),
                AppCard(
                  child: Column(
                    children: [
                      _billRow('Item total', '₹$itemTotal*'),
                      _billRow('Combo savings', '– ₹$_comboSavings',
                          highlight: true),
                      _billRow(
                          'Delivery charges',
                          deliveryFee == 0
                              ? '₹0 (free over ₹999)'
                              : '₹$deliveryFee'),
                      _billRow('Total payable', '₹$total*',
                          bold: true, last: true),
                      const SizedBox(height: 6),
                      Align(
                        alignment: Alignment.centerLeft,
                        child: Text('* placeholder pricing',
                            style: TextStyle(fontSize: 10.5, color: c.gold)),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 14),
                ElevatedButton(
                  onPressed: () => context.go('/cart/checkout'),
                  child: const Text('Proceed to Checkout'),
                ),
                const SizedBox(height: 8),
                OutlinedButton(
                  onPressed: () => ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                        content: Text('Saved cart as Monthly Plan (placeholder)'),
                        duration: Duration(milliseconds: 900)),
                  ),
                  child: const Text('Save Cart as Monthly Plan'),
                ),
              ],
            ),
    );
  }

  Widget _billRow(String label, String value,
          {bool bold = false, bool highlight = false, bool last = false}) =>
      Builder(builder: (context) {
        final c = context.colors;
        return Container(
          padding: const EdgeInsets.symmetric(vertical: 9),
          decoration: BoxDecoration(
            border: last
                ? const Border()
                : Border(bottom: BorderSide(color: c.line)),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(label,
                  style: TextStyle(
                      fontSize: bold ? 16 : 13,
                      fontWeight: bold ? FontWeight.w700 : FontWeight.w400)),
              Text(value,
                  style: TextStyle(
                      fontSize: bold ? 16 : 13,
                      fontWeight: FontWeight.w700,
                      color: (bold || highlight) ? c.green : c.ink)),
            ],
          ),
        );
      });
}

class _EmptyCart extends StatelessWidget {
  const _EmptyCart({required this.onShop});
  final VoidCallback onShop;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.shopping_cart_outlined, size: 56, color: c.muted),
          const SizedBox(height: 12),
          Text('Your cart is empty',
              style: context.text.titleMedium),
          const SizedBox(height: 6),
          Text('Add groceries to get started',
              style: TextStyle(color: c.muted)),
          const SizedBox(height: 16),
          SizedBox(
            width: 200,
            child: ElevatedButton(
                onPressed: onShop, child: const Text('Shop now')),
          ),
        ],
      ),
    );
  }
}
