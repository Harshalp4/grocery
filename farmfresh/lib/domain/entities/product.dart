/// A pack-size variant of a product (500 g / 1 kg / 5 kg …).
class ProductVariant {
  const ProductVariant({
    required this.id,
    required this.label,
    required this.price,
    required this.marketPrice,
    required this.stock,
    required this.inStock,
  });

  final String id;
  final String label;
  final int price;
  final int marketPrice;
  final int stock;
  final bool inStock;

  int get savingsPercent => marketPrice <= 0
      ? 0
      : (((marketPrice - price) / marketPrice) * 100).round();
}

/// A sellable grocery product. Prices are in whole rupees.
class Product {
  const Product({
    required this.id,
    required this.name,
    required this.source,
    required this.packedDate,
    required this.price,
    required this.marketPrice,
    required this.grade,
    this.tags = const <String>[],
    this.harvestMonth,
    this.packSize,
    this.nutrition = const <String, String>{},
    this.imageUrl,
    this.stock = 99,
    this.inStock = true,
    this.variants = const <ProductVariant>[],
  });

  final String id;
  final String name;
  final String source;
  final String packedDate;
  final int price;
  final int marketPrice;
  final String grade;

  /// Highlight tags: `best`, `fresh`, `premium`.
  final List<String> tags;
  final String? harvestMonth;
  final String? packSize;
  final Map<String, String> nutrition;

  /// Relative image path from the API (e.g. `/uploads/x.png`), or null.
  final String? imageUrl;
  final int stock;
  final bool inStock;
  final List<ProductVariant> variants;

  bool get hasVariants => variants.isNotEmpty;

  /// The variant to pre-select / add by default (first in-stock, else first).
  ProductVariant? get defaultVariant {
    if (variants.isEmpty) return null;
    return variants.firstWhere((v) => v.inStock, orElse: () => variants.first);
  }

  /// Lowest variant price (for the "from ₹X" card price), else the base price.
  int get displayPrice =>
      hasVariants ? variants.map((v) => v.price).reduce((a, b) => a < b ? a : b) : price;

  int get displayMarketPrice {
    if (!hasVariants) return marketPrice;
    final v = variants.reduce((a, b) => a.price < b.price ? a : b);
    return v.marketPrice;
  }

  /// Percentage saved vs. market price, rounded.
  int get savingsPercent => displayMarketPrice <= 0
      ? 0
      : (((displayMarketPrice - displayPrice) / displayMarketPrice) * 100).round();
}
