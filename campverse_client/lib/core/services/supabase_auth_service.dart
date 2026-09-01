// Passkey API in Supabase Flutter SDK is annotated as @experimental.
// ignore_for_file: experimental_member_use

import 'package:campverse/core/models/app_role.dart';
import 'package:campverse/core/models/passkey_model.dart';
import 'package:flutter/foundation.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:jwt_decoder/jwt_decoder.dart';
import 'package:local_auth/local_auth.dart';
import 'package:passkeys/authenticator.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Supabase authentication service handling credentials, MFA, and passkeys.
class SupabaseAuthService {
  /// Default constructor accepting optional injected clients for testing.
  SupabaseAuthService({
    SupabaseClient? client,
    LocalAuthentication? localAuth,
    PasskeyAuthenticator? authenticator,
  })  : _client = client ?? Supabase.instance.client,
        _localAuth = localAuth ?? LocalAuthentication(),
        _authenticator = authenticator ?? PasskeyAuthenticator();

  final SupabaseClient _client;
  final LocalAuthentication _localAuth;
  final PasskeyAuthenticator _authenticator;

  /// Direct handle to the underlying SupabaseClient.
  SupabaseClient get client => _client;

  /// Passkey authenticator instance for platform WebAuthn ceremonies.
  PasskeyAuthenticator get authenticator => _authenticator;

  /// Current active Supabase authentication session.
  Session? get currentSession => _client.auth.currentSession;

  /// Current authenticated Supabase user profile.
  User? get currentUser => _client.auth.currentUser;

  /// Human-friendly translation for Supabase WebAuthn and passkey error codes.
  static String mapPasskeyError(Object error) {
    if (error is AuthException) {
      final code = error.code ?? '';
      switch (code) {
        case 'passkey_disabled':
          return 'Passkey sign-in is not enabled on this project. '
              'Please sign in with password.';
        case 'too_many_passkeys':
          return 'The maximum number of passkeys allowed for this account '
              'has been reached.';
        case 'webauthn_credential_exists':
          return 'This authenticator has already been registered to '
              'your account.';
        case 'webauthn_credential_not_found':
          return 'No matching passkey found. Sign in with password or '
              'register this device.';
        case 'webauthn_challenge_not_found':
          return 'Passkey challenge was not found. Please try again.';
        case 'webauthn_challenge_expired':
          return 'The passkey challenge expired. Please retry.';
        case 'webauthn_verification_failed':
          return 'WebAuthn signature verification failed. Please try again.';
        case 'email_not_confirmed':
          return 'Account email is not confirmed. Please check your inbox.';
        case 'user_banned':
          return 'Account has been suspended. Please contact '
              'campus administration.';
        default:
          return error.message;
      }
    }
    final errStr = error.toString();
    if (errStr.contains('UserCancelled') ||
        errStr.contains('cancelled') ||
        errStr.contains('canceled') ||
        errStr.contains('AbortError') ||
        errStr.contains('NotAllowedError')) {
      return 'Passkey authentication cancelled.';
    }
    return errStr;
  }

  /// Sign in with Email / Username + Password.
  Future<AuthResponse> signInWithPassword({
    required String email,
    required String password,
    String? captchaToken,
  }) async {
    return _client.auth.signInWithPassword(
      email: email.trim(),
      password: password,
      captchaToken: captchaToken,
    );
  }

  /// Authenticate using Supabase WebAuthn Passkeys.
  Future<AuthResponse> signInWithPasskey({String? captchaToken}) async {
    return _client.auth.signInWithPasskey(
      _authenticator,
      captchaToken: captchaToken,
    );
  }

  /// Sign in with Google across Web, Desktop, iOS, and Android platforms.
  Future<AuthResponse?> signInWithGoogle({
    String? webClientId,
    String? iosClientId,
    String? redirectTo,
  }) async {
    // 1. On mobile devices (Android/iOS), try native Google Sign In
    if (!kIsWeb &&
        (defaultTargetPlatform == TargetPlatform.android ||
            defaultTargetPlatform == TargetPlatform.iOS)) {
      try {
        final googleSignIn = GoogleSignIn(
          serverClientId: webClientId,
          clientId: iosClientId,
          scopes: const ['email', 'profile'],
        );
        final googleUser = await googleSignIn.signIn();
        if (googleUser == null) {
          return null; // User cancelled
        }
        final googleAuth = await googleUser.authentication;
        final idToken = googleAuth.idToken;
        if (idToken != null) {
          return await _client.auth.signInWithIdToken(
            provider: OAuthProvider.google,
            idToken: idToken,
            accessToken: googleAuth.accessToken,
          );
        }
      } on Object {
        // If native Google Sign-in is unconfigured/fails, fallback to OAuth
      }
    }

    // 2. Universal OAuth (Web, Desktop, or Mobile deep-link)
    final launched = await _client.auth.signInWithOAuth(
      OAuthProvider.google,
      redirectTo: redirectTo ??
          (kIsWeb ? null : 'io.supabase.campverse://login-callback'),
      authScreenLaunchMode: LaunchMode.externalApplication,
    );

    if (!launched) {
      throw const AuthException('Could not launch Google Sign-In.');
    }
    return null;
  }

  /// Fallback device biometrics check (Fingerprint, Touch ID, Face ID).
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

  /// Registers a new WebAuthn passkey for the currently authenticated user.
  Future<AppPasskey> registerPasskey({String? friendlyName}) async {
    final passkey = await _client.auth.registerPasskey(_authenticator);

    var finalName = friendlyName?.trim();
    if (finalName != null && finalName.isNotEmpty) {
      try {
        final clampedName = finalName.length > 120
            ? finalName.substring(0, 120)
            : finalName;
        await _client.auth.passkey.update(
          passkeyId: passkey.id,
          friendlyName: clampedName,
        );
      } on Object {
        // If rename fails non-critically, proceed with original passkey
      }
    } else {
      finalName = passkey.friendlyName ?? 'Passkey Authenticator';
    }

    return AppPasskey(
      id: passkey.id,
      friendlyName: finalName,
      createdAt: passkey.createdAt,
    );
  }

  /// Retrieves list of all registered passkeys for the current user.
  Future<List<AppPasskey>> listPasskeys() async {
    try {
      final passkeys = await _client.auth.passkey.list();
      return passkeys.map((p) {
        return AppPasskey(
          id: p.id,
          friendlyName: p.friendlyName ?? 'Registered Passkey',
          createdAt: p.createdAt,
          lastUsedAt: p.lastUsedAt,
        );
      }).toList();
    } on Object {
      return [];
    }
  }

  /// Updates friendly name of a registered passkey.
  Future<void> updatePasskeyName({
    required String passkeyId,
    required String friendlyName,
  }) async {
    final safeName = friendlyName.trim();
    final clampedName =
        safeName.length > 120 ? safeName.substring(0, 120) : safeName;
    await _client.auth.passkey.update(
      passkeyId: passkeyId,
      friendlyName: clampedName,
    );
  }

  /// Revokes / deletes a passkey credential from Supabase Auth.
  Future<void> deletePasskey({required String passkeyId}) async {
    await _client.auth.passkey.delete(passkeyId: passkeyId);
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
