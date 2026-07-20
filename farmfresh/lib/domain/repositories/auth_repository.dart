import '../entities/app_user.dart';

/// Customer phone + OTP authentication.
///
/// API mapping:
///   requestOtp -> POST /auth/otp/request
///   verifyOtp  -> POST /auth/otp/verify
abstract interface class AuthRepository {
  Future<OtpRequest> requestOtp(String phone);
  Future<AuthSession> verifyOtp(String phone, String code, {String? name});
  Future<AppUser> updateName(String name);
}
