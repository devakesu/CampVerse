import 'package:campverse/core/models/app_role.dart';
import 'package:campverse/core/models/auth_user.dart';
import 'package:campverse/core/models/passkey_model.dart';
import 'package:campverse/core/providers/auth_provider.dart';
import 'package:campverse/core/services/secure_storage_service.dart';
import 'package:campverse/core/services/supabase_auth_service.dart';
import 'package:campverse/features/auth/login/login_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

void main() {
  group('AppRole Model & Claim Security Tests', () {
    test('AppRole parses all valid PostgreSQL database strings', () {
      expect(AppRole.fromDbString('super_admin'), AppRole.superAdmin);
      expect(AppRole.fromDbString('principal'), AppRole.principal);
      expect(AppRole.fromDbString('office_admin'), AppRole.officeAdmin);
      expect(AppRole.fromDbString('student_union'), AppRole.studentUnion);
      expect(AppRole.fromDbString('hod'), AppRole.hod);
      expect(AppRole.fromDbString('faculty'), AppRole.faculty);
      expect(AppRole.fromDbString('club_admin'), AppRole.clubAdmin);
      expect(AppRole.fromDbString('student'), AppRole.student);
    });

    test('AppRole returns default student for unknown or null strings', () {
      expect(AppRole.fromDbString(null), AppRole.student);
      expect(AppRole.fromDbString('invalid_role'), AppRole.student);
    });

    test('AppRole.fromClaim safely parses JWT claim strings', () {
      expect(AppRole.fromClaim('club_admin'), AppRole.clubAdmin);
      expect(AppRole.fromClaim('hod'), AppRole.hod);
      expect(AppRole.fromClaim(null), isNull);
      expect(AppRole.fromClaim(''), isNull);
    });

    test('HOD role correctly implies faculty access', () {
      expect(AppRole.hod.impliesFaculty, isTrue);
      expect(AppRole.student.impliesFaculty, isFalse);
      expect(AppRole.clubAdmin.impliesFaculty, isFalse);
    });

    test('AuthUserState computed properties', () {
      const state1 = AuthUserState(
        availableRoles: [AppRole.student, AppRole.clubAdmin],
      );
      expect(state1.hasMultipleRoles, isTrue);

      const state2 = AuthUserState();
      expect(state2.hasMultipleRoles, isFalse);
    });

    test('AuthUserState handles loadingAction and copyWith accurately', () {
      const initial = AuthUserState();
      expect(initial.loadingAction, AuthLoadingAction.none);

      final passwordLoading = initial.copyWith(
        isLoading: true,
        loadingAction: AuthLoadingAction.password,
      );
      expect(passwordLoading.isLoading, isTrue);
      expect(passwordLoading.loadingAction, AuthLoadingAction.password);

      final passkeyLoading = initial.copyWith(
        isLoading: true,
        loadingAction: AuthLoadingAction.passkey,
      );
      expect(passkeyLoading.loadingAction, AuthLoadingAction.passkey);

      final resetState = passwordLoading.copyWith(isLoading: false);
      expect(resetState.isLoading, isFalse);
      expect(resetState.loadingAction, AuthLoadingAction.none);
    });
  });

  group('WebAuthn Passkey Model & Error Translation Tests', () {
    test('AppPasskey parses JSON and detects device type accurately', () {
      final macPasskey = AppPasskey.fromJson(const {
        'id': 'pk-123',
        'friendly_name': 'MacBook Pro Touch ID',
        'created_at': '2026-09-01T12:00:00Z',
      });
      expect(macPasskey.deviceType, PasskeyDeviceType.apple);
      expect(macPasskey.id, 'pk-123');

      final yubiPasskey = AppPasskey.fromJson(const {
        'id': 'pk-456',
        'friendly_name': 'YubiKey 5C NFC',
        'created_at': '2026-09-01T12:00:00Z',
      });
      expect(yubiPasskey.deviceType, PasskeyDeviceType.securityKey);

      final windowsPasskey = AppPasskey.fromJson(const {
        'id': 'pk-789',
        'friendly_name': 'Windows Hello Office Laptop',
        'created_at': '2026-09-01T12:00:00Z',
      });
      expect(windowsPasskey.deviceType, PasskeyDeviceType.windows);

      final pixelPasskey = AppPasskey.fromJson(const {
        'id': 'pk-999',
        'friendly_name': 'Google Pixel Fingerprint',
        'created_at': '2026-09-01T12:00:00Z',
      });
      expect(pixelPasskey.deviceType, PasskeyDeviceType.google);
    });

    test('SupabaseAuthService translates WebAuthn error codes cleanly', () {
      expect(
        SupabaseAuthService.mapPasskeyError(
          const AuthException('Passkey disabled', code: 'passkey_disabled'),
        ),
        contains('not enabled'),
      );

      expect(
        SupabaseAuthService.mapPasskeyError(
          const AuthException(
            'Credential not found',
            code: 'webauthn_credential_not_found',
          ),
        ),
        contains('No matching passkey found'),
      );

      expect(
        SupabaseAuthService.mapPasskeyError(
          const AuthException(
            'Challenge expired',
            code: 'webauthn_challenge_expired',
          ),
        ),
        contains('challenge expired'),
      );

      expect(
        SupabaseAuthService.mapPasskeyError('UserCancelled WebAuthn ceremony'),
        'Passkey authentication cancelled.',
      );
    });
  });

  group('LoginScreen Responsive & Overflow Tests', () {
    testWidgets(
      'LoginScreen renders without overflow on various window sizes',
      (tester) async {
        final screenSizes = [
          const Size(1920, 1080), // Standard 1080p Desktop
          const Size(1440, 900), // Common Laptop Desktop
          const Size(1280, 720), // Compact Desktop
          const Size(
            1024,
            600,
          ), // Low-height / Netbook (original 80px overflow)
          const Size(800, 600), // Narrow desktop
          const Size(800, 480), // Extreme low height desktop
          const Size(768, 1024), // Tablet portrait
          const Size(1024, 768), // Tablet landscape
          const Size(375, 667), // Standard Mobile portrait
          const Size(414, 896), // Large Mobile portrait
          const Size(667, 375), // Mobile landscape
          const Size(320, 568), // Ultra-compact mobile
        ];

        for (final size in screenSizes) {
          tester.view.physicalSize = size;
          tester.view.devicePixelRatio = 1.0;
          addTearDown(() {
            tester.view.resetPhysicalSize();
            tester.view.resetDevicePixelRatio();
          });

          await tester.pumpWidget(
            ProviderScope(
              overrides: [
                authStateProvider.overrideWith(
                  (ref) => _MockAuthNotifier(),
                ),
              ],
              child: const MaterialApp(
                home: LoginScreen(),
              ),
            ),
          );
          await tester.pumpAndSettle();

          final err = tester.takeException();
          expect(
            err,
            isNull,
            reason: 'RenderFlex overflow occurred at size: $size',
          );
        }
      },
    );

    testWidgets('LoginScreen handles dynamic window resize without error', (
      tester,
    ) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            authStateProvider.overrideWith(
              (ref) => _MockAuthNotifier(),
            ),
          ],
          child: const MaterialApp(
            home: LoginScreen(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      final resizeSequence = [
        const Size(1920, 1080),
        const Size(1024, 600),
        const Size(800, 500),
        const Size(760, 900), // Cross desktop/mobile boundary
        const Size(375, 667),
        const Size(667, 375),
        const Size(1280, 720),
      ];

      for (final size in resizeSequence) {
        tester.view.physicalSize = size;
        tester.view.devicePixelRatio = 1.0;
        await tester.pumpAndSettle();
        expect(
          tester.takeException(),
          isNull,
          reason: 'Error occurred during dynamic window resize to $size',
        );
      }
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });
  });

  group('SecureStorageService Tests', () {
    setUp(() {
      FlutterSecureStorage.setMockInitialValues(<String, String>{});
    });

    test(
      'SecureStorageService saves and retrieves active role safely',
      () async {
        final service = SecureStorageService();
        await service.saveActiveRole('faculty');
        final role = await service.getActiveRole();
        expect(role, 'faculty');
        await service.clearActiveRole();
        expect(await service.getActiveRole(), isNull);
      },
    );

    test(
      'SecureStorageService manages MFA session verification safely',
      () async {
        final service = SecureStorageService();
        await service.setMfaVerifiedForSession('session-123');
        expect(await service.isMfaVerifiedForSession('session-123'), isTrue);
        expect(await service.isMfaVerifiedForSession('session-other'), isFalse);
      },
    );

    test(
      'SecureStorageService stores and restores role switch within TTL',
      () async {
        final service = SecureStorageService();
        await service.storeRoleSwitch('club_admin');
        final role = await service.getRestoredRoleIfValid();
        expect(role, 'club_admin');
        await service.clearRoleSwitch();
        expect(await service.getRestoredRoleIfValid(), isNull);
      },
    );

    test(
      'SecureStorageService clearAll cleans all state without error',
      () async {
        final service = SecureStorageService();
        await service.saveActiveRole('principal');
        await service.storeRoleSwitch('principal');
        await service.clearAll();
        expect(await service.getActiveRole(), isNull);
        expect(await service.getRestoredRoleIfValid(), isNull);
      },
    );
  });
}

class _MockAuthNotifier extends StateNotifier<AuthUserState>
    implements AuthNotifier {
  _MockAuthNotifier() : super(const AuthUserState());

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}
