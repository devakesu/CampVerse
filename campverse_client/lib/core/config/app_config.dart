/// Application configuration constants and environment variable bindings.
class AppConfig {
  AppConfig._();

  /// Supabase project URL endpoint.
  static const String supabaseUrl = String.fromEnvironment(
    'SUPABASE_URL',
    defaultValue: 'http://localhost:54321',
  );

  /// Supabase publishable client key (modern replacement for anon key).
  static const String supabasePublishableKey = String.fromEnvironment(
    'SUPABASE_PUBLISHABLE_KEY',
    defaultValue: 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.dummy_publishable_key',
  );

  /// API Gateway base URL endpoint.
  static const String apiBaseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'http://localhost:80/api',
  );

  /// Application human-readable display name.
  static const String appName = 'CampVerse';

  /// Application release version string from environment (e.g. APP_VERSION
  /// or VERSION).
  static const String appVersion = String.fromEnvironment(
    'APP_VERSION',
    defaultValue: String.fromEnvironment(
      'VERSION',
      defaultValue: 'v1.0.0',
    ),
  );

  // ── Google Sign-In OAuth Client IDs ────────────────────────────────────────

  /// Web / Android server client ID for Google Sign-In.
  /// Required for Android native sign-in and web OAuth redirect flow.
  static const String googleWebClientId = String.fromEnvironment(
    'GOOGLE_WEB_CLIENT_ID',
  );

  /// iOS client ID for native Google Sign-In on iOS.
  static const String googleIosClientId = String.fromEnvironment(
    'GOOGLE_IOS_CLIENT_ID',
  );

  // ── Support & Contact ───────────────────────────────────────────────────────

  /// Publicly reachable Contact Us URL (campus support portal or form).
  static const String contactUsUrl = String.fromEnvironment(
    'CONTACT_US_URL',
    defaultValue: 'https://campverse.dev/contact',
  );

  /// Support email address shown in institutional contact prompts.
  static const String supportEmail = String.fromEnvironment(
    'SUPPORT_EMAIL',
    defaultValue: 'support@campverse.dev',
  );
}
