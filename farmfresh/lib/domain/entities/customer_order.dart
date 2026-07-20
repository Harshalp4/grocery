import 'basket_line.dart';

String orderStatusLabel(String status) => switch (status) {
      'placed' => 'Placed',
      'confirmed' => 'Confirmed',
      'packed' => 'Packed',
      'out_for_delivery' => 'Out for delivery',
      'delivered' => 'Delivered',
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
    required this.slot,
    required this.createdAt,
    required this.items,
    this.eta,
    this.partnerName,
    this.returnStatus,
    this.events = const [],
  });

  final String id;
  final String code;
  final String status;
  final String paymentStatus;
  final String paymentMethod;
  final int total;
  final String slot;
  final DateTime createdAt;
  final List<BasketLine> items;
  final String? eta;
  final String? partnerName;
  final String? returnStatus; // requested | approved | rejected | refunded
  final List<OrderEvent> events;

  String get statusLabel => orderStatusLabel(status);
  bool get isCancellable => status == 'placed' || status == 'confirmed';
  bool get canReport => status == 'delivered' && returnStatus == null;
}

/// Result of a serviceability check for a pincode.
class ServiceCheck {
  const ServiceCheck({required this.serviceable, this.etaLabel});
  final bool serviceable;
  final String? etaLabel;
}
