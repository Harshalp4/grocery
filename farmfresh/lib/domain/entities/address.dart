/// A saved delivery address.
class Address {
  const Address({
    required this.id,
    required this.label,
    required this.line,
    this.area,
    this.city,
    this.pincode,
    this.isDefault = false,
  });

  final String id;
  final String label;
  final String line;
  final String? area;
  final String? city;
  final String? pincode;
  final bool isDefault;

  /// Full one-line address for display and orders.
  String get formatted => [
        line,
        if (area?.isNotEmpty == true) area,
        if (city?.isNotEmpty == true) city,
        if (pincode?.isNotEmpty == true) pincode,
      ].join(', ');
}

/// Input for creating/updating an address.
class AddressInput {
  const AddressInput({
    required this.label,
    required this.line,
    this.area,
    this.city,
    this.pincode,
    this.isDefault = false,
  });

  final String label;
  final String line;
  final String? area;
  final String? city;
  final String? pincode;
  final bool isDefault;
}
