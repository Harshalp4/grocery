import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:sign_in_with_apple/sign_in_with_apple.dart';

/// Thrown when a social sign-in can't complete (usually because Firebase Auth
/// isn't configured yet — see SOCIAL_SIGN_IN.md).
class SocialSignInException implements Exception {
  SocialSignInException(this.message);
  final String message;
  @override
  String toString() => message;
}

/// Google / Apple sign-in through **Firebase Authentication**. Both return the
/// Firebase ID token for the backend (`/auth/firebase`) to verify, or null if
/// the user cancels. Throws [SocialSignInException] when Firebase isn't set up.
abstract class SocialSignIn {
  static FirebaseAuth get _auth => FirebaseAuth.instance;

  /// Firebase's Web OAuth client id (public). Needed so Google Sign-In returns
  /// an id token Firebase will accept. Override with --dart-define if the
  /// Firebase project changes.
  static const _googleServerClientId = String.fromEnvironment(
    'GOOGLE_SERVER_CLIENT_ID',
    defaultValue: '813226610037-kctl44r7to2m1id2n0b1i2l189b7f9d1.apps.googleusercontent.com',
  );

  static Future<String?> google() async {
    try {
      final account = await GoogleSignIn(
        scopes: const ['email'],
        serverClientId: _googleServerClientId.isEmpty ? null : _googleServerClientId,
      ).signIn();
      if (account == null) return null; // cancelled
      final gauth = await account.authentication;
      final cred = GoogleAuthProvider.credential(
        idToken: gauth.idToken,
        accessToken: gauth.accessToken,
      );
      final result = await _auth.signInWithCredential(cred);
      return _idToken(result);
    } on SocialSignInException {
      rethrow;
    } on FirebaseAuthException catch (e) {
      throw SocialSignInException(_friendly(e));
    } catch (_) {
      throw SocialSignInException('Google sign-in isn\'t available right now.');
    }
  }

  static Future<String?> apple() async {
    try {
      if (!await SignInWithApple.isAvailable()) {
        throw SocialSignInException('Apple sign-in isn\'t available on this device.');
      }
      final apple = await SignInWithApple.getAppleIDCredential(scopes: const [
        AppleIDAuthorizationScopes.email,
        AppleIDAuthorizationScopes.fullName,
      ]);
      // Apple only returns the name on first sign-in — push it into the Firebase
      // profile so /auth/firebase can read it from the token.
      final cred = OAuthProvider('apple.com').credential(
        idToken: apple.identityToken,
        accessToken: apple.authorizationCode,
      );
      final result = await _auth.signInWithCredential(cred);
      final name = [apple.givenName, apple.familyName]
          .where((e) => e != null && e.isNotEmpty).join(' ').trim();
      if (name.isNotEmpty && (result.user?.displayName ?? '').isEmpty) {
        await result.user?.updateDisplayName(name);
      }
      return _idToken(result, forceRefresh: name.isNotEmpty);
    } on SignInWithAppleAuthorizationException {
      return null; // cancelled
    } on SocialSignInException {
      rethrow;
    } on FirebaseAuthException catch (e) {
      throw SocialSignInException(_friendly(e));
    } catch (_) {
      throw SocialSignInException('Apple sign-in isn\'t available right now.');
    }
  }

  static Future<String?> _idToken(UserCredential result, {bool forceRefresh = false}) async {
    final token = await result.user?.getIdToken(forceRefresh);
    if (token == null || token.isEmpty) {
      throw SocialSignInException('Sign-in isn\'t configured yet.');
    }
    return token;
  }

  static String _friendly(FirebaseAuthException e) =>
      e.code == 'operation-not-allowed' || e.code == 'configuration-not-found'
          ? 'This sign-in method isn\'t enabled yet.'
          : 'Sign-in failed. Please try again.';
}
