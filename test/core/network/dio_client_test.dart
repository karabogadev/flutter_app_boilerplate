import 'dart:convert';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter_app_boilerplate/core/constants/api_constants.dart';
import 'package:flutter_app_boilerplate/core/error/exceptions.dart';
import 'package:flutter_app_boilerplate/core/network/dio_client.dart';
import 'package:flutter_test/flutter_test.dart';

class _Adapter implements HttpClientAdapter {
  _Adapter(this.respond);

  final Future<ResponseBody> Function(RequestOptions options) respond;
  RequestOptions? lastRequest;

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) {
    lastRequest = options;
    return respond(options);
  }

  @override
  void close({bool force = false}) {}
}

DioClient _client(Future<ResponseBody> Function(RequestOptions) respond) =>
    DioClient(dio: Dio()..httpClientAdapter = _Adapter(respond));

void main() {
  test('maps an error response to ServerException with its message', () {
    final client = _client(
      (_) async => ResponseBody.fromString(
        jsonEncode({'message': 'Email already taken'}),
        422,
        headers: {
          Headers.contentTypeHeader: [Headers.jsonContentType],
        },
      ),
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
      late _Adapter adapter;
      final client = DioClient(
        dio: Dio()
          ..httpClientAdapter = adapter = _Adapter(
            (_) async => ResponseBody.fromString('{}', 200),
          ),
      );

      client.setAuthToken('abc');
      await client.get<dynamic>('/me');
      expect(
        adapter.lastRequest?.headers[ApiConstants.authorization],
        'Bearer abc',
      );

      client.clearAuthToken();
      await client.get<dynamic>('/me');
      expect(adapter.lastRequest?.headers[ApiConstants.authorization], isNull);
    },
  );
}
