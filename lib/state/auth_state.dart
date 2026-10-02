import 'package:flutter/foundation.dart';

import '../data/api_exception.dart';
import '../data/auth_repository.dart';
import '../data/google_auth_service.dart';

enum AuthStatus { unknown, loggedOut, loggedIn }

/// Global authentication state: whether we have a usable session, and the
/// loading/error state of whatever login attempt is in flight.
///
/// Screens never talk to [AuthRepository] or [GoogleAuthService] directly;
/// they go through this notifier so login/logout always updates the same
/// single source of truth that `main.dart` uses to decide which screen to
/// show.
class AuthState extends ChangeNotifier {
  AuthState({
    required AuthRepository authRepository,
    GoogleAuthService? googleAuthService,
  })  : _authRepository = authRepository,
        _googleAuthService = googleAuthService ?? GoogleAuthService();

  final AuthRepository _authRepository;
  final GoogleAuthService _googleAuthService;

  AuthStatus status = AuthStatus.unknown;
  bool isLoading = false;
  String? errorMessage;

  bool get isLoggedIn => status == AuthStatus.loggedIn;

  /// Called once at app start to decide whether to show the login screen or
  /// jump straight to the dashboard using a previously stored token.
  Future<void> checkInitialSession() async {
    final hasSession = await _authRepository.hasValidSession();
    status = hasSession ? AuthStatus.loggedIn : AuthStatus.loggedOut;
    notifyListeners();
  }

  Future<bool> login(String email, String password) async {
    return _attempt(() => _authRepository.login(email, password));
  }

  Future<bool> loginWithGoogle() async {
    return _attempt(() async {
      final idToken = await _googleAuthService.signInAndGetIdToken();
      if (idToken == null) {
        // User cancelled the Google flow; not an error, just no-op.
        throw _Cancelled();
      }
      return _authRepository.loginWithGoogle(idToken);
    }, ignoreCancelled: true);
  }

  Future<bool> _attempt(
    Future<String> Function() action, {
    bool ignoreCancelled = false,
  }) async {
    isLoading = true;
    errorMessage = null;
    notifyListeners();
    try {
      await action();
      status = AuthStatus.loggedIn;
      isLoading = false;
      notifyListeners();
      return true;
    } on _Cancelled {
      isLoading = false;
      notifyListeners();
      return false;
    } on ApiException catch (e) {
      errorMessage = e.message;
      isLoading = false;
      notifyListeners();
      return false;
    } catch (e) {
      errorMessage = 'Could not sign in: $e';
      isLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<void> logout() async {
    await _authRepository.logout();
    status = AuthStatus.loggedOut;
    notifyListeners();
  }
}

class _Cancelled implements Exception {}
