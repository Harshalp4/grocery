import '../../domain/entities/customer_order.dart';
import '../../domain/entities/order.dart';
import '../../domain/repositories/order_repository.dart';

/// Offline stand-in (used when useRemote is off).
class MockOrderRepository implements OrderRepository {
  const MockOrderRepository();

  @override
  Future<OrderConfirmation> placeOrder(OrderInput input) async {
    await Future<void>.delayed(const Duration(milliseconds: 400));
    return OrderConfirmation(
      id: 'mock',
      code: 'FF-DEMO-0001',
      status: 'placed',
      paymentStatus: input.paymentMethod == PaymentMethod.cod ? 'pending' : 'paid',
      total: input.total,
      slot: input.slot,
    );
  }

  @override
  Future<List<CustomerOrder>> myOrders() async => const [];

  @override
  Future<CustomerOrder> orderDetail(String id) async => CustomerOrder(
        id: id,
        code: 'FF-DEMO-0001',
        status: 'placed',
        paymentStatus: 'pending',
        paymentMethod: 'cod',
        total: 0,
        slot: '',
        createdAt: DateTime(2026),
        items: const [],
      );

  @override
  Future<void> cancelOrder(String id) async {}

  @override
  Future<void> requestReturn(String id, String reason) async {}

  @override
  Future<List<String>> deliverySlots() async =>
      const ['Tomorrow · 8–11 AM', 'Tomorrow · 5–8 PM', 'Sun · 8–11 AM'];

  @override
  Future<ServiceCheck> checkServiceable(String pincode) async =>
      const ServiceCheck(serviceable: true, etaLabel: 'Next day');
}
