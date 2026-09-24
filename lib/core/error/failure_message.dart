import 'package:easy_localization/easy_localization.dart';

import '../localization/locale_keys.dart';
import 'failures.dart';

extension FailureMessage on Failure {
  /// Translated, user-facing text for this failure.
  ///
  /// 4xx and validation messages come from the backend and are shown as-is
  /// (they usually explain what to fix, e.g. "Email already taken"). Anything
  /// else gets a generic translated message instead of internal details.
  String get localizedMessage => switch (this) {
    NetworkFailure() => LocaleKeys.errorsNetworkError.tr(),
    ServerFailure(:final statusCode?) when statusCode >= 500 =>
      LocaleKeys.errorsServerError.tr(),
    ServerFailure(:final message) ||
    ValidationFailure(:final message) => message,
    CacheFailure() || UnexpectedFailure() => LocaleKeys.errorsUnknownError.tr(),
  };
}
