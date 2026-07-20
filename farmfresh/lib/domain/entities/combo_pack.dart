/// Type of combo pack, used for the tabbed grouping on the Combos screen.
enum ComboType { family, health, festival }

/// A fixed-price bundle (Family / Health / Festival pack).
class ComboPack {
  const ComboPack({
    required this.id,
    required this.name,
    required this.type,
    required this.price,
    required this.size,
    required this.duration,
    required this.items,
    required this.savingsNote,
  });

  final String id;
  final String name;
  final ComboType type;
  final int price;
  final String size;
  final String duration;

  /// Comma-separated contents, e.g. "Rice 5kg, Atta 5kg, …".
  final String items;
  final String savingsNote;

  List<String> get itemList =>
      items.split(',').map((e) => e.trim()).where((e) => e.isNotEmpty).toList();
}
