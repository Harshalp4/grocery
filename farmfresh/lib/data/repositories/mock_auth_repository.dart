import '../../domain/entities/app_user.dart';
import '../../domain/repositories/auth_repository.dart';

/// Offline auth stand-in (used when useRemote is off): any 4-digit code works.
class MockAuthRepository implements AuthRepository {
  const MockAuthRepository();

  @override
  Future<OtpRequest> requestOtp(String phone) async {
    await Future<void>.delayed(const Duration(milliseconds: 300));
    return const OtpRequest(retryIn: 30, devOtp: '1234');
  }

  @override
  Future<AuthSession> verifyOtp(String phone, String code,
      {String? name}) async {
    await Future<void>.delayed(const Duration(milliseconds: 300));
    return AuthSession(
      token: 'mock-token',
      user: AppUser(id: 'mock', phone: phone, name: name ?? 'Guest'),
    );
  }

  @override
  Future<AppUser> updateName(String name) async =>
      AppUser(id: 'mock', phone: '', name: name);
}
