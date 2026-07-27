/// A signed-in customer. Email is the login identity; phone is the delivery
/// mobile number collected in the profile step.
class AppUser {
  const AppUser({
    required this.id,
    this.email,
    this.phone = '',
    this.name,
    this.profileComplete = false,
  });

  final String id;
  final String? email;
  final String phone;
  final String? name;

  /// Whether the mandatory name + mobile have been filled in.
  final bool profileComplete;

  AppUser copyWith({String? name, String? phone, bool? profileComplete}) => AppUser(
        id: id,
        email: email,
        phone: phone ?? this.phone,
        name: name ?? this.name,
        profileComplete: profileComplete ?? this.profileComplete,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'email': email,
        'phone': phone,
        'name': name,
        'profileComplete': profileComplete,
      };

  factory AppUser.fromJson(Map<String, dynamic> j) => AppUser(
        id: j['id'] as String,
        email: j['email'] as String?,
        phone: (j['phone'] as String?) ?? '',
        name: j['name'] as String?,
        profileComplete: j['profileComplete'] as bool? ?? false,
      );
}

/// Result of requesting an OTP. [devOtp] is only present in backend dev mode.
class OtpRequest {
  const OtpRequest({required this.retryIn, this.devOtp});
  final int retryIn;
  final String? devOtp;
}

/// Result of verifying an OTP / social sign-in — a session token + the user.
class AuthSession {
  const AuthSession({required this.token, required this.user});
  final String token;
  final AppUser user;
}
