import '../../domain/entities/basket_line.dart';
import '../../domain/entities/customer_order.dart';
import '../../domain/entities/order.dart';
import '../../domain/repositories/order_repository.dart';
import '../datasources/api_client.dart';

/// Orders via the backend (`POST /orders`, `GET /auth/orders`, `GET /slots`).
class RemoteOrderRepository implements OrderRepository {
  RemoteOrderRepository(this._api);
  final ApiClient _api;

  @override
  Future<OrderConfirmation> placeOrder(OrderInput input) async {
    final j = await _api.postJson('/orders', {
      'customerName': input.customerName,
      'phone': input.phone,
      'address': input.address,
      'slot': input.slot,
      'paymentMethod': input.paymentMethod.name,
      'items': input.items
          .map((l) => {
                'name': l.name,
                'quantity': l.quantity,
                'priceLabel': l.priceLabel,
                'price': _rupees(l.priceLabel),
                if (l.productId != null) 'productId': l.productId,
                if (l.variantId != null) 'variantId': l.variantId,
              })
          .toList(),
      'itemTotal': input.itemTotal,
      'savings': input.savings,
      'deliveryFee': input.deliveryFee,
      'total': input.total,
    }) as Map<String, dynamic>;

    return OrderConfirmation(
      id: j['id'] as String,
      code: j['code'] as String,
      status: j['status'] as String,
      paymentStatus: j['paymentStatus'] as String,
      total: (j['total'] as num).toInt(),
      slot: j['slot'] as String,
    );
  }

  @override
  Future<List<CustomerOrder>> myOrders() async {
    final data = await _api.getJson('/auth/orders') as List<dynamic>;
    return data.map((e) => _order(e as Map<String, dynamic>)).toList();
  }

  @override
  Future<CustomerOrder> orderDetail(String id) async {
    final j = await _api.getJson('/auth/orders/$id') as Map<String, dynamic>;
    return _order(j);
  }

  @override
  Future<void> cancelOrder(String id) =>
      _api.postJson('/auth/orders/$id/cancel', const {});

  @override
  Future<void> requestReturn(String id, String reason) =>
      _api.postJson('/auth/orders/$id/return', {'reason': reason});

  @override
  Future<List<String>> deliverySlots() async {
    final data = await _api.getJson('/slots') as List<dynamic>;
    return data
        .map((e) => (e as Map<String, dynamic>)['label'] as String)
        .toList();
  }

  @override
  Future<ServiceCheck> checkServiceable(String pincode) async {
    final j = await _api.getJson('/serviceable', {'pincode': pincode})
        as Map<String, dynamic>;
    return ServiceCheck(
      serviceable: j['serviceable'] as bool? ?? true,
      etaLabel: j['etaLabel'] as String?,
    );
  }

  CustomerOrder _order(Map<String, dynamic> j) {
    final partner = j['deliveryPartner'] as Map<String, dynamic>?;
    final ret = j['returnRequest'] as Map<String, dynamic>?;
    return CustomerOrder(
      id: j['id'] as String,
      code: j['code'] as String,
      status: j['status'] as String,
      paymentStatus: j['paymentStatus'] as String,
      paymentMethod: j['paymentMethod'] as String,
      total: (j['total'] as num).toInt(),
      slot: j['slot'] as String,
      eta: j['eta'] as String?,
      partnerName: partner?['name'] as String?,
      returnStatus: ret?['status'] as String?,
      createdAt:
          DateTime.tryParse(j['createdAt'] as String? ?? '') ?? DateTime(2026),
      items: ((j['items'] as List<dynamic>?) ?? [])
          .map((e) => BasketLine(
                name: (e as Map<String, dynamic>)['name'] as String,
                quantity: e['quantity'] as String? ?? '',
                priceLabel: e['priceLabel'] as String? ?? '',
              ))
          .toList(),
      events: ((j['events'] as List<dynamic>?) ?? [])
          .map((e) => OrderEvent(
                status: (e as Map<String, dynamic>)['status'] as String,
                note: e['note'] as String?,
                createdAt: DateTime.tryParse(e['createdAt'] as String? ?? '') ??
                    DateTime(2026),
              ))
          .toList(),
    );
  }

  int _rupees(String label) {
    final digits = label.replaceAll(RegExp(r'[^0-9]'), '');
    return digits.isEmpty ? 0 : int.parse(digits);
  }
}
