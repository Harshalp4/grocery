import '../../domain/entities/app_user.dart';
import '../../domain/repositories/auth_repository.dart';
import '../datasources/api_client.dart';

/// Customer auth via the backend: email OTP (`/auth/email/*`), social
/// (`/auth/google`, `/auth/apple`), profile (`/auth/complete-profile`), and the
/// legacy phone OTP (`/auth/otp/*`, kept for later).
class RemoteAuthRepository implements AuthRepository {
  RemoteAuthRepository(this._api);
  final ApiClient _api;

  // ---- Email OTP ----
  @override
  Future<OtpRequest> requestEmailOtp(String email) async {
    final j = await _api.postJson('/auth/email/request', {'email': email})
        as Map<String, dynamic>;
    return OtpRequest(
      retryIn: (j['retryIn'] as num?)?.toInt() ?? 30,
      devOtp: j['devOtp'] as String?,
    );
  }

  @override
  Future<AuthSession> verifyEmailOtp(String email, String code) async {
    final j = await _api.postJson('/auth/email/verify', {
      'email': email,
      'code': code,
    }) as Map<String, dynamic>;
    return _session(j);
  }

  // ---- Social (Google/Apple via Firebase Auth) ----
  @override
  Future<AuthSession> signInWithFirebase(String firebaseIdToken) async {
    final j = await _api.postJson('/auth/firebase', {'idToken': firebaseIdToken})
        as Map<String, dynamic>;
    return _session(j);
  }

  // ---- Profile ----
  @override
  Future<AppUser> completeProfile(String name, String phone) async {
    final j = await _api.postJson('/auth/complete-profile', {
      'name': name,
      'phone': phone,
    }) as Map<String, dynamic>;
    return _user(j['user'] as Map<String, dynamic>, j['profileComplete'] as bool?);
  }

  // ---- Legacy phone OTP (kept for later) ----
  @override
  Future<OtpRequest> requestOtp(String phone) async {
    final j = await _api.postJson('/auth/otp/request', {'phone': phone})
        as Map<String, dynamic>;
    return OtpRequest(
      retryIn: (j['retryIn'] as num?)?.toInt() ?? 30,
      devOtp: j['devOtp'] as String?,
    );
  }

  @override
  Future<AuthSession> verifyOtp(String phone, String code, {String? name}) async {
    final j = await _api.postJson('/auth/otp/verify', {
      'phone': phone,
      'code': code,
      if (name != null && name.isNotEmpty) 'name': name,
    }) as Map<String, dynamic>;
    return _session(j);
  }

  @override
  Future<AppUser> updateProfile(String name, String phone) async {
    final j = await _api.putJson('/auth/me', {'name': name, 'phone': phone})
        as Map<String, dynamic>;
    return AppUser.fromJson(j);
  }

  @override
  Future<void> deleteAccount() => _api.deleteJson('/auth/me');

  /// Build a session from a `{ token, profileComplete, user }` response.
  AuthSession _session(Map<String, dynamic> j) => AuthSession(
        token: j['token'] as String,
        user: _user(j['user'] as Map<String, dynamic>, j['profileComplete'] as bool?),
      );

  /// Merge the top-level [profileComplete] flag into the user object.
  AppUser _user(Map<String, dynamic> u, bool? profileComplete) {
    final merged = Map<String, dynamic>.from(u);
    if (profileComplete != null) merged['profileComplete'] = profileComplete;
    return AppUser.fromJson(merged);
  }
}
