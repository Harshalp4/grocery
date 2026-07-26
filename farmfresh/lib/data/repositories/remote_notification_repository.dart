import '../../domain/entities/app_notification.dart';
import '../../domain/repositories/notification_repository.dart';
import '../datasources/api_client.dart';

/// Notification inbox via the backend (`/notifications`).
class RemoteNotificationRepository implements NotificationRepository {
  RemoteNotificationRepository(this._api);
  final ApiClient _api;

  @override
  Future<List<AppNotification>> list() async {
    final data = await _api.getJson('/notifications') as List<dynamic>;
    return data.map((e) => _fromJson(e as Map<String, dynamic>)).toList();
  }

  @override
  Future<int> unreadCount() async {
    final j =
        await _api.getJson('/notifications/unread-count') as Map<String, dynamic>;
    return (j['count'] as num?)?.toInt() ?? 0;
  }

  @override
  Future<void> markAllRead() =>
      _api.postJson('/notifications/read-all', const <String, dynamic>{});

  AppNotification _fromJson(Map<String, dynamic> j) => AppNotification(
        id: j['id'] as String,
        title: j['title'] as String,
        body: j['body'] as String,
        type: j['type'] as String? ?? 'system',
        orderId: j['orderId'] as String?,
        read: j['read'] as bool? ?? false,
        createdAt:
            DateTime.tryParse(j['createdAt'] as String? ?? '') ?? DateTime(2026),
      );
}
