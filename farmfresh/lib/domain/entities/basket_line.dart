/// A single line in a generated/saved list (Auto Kirana, Repeat Last Month)
/// or the cart: an item name, a quantity label and a price label.
///
/// [productId]/[variantId] are set when the line came from a real catalog
/// product, so the backend can decrement stock on checkout.
class BasketLine {
  const BasketLine({
    required this.name,
    required this.quantity,
    required this.priceLabel,
    this.productId,
    this.variantId,
    this.qty = 1,
  });

  final String name;
  final String quantity;
  final String priceLabel;
  final String? productId;
  final String? variantId;

  /// Unit count of this line (for cart quantity steppers).
  final int qty;

  BasketLine copyWith({int? qty}) => BasketLine(
        name: name,
        quantity: quantity,
        priceLabel: priceLabel,
        productId: productId,
        variantId: variantId,
        qty: qty ?? this.qty,
      );
}
