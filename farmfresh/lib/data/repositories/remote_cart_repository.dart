import '../../domain/entities/basket_line.dart';
import '../../domain/repositories/cart_repository.dart';
import '../datasources/api_client.dart';

/// Persistent cart via the backend (`/cart`).
class RemoteCartRepository implements CartRepository {
  RemoteCartRepository(this._api);
  final ApiClient _api;

  @override
  Future<List<BasketLine>> load() async {
    final data = await _api.getJson('/cart') as List<dynamic>;
    return data.map((e) => _line(e as Map<String, dynamic>)).toList();
  }

  @override
  Future<void> replace(List<BasketLine> lines) async {
    await _api.putJson('/cart', {
      'items': lines
          .map((l) => {
                'name': l.name,
                'quantity': l.quantity,
                'priceLabel': l.priceLabel,
                'price': _rupees(l.priceLabel),
                'qty': l.qty,
                if (l.productId != null) 'productId': l.productId,
                if (l.variantId != null) 'variantId': l.variantId,
              })
          .toList(),
    });
  }

  BasketLine _line(Map<String, dynamic> j) => BasketLine(
        name: j['name'] as String? ?? '',
        quantity: j['quantity'] as String? ?? '',
        priceLabel: j['priceLabel'] as String? ?? '',
        qty: (j['qty'] as num?)?.toInt() ?? 1,
        productId: j['productId'] as String?,
        variantId: j['variantId'] as String?,
      );

  int _rupees(String label) {
    final d = label.replaceAll(RegExp(r'[^0-9]'), '');
    return d.isEmpty ? 0 : int.parse(d);
  }
}
