import '../../domain/entities/app_notification.dart';
import '../../domain/repositories/notification_repository.dart';

/// Offline stand-in (used when useRemote is off).
class MockNotificationRepository implements NotificationRepository {
  const MockNotificationRepository();

  @override
  Future<List<AppNotification>> list() async => const [];

  @override
  Future<int> unreadCount() async => 0;

  @override
  Future<void> markAllRead() async {}

  @override
  Future<void> registerToken(String token, {String platform = 'android'}) async {}
}
