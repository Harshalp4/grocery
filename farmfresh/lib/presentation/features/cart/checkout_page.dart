import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/dimens.dart';
import '../../../core/theme/theme_ext.dart';
import '../../../core/widgets/app_card.dart';
import '../../../core/widgets/basket_line_tile.dart';
import '../../../core/widgets/bottom_sheet_shell.dart';
import '../../../core/widgets/section_header.dart';
import '../../../domain/entities/address.dart';
import '../../../domain/entities/customer_order.dart';
import '../../../domain/entities/order.dart';
import '../../providers/auth_controller.dart';
import '../../providers/cart_controller.dart';
import '../../providers/repository_providers.dart';

/// Screen 9 — Checkout. Address, delivery slot, payment method, order summary.
class CheckoutPage extends ConsumerStatefulWidget {
  const CheckoutPage({super.key});

  @override
  ConsumerState<CheckoutPage> createState() => _CheckoutPageState();
}

class _CheckoutPageState extends ConsumerState<CheckoutPage> {
  int _slot = 0;
  int _payment = 0;
  bool _placing = false;
  String? _selectedAddressId; // null = use default / guest fallback

  // Fallback address for guest checkout (not signed in).
  static const _guestAddress =
      'A-1203, Palm Heights, Sector 15, Vashi, Navi Mumbai 400703';

  // Cash on Delivery only for now (UPI/Card to be added with a real gateway).
  static const _payments = <(IconData, String)>[
    (Icons.payments_outlined, 'Cash on Delivery'),
  ];

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final cart = ref.watch(cartControllerProvider);
    final signedIn = ref.watch(authControllerProvider).isAuthenticated;
    final addresses = ref.watch(addressesProvider);
    final slots = ref.watch(deliverySlotsProvider);
    final itemTotal = cart.itemTotal;
    const savings = 260;
    final toPay = itemTotal - savings;
    final slotLabels = slots.valueOrNull ?? const <String>[];

    // Serviceability of the chosen address's pincode.
    final resolved = _resolveAddress(addresses.valueOrNull ?? const []);
    final pincode = (resolved?.pincode?.isNotEmpty ?? false)
        ? resolved!.pincode!
        : '400703';
    final service = ref.watch(serviceableProvider(pincode));
    final serviceable = service.valueOrNull?.serviceable ?? true;

