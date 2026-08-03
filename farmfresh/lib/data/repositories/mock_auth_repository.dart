import '../../domain/entities/app_user.dart';
import '../../domain/repositories/auth_repository.dart';

/// Offline auth stand-in (used when useRemote is off): any code works.
class MockAuthRepository implements AuthRepository {
  const MockAuthRepository();

  AuthSession _mock({String? email, String phone = '', String? name}) => AuthSession(
        token: 'mock-token',
        user: AppUser(
          id: 'mock',
          email: email,
          phone: phone,
          name: name,
          profileComplete: name != null && phone.isNotEmpty,
        ),
      );

  @override
  Future<OtpRequest> requestEmailOtp(String email) async =>
      const OtpRequest(retryIn: 30, devOtp: '123456');

  @override
  Future<AuthSession> verifyEmailOtp(String email, String code) async =>
      _mock(email: email);

  @override
  Future<AuthSession> signInWithFirebase(String firebaseIdToken) async =>
      _mock(email: 'guest@firebase.com', name: 'Social User');

  @override
  Future<AppUser> completeProfile(String name, String phone) async =>
      AppUser(id: 'mock', phone: phone, name: name, profileComplete: true);

  @override
  Future<OtpRequest> requestOtp(String phone) async =>
      const OtpRequest(retryIn: 30, devOtp: '1234');

  @override
  Future<AuthSession> verifyOtp(String phone, String code, {String? name}) async =>
      _mock(phone: phone, name: name);

  @override
  Future<AppUser> updateProfile(String name, String phone) async =>
      AppUser(id: 'mock', phone: phone, name: name, profileComplete: true);

  @override
  Future<void> deleteAccount() async {}
}
