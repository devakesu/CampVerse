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
    defaultValue:
        'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.dummy_publishable_key',
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
}
