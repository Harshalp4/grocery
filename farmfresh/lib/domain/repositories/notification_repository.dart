import '../entities/app_notification.dart';

/// The customer's notification inbox.
///
/// API mapping:
///   list         -> GET  /notifications
///   unreadCount  -> GET  /notifications/unread-count
///   markAllRead  -> POST /notifications/read-all
abstract interface class NotificationRepository {
  Future<List<AppNotification>> list();
  Future<int> unreadCount();
  Future<void> markAllRead();

  /// Register/refresh this device's FCM token (POST /notifications/token).
  Future<void> registerToken(String token, {String platform});
}
