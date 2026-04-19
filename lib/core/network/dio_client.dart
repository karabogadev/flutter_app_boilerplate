import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

import '../constants/api_constants.dart';
import '../error/exceptions.dart';

typedef GetRefreshToken = Future<String?> Function();
typedef SaveTokens = Future<void> Function(String accessToken, String? refreshToken);
typedef OnLogout = Future<void> Function();

class DioClient {
  DioClient._internal();
  static DioClient? _instance;

  static DioClient get instance {
    _instance ??= DioClient._internal();
    return _instance!;
  }

  factory DioClient() => instance;

  late final Dio _dio = _createDio();

  /// Configure token refresh. Call this once from the DI container after
  /// auth dependencies are set up.
  void configureTokenRefresh({
    required GetRefreshToken getRefreshToken,
    required SaveTokens saveTokens,
    required OnLogout onLogout,
  }) {
    _dio.interceptors.removeWhere((i) => i is _TokenRefreshInterceptor);
    _dio.interceptors.add(_TokenRefreshInterceptor(
      mainDio: _dio,
      getRefreshToken: getRefreshToken,
      saveTokens: saveTokens,
      onLogout: onLogout,
    ));
  }

  Dio _createDio() {
    final dio = Dio(
      BaseOptions(
        baseUrl: ApiConstants.baseUrl,
        connectTimeout: ApiConstants.connectTimeout,
        receiveTimeout: ApiConstants.receiveTimeout,
        sendTimeout: ApiConstants.sendTimeout,
        headers: {
          'Content-Type': ApiConstants.contentType,
          'Accept': ApiConstants.accept,
        },
      ),
    );

    if (kDebugMode) {
      dio.interceptors.add(_LoggingInterceptor());
    }

    return dio;
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
  }) async {
    try {
      return await _dio.get<T>(path,
          queryParameters: queryParameters, options: options);
    } on DioException catch (e) {
      throw _handleDioError(e);
    }
  }

  Future<Response<T>> post<T>(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Options? options,
  }) async {
    try {
      return await _dio.post<T>(path,
          data: data, queryParameters: queryParameters, options: options);
    } on DioException catch (e) {
      throw _handleDioError(e);
    }
  }

  Future<Response<T>> put<T>(
    String path, {
    dynamic data,
    Options? options,
  }) async {
    try {
      return await _dio.put<T>(path, data: data, options: options);
    } on DioException catch (e) {
      throw _handleDioError(e);
    }
  }

  Future<Response<T>> patch<T>(
    String path, {
    dynamic data,
    Options? options,
  }) async {
    try {
      return await _dio.patch<T>(path, data: data, options: options);
    } on DioException catch (e) {
      throw _handleDioError(e);
    }
  }

  Future<Response<T>> delete<T>(
    String path, {
    dynamic data,
    Options? options,
  }) async {
    try {
      return await _dio.delete<T>(path, data: data, options: options);
    } on DioException catch (e) {
      throw _handleDioError(e);
    }
  }

  Exception _handleDioError(DioException error) {
    switch (error.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.sendTimeout:
      case DioExceptionType.receiveTimeout:
        return const NetworkException(message: 'Connection timed out');
      case DioExceptionType.connectionError:
        return const NetworkException(message: 'No internet connection');
      case DioExceptionType.badResponse:
        return ServerException(
          message: _extractErrorMessage(error.response),
          statusCode: error.response?.statusCode,
        );
      case DioExceptionType.cancel:
        return const ServerException(message: 'Request cancelled');
      default:
        return ServerException(message: error.message ?? 'Unknown error');
    }
  }

  String _extractErrorMessage(Response<dynamic>? response) {
    if (response?.data == null) return 'Server error';
    try {
      final data = response!.data;
      if (data is Map<String, dynamic>) {
        final message = data['message'];
        final error = data['error'];
        if (message is String) return message;
        if (error is String) return error;
      }
    } catch (_) {}
    return 'Server error';
  }
}

class _TokenRefreshInterceptor extends Interceptor {
  final Dio mainDio;
  final GetRefreshToken getRefreshToken;
  final SaveTokens saveTokens;
  final OnLogout onLogout;

  bool _isRefreshing = false;

  // Separate Dio for the refresh call — avoids interceptor recursion.
  late final Dio _refreshDio = Dio(
    BaseOptions(
      baseUrl: ApiConstants.baseUrl,
      connectTimeout: ApiConstants.connectTimeout,
      receiveTimeout: ApiConstants.receiveTimeout,
    ),
  );

  _TokenRefreshInterceptor({
    required this.mainDio,
    required this.getRefreshToken,
    required this.saveTokens,
    required this.onLogout,
  });

  @override
  Future<void> onError(
    DioException err,
    ErrorInterceptorHandler handler,
  ) async {
    final is401 = err.response?.statusCode == 401;
    final isRetry = err.requestOptions.extra['_isTokenRefreshRetry'] == true;

    if (!is401 || isRetry || _isRefreshing) {
      handler.next(err);
      return;
    }

    _isRefreshing = true;
    try {
      final refreshToken = await getRefreshToken();
      if (refreshToken == null) {
        await onLogout();
        handler.next(err);
        return;
      }

      final refreshResponse =
          await _refreshDio.post<Map<String, dynamic>>(
        ApiConstants.refreshToken,
        data: {'refresh_token': refreshToken},
      );

      final data = refreshResponse.data;
      if (data == null) {
        await onLogout();
        handler.next(err);
        return;
      }

      final newAccessToken = data['access_token'] as String;
      final newRefreshToken = data['refresh_token'] as String?;

      await saveTokens(newAccessToken, newRefreshToken);
      mainDio.options.headers[ApiConstants.authorization] =
          '${ApiConstants.bearer} $newAccessToken';

      // Retry the original request with the fresh token.
      final retryResponse = await mainDio.request<dynamic>(
        err.requestOptions.path,
        data: err.requestOptions.data,
        queryParameters: err.requestOptions.queryParameters,
        options: Options(
          method: err.requestOptions.method,
          headers: {
            ...err.requestOptions.headers,
            ApiConstants.authorization:
                '${ApiConstants.bearer} $newAccessToken',
          },
          extra: {'_isTokenRefreshRetry': true},
        ),
      );
      handler.resolve(retryResponse);
    } catch (_) {
      await onLogout();
      handler.next(err);
    } finally {
      _isRefreshing = false;
    }
  }
}

class _LoggingInterceptor extends Interceptor {
  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    debugPrint('┌────────────────────────────────────────────────');
    debugPrint('│ 🌐 REQUEST: ${options.method} ${options.uri}');
    debugPrint('│ Headers: ${options.headers}');
    if (options.data != null) debugPrint('│ Body: ${options.data}');
    debugPrint('└────────────────────────────────────────────────');
    handler.next(options);
  }

  @override
  void onResponse(Response<dynamic> response, ResponseInterceptorHandler handler) {
    debugPrint('┌────────────────────────────────────────────────');
    debugPrint('│ ✅ RESPONSE: ${response.statusCode}');
    debugPrint('│ Data: ${response.data}');
    debugPrint('└────────────────────────────────────────────────');
    handler.next(response);
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    debugPrint('┌────────────────────────────────────────────────');
    debugPrint('│ ❌ ERROR: ${err.type}');
    debugPrint('│ Message: ${err.message}');
    debugPrint('│ Response: ${err.response?.data}');
    debugPrint('└────────────────────────────────────────────────');
    handler.next(err);
  }
}
