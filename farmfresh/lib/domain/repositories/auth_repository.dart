import '../entities/app_user.dart';

/// Customer authentication.
///
/// API mapping:
///   requestEmailOtp  -> POST /auth/email/request
///   verifyEmailOtp   -> POST /auth/email/verify
///   signInWithFirebase -> POST /auth/firebase  (Google/Apple via Firebase Auth)
///   completeProfile  -> POST /auth/complete-profile
///   deleteAccount    -> DELETE /auth/me
/// The legacy phone requestOtp/verifyOtp map to /auth/otp/* (kept for later).
abstract interface class AuthRepository {
  // --- Email OTP ---
  Future<OtpRequest> requestEmailOtp(String email);
  Future<AuthSession> verifyEmailOtp(String email, String code);

  // --- Social (Google/Apple through Firebase Auth) ---
  Future<AuthSession> signInWithFirebase(String firebaseIdToken);

  // --- Mandatory profile step (name + mobile) ---
  Future<AppUser> completeProfile(String name, String phone);

  // --- Legacy phone OTP (kept for later use) ---
  Future<OtpRequest> requestOtp(String phone);
  Future<AuthSession> verifyOtp(String phone, String code, {String? name});

  Future<AppUser> updateName(String name);

  /// Permanently delete the signed-in customer's account (DELETE /auth/me).
  Future<void> deleteAccount();
}
