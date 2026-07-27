import 'dart:async';
import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../core/auth/social_sign_in.dart';
import '../../core/push/push_service.dart';
import '../../data/datasources/auth_token.dart';
import '../../domain/entities/app_user.dart';
import 'cart_controller.dart';
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

  // ---- Email OTP ----
  Future<OtpRequest> requestEmailOtp(String email) =>
      ref.read(authRepositoryProvider).requestEmailOtp(email);

  /// Verify the email code and start the session. Returns true if the profile
  /// (name + mobile) is already complete, so the caller can route to Home vs
  /// the profile step.
  Future<bool> verifyEmailOtp(String email, String code) async {
    final session = await ref.read(authRepositoryProvider).verifyEmailOtp(email, code);
    return _startSession(session);
  }

  // ---- Social ----
  /// Returns true on success (profile complete flag via [_startSession]),
  /// throws [SocialSignInException] on config errors. Returns null if cancelled.
  Future<bool?> signInWithGoogle() async {
    final res = await SocialSignIn.google();
    if (res == null) return null; // cancelled
    final session = await ref.read(authRepositoryProvider).signInWithGoogle(res.idToken);
    return _startSession(session);
  }

  Future<bool?> signInWithApple() async {
    final res = await SocialSignIn.apple();
    if (res == null) return null; // cancelled
    final session = await ref
        .read(authRepositoryProvider)
        .signInWithApple(res.identityToken, name: res.name);
    return _startSession(session);
  }

  // ---- Profile step ----
  Future<void> completeProfile(String name, String phone) async {
    final user = await ref.read(authRepositoryProvider).completeProfile(name, phone);
    await _persistUser(user);
  }

  /// Persist a fresh session, prime push + cart, and report profileComplete.
  Future<bool> _startSession(AuthSession session) async {
    AuthToken.value = session.token;
    await _prefs.setString(_kToken, session.token);
    await _prefs.setString(_kUser, jsonEncode(session.user.toJson()));
    state = AuthState(user: session.user);
    unawaited(_registerPush());
    unawaited(ref.read(cartControllerProvider.notifier).loadFromServer());
    return session.user.profileComplete;
  }

  Future<void> _persistUser(AppUser user) async {
    await _prefs.setString(_kUser, jsonEncode(user.toJson()));
    state = AuthState(user: user);
  }

  // ---- Legacy phone OTP (kept for later) ----
  Future<OtpRequest> requestOtp(String phone) {
    return ref.read(authRepositoryProvider).requestOtp(phone);
  }

  Future<void> verifyOtp(String phone, String code, {String? name}) async {
    final session =
        await ref.read(authRepositoryProvider).verifyOtp(phone, code, name: name);
    await _startSession(session);
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
