/// A signed-in customer.
class AppUser {
  const AppUser({required this.id, required this.phone, this.name});

  final String id;
  final String phone;
  final String? name;

  Map<String, dynamic> toJson() => {'id': id, 'phone': phone, 'name': name};

  factory AppUser.fromJson(Map<String, dynamic> j) => AppUser(
        id: j['id'] as String,
        phone: j['phone'] as String,
        name: j['name'] as String?,
      );
}

/// Result of requesting an OTP. [devOtp] is only present in backend dev mode.
class OtpRequest {
  const OtpRequest({required this.retryIn, this.devOtp});
  final int retryIn;
  final String? devOtp;
}

/// Result of verifying an OTP — a session token + the user.
class AuthSession {
  const AuthSession({required this.token, required this.user});
  final String token;
  final AppUser user;
}
