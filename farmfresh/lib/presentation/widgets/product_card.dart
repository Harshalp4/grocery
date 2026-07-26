import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/config/api_config.dart';
import '../../core/theme/dimens.dart';
import '../../core/theme/theme_ext.dart';
import '../../core/widgets/bottom_sheet_shell.dart';
import '../../core/widgets/image_placeholder.dart';
import '../../domain/entities/product.dart';
import '../providers/cart_controller.dart';

/// The `.prod` card: image, name, source, price vs. market, stock state, and a
/// variant-aware "+ Add" button. Used in Home scrollers and the Products grid.
class ProductCard extends ConsumerWidget {
  const ProductCard({super.key, required this.product, required this.onTap});

  final Product product;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = context.colors;
    final img = ApiConfig.imageUrl(product.imageUrl);
    final outOfStock = !product.inStock;
    final lowStock = product.inStock &&
        !product.hasVariants &&
        product.stock > 0 &&
        product.stock <= 5;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: c.surface,
          borderRadius: AppRadius.mdAll,
          border: Border.all(color: c.line),
        ),
        clipBehavior: Clip.antiAlias,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            SizedBox(
              height: 96,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  if (img != null)
                    Image.network(
                      img,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) =>
                          ImagePlaceholder(label: product.name),
                      loadingBuilder: (ctx, child, progress) => progress == null
                          ? child
                          : Container(color: c.greenSoft),
                    )
                  else
                    ImagePlaceholder(label: product.name),
                  if (outOfStock)
                    Container(
                      color: Colors.black.withValues(alpha: 0.45),
                      alignment: Alignment.center,
                      child: const Text('Out of stock',
                          style: TextStyle(
                              color: Colors.white,
                              fontSize: 12,
                              fontWeight: FontWeight.w700)),
                    ),
                ],
              ),
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(10),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      product.name,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          height: 1.2),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      lowStock
                          ? 'Only ${product.stock} left'
                          : '${product.source} · ${product.packedDate}',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                          fontSize: 10.5,
                          color: lowStock ? const Color(0xFFB4690E) : c.muted,
                          fontWeight:
                              lowStock ? FontWeight.w700 : FontWeight.w400),
                    ),
                    const Spacer(),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.baseline,
                      textBaseline: TextBaseline.alphabetic,
                      children: [
                        if (product.hasVariants)
                          Text('from ',
                              style:
                                  TextStyle(fontSize: 10, color: c.muted)),
                        Text('₹${product.displayPrice}',
                            style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w800,
                                color: c.green)),
                        if (product.displayMarketPrice > product.displayPrice) ...[
                          const SizedBox(width: 5),
                          Text('₹${product.displayMarketPrice}',
                              style: TextStyle(
                                  fontSize: 10.5,
                                  color: c.muted,
                                  decoration: TextDecoration.lineThrough)),
                        ],
                      ],
                    ),
                    const SizedBox(height: 8),
                    _AddButton(
                      product: product,
                      onAdd: () => _add(context, ref),
                      enabled: !outOfStock,
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _add(BuildContext context, WidgetRef ref) {
    if (product.hasVariants) {
      _showVariantPicker(context, ref);
    } else {
      ref.read(cartControllerProvider.notifier).addProduct(product);
      _toast(context, '${product.name} added to cart');
    }
  }

  void _showVariantPicker(BuildContext context, WidgetRef ref) {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (_) => BottomSheetShell(
        title: product.name,
        subtitle: 'Choose a pack size',
        child: Column(
          children: [
            for (final v in product.variants)
              ListTile(
                contentPadding: EdgeInsets.zero,
                enabled: v.inStock,
                title: Text(v.label,
                    style: const TextStyle(fontWeight: FontWeight.w700)),
                subtitle: v.inStock
                    ? Text('₹${v.price}'
                        '${v.marketPrice > v.price ? '   ₹${v.marketPrice}' : ''}')
                    : const Text('Out of stock'),
                trailing: v.inStock
                    ? Icon(Icons.add_circle, color: context.colors.green)
                    : null,
                onTap: v.inStock
                    ? () {
                        ref
                            .read(cartControllerProvider.notifier)
                            .addProduct(product, variant: v);
                        Navigator.pop(context);
                        _toast(context, '${product.name} (${v.label}) added');
                      }
                    : null,
              ),
          ],
        ),
      ),
    );
  }

  void _toast(BuildContext context, String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg), duration: const Duration(milliseconds: 900)),
    );
  }
}

class _AddButton extends StatelessWidget {
  const _AddButton(
      {required this.product, required this.onAdd, required this.enabled});
  final Product product;
  final VoidCallback onAdd;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return SizedBox(
      width: double.infinity,
      height: 34,
      child: TextButton(
        onPressed: enabled ? onAdd : null,
        style: TextButton.styleFrom(
          backgroundColor: enabled ? c.greenSoft : c.line.withValues(alpha: 0.4),
          foregroundColor: c.green,
          disabledForegroundColor: c.muted,
          padding: EdgeInsets.zero,
          shape:
              const RoundedRectangleBorder(borderRadius: AppRadius.pillAll),
          textStyle:
              const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
        ),
        child: Text(enabled
            ? (product.hasVariants ? 'Select size' : '+ Add')
            : 'Out of stock'),
      ),
    );
  }
}
