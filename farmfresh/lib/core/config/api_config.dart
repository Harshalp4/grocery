import 'dart:io' show Platform;

/// Backend connection settings.
///
/// [useRemote] flips the whole app between the mock repositories and the real
/// HTTP backend (see `main.dart`, which reads this to build provider overrides).
///
/// [baseUrl] defaults to the local dev server, choosing the right host per
/// platform (Android emulators reach the host machine via 10.0.2.2). Override
/// for a deployed backend with:
///   flutter run --dart-define=API_BASE=https://api.yourdomain.com
abstract class ApiConfig {
  static const bool useRemote =
      bool.fromEnvironment('USE_REMOTE', defaultValue: true);

  static const String _override =
      String.fromEnvironment('API_BASE', defaultValue: '');

  static String get baseUrl {
    if (_override.isNotEmpty) return _override;
    if (Platform.isAndroid) return 'http://10.0.2.2:4000';
    return 'http://localhost:4000'; // iOS simulator, macOS, desktop
  }

  /// Turns a relative image path (`/uploads/x.png`) into a full URL. Returns
  /// null for empty/absent paths so widgets can show a placeholder.
  static String? imageUrl(String? path) {
    if (path == null || path.isEmpty) return null;
    if (path.startsWith('http')) return path;
    return '$baseUrl$path';
  }
}
