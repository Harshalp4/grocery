/// A monthly subscription plan option.
class SubscriptionPlan {
  const SubscriptionPlan({
    required this.id,
    required this.name,
    required this.description,
    required this.priceLabel,
  });

  final String id;
  final String name;
  final String description;
  final String priceLabel;
}
