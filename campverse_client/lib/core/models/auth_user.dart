import 'package:campverse/core/models/app_role.dart';
import 'package:campverse/core/models/passkey_model.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Representation of the authenticated user's state.
class AuthUserState {
  /// Default constructor for immutable authentication state.
  const AuthUserState({
    this.session,
    this.user,
    this.baseRole = AppRole.student,
    this.availableRoles = const [AppRole.student],
    this.activeRole,
    this.isMfaPending = false,
    this.isLoading = false,
    this.errorMessage,
    this.userPasskeys = const [],
    this.isLoadingPasskeys = false,
    this.accountNotFound = false,
    this.accountSuspended = false,
  });

  /// Active Supabase session if authenticated.
  final Session? session;

  /// User profile details from Supabase.
  final User? user;

  /// Primary base role of the user (always used as login-entry role).
  final AppRole baseRole;

  /// All derived roles authorized for the user.
  final List<AppRole> availableRoles;

  /// Currently active role perspective for the session.
  ///
  /// Set to [baseRole] on every fresh login. Switches persist for 30 minutes
  /// via the secure-storage TTL; after that, reverts to [baseRole].
  final AppRole? activeRole;

  /// True if MFA challenge verification is awaiting completion.
  final bool isMfaPending;

  /// True if an authentication network operation is running.
  final bool isLoading;

  /// User-facing error message if any.
  final String? errorMessage;

  /// List of registered passkeys for the current authenticated user.
  final List<AppPasskey> userPasskeys;

  /// True if passkeys list is currently being fetched or modified.
  final bool isLoadingPasskeys;

  /// True when login was attempted but no institutional profile was found,
  /// or the profile is pending_verification or alumni status.
  /// The UI surfaces a "contact your institution admin" message.
  final bool accountNotFound;

  /// True when login was attempted but the account has been suspended.
  /// The UI surfaces a distinct suspension warning.
  final bool accountSuspended;

  /// True if session is present and MFA has cleared.
  bool get isAuthenticated => session != null && !isMfaPending;

  /// True if user is authorized for more than one role.
  bool get hasMultipleRoles => availableRoles.length > 1;

  /// Creates a copy of this state with specified overrides.
  AuthUserState copyWith({
    Session? session,
    User? user,
    AppRole? baseRole,
    List<AppRole>? availableRoles,
    AppRole? activeRole,
    bool? isMfaPending,
    bool? isLoading,
    String? errorMessage,
    List<AppPasskey>? userPasskeys,
    bool? isLoadingPasskeys,
    bool? accountNotFound,
    bool? accountSuspended,
    bool clearActiveRole = false,
    bool clearError = false,
    bool clearAccountFlags = false,
  }) {
    return AuthUserState(
      session: session ?? this.session,
      user: user ?? this.user,
      baseRole: baseRole ?? this.baseRole,
      availableRoles: availableRoles ?? this.availableRoles,
      activeRole: clearActiveRole ? null : (activeRole ?? this.activeRole),
      isMfaPending: isMfaPending ?? this.isMfaPending,
      isLoading: isLoading ?? this.isLoading,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
      userPasskeys: userPasskeys ?? this.userPasskeys,
      isLoadingPasskeys: isLoadingPasskeys ?? this.isLoadingPasskeys,
      accountNotFound: !clearAccountFlags && (accountNotFound ?? this.accountNotFound),
      accountSuspended: !clearAccountFlags && (accountSuspended ?? this.accountSuspended),
    );
  }
}
