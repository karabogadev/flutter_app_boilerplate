import 'package:flutter/material.dart';
import 'package:flutter_app_boilerplate/core/error/failure_message.dart';
import 'package:flutter_app_boilerplate/core/error/failures.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../helpers/pump_app.dart';

void main() {
  setUpAll(setUpLocalization);

  Future<String> render(
    WidgetTester tester,
    Failure failure,
    Locale locale,
  ) async {
    late String text;
    await tester.pumpApp(
      Builder(
        builder: (context) {
          text = failure.localizedMessage;
          return const SizedBox.shrink();
        },
      ),
      locale: locale,
    );
    return text;
  }

  testWidgets('network failures are translated (tr)', (tester) async {
    expect(
      await render(tester, const NetworkFailure(), const Locale('tr')),
      'İnternet bağlantısı yok. Lütfen ağınızı kontrol edin.',
    );
  });

  testWidgets('unexpected failures get a generic message', (tester) async {
    expect(
      await render(tester, const UnexpectedFailure(), const Locale('en')),
      'An unexpected error occurred.',
    );
  });

  testWidgets('5xx hides server details; 4xx shows the server message', (
    tester,
  ) async {
    expect(
      await render(
        tester,
        const ServerFailure(message: 'NullPointerException', statusCode: 500),
        const Locale('en'),
      ),
      'Server error. Please try again later.',
    );
    expect(
      await render(
        tester,
        const ServerFailure(message: 'Email already taken', statusCode: 422),
        const Locale('en'),
      ),
      'Email already taken',
    );
  });
}
