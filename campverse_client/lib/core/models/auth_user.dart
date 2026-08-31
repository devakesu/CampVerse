import 'package:campverse/core/models/app_role.dart';
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
  });

  /// Active Supabase session if authenticated.
  final Session? session;

  /// User profile details from Supabase.
  final User? user;

  /// Primary base role of the user.
  final AppRole baseRole;

  /// All derived roles authorized for the user.
  final List<AppRole> availableRoles;

  /// Currently active role perspective for the session.
  final AppRole? activeRole;

  /// True if MFA challenge verification is awaiting completion.
  final bool isMfaPending;

  /// True if an authentication network operation is running.
  final bool isLoading;

  /// User-facing error message if any.
  final String? errorMessage;

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
    bool clearActiveRole = false,
    bool clearError = false,
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
    );
  }
}
