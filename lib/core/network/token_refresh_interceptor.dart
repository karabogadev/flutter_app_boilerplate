import 'package:dio/dio.dart';

import '../constants/api_constants.dart';
import '../logging/app_logger.dart';

typedef GetRefreshToken = Future<String?> Function();
typedef SaveTokens = Future<void> Function(
  String accessToken,
  String? refreshToken,
);
typedef OnSessionExpired = Future<void> Function();

/// Refreshes the access token when an authenticated request gets a 401, then
/// retries that request once.
///
/// - Only requests that carried an `Authorization` header trigger a refresh,
///   so a failed login (401 without a token) is passed through untouched.
/// - Concurrent 401s share a single refresh call instead of racing.
/// - A 401 for a request sent with an already-replaced token is retried with
///   the current token without refreshing again.
/// - The session is expired only when the server rejects the refresh token.
///   Network errors during refresh fail the request but keep the session.
class TokenRefreshInterceptor extends Interceptor {
  TokenRefreshInterceptor({
    required Dio dio,
    required Dio refreshDio,
    required GetRefreshToken getRefreshToken,
    required SaveTokens saveTokens,
    required OnSessionExpired onSessionExpired,
  })  : _dio = dio,
        _refreshDio = refreshDio,
        _getRefreshToken = getRefreshToken,
        _saveTokens = saveTokens,
        _onSessionExpired = onSessionExpired;

  static const _retriedKey = 'tokenRefreshRetried';

  final Dio _dio;
  final Dio _refreshDio;
  final GetRefreshToken _getRefreshToken;
  final SaveTokens _saveTokens;
  final OnSessionExpired _onSessionExpired;

  Future<String?>? _refreshInFlight;

  @override
  Future<void> onError(
    DioException err,
    ErrorInterceptorHandler handler,
  ) async {
    final request = err.requestOptions;
    final sentAuthHeader = request.headers[ApiConstants.authorization];

    if (err.response?.statusCode != 401 ||
        sentAuthHeader == null ||
        request.extra[_retriedKey] == true) {
      return handler.next(err);
    }

    final currentAuthHeader = _dio.options.headers[ApiConstants.authorization];
    final freshAuthHeader =
        currentAuthHeader is String && currentAuthHeader != sentAuthHeader
            ? currentAuthHeader
            : await _refresh();

    if (freshAuthHeader == null) return handler.next(err);

    try {
      final response = await _dio.fetch<dynamic>(
        request.copyWith(
          headers: {
            ...request.headers,
            ApiConstants.authorization: freshAuthHeader,
          },
          extra: {...request.extra, _retriedKey: true},
        ),
      );
      handler.resolve(response);
    } on DioException catch (retryError) {
      handler.next(retryError);
    }
  }

  /// Returns the new `Authorization` header value, or null if the token
  /// could not be refreshed.
  Future<String?> _refresh() =>
      _refreshInFlight ??= _performRefresh().whenComplete(
        () => _refreshInFlight = null,
      );

  Future<String?> _performRefresh() async {
    final refreshToken = await _getRefreshToken();
    if (refreshToken == null) {
      await _onSessionExpired();
      return null;
    }

    try {
      final response = await _refreshDio.post<Map<String, dynamic>>(
        ApiConstants.refreshToken,
        data: {'refresh_token': refreshToken},
      );
      final data = response.data;
      final accessToken = data?['access_token'];
      if (accessToken is! String) {
        await _onSessionExpired();
        return null;
      }
      final newRefreshToken = data?['refresh_token'];
      await _saveTokens(
        accessToken,
        newRefreshToken is String ? newRefreshToken : null,
      );

      final authHeader = '${ApiConstants.bearer} $accessToken';
      _dio.options.headers[ApiConstants.authorization] = authHeader;
      return authHeader;
    } on DioException catch (e, stackTrace) {
      AppLogger.error(
        'Token refresh failed',
        error: e,
        stackTrace: stackTrace,
        name: 'network',
      );
      if (_isRejection(e)) await _onSessionExpired();
      return null;
    }
  }

  static bool _isRejection(DioException e) =>
      const {400, 401, 403}.contains(e.response?.statusCode);
}
