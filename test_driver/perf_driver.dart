import 'package:flutter_driver/flutter_driver.dart' as driver;
import 'package:integration_test/integration_test_driver.dart';

/// Writes the timeline recorded by `binding.traceAction` to
/// `build/<reportKey>.timeline_summary.json`. Gate CI on fields such as
/// `worst_frame_build_time_millis` and `missed_frame_build_budget_count`.
Future<void> main() {
  return integrationDriver(
    responseDataCallback: (data) async {
      final timelines = data ?? const <String, dynamic>{};
      for (final MapEntry(:key, :value) in timelines.entries) {
        final timeline = driver.Timeline.fromJson(
          value as Map<String, dynamic>,
        );
        await driver.TimelineSummary.summarize(
          timeline,
        ).writeTimelineToFile(key, pretty: true, includeSummary: true);
      }
    },
  );
}
