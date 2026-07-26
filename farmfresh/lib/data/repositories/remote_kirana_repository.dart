import '../../domain/entities/basket_line.dart';
import '../../domain/entities/kirana_plan.dart';
import '../../domain/repositories/kirana_repository.dart';
import '../datasources/api_client.dart';

/// Auto Kirana + Repeat Last Month backed by the HTTP API.
class RemoteKiranaRepository implements KiranaRepository {
  RemoteKiranaRepository(this._api);
  final ApiClient _api;

  @override
  Future<KiranaPlan> generate(KiranaInput input) async {
    final j = await _api.postJson('/kirana/generate', {
      'members': input.members,
      'adults': input.adults,
      'children': input.children,
      'budget': input.budget,
      'preference': input.preference,
      'usage': input.usage,
    }) as Map<String, dynamic>;

    return KiranaPlan(
      title: j['title'] as String,
      subtitle: j['subtitle'] as String,
      lines: (j['lines'] as List<dynamic>)
          .map((e) => _line(e as Map<String, dynamic>))
          .toList(),
      estimatedTotal: (j['estimatedTotal'] as num).toInt(),
    );
  }

  @override
  Future<List<BasketLine>> lastMonthBasket() async {
    final data = await _api.getJson('/orders/last') as List<dynamic>;
    return data.map((e) => _line(e as Map<String, dynamic>)).toList();
  }

  BasketLine _line(Map<String, dynamic> j) => BasketLine(
        name: j['name'] as String,
        quantity: j['quantity'] as String,
        priceLabel: j['priceLabel'] as String,
      );
}
