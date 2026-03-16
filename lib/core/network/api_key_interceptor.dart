import 'package:dio/dio.dart';

/// Intercepts each request and appends the effective API key as a query
/// parameter. The key is fetched lazily via [_getKey] to support the hybrid
/// BYOK strategy (user-stored key → .env fallback).
class ApiKeyInterceptor extends Interceptor {
  ApiKeyInterceptor(this._getKey);

  final Future<String> Function() _getKey;

  @override
  Future<void> onRequest(
    RequestOptions options,
    RequestInterceptorHandler handler,
  ) async {
    final key = await _getKey();
    if (key.isNotEmpty) {
      options.queryParameters = {...options.queryParameters, 'key': key};
    }
    handler.next(options);
  }
}
