import '../entities/support_ticket.dart';

/// Customer support tickets.
///
/// API mapping:
///   myTickets -> GET  /support
///   raise     -> POST /support
abstract interface class SupportRepository {
  Future<List<SupportTicket>> myTickets();
  Future<SupportTicket> raise(String subject, String message, {String? orderId});
}
