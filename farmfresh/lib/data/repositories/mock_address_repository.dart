import '../../domain/entities/address.dart';
import '../../domain/repositories/address_repository.dart';

/// Offline stand-in (used when useRemote is off).
class MockAddressRepository implements AddressRepository {
  const MockAddressRepository();

  @override
  Future<List<Address>> list() async => const [];

  @override
  Future<Address> add(AddressInput input) async => Address(
        id: 'mock',
        label: input.label,
        line: input.line,
        area: input.area,
        city: input.city,
        pincode: input.pincode,
        isDefault: true,
      );

  @override
  Future<Address> update(String id, AddressInput input) async => Address(
        id: id,
        label: input.label,
        line: input.line,
        area: input.area,
        city: input.city,
        pincode: input.pincode,
        isDefault: input.isDefault,
      );

  @override
  Future<void> remove(String id) async {}
}
