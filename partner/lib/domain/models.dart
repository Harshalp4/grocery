class Partner {
  const Partner({
    required this.id,
    required this.name,
    required this.phone,
    required this.active,
    required this.onDuty,
    required this.mustChangePassword,
    this.vehicleType,
    this.vehicleNumber,
    this.zone,
  });

  final String id;
  final String name;
  final String phone;
  final bool active;
  final bool onDuty;
  final bool mustChangePassword;
  final String? vehicleType;
  final String? vehicleNumber;
  final String? zone;

  factory Partner.fromJson(Map<String, dynamic> j) => Partner(
        id: j['id'] as String,
        name: j['name'] as String? ?? '',
        phone: j['phone'] as String? ?? '',
        active: j['active'] as bool? ?? true,
        onDuty: j['onDuty'] as bool? ?? false,
        mustChangePassword: j['mustChangePassword'] as bool? ?? false,
        vehicleType: j['vehicleType'] as String?,
        vehicleNumber: j['vehicleNumber'] as String?,
        zone: j['zone'] as String?,
      );

  Partner copyWith({bool? onDuty}) => Partner(
        id: id,
        name: name,
        phone: phone,
        active: active,
        onDuty: onDuty ?? this.onDuty,
        mustChangePassword: mustChangePassword,
        vehicleType: vehicleType,
        vehicleNumber: vehicleNumber,
        zone: zone,
      );
}

class OrderItem {
  const OrderItem({required this.name, required this.quantity, required this.qty, required this.priceLabel});
  final String name;
  final String quantity;
  final int qty;
  final String priceLabel;

  factory OrderItem.fromJson(Map<String, dynamic> j) => OrderItem(
        name: j['name'] as String? ?? '',
        quantity: j['quantity'] as String? ?? '',
        qty: (j['qty'] as num?)?.toInt() ?? 1,
        priceLabel: j['priceLabel'] as String? ?? '',
      );
}

/// Covers both the list card and the full detail shape.
class DeliveryOrder {
  const DeliveryOrder({
    required this.id,
    required this.code,
    required this.status,
    required this.customerName,
    required this.address,
    required this.slot,
    required this.paymentMethod,
    required this.codToCollect,
    required this.total,
    required this.itemCount,
    this.phone,
    this.items = const [],
    this.destLat,
    this.destLng,
    this.pickedUpAt,
    this.deliveredAt,
    this.failureReason,
  });

  final String id;
  final String code;
  final String status;
  final String customerName;
  final String address;
  final String slot;
  final String paymentMethod;
  final int codToCollect;
  final int total;
  final int itemCount;
  final String? phone;
  final List<OrderItem> items;
  final double? destLat;
  final double? destLng;
  final String? pickedUpAt;
  final String? deliveredAt;
  final String? failureReason;

  bool get isCod => paymentMethod == 'cod';

  factory DeliveryOrder.fromJson(Map<String, dynamic> j) {
    final items = (j['items'] as List<dynamic>?)
            ?.map((e) => OrderItem.fromJson(e as Map<String, dynamic>))
            .toList() ??
        const <OrderItem>[];
    final dest = j['dest'] as Map<String, dynamic>?;
    return DeliveryOrder(
      id: j['id'] as String,
      code: j['code'] as String,
      status: j['status'] as String? ?? 'packed',
      customerName: j['customerName'] as String? ?? '',
      phone: j['phone'] as String?,
      address: (j['address'] ?? j['area'] ?? '') as String,
      slot: j['slot'] as String? ?? '',
      paymentMethod: j['paymentMethod'] as String? ?? 'cod',
      codToCollect: (j['codToCollect'] as num?)?.toInt() ?? 0,
      total: (j['total'] as num?)?.toInt() ?? 0,
      itemCount: (j['itemCount'] as num?)?.toInt() ??
          items.fold<int>(0, (s, i) => s + i.qty),
      items: items,
      destLat: (dest?['lat'] as num?)?.toDouble(),
      destLng: (dest?['lng'] as num?)?.toDouble(),
      pickedUpAt: j['pickedUpAt'] as String?,
      deliveredAt: j['deliveredAt'] as String?,
      failureReason: j['failureReason'] as String?,
    );
  }
}

class DeliverySummary {
  const DeliverySummary({required this.delivered, required this.failed, required this.codCollected});
  final int delivered;
  final int failed;
  final int codCollected;

  factory DeliverySummary.fromJson(Map<String, dynamic> j) => DeliverySummary(
        delivered: (j['delivered'] as num?)?.toInt() ?? 0,
        failed: (j['failed'] as num?)?.toInt() ?? 0,
        codCollected: (j['codCollected'] as num?)?.toInt() ?? 0,
      );
}

class LoginResult {
  const LoginResult({required this.token, required this.partner, required this.mustChangePassword});
  final String token;
  final Partner partner;
  final bool mustChangePassword;
}
