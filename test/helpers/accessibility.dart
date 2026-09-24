import 'package:flutter_test/flutter_test.dart';

/// Checks the pumped screen against Flutter's accessibility guidelines:
/// tap target sizes (Android 48dp, iOS 44pt), labeled tap targets and text
/// contrast (WCAG AA). See https://docs.flutter.dev/ui/accessibility.
Future<void> expectMeetsAccessibilityGuidelines(WidgetTester tester) async {
  final handle = tester.ensureSemantics();
  await expectLater(tester, meetsGuideline(androidTapTargetGuideline));
  await expectLater(tester, meetsGuideline(iOSTapTargetGuideline));
  await expectLater(tester, meetsGuideline(labeledTapTargetGuideline));
  await expectLater(tester, meetsGuideline(textContrastGuideline));
  handle.dispose();
}
