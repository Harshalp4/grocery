import '../entities/category.dart';
import '../entities/combo_pack.dart';
import '../entities/product.dart';
import '../entities/promo_banner.dart';
import '../entities/review.dart';
import '../entities/subscription_plan.dart';

/// Catalog read operations. Backed by mock data today; swap in a remote
/// implementation (REST) later without touching the UI.
///
/// API mapping (see wireframe `API:` comments and PLAN.md §5):
///   getCategories   -> GET /categories
///   getProducts     -> GET /products
///   getReviews      -> GET /products/:id/reviews
///   getCombos       -> GET /combos?type=
///   getSubscriptions-> GET /subscriptions
abstract interface class CatalogRepository {
  Future<List<Category>> getCategories();
  Future<List<Product>> getProducts();
  Future<List<Review>> getReviews(String productId);
  Future<List<ComboPack>> getCombos(ComboType type);
  Future<List<SubscriptionPlan>> getSubscriptions();

  /// Submit a customer review (requires a signed-in customer).
  Future<void> submitReview(String productId, int rating, String text,
      {String? area});

  /// Wishlist / favorites (requires a signed-in customer).
  Future<List<Product>> getWishlist();
  Future<void> addToWishlist(String productId);
  Future<void> removeFromWishlist(String productId);

  /// Home-screen promo banners.
  Future<List<PromoBanner>> getBanners();
}
