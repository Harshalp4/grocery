import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/pricing.dart';
import '../../../core/theme/dimens.dart';
import '../../../core/theme/theme_ext.dart';
import '../../../core/widgets/app_card.dart';
import '../../../core/widgets/section_header.dart';
import '../../../domain/entities/basket_line.dart';
import '../../providers/cart_controller.dart';
import '../../providers/repository_providers.dart';
import '../../widgets/product_card.dart';

/// Screen 8 — Cart. Line items, coupon, suggested add-ons, bill summary.
class CartPage extends ConsumerWidget {
  const CartPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cart = ref.watch(cartControllerProvider);
    final products = ref.watch(productsProvider);

    final itemTotal = cart.itemTotal;
    final discount = cart.discount;
    final deliveryFee = Pricing.deliveryFee(itemTotal);
    final total = Pricing.payable(itemTotal, discount);

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
                        _CartLineRow(
                          line: cart.lines[i],
                          showDivider: i != cart.lines.length - 1,
                          onChanged: (q) => ref
                              .read(cartControllerProvider.notifier)
                              .setQty(i, q),
                        ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                _CouponBar(itemTotal: itemTotal),
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
                      _billRow('Item total', '₹$itemTotal'),
                      if (discount > 0)
                        _billRow('Coupon (${cart.couponCode})', '– ₹$discount',
                            highlight: true),
                      _billRow(
                          'Delivery charges',
                          deliveryFee == 0
                              ? '₹0 (free over ₹999)'
                              : '₹$deliveryFee'),
                      _billRow('Total payable', '₹$total',
                          bold: true, last: true),
                    ],
                  ),
                ),
                const SizedBox(height: 14),
                ElevatedButton(
                  onPressed: () => context.go('/cart/checkout'),
                  child: const Text('Proceed to Checkout'),
                ),
                const SizedBox(height: 8),
                const OutlinedButton(
                  onPressed: null, // saved plans not built yet
                  child: Text('Save Cart as Monthly Plan (coming soon)'),
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

/// One cart line: name·pack, a −/+ quantity stepper, and the line total.
class _CartLineRow extends StatelessWidget {
  const _CartLineRow({
    required this.line,
    required this.showDivider,
    required this.onChanged,
  });
  final BasketLine line;
  final bool showDivider;
  final ValueChanged<int> onChanged;

  int get _unit {
    final d = line.priceLabel.replaceAll(RegExp(r'[^0-9]'), '');
    return d.isEmpty ? 0 : int.parse(d);
  }

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 9),
      decoration: BoxDecoration(
        border: showDivider
            ? Border(bottom: BorderSide(color: c.line))
            : const Border(),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('${line.name} · ${line.quantity}',
                    style: const TextStyle(
                        fontSize: 13, fontWeight: FontWeight.w600)),
                Text('₹$_unit each',
                    style: TextStyle(fontSize: 11, color: c.muted)),
              ],
            ),
          ),
          _Stepper(qty: line.qty, onChanged: onChanged),
          const SizedBox(width: 10),
          SizedBox(
            width: 58,
            child: Text('₹${_unit * line.qty}',
                textAlign: TextAlign.right,
                style: TextStyle(
                    fontSize: 13, fontWeight: FontWeight.w700, color: c.green)),
          ),
        ],
      ),
    );
  }
}

class _Stepper extends StatelessWidget {
  const _Stepper({required this.qty, required this.onChanged});
  final int qty;
  final ValueChanged<int> onChanged;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    Widget btn(IconData icon, VoidCallback onTap) => InkWell(
          onTap: onTap,
          borderRadius: AppRadius.pillAll,
          child: Padding(
            padding: const EdgeInsets.all(6),
            child: Icon(icon, size: 16, color: c.green),
          ),
        );
    return Container(
      decoration: BoxDecoration(color: c.greenSoft, borderRadius: AppRadius.pillAll),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          btn(Icons.remove, () => onChanged(qty - 1)),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8),
            child: Text('$qty',
                style: TextStyle(
                    fontSize: 13, fontWeight: FontWeight.w700, color: c.green)),
          ),
          btn(Icons.add, () => onChanged(qty + 1)),
        ],
      ),
    );
  }
}

/// Coupon input + apply/remove, backed by the real `/coupons/validate` endpoint.
class _CouponBar extends ConsumerStatefulWidget {
  const _CouponBar({required this.itemTotal});
  final int itemTotal;

  @override
  ConsumerState<_CouponBar> createState() => _CouponBarState();
}

class _CouponBarState extends ConsumerState<_CouponBar> {
  final _ctl = TextEditingController();
  bool _busy = false;
  bool _ok = false;
  String? _msg;

  @override
  void dispose() {
    _ctl.dispose();
    super.dispose();
  }

  Future<void> _apply() async {
    final code = _ctl.text.trim();
    if (code.isEmpty) return;
    setState(() {
      _busy = true;
      _msg = null;
    });
    try {
      final r = await ref
          .read(orderRepositoryProvider)
          .validateCoupon(code, widget.itemTotal);
      if (!mounted) return;
      if (r.valid) {
        ref
            .read(cartControllerProvider.notifier)
            .applyCoupon(r.code ?? code.toUpperCase(), r.discount);
      } else {
        ref.read(cartControllerProvider.notifier).clearCoupon();
      }
      setState(() {
        _ok = r.valid;
        _msg = r.message;
      });
    } catch (_) {
      if (mounted) {
        setState(() {
          _ok = false;
          _msg = 'Could not apply coupon';
        });
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  void _remove() {
    ref.read(cartControllerProvider.notifier).clearCoupon();
    _ctl.clear();
    setState(() {
      _ok = false;
      _msg = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final applied = ref.watch(cartControllerProvider).couponCode != null;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: TextField(
                controller: _ctl,
                enabled: !applied,
                textCapitalization: TextCapitalization.characters,
                decoration: const InputDecoration(hintText: 'Coupon code'),
              ),
            ),
            const SizedBox(width: 8),
            TextButton(
              onPressed: _busy ? null : (applied ? _remove : _apply),
              style: TextButton.styleFrom(
                backgroundColor: c.greenSoft,
                foregroundColor: c.green,
                minimumSize: const Size(0, 48),
                padding: const EdgeInsets.symmetric(horizontal: 18),
                shape: const RoundedRectangleBorder(
                    borderRadius: AppRadius.pillAll),
              ),
              child: Text(applied ? 'Remove' : (_busy ? '…' : 'Apply')),
            ),
          ],
        ),
        if (_msg != null)
          Padding(
            padding: const EdgeInsets.only(top: 6, left: 4),
            child: Text(_msg!,
                style: TextStyle(
                    fontSize: 11.5, color: _ok ? c.green : Colors.red)),
          ),
      ],
    );
  }
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
