import 'basket_line.dart';

/// User inputs for the Auto Kirana generator (flagship feature).
class KiranaInput {
  const KiranaInput({
    required this.members,
    required this.adults,
    required this.children,
    required this.budget,
    required this.preference,
    required this.usage,
  });

  final String members;
  final int adults;
  final int children;
  final int budget;
  final String preference;
  final String usage;
}

/// The generated monthly basket for a household.
class KiranaPlan {
  const KiranaPlan({
    required this.title,
    required this.subtitle,
    required this.lines,
    required this.estimatedTotal,
  });

  final String title;
  final String subtitle;
  final List<BasketLine> lines;
  final int estimatedTotal;
}
