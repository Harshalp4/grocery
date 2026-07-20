import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/dimens.dart';
import '../../../core/theme/theme_ext.dart';
import '../../../domain/entities/product.dart';
import '../../providers/refresh.dart';
import '../../providers/repository_providers.dart';
import '../../widgets/product_card.dart';

/// Screen 6 — Product Listing. Search, quick filter chips, 2-column grid.
class ProductsPage extends ConsumerStatefulWidget {
  const ProductsPage({super.key});

  @override
  ConsumerState<ProductsPage> createState() => _ProductsPageState();
}

class _ProductsPageState extends ConsumerState<ProductsPage> {
  static const _filters = ['All', 'Best Seller', 'Freshly Packed', 'Premium Grade'];
  int _selected = 0;
  String _query = '';

  bool _matchesFilter(Product p) {
    switch (_selected) {
      case 1:
        return p.tags.contains('best');
      case 2:
        return p.tags.contains('fresh');
      case 3:
        return p.tags.contains('premium');
      default:
        return true;
    }
  }

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final products = ref.watch(productsProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Products')),
      body: products.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Failed to load: $e')),
        data: (all) {
          final list = all
              .where(_matchesFilter)
              .where((p) =>
                  p.name.toLowerCase().contains(_query.toLowerCase()))
              .toList();
          return RefreshIndicator(
            onRefresh: () => refreshCatalogAsync(ref),
            color: c.green,
            child: CustomScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            slivers: [
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
                  child: Column(
                    children: [
                      TextField(
                        onChanged: (v) => setState(() => _query = v),
                        decoration: InputDecoration(
                          hintText: 'Search products…',
                          prefixIcon: Icon(Icons.search, color: c.muted),
                          filled: true,
                          fillColor: c.beige,
                          border: OutlineInputBorder(
                            borderRadius: AppRadius.pillAll,
                            borderSide: BorderSide(color: c.beigeDeep),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: AppRadius.pillAll,
                            borderSide: BorderSide(color: c.beigeDeep),
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                      SizedBox(
                        height: 36,
                        child: ListView.separated(
                          scrollDirection: Axis.horizontal,
                          itemCount: _filters.length,
                          separatorBuilder: (_, __) => const SizedBox(width: 8),
                          itemBuilder: (_, i) => ChoiceChip(
                            label: Text(_filters[i]),
                            selected: _selected == i,
                            onSelected: (_) => setState(() => _selected = i),
                            selectedColor: c.green,
                            labelStyle: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color:
                                  _selected == i ? Colors.white : c.ink,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 14),
                    ],
                  ),
                ),
              ),
              if (list.isEmpty)
                const SliverFillRemaining(
                  hasScrollBody: false,
                  child: Center(child: Text('No products match your search')),
                )
              else
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                  sliver: SliverGrid(
                    gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      mainAxisSpacing: 12,
                      crossAxisSpacing: 12,
                      childAspectRatio: 0.72,
                    ),
                    delegate: SliverChildBuilderDelegate(
                      (_, i) => ProductCard(
                        product: list[i],
                        onTap: () =>
                            context.go('/products/detail/${list[i].id}'),
                      ),
                      childCount: list.length,
                    ),
                  ),
                ),
            ],
          ),
          );
        },
      ),
    );
  }
}
