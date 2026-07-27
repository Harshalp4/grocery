import 'package:google_sign_in/google_sign_in.dart';
import 'package:sign_in_with_apple/sign_in_with_apple.dart';

/// Thrown when a social sign-in can't complete (usually because OAuth isn't
/// configured yet — see SOCIAL_SIGN_IN.md).
class SocialSignInException implements Exception {
  SocialSignInException(this.message);
  final String message;
  @override
  String toString() => message;
}

/// Native Google / Apple sign-in. Returns the provider tokens for the backend
/// to verify, or null if the user cancels. Throws [SocialSignInException] with a
/// friendly message when the provider isn't set up.
abstract class SocialSignIn {
  /// Optional web/server client id used to mint a backend-audience Google id
  /// token. Pass with --dart-define=GOOGLE_SERVER_CLIENT_ID=... (Android reads
  /// google-services.json when this is empty).
  static const _googleServerClientId =
      String.fromEnvironment('GOOGLE_SERVER_CLIENT_ID', defaultValue: '');

  static Future<({String idToken})?> google() async {
    try {
      final signIn = GoogleSignIn(
        scopes: const ['email'],
        serverClientId: _googleServerClientId.isEmpty ? null : _googleServerClientId,
      );
      final account = await signIn.signIn();
      if (account == null) return null; // cancelled
      final auth = await account.authentication;
      final token = auth.idToken;
      if (token == null || token.isEmpty) {
        throw SocialSignInException('Google sign-in isn\'t configured yet.');
      }
      return (idToken: token);
    } on SocialSignInException {
      rethrow;
    } catch (_) {
      throw SocialSignInException('Google sign-in isn\'t available right now.');
    }
  }

  static Future<({String identityToken, String? name})?> apple() async {
    try {
      if (!await SignInWithApple.isAvailable()) {
        throw SocialSignInException('Apple sign-in isn\'t available on this device.');
      }
      final cred = await SignInWithApple.getAppleIDCredential(
        scopes: const [
          AppleIDAuthorizationScopes.email,
          AppleIDAuthorizationScopes.fullName,
        ],
      );
      final token = cred.identityToken;
      if (token == null || token.isEmpty) {
        throw SocialSignInException('Apple sign-in isn\'t configured yet.');
      }
      final name = [cred.givenName, cred.familyName]
          .where((e) => e != null && e.isNotEmpty)
          .join(' ')
          .trim();
      return (identityToken: token, name: name.isEmpty ? null : name);
    } on SignInWithAppleAuthorizationException {
      return null; // cancelled / not authorized
    } on SocialSignInException {
      rethrow;
    } catch (_) {
      throw SocialSignInException('Apple sign-in isn\'t available right now.');
    }
  }
}
