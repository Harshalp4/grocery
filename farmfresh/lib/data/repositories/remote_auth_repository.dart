import '../../domain/entities/app_user.dart';
import '../../domain/repositories/auth_repository.dart';
import '../datasources/api_client.dart';

/// Phone/OTP auth via the backend (`/auth/otp/*`).
class RemoteAuthRepository implements AuthRepository {
  RemoteAuthRepository(this._api);
  final ApiClient _api;

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
  Future<AuthSession> verifyOtp(String phone, String code,
      {String? name}) async {
    final j = await _api.postJson('/auth/otp/verify', {
      'phone': phone,
      'code': code,
      if (name != null && name.isNotEmpty) 'name': name,
    }) as Map<String, dynamic>;
    return AuthSession(
      token: j['token'] as String,
      user: AppUser.fromJson(j['user'] as Map<String, dynamic>),
    );
  }

  @override
  Future<AppUser> updateName(String name) async {
    final j = await _api.putJson('/auth/me', {'name': name})
        as Map<String, dynamic>;
    return AppUser.fromJson(j);
  }
}
