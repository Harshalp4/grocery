import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/theme.dart';
import '../domain/models.dart';
import '../providers.dart';

class OrderDetailPage extends ConsumerStatefulWidget {
  const OrderDetailPage({super.key, required this.orderId});
  final String orderId;

  @override
  ConsumerState<OrderDetailPage> createState() => _OrderDetailPageState();
}

class _OrderDetailPageState extends ConsumerState<OrderDetailPage> {
  bool _busy = false;

  Future<void> _run(Future<void> Function() op) async {
    setState(() => _busy = true);
    try {
      await op();
      ref.invalidate(orderDetailProvider(widget.orderId));
      ref.invalidate(ordersProvider('active'));
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('$e')));
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final async = ref.watch(orderDetailProvider(widget.orderId));
    return Scaffold(
      appBar: AppBar(
        title: Text(async.valueOrNull?.code ?? 'Order'),
      ),
      body: async.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Could not load: $e')),
        data: (o) => _body(context, o),
      ),
    );
  }

  Widget _body(BuildContext context, DeliveryOrder o) {
    final muted = Theme.of(context).colorScheme.onSurfaceVariant;
    return Column(
      children: [
        Expanded(
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              _card([
                _row(Icons.person_outline, o.customerName),
                if (o.phone != null) _row(Icons.phone_outlined, '+91 ${o.phone}'),
                _row(Icons.location_on_outlined, o.address),
                _row(Icons.schedule, o.slot),
              ]),
              const SizedBox(height: 12),
              _card([
                Row(children: [
                  const Text('Payment', style: TextStyle(fontWeight: FontWeight.w700)),
                  const Spacer(),
                  Text(o.isCod ? 'Cash on delivery' : o.paymentMethod.toUpperCase(),
                      style: TextStyle(color: muted)),
                ]),
                if (o.isCod && o.codToCollect > 0) ...[
                  const SizedBox(height: 8),
                  Row(children: [
                    const Text('Collect'),
                    const Spacer(),
                    Text('₹${o.codToCollect}',
                        style: const TextStyle(
                            fontWeight: FontWeight.w800, color: riderGold, fontSize: 16)),
                  ]),
                ],
              ]),
              const SizedBox(height: 12),
              Text('Items (${o.itemCount})',
                  style: const TextStyle(fontWeight: FontWeight.w700)),
              const SizedBox(height: 6),
              _card([
                for (final it in o.items)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 5),
                    child: Row(children: [
                      Text('${it.qty}×',
                          style: const TextStyle(fontWeight: FontWeight.w700)),
                      const SizedBox(width: 8),
                      Expanded(child: Text('${it.name} · ${it.quantity}')),
                      Text(it.priceLabel, style: TextStyle(color: muted)),
                    ]),
                  ),
              ]),
              if (o.status == 'failed' && o.failureReason != null) ...[
                const SizedBox(height: 12),
                _card([
                  const Text('Delivery failed',
                      style: TextStyle(fontWeight: FontWeight.w700, color: riderRed)),
                  const SizedBox(height: 4),
                  Text(o.failureReason!, style: TextStyle(color: muted)),
                  const SizedBox(height: 4),
                  Text('Returned to dispatch for re-assignment.',
                      style: TextStyle(fontSize: 12, color: muted)),
                ]),
              ],
            ],
          ),
        ),
        _actions(context, o),
      ],
    );
  }

  Widget _actions(BuildContext context, DeliveryOrder o) {
    Widget bar(List<Widget> children) => SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
            child: Row(children: children),
          ),
        );

    if (o.status == 'packed') {
      return bar([
        Expanded(
          child: FilledButton.icon(
            onPressed: _busy
                ? null
                : () => _run(() async {
                      await ref.read(partnerRepositoryProvider).setStatus(o.id, 'picked_up');
                    }),
            icon: const Icon(Icons.inventory_2_outlined),
            label: const Text('Mark picked up'),
          ),
        ),
      ]);
    }
    if (o.status == 'picked_up') {
      return bar([
        Expanded(
          child: FilledButton.icon(
            onPressed: _busy
                ? null
                : () => _run(() async {
                      await ref.read(partnerRepositoryProvider).setStatus(o.id, 'out_for_delivery');
                    }),
            icon: const Icon(Icons.local_shipping_outlined),
            label: const Text('Start delivery'),
          ),
        ),
      ]);
    }
    if (o.status == 'out_for_delivery') {
      return bar([
        Expanded(
          child: OutlinedButton(
            onPressed: _busy ? null : () => _openFail(o),
            child: const Text("Can't deliver"),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          flex: 2,
          child: FilledButton.icon(
            onPressed: _busy ? null : () => _openDeliver(o),
            icon: const Icon(Icons.check_circle_outline),
            label: const Text('Deliver'),
          ),
        ),
      ]);
    }
    // delivered / other terminal states
    return bar([
      Expanded(
        child: Container(
          alignment: Alignment.center,
          padding: const EdgeInsets.symmetric(vertical: 14),
          child: Text(
            o.status == 'delivered' ? '✓ Delivered' : o.status,
            style: const TextStyle(fontWeight: FontWeight.w700, color: riderGreen),
          ),
        ),
      ),
    ]);
  }

  Future<void> _openDeliver(DeliveryOrder o) async {
    final done = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      builder: (_) => _DeliverSheet(order: o),
    );
    if (done == true) {
      ref.invalidate(orderDetailProvider(widget.orderId));
      ref.invalidate(ordersProvider('active'));
    }
  }

  Future<void> _openFail(DeliveryOrder o) async {
    final done = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      builder: (_) => _FailSheet(order: o),
    );
    if (done == true) {
      ref.invalidate(orderDetailProvider(widget.orderId));
      ref.invalidate(ordersProvider('active'));
    }
  }

  Widget _card(List<Widget> children) => Card(
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: children),
        ),
      );

  Widget _row(IconData icon, String text) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 5),
        child: Row(children: [
          Icon(icon, size: 18, color: riderBlue),
          const SizedBox(width: 10),
          Expanded(child: SelectableText(text)),
        ]),
      );
}

