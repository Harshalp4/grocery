import 'dart:async';
import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../core/push/push_service.dart';
import '../../data/datasources/auth_token.dart';
import '../../domain/entities/app_user.dart';
import 'repository_providers.dart';

/// Overridden in main() with the loaded instance.
final sharedPreferencesProvider = Provider<SharedPreferences>(
  (ref) => throw UnimplementedError('sharedPreferencesProvider not overridden'),
);

const _kToken = 'auth_token';
const _kUser = 'auth_user';

class AuthState {
  const AuthState({this.user});
  final AppUser? user;
  bool get isAuthenticated => user != null;
}

/// Holds the signed-in user and persists the session across restarts.
/// On construction it restores any saved token/user and primes [AuthToken]
/// so the shared ApiClient is authenticated from the first request.
class AuthController extends Notifier<AuthState> {
  SharedPreferences get _prefs => ref.read(sharedPreferencesProvider);

  @override
  AuthState build() {
    final token = _prefs.getString(_kToken);
    final userJson = _prefs.getString(_kUser);
    if (token != null && userJson != null) {
      AuthToken.value = token;
      return AuthState(
        user: AppUser.fromJson(jsonDecode(userJson) as Map<String, dynamic>),
      );
    }
    return const AuthState();
  }

  Future<OtpRequest> requestOtp(String phone) {
    return ref.read(authRepositoryProvider).requestOtp(phone);
  }

  Future<void> verifyOtp(String phone, String code, {String? name}) async {
    final session =
        await ref.read(authRepositoryProvider).verifyOtp(phone, code, name: name);
    AuthToken.value = session.token;
    await _prefs.setString(_kToken, session.token);
    await _prefs.setString(_kUser, jsonEncode(session.user.toJson()));
    state = AuthState(user: session.user);
    // Register this device for push now that we're authenticated (no-op if
    // push is unavailable).
    unawaited(_registerPush());
  }

  Future<void> _registerPush() async {
    final token = await PushService.deviceToken();
    if (token == null) return;
    try {
      await ref.read(notificationRepositoryProvider).registerToken(token);
    } catch (_) {/* best effort */}
  }

  Future<void> updateName(String name) async {
    final user = await ref.read(authRepositoryProvider).updateName(name);
    await _prefs.setString(_kUser, jsonEncode(user.toJson()));
    state = AuthState(user: user);
  }

  Future<void> logout() async {
    AuthToken.value = null;
    await _prefs.remove(_kToken);
    await _prefs.remove(_kUser);
    state = const AuthState();
  }

  /// Permanently delete the account, then clear the local session.
  Future<void> deleteAccount() async {
    await ref.read(authRepositoryProvider).deleteAccount();
    await logout();
  }
}

final authControllerProvider =
    NotifierProvider<AuthController, AuthState>(AuthController.new);
