import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/dimens.dart';
import '../../../core/theme/theme_controller.dart';
import '../../../core/theme/theme_ext.dart';
import '../../../core/widgets/info_note.dart';
import '../../../core/widgets/section_header.dart';
import '../../../domain/entities/category.dart';
import '../../../domain/entities/product.dart';
import '../../providers/refresh.dart';
import '../../providers/repository_providers.dart';
import '../../widgets/category_icons.dart';
import '../../widgets/product_card.dart';
import 'widgets/home_hero.dart';
import 'widgets/location_sheet.dart';
import 'widgets/quick_actions.dart';

/// Screen 3 — Home. Location + search, hero, quick actions, categories,
/// product scrollers and the trust section.
class HomePage extends ConsumerStatefulWidget {
  const HomePage({super.key});

  @override
  ConsumerState<HomePage> createState() => _HomePageState();
}

class _HomePageState extends ConsumerState<HomePage> {
  String _location = 'Navi Mumbai';

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final categories = ref.watch(categoriesProvider);
    final products = ref.watch(productsProvider);

    return Scaffold(
      body: SafeArea(
        bottom: false,
        child: RefreshIndicator(
          onRefresh: () => refreshCatalogAsync(ref),
          color: c.green,
          child: ListView(
          padding: EdgeInsets.zero,
          physics: const AlwaysScrollableScrollPhysics(),
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
              child: Column(
                children: [
                  _TopRow(
                    location: _location,
                    onPickLocation: _pickLocation,
                  ),
                  const SizedBox(height: 12),
                  _SearchBar(onTap: () => context.go('/products')),
                ],
              ),
            ),
            Padding(
              padding: AppSpacing.page,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  HomeHero(onShop: () => context.go('/products')),
                  const SizedBox(height: 16),
                  const QuickActions(),
                  SectionHeader(
                    'Shop by Category',
                    actionLabel: 'See all',
                    onAction: () => context.go('/products'),
                  ),
                  categories.when(
                    loading: () => const _LoadingRow(),
                    error: (e, _) => Text('Could not load categories',
                        style: TextStyle(color: c.muted)),
                    data: (list) => _CategoryGrid(items: list),
                  ),
                  SectionHeader(
                    "Today's Best Deals",
                    actionLabel: 'More',
                    onAction: () => context.go('/products'),
                  ),
                  _ProductScroller(products: products, range: (0, 4)),
                  SectionHeader(
                    'Freshly Packed This Week',
                    actionLabel: 'More',
                    onAction: () => context.go('/products'),
                  ),
                  _ProductScroller(products: products, range: (2, 6)),
                  SectionHeader(
                    'Best Sellers',
                    actionLabel: 'More',
                    onAction: () => context.go('/products'),
                  ),
                  _ProductScroller(products: products, range: (4, 8)),
                  const SectionHeader('Why families trust us'),
                  const _TrustGrid(),
                  const SizedBox(height: 14),
                  const InfoNote(
                    'All prices are placeholders for wireframe review',
                  ),
                  const SizedBox(height: 8),
                ],
              ),
            ),
          ],
        ),
        ),
      ),
    );
  }

  Future<void> _pickLocation() async {
    final picked = await showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => const LocationSheet(),
    );
    if (picked != null) setState(() => _location = picked);
  }
}

class _TopRow extends ConsumerWidget {
  const _TopRow({required this.location, required this.onPickLocation});

