/// A home-screen promo banner (managed from the admin CMS).
class PromoBanner {
  const PromoBanner({
    required this.id,
    required this.title,
    required this.subtitle,
    this.imageUrl,
    this.actionType,
    this.actionValue,
  });

  final String id;
  final String title;
  final String subtitle;
  final String? imageUrl;
  final String? actionType; // category | product | url
  final String? actionValue;
}
