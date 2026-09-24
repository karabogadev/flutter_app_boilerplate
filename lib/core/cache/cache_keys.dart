/// Keys for [CacheManager] (SharedPreferences). Auth tokens are deliberately
/// absent: they live in `SecureCacheManager`.
enum CacheKeys {
  // Auth
  user('user'),

  // Onboarding
  onboardingCompleted('onboarding_completed'),

  // Settings
  themeMode('theme_mode'),

  // Feature flags
  notificationsEnabled('notifications_enabled');

  const CacheKeys(this.key);
  final String key;
}
