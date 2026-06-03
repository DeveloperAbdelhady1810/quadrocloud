import 'dart:convert';
import 'dart:math';
import 'package:crypto/crypto.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:sign_in_with_apple/sign_in_with_apple.dart';

class SocialAuthService {
  static final _google = GoogleSignIn(scopes: ['email', 'profile']);

  // ─── Google ───────────────────────────────────────────────────────────────

  static Future<Map<String, String?>> signInWithGoogle() async {
    final account = await _google.signIn();
    if (account == null) throw Exception('cancelled');
    final auth = await account.authentication;
    if (auth.idToken == null) throw Exception('no_id_token');
    return {
      'provider': 'google',
      'token': auth.idToken,
      'name': account.displayName,
      'email': account.email,
    };
  }

  static Future<void> signOutGoogle() async {
    try {
      await _google.signOut();
    } catch (_) {}
  }

  // ─── Apple ────────────────────────────────────────────────────────────────

  static String _nonce([int length = 32]) {
    const chars =
        'ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789';
    final rng = Random.secure();
    return List.generate(length, (_) => chars[rng.nextInt(chars.length)]).join();
  }

  static String _sha256(String input) =>
      sha256.convert(utf8.encode(input)).toString();

  static Future<Map<String, String?>> signInWithApple() async {
    final rawNonce = _nonce();
    final credential = await SignInWithApple.getAppleIDCredential(
      scopes: [
        AppleIDAuthorizationScopes.email,
        AppleIDAuthorizationScopes.fullName,
      ],
      nonce: _sha256(rawNonce),
    );

    final fullName = [credential.givenName, credential.familyName]
        .where((s) => s != null && s.isNotEmpty)
        .join(' ');

    return {
      'provider': 'apple',
      'token': credential.identityToken,
      'user_id': credential.userIdentifier,
      'name': fullName.isNotEmpty ? fullName : null,
      'email': credential.email,
    };
  }
}
