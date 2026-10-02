import 'api_client.dart';
import 'api_exception.dart';
import 'token_storage.dart';

/// Wraps the two login endpoints and owns the session (the stored JWT).
///
/// Both `/api/auth/login` and `/api/auth/oauth/google` return the same
/// `{"token": "<jwt>"}` shape, so both paths funnel through
/// [_storeTokenFrom].
class AuthRepository {
  AuthRepository({ApiClient? apiClient, TokenStorage? tokenStorage})
      : _apiClient = apiClient ?? ApiClient(),
        _tokenStorage = tokenStorage ?? TokenStorage();

  final ApiClient _apiClient;
  final TokenStorage _tokenStorage;

  Future<String> login(String email, String password) async {
    try {
      final response = await _apiClient.post(
        '/api/auth/login',
        data: {'email': email, 'password': password},
      );
      return await _storeTokenFrom(response.data);
    } on ApiException catch (e) {
      if (e.statusCode == 401) {
        throw ApiException('Incorrect email or password.', statusCode: 401);
      }
      rethrow;
    }
  }

  /// Exchanges a Google ID token (obtained from `google_sign_in` on the
  /// device) for this app's own JWT.
  Future<String> loginWithGoogle(String idToken) async {
    final response = await _apiClient.post(
      '/api/auth/oauth/google',
      data: {'idToken': idToken},
    );
    return _storeTokenFrom(response.data);
  }

  Future<void> logout() => _tokenStorage.deleteToken();

  Future<bool> hasValidSession() async {
    final token = await _tokenStorage.readToken();
    return token != null && token.isNotEmpty;
  }

  Future<String> _storeTokenFrom(dynamic data) async {
    if (data is Map && data['token'] is String) {
      final token = data['token'] as String;
      if (token.isNotEmpty) {
        await _tokenStorage.saveToken(token);
        return token;
      }
    }
    throw ApiException('Unexpected response from the server while signing in.');
  }
}
