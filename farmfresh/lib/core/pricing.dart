/// Single source of truth for order pricing rules shared by the cart and the
/// checkout screens, so the two can never drift apart (they used to: the cart
/// charged ₹40 delivery while checkout charged ₹0, showing different totals).
abstract class Pricing {
  /// Orders at or above this item subtotal (₹) ship free.
  static const int freeDeliveryOver = 999;

  /// Flat delivery fee (₹) applied below the free-delivery threshold.
  static const int deliveryFeeFlat = 40;

  /// Delivery fee for a given item subtotal. Free once the subtotal reaches
  /// [freeDeliveryOver].
  static int deliveryFee(int itemTotal) =>
      itemTotal >= freeDeliveryOver ? 0 : deliveryFeeFlat;

  /// Final payable = items − coupon discount + delivery fee (never below 0).
  static int payable(int itemTotal, int discount) {
    final total = itemTotal - discount + deliveryFee(itemTotal);
    return total < 0 ? 0 : total;
  }
}
