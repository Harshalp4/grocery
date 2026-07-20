import '../entities/customer_order.dart';
import '../entities/order.dart';

/// Placing customer orders + reading the user's order history and slots.
///
/// API mapping:
///   placeOrder     -> POST /orders
///   myOrders       -> GET /auth/orders (requires a customer token)
///   deliverySlots  -> GET /slots
abstract interface class OrderRepository {
  Future<OrderConfirmation> placeOrder(OrderInput input);
  Future<List<CustomerOrder>> myOrders();
  Future<CustomerOrder> orderDetail(String id);
  Future<void> cancelOrder(String id);
  Future<void> requestReturn(String id, String reason);
  Future<List<String>> deliverySlots();
  Future<ServiceCheck> checkServiceable(String pincode);
}
