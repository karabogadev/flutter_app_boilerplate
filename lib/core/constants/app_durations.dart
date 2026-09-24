abstract class AppDurations {
  // Animation durations
  static const Duration instant = Duration.zero;
  static const Duration fast = Duration(milliseconds: 150);
  static const Duration normal = Duration(milliseconds: 300);
  static const Duration slow = Duration(milliseconds: 500);
  static const Duration slower = Duration(milliseconds: 700);

  // Page transitions
  static const Duration pageTransition = Duration(milliseconds: 300);
  static const Duration modalTransition = Duration(milliseconds: 250);

  // Loading states
  static const Duration shimmerDuration = Duration(milliseconds: 1500);
  static const Duration snackbarDuration = Duration(seconds: 3);

  // Debounce
  static const Duration debounceShort = Duration(milliseconds: 300);
  static const Duration debounceMedium = Duration(milliseconds: 500);
  static const Duration debounceLong = Duration(seconds: 1);

  // Timeout
  static const Duration timeout = Duration(seconds: 30);
  static const Duration sessionTimeout = Duration(minutes: 30);
}
