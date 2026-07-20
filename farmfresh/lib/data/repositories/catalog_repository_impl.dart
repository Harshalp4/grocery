import '../../domain/entities/category.dart';
import '../../domain/entities/combo_pack.dart';
import '../../domain/entities/product.dart';
import '../../domain/entities/review.dart';
import '../../domain/entities/subscription_plan.dart';
import '../../domain/repositories/catalog_repository.dart';
import '../datasources/mock_data.dart';

/// Mock-backed catalog. Replace with a `RemoteCatalogRepository` (same
/// interface) when the API is ready — nothing above this layer changes.
class MockCatalogRepository implements CatalogRepository {
  const MockCatalogRepository();

  static const _latency = Duration(milliseconds: 300);

  @override
  Future<List<Category>> getCategories() async {
    await Future<void>.delayed(_latency);
    return MockData.categories;
  }

  @override
  Future<List<Product>> getProducts() async {
    await Future<void>.delayed(_latency);
    return MockData.products;
  }

  @override
  Future<List<Review>> getReviews(String productId) async {
    await Future<void>.delayed(_latency);
    return MockData.reviews;
  }

  @override
  Future<List<ComboPack>> getCombos(ComboType type) async {
    await Future<void>.delayed(_latency);
    return switch (type) {
      ComboType.family => MockData.familyPacks,
      ComboType.health => MockData.healthPacks,
      ComboType.festival => MockData.festivalPacks,
    };
  }

  @override
  Future<List<SubscriptionPlan>> getSubscriptions() async {
    await Future<void>.delayed(_latency);
    return MockData.subscriptions;
  }
}
