/// A customer support ticket.
class SupportTicket {
  const SupportTicket({
    required this.id,
    required this.subject,
    required this.message,
    required this.status,
    required this.createdAt,
    this.reply,
    this.orderId,
  });

  final String id;
  final String subject;
  final String message;
  final String status; // open | resolved | closed
  final DateTime createdAt;
  final String? reply;
  final String? orderId;
}
