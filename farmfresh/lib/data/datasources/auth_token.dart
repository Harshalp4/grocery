/// Process-wide holder for the current customer auth token. The [ApiClient]
/// reads it to attach `Authorization: Bearer <token>` to every request; the
/// auth controller sets/clears it on login/logout. Kept deliberately simple so
/// the single shared ApiClient always sees the latest token.
class AuthToken {
  static String? value;
}
