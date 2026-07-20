import '../../domain/entities/address.dart';
import '../../domain/repositories/address_repository.dart';
import '../datasources/api_client.dart';

/// Address book via the backend (`/addresses`, customer-authed).
class RemoteAddressRepository implements AddressRepository {
  RemoteAddressRepository(this._api);
  final ApiClient _api;

  @override
  Future<List<Address>> list() async {
    final data = await _api.getJson('/addresses') as List<dynamic>;
    return data.map((e) => _address(e as Map<String, dynamic>)).toList();
  }

  @override
  Future<Address> add(AddressInput input) async {
    final j = await _api.postJson('/addresses', _body(input))
        as Map<String, dynamic>;
    return _address(j);
  }

  @override
  Future<Address> update(String id, AddressInput input) async {
    final j = await _api.putJson('/addresses/$id', _body(input))
        as Map<String, dynamic>;
    return _address(j);
  }

  @override
  Future<void> remove(String id) => _api.deleteJson('/addresses/$id');

  Map<String, dynamic> _body(AddressInput i) => {
        'label': i.label,
        'line': i.line,
        'area': i.area,
        'city': i.city,
        'pincode': i.pincode,
        'isDefault': i.isDefault,
      };

  Address _address(Map<String, dynamic> j) => Address(
        id: j['id'] as String,
        label: j['label'] as String? ?? 'Home',
        line: j['line'] as String,
        area: j['area'] as String?,
        city: j['city'] as String?,
        pincode: j['pincode'] as String?,
        isDefault: j['isDefault'] as bool? ?? false,
      );
}
