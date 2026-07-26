import '../../domain/entities/basket_line.dart';
import '../../domain/repositories/cart_repository.dart';

/// Offline stand-in (used when useRemote is off): no server persistence.
class MockCartRepository implements CartRepository {
  const MockCartRepository();

  @override
  Future<List<BasketLine>> load() async => const [];

  @override
  Future<void> replace(List<BasketLine> lines) async {}
}
