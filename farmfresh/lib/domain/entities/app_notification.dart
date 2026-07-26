/// An item in the customer's notification inbox.
class AppNotification {
  const AppNotification({
    required this.id,
    required this.title,
    required this.body,
    required this.type,
    required this.read,
    required this.createdAt,
    this.orderId,
  });

  final String id;
  final String title;
  final String body;
  final String type; // order | promo | system
  final bool read;
  final DateTime createdAt;
  final String? orderId;
}
