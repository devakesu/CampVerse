import 'package:campverse/core/models/app_role.dart';
import 'package:campverse/core/models/auth_user.dart';
import 'package:campverse/core/models/passkey_model.dart';
import 'package:campverse/core/services/supabase_auth_service.dart';
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
}

