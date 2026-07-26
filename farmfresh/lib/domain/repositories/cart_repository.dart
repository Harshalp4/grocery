import '../entities/basket_line.dart';

/// Persistent server cart for signed-in customers.
///
/// API mapping:
///   load    -> GET /cart
///   replace -> PUT /cart   (bulk replace)
abstract interface class CartRepository {
  Future<List<BasketLine>> load();
  Future<void> replace(List<BasketLine> lines);
}
