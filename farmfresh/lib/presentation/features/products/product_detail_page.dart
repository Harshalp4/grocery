import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/config/api_config.dart';
import '../../../core/theme/dimens.dart';
import '../../../core/theme/theme_ext.dart';
import '../../../core/widgets/app_card.dart';
import '../../../core/widgets/app_tag.dart';
import '../../../core/widgets/basket_line_tile.dart';
import '../../../core/widgets/image_placeholder.dart';
import '../../../core/widgets/section_header.dart';
import '../../../domain/entities/product.dart';
import '../../../domain/entities/review.dart';
import '../../providers/cart_controller.dart';
import '../../providers/repository_providers.dart';

/// Screen 7 — Product Detail. Falls back gracefully if the id is unknown.
class ProductDetailPage extends ConsumerWidget {
  const ProductDetailPage({super.key, required this.productId});

  final String productId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final products = ref.watch(productsProvider);
    return products.when(
      loading: () => const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      ),
      error: (e, _) => Scaffold(
        appBar: AppBar(),
        body: Center(child: Text('Failed to load: $e')),
      ),
      data: (list) {
        final product = list.where((p) => p.id == productId).firstOrNull;
        if (product == null) {
          return Scaffold(
            appBar: AppBar(title: const Text('Product')),
            body: const Center(child: Text('Product not found')),
          );
        }
        return _DetailView(product: product);
      },
    );
  }
}

class _DetailView extends ConsumerStatefulWidget {
  const _DetailView({required this.product});
  final Product product;

  @override
  ConsumerState<_DetailView> createState() => _DetailViewState();
}

class _DetailViewState extends ConsumerState<_DetailView> {
  ProductVariant? _variant;

  @override
  void initState() {
    super.initState();
    _variant = widget.product.defaultVariant;
  }

