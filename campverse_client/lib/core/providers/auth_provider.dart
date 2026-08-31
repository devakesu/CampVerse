import 'dart:async';
import 'package:campverse/core/models/app_role.dart';
import 'package:campverse/core/models/auth_user.dart';
import 'package:campverse/core/services/role_service.dart';
import 'package:campverse/core/services/secure_storage_service.dart';
import 'package:campverse/core/services/supabase_auth_service.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Provider exposing SecureStorageService instance.
final secureStorageServiceProvider = Provider<SecureStorageService>((ref) {
  return SecureStorageService();
});

/// Provider exposing SupabaseAuthService instance.
final supabaseAuthServiceProvider = Provider<SupabaseAuthService>((ref) {
  return SupabaseAuthService();
});

/// Provider exposing RoleService instance.
final roleServiceProvider = Provider<RoleService>((ref) {
  return RoleService();
});

/// Central state notifier provider managing authentication and roles.
final authStateProvider =
    StateNotifierProvider<AuthNotifier, AuthUserState>((ref) {
  return AuthNotifier(
    authService: ref.read(supabaseAuthServiceProvider),
    roleService: ref.read(roleServiceProvider),
    storageService: ref.read(secureStorageServiceProvider),
  );
});

/// StateNotifier orchestrating authentication flows, MFA, and role state.
class AuthNotifier extends StateNotifier<AuthUserState> {
  /// Default constructor for AuthNotifier.
  AuthNotifier({
    required this.authService,
    required this.roleService,
    required this.storageService,
  }) : super(const AuthUserState(isLoading: true)) {
    _init();
  }

  /// Supabase authentication service.
  final SupabaseAuthService authService;

  /// Role resolution and assignment service.
  final RoleService roleService;

  /// Hardware-encrypted storage service.
  final SecureStorageService storageService;

  StreamSubscription<AuthState>? _authSubscription;

  void _init() {
    unawaited(_processSession(authService.currentSession));

    _authSubscription =
        authService.client.auth.onAuthStateChange.listen((data) {
      final event = data.event;
      final session = data.session;

      if (event == AuthChangeEvent.signedIn ||
          event == AuthChangeEvent.tokenRefreshed ||
          event == AuthChangeEvent.userUpdated) {
        unawaited(_processSession(session));
      } else if (event == AuthChangeEvent.signedOut) {
        state = const AuthUserState();
      }
    });
  }

  Future<void> _processSession(Session? session) async {
    if (session == null) {
      state = const AuthUserState();
      return;
    }

    state = state.copyWith(
      isLoading: true,
      session: session,
      user: session.user,
    );

    try {
      // 1. Check MFA status
      final factors = await authService.getEnrolledMfaFactors();
      if (factors.isNotEmpty) {
        final isVerified = await storageService.isMfaVerifiedForSession(
          session.accessToken,
        );
        if (!isVerified) {
          state = state.copyWith(
            isMfaPending: true,
            isLoading: false,
          );
          return;
        }
      }

      // 2. Fetch server-derived authorized roles
      final roles = await roleService.resolveUserRoles(session.accessToken);
      final baseRole = roles.isNotEmpty ? roles.first : AppRole.student;

      // 3. Extract active role from JWT claim
      var activeRole = authService.extractActiveRoleFromJwt(session);

      // If user only has 1 role, active role is always that role
      if (roles.length == 1) {
        activeRole = roles.first;
      }

      state = state.copyWith(
        session: session,
        user: session.user,
        baseRole: baseRole,
        availableRoles: roles,
        activeRole: activeRole,
        isMfaPending: false,
        isLoading: false,
        clearError: true,
      );
    } on Exception catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: 'Failed to initialize session: $e',
      );
    }
  }

  /// Sign in with email/username + password.
  Future<bool> signInWithPassword({
    required String email,
    required String password,
  }) async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      final res = await authService.signInWithPassword(
        email: email,
        password: password,
      );
      if (res.session != null) {
        await _processSession(res.session);
        return true;
      }
      state = state.copyWith(
        isLoading: false,
        errorMessage: 'Invalid credentials. Please check your login details.',
      );
      return false;
    } on Exception catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: e is AuthException ? e.message : e.toString(),
      );
      return false;
    }
  }

  /// Sign in with biometric passkey.
  Future<bool> signInWithPasskey() async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      final authenticated = await authService.authenticateWithBiometrics();
      if (!authenticated) {
        state = state.copyWith(
          isLoading: false,
          errorMessage: 'Biometric verification cancelled or failed.',
        );
        return false;
      }

      final currentSession = authService.currentSession;
      if (currentSession != null) {
        await _processSession(currentSession);
        return true;
      }

      state = state.copyWith(
        isLoading: false,
        errorMessage: 'No stored passkey credentials found on this device.',
      );
      return false;
    } on Exception catch (e) {
      state = state.copyWith(isLoading: false, errorMessage: e.toString());
      return false;
    }
  }

  /// Verify TOTP code for MFA.
  Future<bool> verifyTotp({
    required String factorId,
    required String code,
  }) async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      await authService.verifyTotpChallenge(factorId: factorId, code: code);
      if (state.session != null) {
        await storageService.setMfaVerifiedForSession(
          state.session!.accessToken,
        );
      }
      state = state.copyWith(isMfaPending: false);
      await _processSession(authService.currentSession);
      return true;
    } on Exception {
      state = state.copyWith(
        isLoading: false,
        errorMessage: 'Invalid 2FA code. Please try again.',
      );
      return false;
    }
  }

  /// Verify Email or SMS OTP for MFA.
  Future<bool> verifyEmailOrSmsOtp({
    required String emailOrPhone,
    required String code,
    required OtpType type,
  }) async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      final res = await authService.verifyEmailOrSmsOtp(
        emailOrPhone: emailOrPhone,
        token: code,
        type: type,
      );
      if (res.session != null) {
        await storageService.setMfaVerifiedForSession(
          res.session!.accessToken,
        );
        state = state.copyWith(isMfaPending: false);
        await _processSession(res.session);
        return true;
      }
      state = state.copyWith(
        isLoading: false,
        errorMessage: 'Invalid OTP code. Please check and re-enter.',
      );
      return false;
    } on Exception catch (e) {
      state = state.copyWith(isLoading: false, errorMessage: e.toString());
      return false;
    }
  }

  /// Switch the active role (server-validated).
  Future<bool> switchRole(AppRole targetRole) async {
    if (!state.availableRoles.contains(targetRole)) {
      state = state.copyWith(
        errorMessage: 'You do not have access to this role.',
      );
      return false;
    }

    state = state.copyWith(isLoading: true, clearError: true);
    try {
      final session = state.session;
      if (session == null) {
        return false;
      }

      final res = await roleService.setActiveRole(
        accessToken: session.accessToken,
        targetRole: targetRole,
      );

      if (res.success) {
        state = state.copyWith(
          activeRole: targetRole,
          isLoading: false,
        );
        return true;
      } else {
        state = state.copyWith(
          isLoading: false,
          errorMessage: res.error ?? 'Failed to switch role.',
        );
        return false;
      }
    } on Exception catch (e) {
      state = state.copyWith(isLoading: false, errorMessage: e.toString());
      return false;
    }
  }

  /// Sign out completely and clear cached keys.
  Future<void> signOut() async {
    state = state.copyWith(isLoading: true);
    try {
      await storageService.clearAll();
      await authService.signOut();
    } finally {
      state = const AuthUserState();
    }
  }

  @override
  void dispose() {
    unawaited(_authSubscription?.cancel());
    super.dispose();
  }
}