/// Bottom sheet to complete a delivery: OTP + COD + optional note.
class _DeliverSheet extends ConsumerStatefulWidget {
  const _DeliverSheet({required this.order});
  final DeliveryOrder order;

  @override
  ConsumerState<_DeliverSheet> createState() => _DeliverSheetState();
}

class _DeliverSheetState extends ConsumerState<_DeliverSheet> {
  final _otp = TextEditingController();
  late final TextEditingController _cod =
      TextEditingController(text: widget.order.codToCollect.toString());
  final _note = TextEditingController();
  bool _busy = false;
  String? _error;

  @override
  void dispose() {
    _otp.dispose();
    _cod.dispose();
    _note.dispose();
    super.dispose();
  }

  Future<void> _confirm() async {
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      await ref.read(partnerRepositoryProvider).deliver(
            widget.order.id,
            otp: _otp.text.trim(),
            codCollected: int.tryParse(_cod.text.trim()) ?? 0,
            note: _note.text.trim(),
          );
      if (mounted) Navigator.pop(context, true);
    } catch (e) {
      if (mounted) setState(() => _error = e.toString());
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final bottom = MediaQuery.of(context).viewInsets.bottom;
    return Padding(
      padding: EdgeInsets.fromLTRB(18, 18, 18, 18 + bottom),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text('Complete delivery',
              style: TextStyle(fontSize: 17, fontWeight: FontWeight.w800)),
          const SizedBox(height: 4),
          Text('Ask the customer for their 4-digit delivery code.',
              style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant)),
          const SizedBox(height: 16),
          TextField(
            controller: _otp,
            keyboardType: TextInputType.number,
            maxLength: 4,
            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 22, letterSpacing: 8, fontWeight: FontWeight.w700),
            decoration: const InputDecoration(counterText: '', labelText: 'Delivery code'),
          ),
          if (widget.order.isCod) ...[
            const SizedBox(height: 10),
            TextField(
              controller: _cod,
              keyboardType: TextInputType.number,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              decoration: const InputDecoration(labelText: 'Cash collected (₹)', prefixText: '₹ '),
            ),
          ],
          const SizedBox(height: 10),
          TextField(
            controller: _note,
            decoration: const InputDecoration(labelText: 'Note (optional)'),
          ),
          if (_error != null) ...[
            const SizedBox(height: 10),
            Text(_error!, style: const TextStyle(color: riderRed, fontSize: 13)),
          ],
          const SizedBox(height: 16),
          FilledButton(
            onPressed: _busy ? null : _confirm,
            child: _busy
                ? const SizedBox(
                    height: 20, width: 20,
                    child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                : const Text('Confirm delivery'),
          ),
        ],
      ),
    );
  }
}

/// Bottom sheet to report a failed delivery.
class _FailSheet extends ConsumerStatefulWidget {
  const _FailSheet({required this.order});
  final DeliveryOrder order;

  @override
  ConsumerState<_FailSheet> createState() => _FailSheetState();
}

class _FailSheetState extends ConsumerState<_FailSheet> {
  static const _reasons = [
    'Customer unavailable',
    'Wrong address',
    'Customer refused',
    'Other',
  ];
  String _reason = _reasons.first;
  final _other = TextEditingController();
  bool _busy = false;
  String? _error;

  @override
  void dispose() {
    _other.dispose();
    super.dispose();
  }

  Future<void> _confirm() async {
    final reason = _reason == 'Other' ? _other.text.trim() : _reason;
    if (reason.isEmpty) {
      setState(() => _error = 'Please add a reason');
      return;
    }
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      await ref.read(partnerRepositoryProvider).fail(widget.order.id, reason);
      if (mounted) Navigator.pop(context, true);
    } catch (e) {
      if (mounted) setState(() => _error = e.toString());
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final bottom = MediaQuery.of(context).viewInsets.bottom;
    return Padding(
      padding: EdgeInsets.fromLTRB(18, 18, 18, 18 + bottom),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text("Can't deliver",
              style: TextStyle(fontSize: 17, fontWeight: FontWeight.w800)),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final r in _reasons)
                ChoiceChip(
                  label: Text(r),
                  selected: _reason == r,
                  onSelected: (_) => setState(() => _reason = r),
                ),
            ],
          ),
          if (_reason == 'Other') ...[
            const SizedBox(height: 10),
            TextField(
              controller: _other,
              decoration: const InputDecoration(labelText: 'Reason'),
            ),
          ],
          if (_error != null) ...[
            const SizedBox(height: 10),
            Text(_error!, style: const TextStyle(color: riderRed, fontSize: 13)),
          ],
          const SizedBox(height: 16),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: riderRed),
            onPressed: _busy ? null : _confirm,
            child: _busy
                ? const SizedBox(
                    height: 20, width: 20,
                    child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                : const Text('Report failure'),
          ),
        ],
      ),
    );
  }
}
