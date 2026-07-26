import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/theme_ext.dart';
import '../../../core/widgets/app_card.dart';
import '../../../core/widgets/app_tag.dart';
import '../../../core/widgets/basket_line_tile.dart';
import '../../../core/widgets/bottom_sheet_shell.dart';
import '../../../core/widgets/image_placeholder.dart';
import '../../../domain/entities/basket_line.dart';
import '../../../domain/entities/combo_pack.dart';
import '../../providers/cart_controller.dart';
import '../../providers/repository_providers.dart';

/// Screen 5 — Combo Packs. Family / Health / Festival tabs of fixed-price packs.
class CombosPage extends ConsumerStatefulWidget {
  const CombosPage({super.key});

  @override
  ConsumerState<CombosPage> createState() => _CombosPageState();
}

/// One cart line representing a whole pack.
BasketLine packToLine(ComboPack pack) => BasketLine(
      name: pack.name,
      quantity: pack.size,
      priceLabel: '₹${inr(pack.price)}',
    );

/// Formats an integer with Indian-style thousands grouping for the last group
/// (sufficient for the price ranges here).
String inr(int v) {
  final s = v.toString();
  if (s.length <= 3) return s;
  final head = s.substring(0, s.length - 3);
  final tail = s.substring(s.length - 3);
  return '$head,$tail';
}

class _CombosPageState extends ConsumerState<CombosPage> {
  ComboType _type = ComboType.family;

  static const _tabs = [
    (ComboType.family, 'Family Packs'),
    (ComboType.health, 'Health Packs'),
    (ComboType.festival, 'Festival Packs'),
  ];

  @override
  Widget build(BuildContext context) {
    final packs = ref.watch(combosProvider(_type));
    return Scaffold(
      appBar: AppBar(title: const Text('Combo Packs')),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
            child: SizedBox(
              height: 38,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: _tabs.length,
                separatorBuilder: (_, __) => const SizedBox(width: 8),
                itemBuilder: (_, i) {
                  final t = _tabs[i];
                  return ChoiceChip(
                    label: Text(t.$2),
                    selected: _type == t.$1,
                    onSelected: (_) => setState(() => _type = t.$1),
                    selectedColor: context.colors.green,
                    labelStyle: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color:
                          _type == t.$1 ? Colors.white : context.colors.ink,
                    ),
                  );
                },
              ),
            ),
          ),
          Expanded(
            child: RefreshIndicator(
              onRefresh: () async {
                ref.invalidate(combosProvider);
                await ref.read(combosProvider(_type).future);
              },
              color: context.colors.green,
              child: packs.when(
                loading: () =>
                    const Center(child: CircularProgressIndicator()),
                error: (e, _) => Center(child: Text('Failed to load: $e')),
                data: (list) => ListView.separated(
                  padding: const EdgeInsets.all(16),
                  physics: const AlwaysScrollableScrollPhysics(),
                  itemCount: list.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 12),
                  itemBuilder: (_, i) => _ComboCard(pack: list[i]),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ComboCard extends ConsumerWidget {
  const _ComboCard({required this.pack});
  final ComboPack pack;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = context.colors;
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(pack.name,
                        style: const TextStyle(
                            fontSize: 15, fontWeight: FontWeight.w700)),
                    Text('${pack.size} · ${pack.duration}',
                        style: TextStyle(fontSize: 11.5, color: c.muted)),
                  ],
                ),
              ),
              Text('₹${inr(pack.price)}*',
                  style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                      color: c.green)),
            ],
          ),
          const SizedBox(height: 8),
          Text(pack.items, style: TextStyle(fontSize: 12, color: c.muted)),
          const SizedBox(height: 8),
          AppTag(pack.savingsNote, variant: TagVariant.save),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () => _showDetail(context),
                  style: OutlinedButton.styleFrom(
                      minimumSize: const Size.fromHeight(42)),
                  child: const Text('View Details'),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: ElevatedButton(
                  onPressed: () {
                    ref.read(cartControllerProvider.notifier)
                        .addLine(packToLine(pack));
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                          content: Text('${pack.name} added'),
                          duration: const Duration(milliseconds: 900)),
                    );
                  },
                  style: ElevatedButton.styleFrom(
                      minimumSize: const Size.fromHeight(42)),
                  child: const Text('Add Pack'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _showDetail(BuildContext context) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _ComboDetailSheet(pack: pack),
    );
  }
}

class _ComboDetailSheet extends ConsumerWidget {
  const _ComboDetailSheet({required this.pack});
  final ComboPack pack;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = context.colors;
    return BottomSheetShell(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const ImagePlaceholder(label: 'Combo pack', height: 150),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(pack.name, style: context.text.headlineSmall),
              ),
              AppTag(pack.savingsNote, variant: TagVariant.save),
            ],
          ),
          Text('${pack.size} · ${pack.duration}',
              style: TextStyle(fontSize: 12, color: c.muted)),
          const SizedBox(height: 10),
          for (final item in pack.itemList)
            BasketLineTile(title: item, trailing: '✓', showDivider: true),
          const SizedBox(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Pack price',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800)),
              Text('₹${inr(pack.price)}',
                  style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                      color: c.green)),
            ],
          ),
          const SizedBox(height: 12),
          ElevatedButton(
            onPressed: () {
              ref.read(cartControllerProvider.notifier).addLine(packToLine(pack));
              Navigator.of(context).pop();
              context.go('/cart');
            },
            child: const Text('Add Pack to Cart'),
          ),
        ],
      ),
    );
  }
}
