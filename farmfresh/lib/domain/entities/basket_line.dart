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
  });

  final String name;
  final String quantity;
  final String priceLabel;
  final String? productId;
  final String? variantId;
}
