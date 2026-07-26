import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/theme_ext.dart';
import '../../providers/repository_providers.dart';
import '../../widgets/product_card.dart';

/// The customer's saved favorites.
class WishlistPage extends ConsumerWidget {
  const WishlistPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = context.colors;
    final async = ref.watch(wishlistProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('My Wishlist')),
      body: RefreshIndicator(
        color: c.green,
        onRefresh: () async {
          ref.invalidate(wishlistProvider);
          await ref.read(wishlistProvider.future);
        },
        child: async.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (e, _) => Center(child: Text('Could not load: $e')),
          data: (list) {
            if (list.isEmpty) {
              return ListView(
                children: [
                  const SizedBox(height: 140),
                  Icon(Icons.favorite_border, size: 48, color: c.muted),
                  const SizedBox(height: 10),
                  Center(
                      child: Text('No favorites yet',
                          style: TextStyle(color: c.muted))),
                ],
              );
            }
            return GridView.builder(
              padding: const EdgeInsets.all(16),
              physics: const AlwaysScrollableScrollPhysics(),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                mainAxisSpacing: 12,
                crossAxisSpacing: 12,
                childAspectRatio: 0.72,
              ),
              itemCount: list.length,
              itemBuilder: (_, i) => ProductCard(
                product: list[i],
                onTap: () => context.go('/products/detail/${list[i].id}'),
              ),
            );
          },
        ),
      ),
    );
  }
}
