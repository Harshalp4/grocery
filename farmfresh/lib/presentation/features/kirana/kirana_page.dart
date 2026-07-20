import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/theme_ext.dart';
import '../../../core/widgets/app_card.dart';
import '../../../core/widgets/app_tag.dart';
import '../../../core/widgets/basket_line_tile.dart';
import '../../../core/widgets/bottom_sheet_shell.dart';
import '../../../domain/entities/kirana_plan.dart';
import '../../providers/cart_controller.dart';
import '../../providers/repository_providers.dart';

/// Screen 4 — Auto Kirana List (flagship). Household form → generated basket.
class KiranaPage extends ConsumerStatefulWidget {
  const KiranaPage({super.key});

  @override
  ConsumerState<KiranaPage> createState() => _KiranaPageState();
}

class _KiranaPageState extends ConsumerState<KiranaPage> {
  String _members = '4';
  int _adults = 2;
  int _children = 2;
  final _budget = TextEditingController(text: '4500');
  String _pref = 'Vegetarian';
  String _usage = 'Regular cooking';

  bool _loading = false;
  KiranaPlan? _plan;

  @override
  void dispose() {
    _budget.dispose();
    super.dispose();
  }

  Future<void> _generate() async {
    setState(() => _loading = true);
    final plan = await ref.read(kiranaRepositoryProvider).generate(
          KiranaInput(
            members: _members,
            adults: _adults,
            children: _children,
            budget: int.tryParse(_budget.text) ?? 0,
            preference: _pref,
            usage: _usage,
          ),
        );
    if (!mounted) return;
    setState(() {
      _loading = false;
      _plan = plan;
    });
    _showResultSheet(plan);
  }

  void _showResultSheet(KiranaPlan plan) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _ResultSheet(plan: plan),
    );
  }

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Scaffold(
      appBar: AppBar(title: const Text('Auto Kirana List')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text(
            'Tell us about your household — we auto-build a monthly grocery basket.',
            style: TextStyle(fontSize: 13, color: c.muted),
          ),
          const SizedBox(height: 14),
          AppCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _label('Family members (total)'),
                _dropdown(_members, const ['2', '4', '5', '6+'],
                    (v) => setState(() => _members = v)),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _label('Adults'),
                          _dropdown('$_adults', const ['1', '2', '3'],
                              (v) => setState(() => _adults = int.parse(v))),
                        ],
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _label('Children'),
                          _dropdown('$_children', const ['0', '1', '2'],
                              (v) => setState(() => _children = int.parse(v))),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                _label('Monthly budget (₹, placeholder)'),
                TextField(
                  controller: _budget,
                  keyboardType: TextInputType.number,
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                ),
                const SizedBox(height: 12),
                _label('Food preference'),
                _dropdown(
                    _pref,
                    const [
                      'Vegetarian',
                      'Mixed',
                      'Jain',
                      'High-protein veg'
                    ],
                    (v) => setState(() => _pref = v)),
                const SizedBox(height: 12),
                _label('Monthly usage pattern'),
                _dropdown(
                    _usage,
                    const [
                      'Regular cooking',
                      'Light cooking',
                      'Heavy / joint family'
                    ],
                    (v) => setState(() => _usage = v)),
                const SizedBox(height: 16),
                _loading
                    ? const ElevatedButton(
                        onPressed: null,
                        child: SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                              strokeWidth: 2, color: Colors.white),
                        ),
                      )
                    : ElevatedButton.icon(
                        onPressed: _generate,
                        icon: const Icon(Icons.auto_awesome, size: 18),
                        label: const Text('Generate Kirana List'),
                      ),
              ],
            ),
          ),
          if (_plan != null) ...[
            const SizedBox(height: 14),
            _InlineResult(
              plan: _plan!,
              onAddAll: () {
                ref.read(cartControllerProvider.notifier)
                    .addLines(_plan!.lines);
                context.go('/cart');
              },
            ),
          ],
        ],
      ),
    );
  }

  Widget _label(String text) => Padding(
        padding: const EdgeInsets.only(bottom: 6),
        child: Text(text,
            style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: context.colors.muted)),
      );

  Widget _dropdown(String value, List<String> options,
      ValueChanged<String> onChanged) {
    return DropdownButtonFormField<String>(
      initialValue: value,
      isExpanded: true,
      items: [
        for (final o in options)
          DropdownMenuItem(value: o, child: Text(o)),
      ],
      onChanged: (v) {
        if (v != null) onChanged(v);
      },
    );
  }
}

class _InlineResult extends StatelessWidget {
  const _InlineResult({required this.plan, required this.onAddAll});
  final KiranaPlan plan;
  final VoidCallback onAddAll;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(plan.title,
                    style: const TextStyle(
                        fontSize: 15, fontWeight: FontWeight.w700)),
              ),
              const AppTag('Auto-generated', variant: TagVariant.green),
            ],
          ),
          const SizedBox(height: 8),
          for (var i = 0; i < plan.lines.length; i++)
            BasketLineTile(
              title: '${plan.lines[i].name} · ${plan.lines[i].quantity}',
              trailing: plan.lines[i].priceLabel,
              showDivider: i != plan.lines.length - 1,
            ),
          const SizedBox(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Total (approx)',
                  style: TextStyle(fontSize: 15, fontWeight: FontWeight.w800)),
              Text('₹${plan.estimatedTotal}*',
                  style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w800,
                      color: c.green)),
            ],
          ),
          const SizedBox(height: 12),
          ElevatedButton(
              onPressed: onAddAll, child: const Text('Add All to Cart')),
        ],
      ),
    );
  }
}

class _ResultSheet extends ConsumerWidget {
  const _ResultSheet({required this.plan});
  final KiranaPlan plan;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = context.colors;
    return BottomSheetShell(
      title: 'Your Monthly Kirana',
      subtitle: plan.subtitle,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          for (var i = 0; i < plan.lines.length; i++)
            BasketLineTile(
              title: '${plan.lines[i].name} · ${plan.lines[i].quantity}',
              trailing: plan.lines[i].priceLabel,
              showDivider: i != plan.lines.length - 1,
            ),
          const SizedBox(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Estimated total',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800)),
              Text('₹${plan.estimatedTotal}*',
                  style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                      color: c.green)),
            ],
          ),
          const SizedBox(height: 12),
          ElevatedButton(
            onPressed: () {
              ref.read(cartControllerProvider.notifier).addLines(plan.lines);
              Navigator.of(context).pop();
              context.go('/cart');
            },
            child: const Text('Add All to Cart'),
          ),
        ],
      ),
    );
  }
}
