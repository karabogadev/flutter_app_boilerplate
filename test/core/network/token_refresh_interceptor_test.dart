import 'package:dio/dio.dart';
import 'package:flutter_app_boilerplate/core/constants/api_constants.dart';
import 'package:flutter_app_boilerplate/core/network/token_refresh_interceptor.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../helpers/fake_http_client_adapter.dart';

const _oldHeader = 'Bearer old';
const _newHeader = 'Bearer new';

void main() {
  late Dio dio;
  late Dio refreshDio;
  late FakeHttpClientAdapter apiAdapter;
  late FakeHttpClientAdapter refreshAdapter;
  late List<(String, String?)> savedTokens;
  late int expiredCount;
  late String? storedRefreshToken;

  /// The API accepts only the new token.
  Future<ResponseBody> api(RequestOptions options) async =>
      options.headers[ApiConstants.authorization] == _newHeader
      ? jsonBody({'ok': true}, 200)
      : jsonBody({'message': 'unauthorized'}, 401);

  void install({
    required Future<ResponseBody> Function(RequestOptions) refresh,
  }) {
    dio = Dio()..httpClientAdapter = apiAdapter = FakeHttpClientAdapter(api);
    refreshDio = Dio()
      ..httpClientAdapter = refreshAdapter = FakeHttpClientAdapter(refresh);
    dio.options.headers[ApiConstants.authorization] = _oldHeader;
    dio.interceptors.add(
      TokenRefreshInterceptor(
        dio: dio,
        refreshDio: refreshDio,
        getRefreshToken: () async => storedRefreshToken,
        saveTokens: (access, refresh) async =>
            savedTokens.add((access, refresh)),
        onSessionExpired: () async => expiredCount++,
      ),
    );
  }

  Future<ResponseBody> successfulRefresh(RequestOptions _) async {
    // Delay so concurrent 401s arrive while the refresh is still in flight.
    await Future<void>.delayed(const Duration(milliseconds: 20));
    return jsonBody({'access_token': 'new', 'refresh_token': 'r2'}, 200);
  }

  setUp(() {
    savedTokens = [];
    expiredCount = 0;
    storedRefreshToken = 'r1';
  });

  test('concurrent 401s share one refresh and all retry', () async {
    install(refresh: successfulRefresh);

    final responses = await Future.wait([
      dio.get<dynamic>('/a'),
      dio.get<dynamic>('/b'),
      dio.get<dynamic>('/c'),
    ]);

    expect(responses.map((r) => r.statusCode), [200, 200, 200]);
    expect(refreshAdapter.requests, hasLength(1));
    expect(refreshAdapter.requests.single.data, {'refresh_token': 'r1'});
    expect(savedTokens, [('new', 'r2')]);
    expect(dio.options.headers[ApiConstants.authorization], _newHeader);
    expect(expiredCount, 0);
  });

  test('a request without Authorization is not refreshed', () async {
    install(refresh: successfulRefresh);
    dio.options.headers.remove(ApiConstants.authorization);

    await expectLater(
      dio.post<dynamic>('/auth/login'),
      throwsA(
        isA<DioException>().having(
          (e) => e.response?.statusCode,
          'status',
          401,
        ),
      ),
    );
    expect(refreshAdapter.requests, isEmpty);
    expect(expiredCount, 0);
  });

  test(
    'a stale token is retried with the current one without refreshing',
    () async {
      install(refresh: successfulRefresh);
      dio.options.headers[ApiConstants.authorization] = _newHeader;

      final response = await dio.get<dynamic>(
        '/a',
        options: Options(headers: {ApiConstants.authorization: _oldHeader}),
      );

      expect(response.statusCode, 200);
      expect(refreshAdapter.requests, isEmpty);
    },
  );

  test(
    'expires the session when the server rejects the refresh token',
    () async {
      install(refresh: (_) async => jsonBody({'message': 'invalid'}, 401));

      await expectLater(dio.get<dynamic>('/a'), throwsA(isA<DioException>()));
      expect(expiredCount, 1);
      expect(savedTokens, isEmpty);
    },
  );

  test(
    'keeps the session when the refresh fails for network reasons',
    () async {
      install(refresh: (_) => throw Exception('offline'));

      await expectLater(dio.get<dynamic>('/a'), throwsA(isA<DioException>()));
      expect(expiredCount, 0);
    },
  );

  test('expires the session when no refresh token is stored', () async {
    storedRefreshToken = null;
    install(refresh: successfulRefresh);

    await expectLater(dio.get<dynamic>('/a'), throwsA(isA<DioException>()));
    expect(expiredCount, 1);
    expect(refreshAdapter.requests, isEmpty);
  });

  test('retries a request at most once', () async {
    // Refresh "succeeds" but the API keeps rejecting the new token.
    install(refresh: successfulRefresh);
    apiAdapter = FakeHttpClientAdapter((_) async => jsonBody({}, 401));
    dio.httpClientAdapter = apiAdapter;

    await expectLater(dio.get<dynamic>('/a'), throwsA(isA<DioException>()));
    expect(apiAdapter.requests, hasLength(2));
    expect(refreshAdapter.requests, hasLength(1));
  });
}
