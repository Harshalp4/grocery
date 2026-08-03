import 'basket_line.dart';

String orderStatusLabel(String status) => switch (status) {
      'placed' => 'Placed',
      'confirmed' => 'Confirmed',
      'packed' => 'Packed',
      'picked_up' => 'Picked up',
      'out_for_delivery' => 'Out for delivery',
      'delivered' => 'Delivered',
      'failed' => 'Delivery failed',
      'cancelled' => 'Cancelled',
      _ => status,
    };

/// One step in an order's tracking timeline.
class OrderEvent {
  const OrderEvent({required this.status, this.note, required this.createdAt});
  final String status;
  final String? note;
  final DateTime createdAt;
  String get label => orderStatusLabel(status);
}

/// An order belonging to the signed-in user (list + detail).
class CustomerOrder {
  const CustomerOrder({
    required this.id,
    required this.code,
    required this.status,
    required this.paymentStatus,
    required this.paymentMethod,
    required this.total,
    this.itemTotal = 0,
    this.savings = 0,
    this.deliveryFee = 0,
    this.couponCode,
    required this.slot,
    required this.createdAt,
    required this.items,
    this.eta,
    this.partnerName,
    this.returnStatus,
    this.events = const [],
    this.destLat,
    this.destLng,
    this.partnerLat,
    this.partnerLng,
    this.partnerLocationAt,
    this.deliveryOtp,
  });

  final String id;
  final String code;
  final String status;
  final String paymentStatus;
  final String paymentMethod;
  final int total;
  final int itemTotal;
  final int savings;
  final int deliveryFee;
  final String? couponCode;
  final String slot;
  final DateTime createdAt;
  final List<BasketLine> items;
  final String? eta;
  final String? partnerName;
  final String? returnStatus; // requested | approved | rejected | refunded
  final List<OrderEvent> events;
  final double? destLat;
  final double? destLng;
  final double? partnerLat;
  final double? partnerLng;
  final DateTime? partnerLocationAt;

  /// 4-digit code the customer shares with the rider to confirm delivery.
  /// Minted server-side at out-for-delivery; null until then / after delivery.
  final String? deliveryOtp;

  String get statusLabel => orderStatusLabel(status);

  /// Show the delivery code while the rider is out for delivery and it exists.
  bool get showDeliveryCode =>
      status == 'out_for_delivery' &&
      deliveryOtp != null &&
      deliveryOtp!.isNotEmpty;
  bool get isCancellable => status == 'placed' || status == 'confirmed';
  bool get canReport => status == 'delivered' && returnStatus == null;

  /// The rider is actively delivering and we have a fresh-enough fix to map.
  bool get hasLiveRider =>
      status == 'out_for_delivery' && partnerLat != null && partnerLng != null;
}

/// Result of a serviceability check for a pincode.
class ServiceCheck {
  const ServiceCheck({required this.serviceable, this.etaLabel});
  final bool serviceable;
  final String? etaLabel;
}
