import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';

/// Thin wrapper around Firebase Cloud Messaging.
///
/// The whole thing is guarded: with the shipped placeholder google-services.json
/// (or on web/desktop), Firebase init or token retrieval fails gracefully and
/// push simply stays off — the in-app notification inbox still works. Drop in a
/// real google-services.json (see PUSH_NOTIFICATIONS.md) to enable it.
abstract class PushService {
  static bool _ready = false;

  /// Call once at startup. Never throws.
  static Future<void> init() async {
    try {
      await Firebase.initializeApp();
      _ready = true;
    } catch (e) {
      _ready = false;
      debugPrint('Push disabled (no valid Firebase config): $e');
    }
  }

  /// The device FCM token, or null when push is unavailable.
  static Future<String?> deviceToken() async {
    if (!_ready) return null;
    try {
      final messaging = FirebaseMessaging.instance;
      await messaging.requestPermission();
      return await messaging.getToken();
    } catch (e) {
      debugPrint('Could not get FCM token: $e');
      return null;
    }
  }
}
