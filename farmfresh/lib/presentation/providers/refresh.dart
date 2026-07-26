import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'repository_providers.dart';

/// Invalidates all catalog reads so the next watch refetches from the backend.
/// Call this from pull-to-refresh and on app resume so admin/backend changes
/// show up in a running app without a restart.
void refreshCatalog(WidgetRef ref) {
  ref.invalidate(categoriesProvider);
  ref.invalidate(productsProvider);
  ref.invalidate(subscriptionsProvider);
  ref.invalidate(combosProvider);
}

/// Same, but awaitable — for RefreshIndicator.onRefresh which expects a Future
/// that completes when the refresh is done.
Future<void> refreshCatalogAsync(WidgetRef ref) async {
  refreshCatalog(ref);
  await Future.wait([
    ref.read(categoriesProvider.future),
    ref.read(productsProvider.future),
  ]);
}
