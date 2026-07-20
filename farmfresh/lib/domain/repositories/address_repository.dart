import '../entities/address.dart';

/// Saved delivery addresses for the signed-in user.
///
/// API mapping: GET/POST/PUT/DELETE /addresses (all require a customer token).
abstract interface class AddressRepository {
  Future<List<Address>> list();
  Future<Address> add(AddressInput input);
  Future<Address> update(String id, AddressInput input);
  Future<void> remove(String id);
}
