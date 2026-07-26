// Web-safe: pulls the platform check from a conditionally-imported file so the
// app compiles on web (which has no dart:io).
import 'platform_stub.dart' if (dart.library.io) 'platform_io.dart';

/// Backend connection settings. Override for a deployed backend with:
///   flutter run --dart-define=API_BASE=https://api.yourdomain.com
abstract class ApiConfig {
  static const String _override =
      String.fromEnvironment('API_BASE', defaultValue: '');

  static String get baseUrl {
    if (_override.isNotEmpty) return _override;
    if (isAndroidHost) return 'http://10.0.2.2:4000';
    return 'http://localhost:4000';
  }
}
