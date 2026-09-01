import 'dart:async';

import 'package:campverse/core/models/app_role.dart';
import 'package:campverse/core/models/auth_user.dart';
import 'package:campverse/core/models/login_result.dart';
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

/// Central state notifier provider managing auth, passkeys, and roles.
final authStateProvider = StateNotifierProvider<AuthNotifier, AuthUserState>((
  ref,
) {
  return AuthNotifier(
    authService: ref.read(supabaseAuthServiceProvider),
    roleService: ref.read(roleServiceProvider),
    storageService: ref.read(secureStorageServiceProvider),
  );
});

/// StateNotifier orchestrating authentication flows, MFA, role management,
/// and the 30-minute role-switch TTL restore behavior.
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
  bool _isProcessingSession = false;
  String? _lastProcessedToken;

  void _init() {
    unawaited(_processSession(authService.currentSession));

    _authSubscription = authService.client.auth.onAuthStateChange.listen((
      data,
    ) {
      final event = data.event;
      final session = data.session;

      if (event == AuthChangeEvent.signedIn ||
          event == AuthChangeEvent.tokenRefreshed ||
          event == AuthChangeEvent.userUpdated) {
        unawaited(_processSession(session));
      } else if (event == AuthChangeEvent.signedOut) {
        _lastProcessedToken = null;
        state = const AuthUserState();
      }
    });
  }

  /// Clear any active error message banner.
  void clearError() {
    if (state.errorMessage != null) {
      state = state.copyWith(clearError: true);
    }
  }

  // ── Session Processing ─────────────────────────────────────────────────────

  Future<void> _processSession(Session? session) async {
    if (session == null) {
      _lastProcessedToken = null;
      state = const AuthUserState();
      return;
    }

    // Skip redundant processing if already fully authenticated with this exact token
    if (_lastProcessedToken == session.accessToken &&
        state.isAuthenticated &&
        state.activeRole != null &&
        !state.isLoading) {
      return;
    }

    if (_isProcessingSession) return;
    _isProcessingSession = true;

    try {
      state = state.copyWith(
        isLoading: true,
        session: session,
        user: session.user,
        clearError: true,
        clearAccountFlags: true,
      );

      // 1. Validate login eligibility (profile exists, account active)
      final loginStatus = await roleService.checkLoginStatus(
        session.accessToken,
      );

      if (!loginStatus.allowed) {
        // Sign out immediately — no valid institutional profile
        await authService.signOut();
        await storageService.clearAll();

        _lastProcessedToken = null;
        state = AuthUserState(
          accountNotFound:
              loginStatus.isNoProfile ||
              loginStatus.isPendingVerification ||
              loginStatus.isAlumni,
          accountSuspended: loginStatus.isSuspended,
          errorMessage: loginStatus.message,
        );
        return;
      }

      // 2. Check MFA status
      final factors = await authService.getEnrolledMfaFactors();
      if (factors.isNotEmpty) {
        final isVerified = await storageService.isMfaVerifiedForSession(
          session.accessToken,
        );
        if (!isVerified) {
          state = state.copyWith(
            isMfaPending: true,
            isLoading: false,
            loadingAction: AuthLoadingAction.none,
          );
          return;
        }
      }

      // 3. Fetch server-derived authorized roles
      final roles = await roleService.resolveUserRoles(session.accessToken);

      // 4. Determine base role from login-status response (server-authoritative)
      final baseRole =
          loginStatus.baseRole ??
          (roles.isNotEmpty ? roles.first : AppRole.student);

      final finalRoles = roles.isNotEmpty ? roles : [baseRole];

      // 5. Restore switched role if within 30-minute TTL window, or keep existing activeRole
      var activeRole = baseRole;
      final restoredRoleStr = await storageService.getRestoredRoleIfValid();
      if (restoredRoleStr != null) {
        final restoredRole = AppRole.fromDbString(restoredRoleStr);
        // Only restore if the role is still in the user's authorized roles
        if (finalRoles.contains(restoredRole)) {
          activeRole = restoredRole;
        } else {
          // Role no longer authorized — clear the stale switch
          await storageService.clearRoleSwitch();
        }
      } else if (state.activeRole != null && finalRoles.contains(state.activeRole)) {
        // Preserve current activeRole across token refresh / session updates
        activeRole = state.activeRole!;
      }

      // Single-role users always use their only role
      if (finalRoles.length == 1) {
        activeRole = finalRoles.first;
      }

      _lastProcessedToken = session.accessToken;

      state = state.copyWith(
        session: session,
        user: session.user,
        baseRole: baseRole,
        availableRoles: finalRoles,
        activeRole: activeRole,
        isMfaPending: false,
        isLoading: false,
        loadingAction: AuthLoadingAction.none,
        clearError: true,
        clearAccountFlags: true,
      );

      // Fetch user's registered passkeys in background
      unawaited(loadUserPasskeys());
    } on Exception catch (e) {
      state = state.copyWith(
        isLoading: false,
        loadingAction: AuthLoadingAction.none,
        errorMessage: 'Failed to initialize session: $e',
      );
    } finally {
      _isProcessingSession = false;
    }
  }

  // ── Sign-In Methods ────────────────────────────────────────────────────────

  /// Sign in with email/username + password.
  ///
  /// Returns a [LoginResult] describing the outcome so the UI can
  /// distinguish "no account" from credential errors or MFA requirements.
  Future<LoginResult> signInWithPassword({
    required String email,
    required String password,
    String? captchaToken,
  }) async {
    state = state.copyWith(
      isLoading: true,
      loadingAction: AuthLoadingAction.password,
      clearError: true,
    );
    try {
      final res = await authService.signInWithPassword(
        email: email,
        password: password,
        captchaToken: captchaToken,
      );
      if (res.session != null) {
        await _processSession(res.session);
        return _loginResultFromState();
      }
      state = state.copyWith(
        isLoading: false,
        loadingAction: AuthLoadingAction.none,
        errorMessage: 'Invalid credentials. Please check your login details.',
      );
      return const LoginError(
        'Invalid credentials. Please check your login details.',
      );
    } on AuthException catch (e) {
      final msg = _mapAuthException(e);
      state = state.copyWith(
        isLoading: false,
        loadingAction: AuthLoadingAction.none,
        errorMessage: msg,
      );
      return LoginError(msg);
    } on Exception catch (e) {
      final msg = e.toString();
      state = state.copyWith(
        isLoading: false,
        loadingAction: AuthLoadingAction.none,
        errorMessage: msg,
      );
      return LoginError(msg);
    }
  }

  /// Sign in with WebAuthn passkey.
  Future<LoginResult> signInWithPasskey({String? captchaToken}) async {
    state = state.copyWith(
      isLoading: true,
      loadingAction: AuthLoadingAction.passkey,
      clearError: true,
    );
    try {
      final res = await authService.signInWithPasskey(
        captchaToken: captchaToken,
      );
      if (res.session != null) {
        await _processSession(res.session);
        return _loginResultFromState();
      }

      final currentSession = authService.currentSession;
      if (currentSession != null) {
        await _processSession(currentSession);
        return _loginResultFromState();
      }

      const msg = 'No matching passkey found on this device.';
      state = state.copyWith(
        isLoading: false,
        loadingAction: AuthLoadingAction.none,
        errorMessage: msg,
      );
      return const LoginError(msg);
    } on Object catch (e) {
      final friendlyError = SupabaseAuthService.mapPasskeyError(e);
      state = state.copyWith(
        isLoading: false,
        loadingAction: AuthLoadingAction.none,
        errorMessage: friendlyError,
      );
      return LoginError(friendlyError);
    }
  }

  /// Sign in with Google (OAuth / Native ID token).
  Future<LoginResult> signInWithGoogle({
    String? webClientId,
    String? iosClientId,
    String? redirectTo,
  }) async {
    state = state.copyWith(
      isLoading: true,
      loadingAction: AuthLoadingAction.google,
      clearError: true,
    );
    try {
      final res = await authService.signInWithGoogle(
        webClientId: webClientId,
        iosClientId: iosClientId,
        redirectTo: redirectTo,
      );
      if (res?.session != null) {
        await _processSession(res!.session);
        return _loginResultFromState();
      }

      final currentSession = authService.currentSession;
      if (currentSession != null) {
        await _processSession(currentSession);
        return _loginResultFromState();
      }

      state = state.copyWith(
        isLoading: false,
        loadingAction: AuthLoadingAction.none,
      );
      return const LoginSuccess(); // OAuth redirect flow — result comes later
    } on Object catch (e) {
      final msg = e is AuthException ? e.message : e.toString();
      state = state.copyWith(
        isLoading: false,
        loadingAction: AuthLoadingAction.none,
        errorMessage: msg,
      );
      return LoginError(msg);
    }
  }

  /// Derives a [LoginResult] from current state after [_processSession].
  LoginResult _loginResultFromState() {
    if (state.accountNotFound) return const LoginNoAccount();
    if (state.accountSuspended) return const LoginSuspended();
    if (state.isMfaPending) return const LoginMfaPending();
    if (state.session != null) return const LoginSuccess();
    return LoginError(state.errorMessage ?? 'Login failed.');
  }

  /// Maps Supabase [AuthException] codes to user-friendly messages.
  static String _mapAuthException(AuthException e) {
    switch (e.code) {
      case 'invalid_credentials':
        return 'Invalid email or password. Please check your credentials.';
      case 'email_not_confirmed':
        return 'Account email is not confirmed. Please check your inbox.';
      case 'user_banned':
        return 'This account has been suspended by your institution admin.';
      case 'too_many_requests':
        return 'Too many login attempts. Please wait a moment and try again.';
      default:
        return e.message;
    }
  }

  // ── Passkeys ───────────────────────────────────────────────────────────────

  /// Loads the registered passkeys for the current authenticated user.
  Future<void> loadUserPasskeys() async {
    if (state.session == null) return;

    state = state.copyWith(isLoadingPasskeys: true);
    try {
      final passkeys = await authService.listPasskeys();
      state = state.copyWith(
        userPasskeys: passkeys,
        isLoadingPasskeys: false,
      );
    } on Object {
      state = state.copyWith(isLoadingPasskeys: false);
    }
  }

  /// Registers a new WebAuthn passkey for the current account.
  Future<bool> registerPasskey({String? friendlyName}) async {
    state = state.copyWith(isLoadingPasskeys: true, clearError: true);
    try {
      final newPasskey = await authService.registerPasskey(
        friendlyName: friendlyName,
      );
      final updatedList = [newPasskey, ...state.userPasskeys];
      state = state.copyWith(
        userPasskeys: updatedList,
        isLoadingPasskeys: false,
      );
      return true;
    } on Object catch (e) {
      final errorMsg = SupabaseAuthService.mapPasskeyError(e);
      state = state.copyWith(
        isLoadingPasskeys: false,
        errorMessage: errorMsg,
      );
      return false;
    }
  }

  /// Renames an existing passkey.
  Future<bool> updatePasskeyName({
    required String passkeyId,
    required String friendlyName,
  }) async {
    state = state.copyWith(isLoadingPasskeys: true, clearError: true);
    try {
      await authService.updatePasskeyName(
        passkeyId: passkeyId,
        friendlyName: friendlyName,
      );
      final updatedList = state.userPasskeys.map((p) {
        if (p.id == passkeyId) {
          return p.copyWith(friendlyName: friendlyName);
        }
        return p;
      }).toList();
      state = state.copyWith(
        userPasskeys: updatedList,
        isLoadingPasskeys: false,
      );
      return true;
    } on Object catch (e) {
      final errorMsg = SupabaseAuthService.mapPasskeyError(e);
      state = state.copyWith(
        isLoadingPasskeys: false,
        errorMessage: errorMsg,
      );
      return false;
    }
  }

  /// Deletes / revokes an existing passkey.
  Future<bool> deletePasskey({required String passkeyId}) async {
    state = state.copyWith(isLoadingPasskeys: true, clearError: true);
    try {
      await authService.deletePasskey(passkeyId: passkeyId);
      final updatedList = state.userPasskeys
          .where((p) => p.id != passkeyId)
          .toList();
      state = state.copyWith(
        userPasskeys: updatedList,
        isLoadingPasskeys: false,
      );
      return true;
    } on Object catch (e) {
      final errorMsg = SupabaseAuthService.mapPasskeyError(e);
      state = state.copyWith(
        isLoadingPasskeys: false,
        errorMessage: errorMsg,
      );
      return false;
    }
  }

  // ── MFA ────────────────────────────────────────────────────────────────────

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

  // ── Role Management ────────────────────────────────────────────────────────

  /// Switch the active role (server-validated).
  ///
  /// Persists the switch with a 30-minute TTL in secure storage.
  /// After 30 minutes of app closure, the next open reverts to [baseRole].
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
      if (session == null) return false;

      final res = await roleService.setActiveRole(
        accessToken: session.accessToken,
        targetRole: targetRole,
      );

      if (res.success) {
        // Persist switch with TTL (base_role skips TTL storage — no need)
        if (targetRole != state.baseRole) {
          await storageService.storeRoleSwitch(targetRole.dbValue);
        } else {
          await storageService.clearRoleSwitch();
        }

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

  // ── Sign Out ───────────────────────────────────────────────────────────────

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
