import 'package:dio/dio.dart';

import '../core/api_config.dart';
import 'api_exception.dart';
import 'token_storage.dart';

/// Thin wrapper around [Dio] shared by every repository.
///
/// It is responsible for exactly two cross-cutting concerns so repositories
/// don't have to repeat them: attaching the stored JWT as
/// `Authorization: Bearer <token>` on every outgoing request, and converting
/// every possible failure (timeout, no connection, non-2xx response,
/// malformed body) into a single, user-readable [ApiException].
class ApiClient {
  ApiClient({Dio? dio, TokenStorage? tokenStorage})
      : _tokenStorage = tokenStorage ?? TokenStorage(),
        _dio = dio ??
            Dio(
              BaseOptions(
                baseUrl: ApiConfig.baseUrl,
                connectTimeout: const Duration(seconds: 10),
                receiveTimeout: const Duration(seconds: 10),
                sendTimeout: const Duration(seconds: 10),
              ),
            ) {
    _dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) async {
          final token = await _tokenStorage.readToken();
          if (token != null && token.isNotEmpty) {
            options.headers['Authorization'] = 'Bearer $token';
          }
          handler.next(options);
        },
      ),
    );
  }

  final Dio _dio;
  final TokenStorage _tokenStorage;

  Future<Response<dynamic>> get(
    String path, {
    Map<String, dynamic>? queryParameters,
  }) {
    return _run(() => _dio.get(path, queryParameters: queryParameters));
  }

  Future<Response<dynamic>> post(String path, {Object? data}) {
    return _run(() => _dio.post(path, data: data));
  }

  Future<Response<dynamic>> put(String path, {Object? data}) {
    return _run(() => _dio.put(path, data: data));
  }

  Future<Response<dynamic>> delete(String path) {
    return _run(() => _dio.delete(path));
  }

  Future<Response<dynamic>> _run(
    Future<Response<dynamic>> Function() request,
  ) async {
    try {
      return await request();
    } on DioException catch (e) {
      throw ApiException(_messageFor(e), statusCode: e.response?.statusCode);
    } on ApiException {
      rethrow;
    } catch (e) {
      throw ApiException('Something went wrong: $e');
    }
  }

  String _messageFor(DioException e) {
    switch (e.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.sendTimeout:
      case DioExceptionType.receiveTimeout:
        return 'The server took too long to respond. Check your connection and try again.';
      case DioExceptionType.connectionError:
        return 'Could not reach the server. Is the backend running and reachable at '
            '${ApiConfig.baseUrl}?';
      case DioExceptionType.badCertificate:
        return 'The server certificate could not be verified.';
      case DioExceptionType.cancel:
        return 'The request was cancelled.';
      case DioExceptionType.badResponse:
        return _extractServerMessage(e.response) ??
            'The server returned an error (status ${e.response?.statusCode ?? 'unknown'}).';
      case DioExceptionType.unknown:
        return 'Network error: ${e.message ?? 'unknown error'}.';
      case DioExceptionType.transformTimeout:
        return 'The server response could not be processed in time. Please try again.';
    }
  }

  /// Best-effort extraction of a human-readable message from whatever shape
  /// the backend's error body happens to have. The exact validation-error DTO
  /// shape is not guaranteed by the contract, so this stays defensive: it
  /// tries a few common field names, falls back to the raw string body, and
  /// never throws even if the body is empty, plain text, or unexpected JSON.
  String? _extractServerMessage(Response<dynamic>? response) {
    final data = response?.data;
    if (data == null) return null;
    if (data is String) {
      final trimmed = data.trim();
      return trimmed.isEmpty ? null : trimmed;
    }
    if (data is Map) {
      for (final key in ['message', 'error', 'detail', 'title']) {
        final value = data[key];
        if (value is String && value.trim().isNotEmpty) return value;
      }
      if (data.isNotEmpty) return data.toString();
    }
    return null;
  }
}
