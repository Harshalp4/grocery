import '../../domain/entities/support_ticket.dart';
import '../../domain/repositories/support_repository.dart';
import '../datasources/api_client.dart';

/// Support tickets via the backend (`/support`).
class RemoteSupportRepository implements SupportRepository {
  RemoteSupportRepository(this._api);
  final ApiClient _api;

  @override
  Future<List<SupportTicket>> myTickets() async {
    final data = await _api.getJson('/support') as List<dynamic>;
    return data.map((e) => _fromJson(e as Map<String, dynamic>)).toList();
  }

  @override
  Future<SupportTicket> raise(String subject, String message,
      {String? orderId}) async {
    final j = await _api.postJson('/support', {
      'subject': subject,
      'message': message,
      if (orderId != null) 'orderId': orderId,
    }) as Map<String, dynamic>;
    return _fromJson(j);
  }

  SupportTicket _fromJson(Map<String, dynamic> j) => SupportTicket(
        id: j['id'] as String,
        subject: j['subject'] as String,
        message: j['message'] as String,
        status: j['status'] as String? ?? 'open',
        reply: j['reply'] as String?,
        orderId: j['orderId'] as String?,
        createdAt:
            DateTime.tryParse(j['createdAt'] as String? ?? '') ?? DateTime(2026),
      );
}