  @override
  Widget build(BuildContext context) {
    final product = widget.product;
    final c = context.colors;
    final reviews = ref.watch(_reviewsProvider(product.id));
    final v = _variant;
    final price = v?.price ?? product.price;
    final market = v?.marketPrice ?? product.marketPrice;
    final inStock = v != null ? v.inStock : product.inStock;
    final stock = v?.stock ?? product.stock;

    return Scaffold(
      appBar: AppBar(title: Text(product.name)),
      body: RefreshIndicator(
        onRefresh: () async {
          ref.invalidate(productsProvider);
          ref.invalidate(_reviewsProvider(product.id));
          await ref.read(productsProvider.future);
        },
        color: c.green,
        child: ListView(
        padding: AppSpacing.page,
        physics: const AlwaysScrollableScrollPhysics(),
        children: [
          ClipRRect(
            borderRadius: AppRadius.smAll,
            child: SizedBox(
              height: 180,
              width: double.infinity,
              child: ApiConfig.imageUrl(product.imageUrl) != null
                  ? Image.network(
                      ApiConfig.imageUrl(product.imageUrl)!,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) =>
                          const ImagePlaceholder(label: 'Product image'),
                    )
                  : const ImagePlaceholder(label: 'Product image'),
            ),
          ),
          const SizedBox(height: 14),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(product.name, style: context.text.headlineSmall),
                    const SizedBox(height: 2),
                    Text('Source: ${product.source}',
                        style: TextStyle(fontSize: 12, color: c.muted)),
                  ],
                ),
              ),
              AppTag(product.grade, variant: TagVariant.gold),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Text('₹$price',
                  style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w800,
                      color: c.green)),
              const SizedBox(width: 8),
              if (market > price)
                Text('₹$market market',
                    style: TextStyle(
                        fontSize: 13,
                        color: c.muted,
                        decoration: TextDecoration.lineThrough)),
              const SizedBox(width: 8),
              if (market > price)
                AppTag(
                    'Save ~${(((market - price) / market) * 100).round()}%',
                    variant: TagVariant.save),
            ],
          ),
          const SizedBox(height: 6),
          _StockLine(inStock: inStock, stock: stock, hasVariant: v != null),
          if (product.hasVariants) ...[
            const SizedBox(height: 12),
            Text('Pack size',
                style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: c.muted)),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final variant in product.variants)
                  ChoiceChip(
                    label: Text('${variant.label}'
                        '${variant.inStock ? '' : ' (out)'}'),
                    selected: _variant?.id == variant.id,
                    onSelected: variant.inStock
                        ? (_) => setState(() => _variant = variant)
                        : null,
                    selectedColor: c.green,
                    labelStyle: TextStyle(
                      fontSize: 12.5,
                      fontWeight: FontWeight.w600,
                      color: _variant?.id == variant.id
                          ? Colors.white
                          : (variant.inStock ? c.ink : c.muted),
                    ),
                  ),
              ],
            ),
          ],
          const SizedBox(height: 14),
          _Facts(product: product),
          const SectionHeader('Nutrition facts (per 100g)'),
          AppCard(
            child: Column(
              children: [
                for (final e in _nutrition(product).entries)
                  BasketLineTile(
                    title: e.key,
                    trailing: e.value,
                    showDivider: e.key != _nutrition(product).keys.last,
                  ),
                const SizedBox(height: 6),
                Align(
                  alignment: Alignment.centerLeft,
                  child: Text('* placeholder values',
                      style: TextStyle(fontSize: 10.5, color: c.gold)),
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: _GhostSmall(
                  icon: Icons.science_outlined,
                  label: 'Lab Report',
                  onTap: () => _toast(context, 'Lab test report (placeholder)'),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _GhostSmall(
                  icon: Icons.qr_code_2,
                  label: 'Trace QR',
                  onTap: () => _toast(context, 'QR traceability (placeholder)'),
                ),
              ),
            ],
          ),
          const SectionHeader('Customer Reviews  ★ 4.7'),
          reviews.when(
            loading: () => const _LoadingBox(),
            error: (e, _) => const SizedBox.shrink(),
            data: (list) => AppCard(
              child: Column(
                children: [
                  for (var i = 0; i < list.length; i++)
                    _ReviewRow(
                        review: list[i], last: i == list.length - 1),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
        ],
      ),
      ),
      bottomNavigationBar: SafeArea(
        child: Container(
          padding: const EdgeInsets.fromLTRB(14, 10, 14, 10),
          decoration: BoxDecoration(
            color: c.surface,
            border: Border(top: BorderSide(color: c.line)),
          ),
          child: Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () =>
                      _toast(context, 'Subscribe Monthly (placeholder)'),
                  child: const Text('Subscribe Monthly'),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: ElevatedButton(
                  onPressed: inStock
                      ? () {
                          ref
                              .read(cartControllerProvider.notifier)
                              .addProduct(product, variant: _variant);
                          _toast(context, 'Added to cart');
                        }
                      : null,
                  child: Text(inStock ? 'Add to Cart' : 'Out of stock'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Map<String, String> _nutrition(Product p) => p.nutrition.isNotEmpty
      ? p.nutrition
      : const {
          'Protein': '—',
          'Carbohydrates': '—',
          'Fibre': '—',
          'Energy': '—',
        };

  void _toast(BuildContext context, String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg), duration: const Duration(milliseconds: 900)),
    );
  }
}

final _reviewsProvider = FutureProvider.family<List<Review>, String>(
  (ref, id) => ref.watch(catalogRepositoryProvider).getReviews(id),
);

/// A one-line stock indicator under the price.
class _StockLine extends StatelessWidget {
  const _StockLine(
      {required this.inStock, required this.stock, required this.hasVariant});
  final bool inStock;
  final int stock;
  final bool hasVariant;

  @override
  Widget build(BuildContext context) {
    late final IconData icon;
    late final Color color;
    late final String text;
    if (!inStock) {
      icon = Icons.cancel;
      color = Colors.red.shade600;
      text = 'Out of stock';
    } else if (stock <= 5) {
      icon = Icons.warning_amber_rounded;
      color = const Color(0xFFB4690E);
      text = 'Only $stock left';
    } else {
      icon = Icons.check_circle;
      color = context.colors.green;
      text = 'In stock';
    }
    return Row(
      children: [
        Icon(icon, size: 16, color: color),
        const SizedBox(width: 6),
        Text(text,
            style: TextStyle(
                fontSize: 12.5, fontWeight: FontWeight.w600, color: color)),
      ],
    );
  }
}

class _Facts extends StatelessWidget {
  const _Facts({required this.product});
  final Product product;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final facts = <(String, String)>[
      ('Harvest month', product.harvestMonth ?? '—'),
      ('Packed date', product.packedDate),
      ('Quality grade', product.grade),
      ('Pack size', product.packSize ?? '—'),
    ];
    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: 2,
      mainAxisSpacing: 8,
      crossAxisSpacing: 8,
      childAspectRatio: 3.4,
      children: [
        for (final f in facts)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 8),
            decoration: BoxDecoration(
              color: c.beige,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(f.$1, style: TextStyle(fontSize: 11, color: c.muted)),
                Text(f.$2,
                    style: const TextStyle(
                        fontSize: 13, fontWeight: FontWeight.w700)),
              ],
            ),
          ),
      ],
    );
  }
}

class _GhostSmall extends StatelessWidget {
  const _GhostSmall({
    required this.icon,
    required this.label,
    required this.onTap,
  });
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return TextButton.icon(
      onPressed: onTap,
      icon: Icon(icon, size: 18),
      label: Text(label),
      style: TextButton.styleFrom(
        backgroundColor: c.greenSoft,
        foregroundColor: c.green,
        minimumSize: const Size.fromHeight(42),
        shape: const RoundedRectangleBorder(borderRadius: AppRadius.pillAll),
        textStyle: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
      ),
    );
  }
}

class _ReviewRow extends StatelessWidget {
  const _ReviewRow({required this.review, required this.last});
  final Review review;
  final bool last;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 11),
      decoration: BoxDecoration(
        border: last ? const Border() : Border(bottom: BorderSide(color: c.line)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CircleAvatar(
            radius: 17,
            backgroundColor: c.goldSoft,
            child: Text(review.initials,
                style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: context.isDark
                        ? const Color(0xFFE8C779)
                        : const Color(0xFF8A6A16))),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('${review.author} · ${review.area}',
                    style: const TextStyle(
                        fontSize: 13, fontWeight: FontWeight.w700)),
                Text(
                  '${'★' * review.rating}${'☆' * (5 - review.rating)} ${review.text}',
                  style: TextStyle(fontSize: 12, color: c.muted),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _LoadingBox extends StatelessWidget {
  const _LoadingBox();
  @override
  Widget build(BuildContext context) => const SizedBox(
        height: 60,
        child: Center(child: CircularProgressIndicator()),
      );
}
