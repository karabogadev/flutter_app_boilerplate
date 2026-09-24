/// Type-safe translation keys for easy_localization
/// Usage: LocaleKeys.authLogin.tr()
abstract class LocaleKeys {
  // App
  static const String appName = 'app_name';

  // Common
  static const String commonOk = 'common.ok';
  static const String commonCancel = 'common.cancel';
  static const String commonSave = 'common.save';
  static const String commonDelete = 'common.delete';
  static const String commonEdit = 'common.edit';
  static const String commonClose = 'common.close';
  static const String commonBack = 'common.back';
  static const String commonNext = 'common.next';
  static const String commonDone = 'common.done';
  static const String commonLoading = 'common.loading';
  static const String commonRetry = 'common.retry';
  static const String commonError = 'common.error';
  static const String commonSuccess = 'common.success';
  static const String commonWarning = 'common.warning';

  // Auth
  static const String authLogin = 'auth.login';
  static const String authRegister = 'auth.register';
  static const String authLogout = 'auth.logout';
  static const String authEmail = 'auth.email';
  static const String authPassword = 'auth.password';
  static const String authConfirmPassword = 'auth.confirm_password';
  static const String authForgotPassword = 'auth.forgot_password';
  static const String authDontHaveAccount = 'auth.dont_have_account';
  static const String authAlreadyHaveAccount = 'auth.already_have_account';
  static const String authLoginSuccess = 'auth.login_success';
  static const String authRegisterSuccess = 'auth.register_success';
  static const String authLogoutSuccess = 'auth.logout_success';
  static const String authWelcomeBack = 'auth.welcome_back';
  static const String authSignInSubtitle = 'auth.sign_in_subtitle';
  static const String authCreateAccount = 'auth.create_account';
  static const String authSignUpSubtitle = 'auth.sign_up_subtitle';
  static const String authName = 'auth.name';
  static const String authNameHint = 'auth.name_hint';
  static const String authEmailHint = 'auth.email_hint';
  static const String authPasswordHint = 'auth.password_hint';
  static const String authConfirmPasswordHint = 'auth.confirm_password_hint';
  static const String authLogoutConfirm = 'auth.logout_confirm';

  // Validation
  static const String validationRequiredField = 'validation.required_field';
  static const String validationInvalidEmail = 'validation.invalid_email';
  static const String validationPasswordTooShort = 'validation.password_too_short';
  static const String validationPasswordsDontMatch = 'validation.passwords_dont_match';

  // Onboarding
  static const String onboardingTitle1 = 'onboarding.title_1';
  static const String onboardingDescription1 = 'onboarding.description_1';
  static const String onboardingTitle2 = 'onboarding.title_2';
  static const String onboardingDescription2 = 'onboarding.description_2';
  static const String onboardingTitle3 = 'onboarding.title_3';
  static const String onboardingDescription3 = 'onboarding.description_3';
  static const String onboardingSkip = 'onboarding.skip';
  static const String onboardingGetStarted = 'onboarding.get_started';

  // Home
  static const String homeTitle = 'home.title';
  /// Usage: LocaleKeys.homeWelcome.tr(namedArgs: {'name': userName})
  static const String homeWelcome = 'home.welcome';
  static const String homeWelcomeBack = 'home.welcome_back';
  static const String homeQuickActions = 'home.quick_actions';
  static const String homeRecentActivity = 'home.recent_activity';
  static const String homeProfile = 'home.profile';
  static const String homeNotifications = 'home.notifications';
  static const String homeFavorites = 'home.favorites';
  static const String homeHistory = 'home.history';
  /// Usage: LocaleKeys.homeActivity.tr(namedArgs: {'index': '1'})
  static const String homeActivity = 'home.activity';
  /// Plural. Usage: LocaleKeys.homeHoursAgo.plural(hours)
  static const String homeHoursAgo = 'home.hours_ago';

  // Settings
  static const String settingsTitle = 'settings.title';
  static const String settingsTheme = 'settings.theme';
  static const String settingsLanguage = 'settings.language';
  static const String settingsNotifications = 'settings.notifications';
  static const String settingsPrivacy = 'settings.privacy';
  static const String settingsTerms = 'settings.terms';
  static const String settingsAbout = 'settings.about';
  static const String settingsVersion = 'settings.version';
  static const String settingsLightTheme = 'settings.light_theme';
  static const String settingsDarkTheme = 'settings.dark_theme';
  static const String settingsSystemTheme = 'settings.system_theme';
  static const String settingsAccount = 'settings.account';
  static const String settingsProfile = 'settings.profile';
  static const String settingsSecurity = 'settings.security';

  // Errors
  static const String errorsServerError = 'errors.server_error';
  static const String errorsNetworkError = 'errors.network_error';
  static const String errorsUnknownError = 'errors.unknown_error';
  static const String errorsSessionExpired = 'errors.session_expired';
}
