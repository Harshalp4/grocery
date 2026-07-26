import '../entities/basket_line.dart';
import '../entities/kirana_plan.dart';

/// Auto Kirana + Repeat Last Month operations.
///
/// API mapping:
///   generate     -> POST /kirana/generate
///   lastMonth    -> GET  /orders/last
abstract interface class KiranaRepository {
  Future<KiranaPlan> generate(KiranaInput input);
  Future<List<BasketLine>> lastMonthBasket();
}
