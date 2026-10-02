import 'package:google_sign_in/google_sign_in.dart';

/// Thin wrapper around the `google_sign_in` plugin.
///
/// This only obtains a Google ID token from Google itself; exchanging that
/// token for the app's own JWT is [AuthRepository.loginWithGoogle]'s job, to
/// keep the two concerns (talking to Google vs. talking to our backend)
/// separate and independently testable.
///
/// Requires a real Android OAuth client ID (and matching SHA-1 fingerprint)
/// registered in Google Cloud Console — see the README's "Google Sign-In
/// setup" section. Without it, [signInAndGetIdToken] will fail with a
/// [GoogleSignInException] (typically `clientConfigurationError` or
/// `providerConfigurationError`), which is expected in this sandbox since no
/// real Google Cloud project was created for this task.
class GoogleAuthService {
  GoogleAuthService({GoogleSignIn? googleSignIn})
      : _googleSignIn = googleSignIn ?? GoogleSignIn.instance;

  final GoogleSignIn _googleSignIn;
  bool _initialized = false;

  Future<void> _ensureInitialized() async {
    if (_initialized) return;
    await _googleSignIn.initialize();
    _initialized = true;
  }

  /// Runs the interactive Google sign-in flow and returns the resulting ID
  /// token, or `null` if the user cancelled the flow.
  Future<String?> signInAndGetIdToken() async {
    await _ensureInitialized();
    try {
      final account = await _googleSignIn.authenticate();
      return account.authentication.idToken;
    } on GoogleSignInException catch (e) {
      if (e.code == GoogleSignInExceptionCode.canceled) {
        return null;
      }
      rethrow;
    }
  }

  Future<void> signOut() async {
    await _ensureInitialized();
    await _googleSignIn.signOut();
  }
}
