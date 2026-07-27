import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';

/// Guarded FCM wrapper. With the shipped placeholder google-services.json, init
/// or token retrieval fails gracefully and push stays off. Drop in a real
/// google-services.json (see PUSH_NOTIFICATIONS.md) to enable it.
abstract class PushService {
  static bool _ready = false;

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
      final m = FirebaseMessaging.instance;
      await m.requestPermission();
      return await m.getToken();
    } catch (e) {
      debugPrint('Could not get FCM token: $e');
      return null;
    }
  }
}
