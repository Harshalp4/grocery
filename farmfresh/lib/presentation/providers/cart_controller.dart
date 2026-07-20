import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/entities/basket_line.dart';
import '../../domain/entities/product.dart';
import '../../data/datasources/mock_data.dart';

/// App-wide cart state. Holds the line items and derives the badge count.
///
/// Kept intentionally simple (matches the wireframe's behaviour) but real:
/// adding a product/basket updates the badge everywhere via Riverpod.
class CartState {
  const CartState({this.lines = const []});

  final List<BasketLine> lines;

  int get count => lines.length;

  int get itemTotal => lines.fold<int>(0, (sum, l) => sum + _rupees(l.priceLabel));

  CartState copyWith({List<BasketLine>? lines}) =>
      CartState(lines: lines ?? this.lines);

  static int _rupees(String label) {
    final digits = label.replaceAll(RegExp(r'[^0-9]'), '');
    return digits.isEmpty ? 0 : int.parse(digits);
  }
}

class CartController extends Notifier<CartState> {
  @override
  CartState build() => const CartState(lines: MockData.starterCart);

  /// Add a product, optionally a specific pack-size [variant].
  void addProduct(Product p, {ProductVariant? variant}) {
    if (variant != null) {
      _add(BasketLine(
        name: p.name,
        quantity: variant.label,
        priceLabel: '₹${variant.price}',
        productId: p.id,
        variantId: variant.id,
      ));
    } else {
      _add(BasketLine(
        name: p.name,
        quantity: p.packSize ?? '1 unit',
        priceLabel: '₹${p.price}',
        productId: p.id,
      ));
    }
  }

  void addLine(BasketLine line) => _add(line);

  void addLines(List<BasketLine> lines) {
    state = state.copyWith(lines: [...state.lines, ...lines]);
  }

  void removeAt(int index) {
    final next = [...state.lines]..removeAt(index);
    state = state.copyWith(lines: next);
  }

  void clear() => state = const CartState(lines: []);

  void _add(BasketLine line) {
    state = state.copyWith(lines: [...state.lines, line]);
  }
}

final cartControllerProvider =
    NotifierProvider<CartController, CartState>(CartController.new);

/// Convenience selector for the bottom-nav badge.
final cartCountProvider = Provider<int>(
  (ref) => ref.watch(cartControllerProvider).count,
);