    return Scaffold(
      appBar: AppBar(title: const Text('Checkout')),
      body: ListView(
        padding: AppSpacing.page,
        children: [
          SectionHeader('Delivery Address',
              actionLabel: signedIn ? 'Manage' : null,
              onAction:
                  signedIn ? () => context.go('/profile/addresses') : null),
          _addressSection(context, signedIn, addresses),
          const SizedBox(height: 8),
          _ServiceBanner(check: service.valueOrNull, pincode: pincode),
          const SectionHeader('Delivery Slot'),
          if (slotLabels.isEmpty)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 8),
              child: Text('Loading slots…'),
            )
          else
            _ChipRow(
              labels: slotLabels,
              selected: _slot.clamp(0, slotLabels.length - 1),
              onSelect: (i) => setState(() => _slot = i),
            ),
          const SectionHeader('Payment Method'),
          AppCard(
            child: Column(
              children: [
                for (var i = 0; i < _payments.length; i++)
                  InkWell(
                    onTap: () => setState(() => _payment = i),
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 9),
                      decoration: BoxDecoration(
                        border: i == _payments.length - 1
                            ? const Border()
                            : Border(bottom: BorderSide(color: c.line)),
                      ),
                      child: Row(
                        children: [
                          Icon(_payments[i].$1, size: 20, color: c.green),
                          const SizedBox(width: 8),
                          Expanded(
                              child: Text(_payments[i].$2,
                                  style: const TextStyle(fontSize: 13))),
                          Icon(
                            _payment == i
                                ? Icons.radio_button_checked
                                : Icons.radio_button_unchecked,
                            size: 18,
                            color: _payment == i ? c.green : c.muted,
                          ),
                        ],
                      ),
                    ),
                  ),
                const SizedBox(height: 6),
                Align(
                  alignment: Alignment.centerLeft,
                  child: Text('Pay in cash when your order arrives',
                      style: TextStyle(fontSize: 10.5, color: c.gold)),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          AppCard(
            child: Column(
              children: [
                BasketLineTile(
                    title: 'Items (${cart.count})', trailing: '₹$itemTotal*'),
                const BasketLineTile(
                    title: 'Savings', trailing: '– ₹$savings'),
                Container(
                  padding: const EdgeInsets.only(top: 9),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('To pay',
                          style: TextStyle(
                              fontSize: 16, fontWeight: FontWeight.w700)),
                      Text('₹$toPay*',
                          style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w800,
                              color: c.green)),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),
          ElevatedButton(
            onPressed: (_placing || cart.lines.isEmpty || !serviceable)
                ? null
                : _placeOrder,
            child: _placing
                ? const SizedBox(
                    height: 20,
                    width: 20,
                    child: CircularProgressIndicator(
                        strokeWidth: 2, color: Colors.white),
                  )
                : const Text('Place Order'),
          ),
        ],
      ),
    );
  }

  Address? _resolveAddress(List<Address> list) {
    if (list.isEmpty) return null;
    if (_selectedAddressId != null) {
      final m = list.where((a) => a.id == _selectedAddressId);
      if (m.isNotEmpty) return m.first;
    }
    return list.firstWhere((a) => a.isDefault, orElse: () => list.first);
  }

  Widget _addressSection(BuildContext context, bool signedIn,
      AsyncValue<List<Address>> addresses) {
    final c = context.colors;
    if (!signedIn) {
      return AppCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Guest checkout',
                style: TextStyle(fontWeight: FontWeight.w700)),
            const SizedBox(height: 4),
            Text(_guestAddress, style: TextStyle(fontSize: 13, color: c.muted)),
            const SizedBox(height: 8),
            GestureDetector(
              onTap: () => context.go('/login'),
              child: Text('Sign in to save & reuse your addresses →',
                  style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: c.green)),
            ),
          ],
        ),
      );
    }
    return addresses.when(
      loading: () =>
          const AppCard(child: Text('Loading addresses…')),
      error: (e, _) =>
          const AppCard(child: Text('Could not load addresses')),
      data: (list) {
        if (list.isEmpty) {
          return AppCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('No saved address yet',
                    style: TextStyle(fontSize: 13, color: c.muted)),
                const SizedBox(height: 10),
                OutlinedButton.icon(
                  onPressed: () => context.go('/profile/addresses'),
                  icon: const Icon(Icons.add, size: 18),
                  label: const Text('Add a delivery address'),
                ),
              ],
            ),
          );
        }
        final selected = _resolveAddress(list)!;
        return AppCard(
          onTap: list.length > 1 ? () => _pickAddress(context, list) : null,
          child: Row(
            children: [
              Icon(Icons.location_on_outlined, color: c.green),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(selected.label,
                        style: const TextStyle(fontWeight: FontWeight.w700)),
                    const SizedBox(height: 2),
                    Text(selected.formatted,
                        style: TextStyle(fontSize: 12.5, color: c.muted)),
                  ],
                ),
              ),
              if (list.length > 1)
                Text('Change',
                    style: TextStyle(
                        fontSize: 12.5,
                        fontWeight: FontWeight.w600,
                        color: c.green)),
            ],
          ),
        );
      },
    );
  }

  void _pickAddress(BuildContext context, List<Address> list) {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (_) => BottomSheetShell(
        title: 'Choose delivery address',
        child: Column(
          children: [
            for (final a in list)
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: Icon(Icons.location_on_outlined,
                    color: context.colors.green),
                title: Text(a.label,
                    style: const TextStyle(fontWeight: FontWeight.w700)),
                subtitle: Text(a.formatted),
                trailing: _resolveAddress(list)?.id == a.id
                    ? Icon(Icons.check_circle, color: context.colors.green)
                    : null,
                onTap: () {
                  setState(() => _selectedAddressId = a.id);
                  Navigator.pop(context);
                },
              ),
          ],
        ),
      ),
    );
  }

  Future<void> _placeOrder() async {
    final cart = ref.read(cartControllerProvider);
    final user = ref.read(authControllerProvider).user;
    final addrList = ref.read(addressesProvider).valueOrNull ?? const [];
    final slotLabels = ref.read(deliverySlotsProvider).valueOrNull ?? const [];
    final resolved = _resolveAddress(addrList);
    final address = resolved?.formatted ?? _guestAddress;
    final slot = slotLabels.isEmpty
        ? 'Tomorrow · 8–11 AM'
        : slotLabels[_slot.clamp(0, slotLabels.length - 1)];
    const savings = 260;
    final total = cart.itemTotal - savings;
    final input = OrderInput(
      customerName: user?.name?.isNotEmpty == true ? user!.name! : 'Guest',
      phone: user?.phone ?? '',
      address: address,
      slot: slot,
      paymentMethod: PaymentMethod.cod, // COD only for now
      items: cart.lines,
      itemTotal: cart.itemTotal,
      savings: savings,
      deliveryFee: 0,
      total: total,
    );

    setState(() => _placing = true);
    try {
      final confirmation =
          await ref.read(orderRepositoryProvider).placeOrder(input);
      if (!mounted) return;
      setState(() => _placing = false);
      _showConfirmation(confirmation);
    } catch (e) {
      if (!mounted) return;
      setState(() => _placing = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Could not place order: $e')),
      );
    }
  }

  void _showConfirmation(OrderConfirmation order) {
    final paidNote = order.paymentStatus == 'paid'
        ? 'Payment received'
        : 'Pay on delivery';
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      isDismissible: false,
      builder: (_) => BottomSheetShell(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Icon(Icons.check_circle, size: 56, color: context.colors.green),
            const SizedBox(height: 6),
            Text('Order placed!', style: context.text.headlineSmall),
            const SizedBox(height: 6),
            Text('Order ${order.code} · ${order.slot}',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 13, color: context.colors.muted)),
            const SizedBox(height: 4),
            Text('₹${order.total} · $paidNote',
                style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: context.colors.green)),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  ref.read(cartControllerProvider.notifier).clear();
                  Navigator.of(context).pop();
                  context.go('/home');
                },
                child: const Text('Back to Home'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Serviceability banner shown under the delivery address.
class _ServiceBanner extends StatelessWidget {
  const _ServiceBanner({required this.check, required this.pincode});
  final ServiceCheck? check;
  final String pincode;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    if (check == null) {
      return const SizedBox.shrink();
    }
    if (check!.serviceable) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: c.greenSoft,
          borderRadius: AppRadius.smAll,
        ),
        child: Row(
          children: [
            Icon(Icons.delivery_dining, size: 18, color: c.green),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                'Delivers to $pincode'
                '${check!.etaLabel != null ? ' · ${check!.etaLabel}' : ''}',
                style: TextStyle(
                    fontSize: 12.5,
                    fontWeight: FontWeight.w600,
                    color: c.green),
              ),
            ),
          ],
        ),
      );
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: const Color(0xFFFDECEC),
        borderRadius: AppRadius.smAll,
        border: Border.all(color: const Color(0xFFF3C0C0)),
      ),
      child: Row(
        children: [
          const Icon(Icons.location_off_outlined,
              size: 18, color: Colors.red),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              "Sorry, we don't deliver to $pincode yet. "
              'Pick a serviceable address.',
              style: const TextStyle(
                  fontSize: 12.5,
                  fontWeight: FontWeight.w600,
                  color: Colors.red),
            ),
          ),
        ],
      ),
    );
  }
}

class _ChipRow extends StatelessWidget {
  const _ChipRow(
      {required this.labels, required this.selected, required this.onSelect});
  final List<String> labels;
  final int selected;
  final ValueChanged<int> onSelect;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return SizedBox(
      height: 38,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: labels.length,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (_, i) => ChoiceChip(
          label: Text(labels[i]),
          selected: selected == i,
          onSelected: (_) => onSelect(i),
          selectedColor: c.green,
          labelStyle: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: selected == i ? Colors.white : c.ink,
          ),
        ),
      ),
    );
  }
}
