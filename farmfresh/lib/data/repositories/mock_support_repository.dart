import '../../domain/entities/support_ticket.dart';
import '../../domain/repositories/support_repository.dart';

/// Offline stand-in (used when useRemote is off).
class MockSupportRepository implements SupportRepository {
  const MockSupportRepository();

  @override
  Future<List<SupportTicket>> myTickets() async => const [];

  @override
  Future<SupportTicket> raise(String subject, String message,
          {String? orderId}) async =>
      SupportTicket(
        id: 'mock',
        subject: subject,
        message: message,
        status: 'open',
        createdAt: DateTime(2026),
      );
}
