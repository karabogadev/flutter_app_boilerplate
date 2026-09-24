import 'package:dio/dio.dart';
import 'package:flutter_app_boilerplate/core/constants/api_constants.dart';
import 'package:flutter_app_boilerplate/core/error/exceptions.dart';
import 'package:flutter_app_boilerplate/core/network/dio_client.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../helpers/fake_http_client_adapter.dart';

DioClient _client(Future<ResponseBody> Function(RequestOptions) respond) =>
    DioClient(dio: Dio()..httpClientAdapter = FakeHttpClientAdapter(respond));

void main() {
  test('maps an error response to ServerException with its message', () {
    final client = _client(
      (_) async => jsonBody({'message': 'Email already taken'}, 422),
    );

    expect(
      client.post<dynamic>('/auth/register'),
      throwsA(
        isA<ServerException>()
            .having((e) => e.message, 'message', 'Email already taken')
            .having((e) => e.statusCode, 'statusCode', 422),
      ),
    );
  });

  test('maps a connection error to NetworkException', () {
    final client = _client(
      (options) => throw DioException.connectionError(
        requestOptions: options,
        reason: 'offline',
      ),
    );

    expect(client.get<dynamic>('/users'), throwsA(isA<NetworkException>()));
  });

  test('maps a timeout to NetworkException', () {
    final client = _client(
      (options) => throw DioException.connectionTimeout(
        requestOptions: options,
        timeout: const Duration(seconds: 1),
      ),
    );

    expect(client.get<dynamic>('/users'), throwsA(isA<NetworkException>()));
  });

  test(
    'setAuthToken and clearAuthToken control the Authorization header',
    () async {
      late FakeHttpClientAdapter adapter;
      final client = DioClient(
        dio: Dio()
          ..httpClientAdapter = adapter = FakeHttpClientAdapter(
            (_) async => ResponseBody.fromString('{}', 200),
          ),
      );

      client.setAuthToken('abc');
      await client.get<dynamic>('/me');
      expect(
        adapter.requests.last.headers[ApiConstants.authorization],
        'Bearer abc',
      );

      client.clearAuthToken();
      await client.get<dynamic>('/me');
      expect(adapter.requests.last.headers[ApiConstants.authorization], isNull);
    },
  );
}
