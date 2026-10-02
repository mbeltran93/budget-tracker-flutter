/// A normalized, user-readable error for any failure talking to the backend.
///
/// Timeouts, connection errors, non-2xx responses and malformed response
/// bodies are all mapped to this single type by [ApiClient], so the UI layer
/// only ever needs to handle one kind of error and can always show
/// [message] directly without risking a crash.
class ApiException implements Exception {
  ApiException(this.message, {this.statusCode});

  final String message;
  final int? statusCode;

  @override
  String toString() => message;
}
