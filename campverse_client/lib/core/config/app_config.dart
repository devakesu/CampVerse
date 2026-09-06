import 'dart:io' show Platform;

import 'package:flutter/foundation.dart' show kDebugMode, kIsWeb;

/// Application configuration constants and environment variable bindings.
class AppConfig {
  AppConfig._();

  /// Resolves an endpoint host for local development.
  static String resolveLocalHost({
    bool isWeb = kIsWeb,
    bool isAndroid = false,
    bool isLinux = false,
    bool isTargetingHostDocker = false,
  }) {
    if (isWeb) {
      return 'localhost';
    }
    if (isAndroid) {
      return '10.0.2.2';
    }
    if (isLinux && isTargetingHostDocker) {
      return 'host.docker.internal';
    }
    return 'localhost';
  }

  /// Resolves the Supabase URL given platform and debug mode context.
  /// In debug mode, forces custom platform values even if env is present.
  static String resolveSupabaseUrl({
    bool isDebug = kDebugMode,
    bool isWeb = kIsWeb,
    bool isAndroid = false,
    bool isLinux = false,
    bool isMacOS = false,
    bool isWindows = false,
    bool isIOS = false,
    String? envValue,
  }) {
    if (!isDebug && envValue != null && envValue.isNotEmpty) {
      return envValue;
    }

    final host = resolveLocalHost(
      isWeb: isWeb,
      isAndroid: isAndroid,
      isLinux: isLinux,
      isTargetingHostDocker: true,
    );
    return 'http://$host:54321';
  }

  /// Resolves the API Gateway base URL given platform and debug mode context.
  /// In debug mode, forces custom platform values even if env is present.
  static String resolveApiBaseUrl({
    bool isDebug = kDebugMode,
    bool isWeb = kIsWeb,
    bool isAndroid = false,
    bool isLinux = false,
    bool isMacOS = false,
    bool isWindows = false,
    bool isIOS = false,
    String? envValue,
  }) {
    if (!isDebug && envValue != null && envValue.isNotEmpty) {
      return envValue;
    }

    final host = resolveLocalHost(
      isWeb: isWeb,
      isAndroid: isAndroid,
      isLinux: isLinux,
    );
    return 'http://$host:80/api';
  }

  /// Supabase project URL endpoint.
  ///
  /// In debug mode (`kDebugMode`), returns platform-specific local endpoints:
  /// - Web / macOS / Windows / iOS: `http://localhost:54321`
  /// - Android (Emulator): `http://10.0.2.2:54321`
  /// - Linux (DevContainer): `http://host.docker.internal:54321`
  ///
  /// In release mode, reads from `--dart-define=SUPABASE_URL` with a fallback
  /// to `http://localhost:54321`.
  static String get supabaseUrl {
    return resolveSupabaseUrl(
      isAndroid: !kIsWeb && Platform.isAndroid,
      isLinux: !kIsWeb && Platform.isLinux,
      isMacOS: !kIsWeb && Platform.isMacOS,
      isWindows: !kIsWeb && Platform.isWindows,
      isIOS: !kIsWeb && Platform.isIOS,
      envValue: const String.fromEnvironment('SUPABASE_URL'),
    );
  }

  /// Supabase publishable client key (modern replacement for anon key).
  static const String supabasePublishableKey = String.fromEnvironment(
    'SUPABASE_PUBLISHABLE_KEY',
    defaultValue: 'sb_publishable_ACJWlzQHlZjBrEguHvfOxg_3BJgxAaH',
  );

  /// API Gateway base URL endpoint.
  ///
  /// In debug mode (`kDebugMode`), returns platform-specific local endpoints:
  /// - Web / macOS / Windows / iOS / Linux: `http://localhost:80/api`
  /// - Android (Emulator): `http://10.0.2.2:80/api`
  ///
  /// In release mode, reads from `--dart-define=API_BASE_URL` with a fallback
  /// to `http://localhost:80/api`.
  static String get apiBaseUrl {
    return resolveApiBaseUrl(
      isAndroid: !kIsWeb && Platform.isAndroid,
      isLinux: !kIsWeb && Platform.isLinux,
      isMacOS: !kIsWeb && Platform.isMacOS,
      isWindows: !kIsWeb && Platform.isWindows,
      isIOS: !kIsWeb && Platform.isIOS,
      envValue: const String.fromEnvironment('API_BASE_URL'),
    );
  }

  /// Application human-readable display name.
  static const String appName = 'CampVerse';

  /// Application release version string from environment (e.g. APP_VERSION
  /// or VERSION).
  static const String appVersion = String.fromEnvironment(
    'APP_VERSION',
    defaultValue: 'v1.0.0',
  );

  // ── Google Sign-In OAuth Client IDs ───────────────────────────────────────

  /// Web / Android server client ID for Google Sign-In.
  /// Required for Android native sign-in and web OAuth redirect flow.
  static const String googleWebClientId = String.fromEnvironment(
    'GOOGLE_WEB_CLIENT_ID',
  );

  /// iOS client ID for native Google Sign-In on iOS.
  static const String googleIosClientId = String.fromEnvironment(
    'GOOGLE_IOS_CLIENT_ID',
  );

  // ── Support & Contact ─────────────────────────────────────────────────────

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
