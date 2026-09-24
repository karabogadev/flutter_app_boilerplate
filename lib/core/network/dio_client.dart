import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

import '../constants/api_constants.dart';
import '../error/exceptions.dart';
import '../logging/app_logger.dart';
import 'token_refresh_interceptor.dart';

/// HTTP client used by every remote data source and the sync queue.
///
/// Converts [DioException]s into the app's own [ServerException] /
/// [NetworkException] so data sources never depend on Dio error types.
///
/// JSON bodies of 50 KB or more are decoded in a background isolate by Dio's
/// default `FusedTransformer`, so large payloads don't block the UI thread.
class DioClient {
  DioClient({Dio? dio, Dio? refreshDio})
    : _dio = dio ?? Dio(_baseOptions()),
      _refreshDio = refreshDio ?? Dio(_baseOptions()) {
    if (kDebugMode) _dio.interceptors.add(_LoggingInterceptor());
  }

  // A fresh instance per Dio: Dio keeps the object it is given, so sharing one
  // would leak the Authorization header set on `_dio` into `_refreshDio`.
  static BaseOptions _baseOptions() => BaseOptions(
    baseUrl: ApiConstants.baseUrl,
    connectTimeout: ApiConstants.connectTimeout,
    receiveTimeout: ApiConstants.receiveTimeout,
    sendTimeout: ApiConstants.sendTimeout,
    headers: {
      'Content-Type': ApiConstants.contentType,
      'Accept': ApiConstants.accept,
    },
  );

  final Dio _dio;

  /// Separate client for the refresh call so it never passes through
  /// [TokenRefreshInterceptor] itself.
  final Dio _refreshDio;

  /// Installs [TokenRefreshInterceptor]. Called once from the DI container,
  /// after the auth data sources exist.
  void configureTokenRefresh({
    required GetRefreshToken getRefreshToken,
    required SaveTokens saveTokens,
    required OnSessionExpired onSessionExpired,
  }) {
    _dio.interceptors
      ..removeWhere((i) => i is TokenRefreshInterceptor)
      ..add(
        TokenRefreshInterceptor(
          dio: _dio,
          refreshDio: _refreshDio,
          getRefreshToken: getRefreshToken,
          saveTokens: saveTokens,
          onSessionExpired: onSessionExpired,
        ),
      );
  }

  void setAuthToken(String token) {
    _dio.options.headers[ApiConstants.authorization] =
        '${ApiConstants.bearer} $token';
  }

  void clearAuthToken() {
    _dio.options.headers.remove(ApiConstants.authorization);
  }

  Future<Response<T>> get<T>(
    String path, {
    Map<String, dynamic>? queryParameters,
    Options? options,
  }) => _send(
    () => _dio.get<T>(path, queryParameters: queryParameters, options: options),
  );

  Future<Response<T>> post<T>(
    String path, {
    Object? data,
    Map<String, dynamic>? queryParameters,
    Options? options,
  }) => _send(
    () => _dio.post<T>(
      path,
      data: data,
      queryParameters: queryParameters,
      options: options,
    ),
  );

  Future<Response<T>> put<T>(String path, {Object? data, Options? options}) =>
      _send(() => _dio.put<T>(path, data: data, options: options));

  Future<Response<T>> patch<T>(String path, {Object? data, Options? options}) =>
      _send(() => _dio.patch<T>(path, data: data, options: options));

  Future<Response<T>> delete<T>(
    String path, {
    Object? data,
    Options? options,
  }) => _send(() => _dio.delete<T>(path, data: data, options: options));

  Future<Response<T>> _send<T>(Future<Response<T>> Function() request) async {
    try {
      return await request();
    } on DioException catch (e) {
      throw _mapDioException(e);
    }
  }

  Exception _mapDioException(DioException error) => switch (error.type) {
    DioExceptionType.connectionTimeout ||
    DioExceptionType.sendTimeout ||
    DioExceptionType.receiveTimeout ||
    DioExceptionType.transformTimeout => const NetworkException(
      message: 'Connection timed out',
    ),
    DioExceptionType.connectionError => const NetworkException(
      message: 'No internet connection',
    ),
    DioExceptionType.badResponse => ServerException(
      message: _extractErrorMessage(error.response),
      statusCode: error.response?.statusCode,
    ),
    DioExceptionType.cancel => const ServerException(
      message: 'Request cancelled',
    ),
    DioExceptionType.badCertificate || DioExceptionType.unknown =>
      ServerException(message: error.message ?? 'Unknown error'),
  };

  String _extractErrorMessage(Response<dynamic>? response) {
    if (response?.data case {'message': final String message}) return message;
    if (response?.data case {'error': final String error}) return error;
    return 'Server error';
  }
}

class _LoggingInterceptor extends Interceptor {
  static const _redacted = '<redacted>';

  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    final headers = {
      ...options.headers,
      if (options.headers.containsKey(ApiConstants.authorization))
        ApiConstants.authorization: _redacted,
    };
    AppLogger.debug(
      '→ ${options.method} ${options.uri}\nHeaders: $headers'
      '${options.data != null ? '\nBody: ${options.data}' : ''}',
      name: 'network',
    );
    handler.next(options);
  }

  @override
  void onResponse(
    Response<dynamic> response,
    ResponseInterceptorHandler handler,
  ) {
    AppLogger.debug(
      '← ${response.statusCode} ${response.requestOptions.uri}',
      name: 'network',
    );
    handler.next(response);
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    AppLogger.debug(
      '✕ ${err.type} ${err.requestOptions.uri}\n'
      '${err.response?.statusCode ?? ''} ${err.response?.data ?? err.message}',
      name: 'network',
    );
    handler.next(err);
  }
}