  final String location;
  final VoidCallback onPickLocation;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = context.colors;
    final mode = ref.watch(themeControllerProvider);
    return Row(
      children: [
        Expanded(
          child: GestureDetector(
            onTap: onPickLocation,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Deliver to',
                    style: TextStyle(fontSize: 11, color: c.muted)),
                Row(
                  children: [
                    Icon(Icons.location_on, size: 16, color: c.green),
                    const SizedBox(width: 2),
                    Text(location,
                        style: const TextStyle(
                            fontSize: 14, fontWeight: FontWeight.w700)),
                    const Icon(Icons.arrow_drop_down, size: 20),
                  ],
                ),
              ],
            ),
          ),
        ),
        IconButton(
          tooltip: 'Toggle theme',
          onPressed: () => ref.read(themeControllerProvider.notifier).toggle(),
          icon: Icon(
            mode == ThemeMode.dark ? Icons.light_mode : Icons.dark_mode,
            color: c.gold,
          ),
        ),
        GestureDetector(
          onTap: () => context.go('/profile'),
          child: CircleAvatar(
            radius: 19,
            backgroundColor: c.goldSoft,
            child: Icon(Icons.person_outline,
                size: 20,
                color: context.isDark
                    ? const Color(0xFFE8C779)
                    : const Color(0xFF8A6A16)),
          ),
        ),
      ],
    );
  }
}

class _SearchBar extends StatelessWidget {
  const _SearchBar({required this.onTap});
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: c.beige,
          borderRadius: AppRadius.pillAll,
          border: Border.all(color: c.beigeDeep),
        ),
        child: Row(
          children: [
            Icon(Icons.search, size: 18, color: c.muted),
            const SizedBox(width: 8),
            Text('Search rice, dal, oil, ghee…',
                style: TextStyle(fontSize: 13, color: c.muted)),
          ],
        ),
      ),
    );
  }
}

class _CategoryGrid extends StatelessWidget {
  const _CategoryGrid({required this.items});
  final List<Category> items;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: items.length,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        mainAxisSpacing: 10,
        crossAxisSpacing: 10,
        childAspectRatio: 1.15,
      ),
      itemBuilder: (_, i) {
        final cat = items[i];
        return GestureDetector(
          onTap: () => context.go('/products'),
          child: Container(
            decoration: BoxDecoration(
              color: c.surface,
              borderRadius: AppRadius.smAll,
              border: Border.all(color: c.line),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(categoryIcon(cat.name), size: 26, color: c.green),
                const SizedBox(height: 6),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  child: Text(
                    cat.name,
                    textAlign: TextAlign.center,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                        fontSize: 11.5, fontWeight: FontWeight.w600),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _ProductScroller extends StatelessWidget {
  const _ProductScroller({required this.products, required this.range});
  final AsyncValue<List<Product>> products;
  final (int, int) range;

  @override
  Widget build(BuildContext context) {
    return products.when(
      loading: () => const _LoadingRow(),
      error: (e, _) => const SizedBox.shrink(),
      data: (list) {
        final slice = list.sublist(
          range.$1.clamp(0, list.length),
          range.$2.clamp(0, list.length),
        );
        return SizedBox(
          height: 244,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            padding: EdgeInsets.zero,
            itemCount: slice.length,
            separatorBuilder: (_, __) => const SizedBox(width: 12),
            itemBuilder: (_, i) => SizedBox(
              width: 150,
              child: ProductCard(
                product: slice[i],
                onTap: () => context.go('/home/detail/${slice[i].id}'),
              ),
            ),
          ),
        );
      },
    );
  }
}

class _LoadingRow extends StatelessWidget {
  const _LoadingRow();
  @override
  Widget build(BuildContext context) => const SizedBox(
        height: 120,
        child: Center(child: CircularProgressIndicator()),
      );
}

class _TrustGrid extends StatelessWidget {
  const _TrustGrid();

  static const _items = <(IconData, String)>[
    (Icons.agriculture_outlined, 'Direct Farm Source'),
    (Icons.sell_outlined, 'Own Label'),
    (Icons.verified_outlined, 'Quality Checked'),
    (Icons.local_shipping_outlined, 'Home Delivery'),
  ];

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: 2,
      mainAxisSpacing: 10,
      crossAxisSpacing: 10,
      childAspectRatio: 3.4,
      children: [
        for (final item in _items)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            decoration: BoxDecoration(
              color: c.greenSoft,
              borderRadius: AppRadius.smAll,
            ),
            child: Row(
              children: [
                Icon(item.$1, size: 22, color: c.green),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    item.$2,
                    style: const TextStyle(
                        fontSize: 12, fontWeight: FontWeight.w600),
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }
}
