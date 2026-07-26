/// Process-wide holder for the current partner auth token. The [ApiClient]
/// reads it to attach `Authorization: Bearer <token>` to every request.
class PartnerToken {
  static String? value;
}
