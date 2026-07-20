import '../../domain/entities/category.dart';
import '../../domain/entities/combo_pack.dart';
import '../../domain/entities/product.dart';
import '../../domain/entities/review.dart';
import '../../domain/entities/subscription_plan.dart';
import '../../domain/repositories/catalog_repository.dart';
import '../datasources/api_client.dart';

/// Catalog repository backed by the FarmFresh HTTP API. Implements the same
/// [CatalogRepository] interface as the mock, so nothing above changes.
class RemoteCatalogRepository implements CatalogRepository {
  RemoteCatalogRepository(this._api);
  final ApiClient _api;

  @override
  Future<List<Category>> getCategories() async {
    final data = await _api.getJson('/categories') as List<dynamic>;
    return data.map((e) => _category(e as Map<String, dynamic>)).toList();
  }

  @override
  Future<List<Product>> getProducts() async {
    final data = await _api.getJson('/products') as List<dynamic>;
    return data.map((e) => _product(e as Map<String, dynamic>)).toList();
  }

  @override
  Future<List<Review>> getReviews(String productId) async {
    final data =
        await _api.getJson('/products/$productId/reviews') as List<dynamic>;
    return data.map((e) => _review(e as Map<String, dynamic>)).toList();
  }

  @override
  Future<List<ComboPack>> getCombos(ComboType type) async {
    final data =
        await _api.getJson('/combos', {'type': type.name}) as List<dynamic>;
    return data.map((e) => _combo(e as Map<String, dynamic>)).toList();
  }

  @override
  Future<List<SubscriptionPlan>> getSubscriptions() async {
    final data = await _api.getJson('/subscriptions') as List<dynamic>;
    return data.map((e) => _subscription(e as Map<String, dynamic>)).toList();
  }

  Category _category(Map<String, dynamic> j) =>
      Category(emoji: j['emoji'] as String? ?? '', name: j['name'] as String);

  Product _product(Map<String, dynamic> j) => Product(
        id: j['id'] as String,
        name: j['name'] as String,
        source: j['source'] as String,
        packedDate: j['packedDate'] as String,
        price: (j['price'] as num).toInt(),
        marketPrice: (j['marketPrice'] as num).toInt(),
        grade: j['grade'] as String,
        tags: (j['tags'] as List<dynamic>? ?? const [])
            .map((e) => e as String)
            .toList(),
        harvestMonth: j['harvestMonth'] as String?,
        packSize: j['packSize'] as String?,
        nutrition: (j['nutrition'] as Map<String, dynamic>? ?? const {})
            .map((k, v) => MapEntry(k, v.toString())),
        imageUrl: j['imageUrl'] as String?,
        stock: (j['stock'] as num?)?.toInt() ?? 0,
        inStock: j['inStock'] as bool? ?? true,
        variants: (j['variants'] as List<dynamic>? ?? const [])
            .map((e) => _variant(e as Map<String, dynamic>))
            .toList(),
      );

  ProductVariant _variant(Map<String, dynamic> j) => ProductVariant(
        id: j['id'] as String,
        label: j['label'] as String,
        price: (j['price'] as num).toInt(),
        marketPrice: (j['marketPrice'] as num).toInt(),
        stock: (j['stock'] as num?)?.toInt() ?? 0,
        inStock: j['inStock'] as bool? ?? true,
      );

  Review _review(Map<String, dynamic> j) => Review(
        initials: j['initials'] as String,
        author: j['author'] as String,
        area: j['area'] as String,
        rating: (j['rating'] as num).toInt(),
        text: j['text'] as String,
      );

  ComboPack _combo(Map<String, dynamic> j) => ComboPack(
        id: j['id'] as String,
        name: j['name'] as String,
        type: ComboType.values.byName(j['type'] as String),
        price: (j['price'] as num).toInt(),
        size: j['size'] as String,
        duration: j['duration'] as String,
        items: j['items'] as String,
        savingsNote: j['savingsNote'] as String,
      );

  SubscriptionPlan _subscription(Map<String, dynamic> j) => SubscriptionPlan(
        id: j['id'] as String,
        name: j['name'] as String,
        description: j['description'] as String,
        priceLabel: j['priceLabel'] as String,
      );
}
