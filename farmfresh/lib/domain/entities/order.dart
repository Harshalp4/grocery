import 'basket_line.dart';

enum PaymentMethod { upi, card, cod }

/// What the app sends to place an order (guest checkout — no auth yet).
class OrderInput {
  const OrderInput({
    required this.customerName,
    required this.phone,
    required this.address,
    required this.slot,
    required this.paymentMethod,
    required this.items,
    required this.itemTotal,
    required this.savings,
    required this.deliveryFee,
    required this.total,
  });

  final String customerName;
  final String phone;
  final String address;
  final String slot;
  final PaymentMethod paymentMethod;
  final List<BasketLine> items;
  final int itemTotal;
  final int savings;
  final int deliveryFee;
  final int total;
}

/// The backend's confirmation after an order is placed.
class OrderConfirmation {
  const OrderConfirmation({
    required this.id,
    required this.code,
    required this.status,
    required this.paymentStatus,
    required this.total,
    required this.slot,
  });

  final String id;
  final String code;
  final String status;
  final String paymentStatus;
  final int total;
  final String slot;
}
