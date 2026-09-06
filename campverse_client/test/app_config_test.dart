import 'package:campverse/core/config/app_config.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('AppConfig URL resolution tests', () {
    test(
      'Forces custom values in kDebugMode even if env is provided',
      () {
        // In debug mode, envValue should be ignored in favor of debug URL
        expect(
          AppConfig.resolveSupabaseUrl(
            isAndroid: true,
            envValue: 'https://production.supabase.co',
          ),
          'http://10.0.2.2:54321',
        );

        expect(
          AppConfig.resolveSupabaseUrl(
            isLinux: true,
            envValue: 'https://production.supabase.co',
          ),
          'http://host.docker.internal:54321',
        );

        expect(
          AppConfig.resolveSupabaseUrl(
            isMacOS: true,
            envValue: 'https://production.supabase.co',
          ),
          'http://localhost:54321',
        );

        expect(
          AppConfig.resolveSupabaseUrl(
            isWindows: true,
            envValue: 'https://production.supabase.co',
          ),
          'http://localhost:54321',
        );

        expect(
          AppConfig.resolveSupabaseUrl(
            isWeb: true,
            envValue: 'https://production.supabase.co',
          ),
          'http://localhost:54321',
        );
      },
    );

    test('Uses environment value in release mode', () {
      expect(
        AppConfig.resolveSupabaseUrl(
          isDebug: false,
          isAndroid: true,
          envValue: 'https://my-project.supabase.co',
        ),
        'https://my-project.supabase.co',
      );

      expect(
        AppConfig.resolveApiBaseUrl(
          isDebug: false,
          isAndroid: true,
          envValue: 'https://api.campverse.dev/api',
        ),
        'https://api.campverse.dev/api',
      );
    });

    test('Resolves API Base URL correctly in debug mode', () {
      expect(
        AppConfig.resolveApiBaseUrl(
          isAndroid: true,
        ),
        'http://10.0.2.2:80/api',
      );

      expect(
        AppConfig.resolveApiBaseUrl(
          isLinux: true,
        ),
        'http://localhost:80/api',
      );

      expect(
        AppConfig.resolveApiBaseUrl(
          isMacOS: true,
        ),
        'http://localhost:80/api',
      );

      expect(
        AppConfig.resolveApiBaseUrl(
          isWindows: true,
        ),
        'http://localhost:80/api',
      );
    });
  });
}
