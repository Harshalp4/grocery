import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/entities/basket_line.dart';
import '../../domain/entities/product.dart';
import 'auth_controller.dart';
import 'repository_providers.dart';

/// App-wide cart state. Holds the line items and derives the badge count.
///
/// Kept intentionally simple (matches the wireframe's behaviour) but real:
/// adding a product/basket updates the badge everywhere via Riverpod.
class CartState {
  const CartState({this.lines = const [], this.couponCode, this.discount = 0});

  final List<BasketLine> lines;
  final String? couponCode;
  final int discount;

  int get count => lines.fold<int>(0, (sum, l) => sum + l.qty);

  int get itemTotal =>
      lines.fold<int>(0, (sum, l) => sum + _rupees(l.priceLabel) * l.qty);

  /// Payable = items − coupon discount (delivery handled at checkout).
  int get payable => (itemTotal - discount).clamp(0, itemTotal);

  CartState copyWith({
    List<BasketLine>? lines,
    String? couponCode,
    int? discount,
    bool clearCoupon = false,
  }) =>
      CartState(
        lines: lines ?? this.lines,
        couponCode: clearCoupon ? null : (couponCode ?? this.couponCode),
        discount: clearCoupon ? 0 : (discount ?? this.discount),
      );

  static int _rupees(String label) {
    final digits = label.replaceAll(RegExp(r'[^0-9]'), '');
    return digits.isEmpty ? 0 : int.parse(digits);
  }
}

class CartController extends Notifier<CartState> {
  @override
  CartState build() => const CartState(); // starts empty

  bool get _authed => ref.read(authControllerProvider).isAuthenticated;

  /// Sync with the server cart (call after login / on app start). If the local
  /// cart already has items (guest added them before signing in), push those up;
  /// otherwise restore the saved server cart.
  Future<void> loadFromServer() async {
    if (!_authed) return;
    try {
      final repo = ref.read(cartRepositoryProvider);
      if (state.lines.isNotEmpty) {
        await repo.replace(state.lines);
      } else {
        state = CartState(lines: await repo.load());
      }
    } catch (_) {
      // Keep the local cart if the server is unreachable.
    }
  }

  // Fire-and-forget push of the whole cart to the server (signed-in only).
  void _sync() {
    if (!_authed) return;
    unawaited(ref.read(cartRepositoryProvider).replace(state.lines).catchError((_) {}));
  }

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

  // Cart mutations clear any applied coupon (its discount may no longer be valid).
  void addLines(List<BasketLine> lines) {
    state = state.copyWith(lines: [...state.lines, ...lines], clearCoupon: true);
    _sync();
  }

  void removeAt(int index) {
    final next = [...state.lines]..removeAt(index);
    state = state.copyWith(lines: next, clearCoupon: true);
    _sync();
  }

  void clear() {
    state = const CartState();
    _sync();
  }

  /// Apply a server-validated coupon (code + computed discount).
  void applyCoupon(String code, int discount) {
    state = state.copyWith(couponCode: code, discount: discount);
  }

  void clearCoupon() => state = state.copyWith(clearCoupon: true);

  /// Set a line's quantity (0 or less removes it).
  void setQty(int index, int qty) {
    if (index < 0 || index >= state.lines.length) return;
    final lines = [...state.lines];
    if (qty <= 0) {
      lines.removeAt(index);
    } else {
      lines[index] = lines[index].copyWith(qty: qty);
    }
    state = state.copyWith(lines: lines, clearCoupon: true);
    _sync();
  }

  // Same catalog product+variant (or same name+pack for non-catalog lines) merges.
  bool _sameItem(BasketLine a, BasketLine b) {
    if (a.productId != null || b.productId != null) {
      return a.productId == b.productId && a.variantId == b.variantId;
    }
    return a.name == b.name && a.quantity == b.quantity;
  }

  void _add(BasketLine line) {
    final lines = [...state.lines];
    final i = lines.indexWhere((l) => _sameItem(l, line));
    if (i >= 0) {
      lines[i] = lines[i].copyWith(qty: lines[i].qty + line.qty);
    } else {
      lines.add(line);
    }
    state = state.copyWith(lines: lines, clearCoupon: true);
    _sync();
  }
}

final cartControllerProvider =
    NotifierProvider<CartController, CartState>(CartController.new);

/// Convenience selector for the bottom-nav badge.
final cartCountProvider = Provider<int>(
  (ref) => ref.watch(cartControllerProvider).count,
);
