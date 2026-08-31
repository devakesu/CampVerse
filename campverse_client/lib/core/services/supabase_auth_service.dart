import 'package:campverse/core/models/app_role.dart';
import 'package:jwt_decoder/jwt_decoder.dart';
import 'package:local_auth/local_auth.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Supabase authentication service handling credentials, MFA, and passkeys.
class SupabaseAuthService {
  /// Default constructor accepting optional injected clients for testing.
  SupabaseAuthService({
    SupabaseClient? client,
    LocalAuthentication? localAuth,
  })  : _client = client ?? Supabase.instance.client,
        _localAuth = localAuth ?? LocalAuthentication();

  final SupabaseClient _client;
  final LocalAuthentication _localAuth;

  /// Direct handle to the underlying SupabaseClient.
  SupabaseClient get client => _client;

  /// Current active Supabase authentication session.
  Session? get currentSession => _client.auth.currentSession;

  /// Current authenticated Supabase user profile.
  User? get currentUser => _client.auth.currentUser;

  /// Sign in with Email/Username + Password.
  Future<AuthResponse> signInWithPassword({
    required String email,
    required String password,
  }) async {
    return _client.auth.signInWithPassword(
      email: email.trim(),
      password: password,
    );
  }

  /// Sign in with Device Biometrics / Passkey simulation.
  Future<bool> authenticateWithBiometrics() async {
    try {
      final isSupported = await _localAuth.isDeviceSupported();
      final canCheckBiometrics = await _localAuth.canCheckBiometrics;
      if (!isSupported && !canCheckBiometrics) {
        return false;
      }

      return await _localAuth.authenticate(
        localizedReason:
            'Authenticate with Passkey / Biometrics to access CampVerse',
        options: const AuthenticationOptions(
          stickyAuth: true,
        ),
      );
    } on Exception {
      return false;
    }
  }

  /// Verify TOTP MFA challenge.
  Future<void> verifyTotpChallenge({
    required String factorId,
    required String code,
  }) async {
    final challenge = await _client.auth.mfa.challenge(factorId: factorId);
    await _client.auth.mfa.verify(
      factorId: factorId,
      challengeId: challenge.id,
      code: code.trim(),
    );
  }

  /// Verify Email or Phone OTP.
  Future<AuthResponse> verifyEmailOrSmsOtp({
    required String emailOrPhone,
    required String token,
    required OtpType type,
  }) async {
    return _client.auth.verifyOTP(
      email: type == OtpType.email ? emailOrPhone : null,
      phone: type == OtpType.sms ? emailOrPhone : null,
      token: token.trim(),
      type: type,
    );
  }

  /// Extract active role claim from session JWT (server-signed app_metadata).
  AppRole? extractActiveRoleFromJwt(Session? session) {
    if (session == null || session.accessToken.isEmpty) {
      return null;
    }

    try {
      final decoded = JwtDecoder.decode(session.accessToken);
      final appMetadata = decoded['app_metadata'] as Map<String, dynamic>?;
      if (appMetadata != null && appMetadata.containsKey('active_role')) {
        return AppRole.fromClaim(appMetadata['active_role']);
      }
      final userMetadata = decoded['user_metadata'] as Map<String, dynamic>?;
      if (userMetadata != null && userMetadata.containsKey('active_role')) {
        return AppRole.fromClaim(userMetadata['active_role']);
      }
    } on Exception {
      // In case decoding fails, return null to force re-auth
    }
    return null;
  }

  /// Check if user has enrolled verified MFA factors.
  Future<List<Factor>> getEnrolledMfaFactors() async {
    try {
      final factors = await _client.auth.mfa.listFactors();
      return factors.totp
          .where((f) => f.status == FactorStatus.verified)
          .toList();
    } on Exception {
      return [];
    }
  }

  /// Sign out and terminate active session.
  Future<void> signOut() async {
    await _client.auth.signOut();
  }
}
