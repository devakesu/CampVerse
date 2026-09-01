/// Sealed class representing the typed outcome of a login attempt.
///
/// Replaces the bare [bool] return from sign-in methods so the UI can
/// distinguish between different failure states without parsing error strings.
sealed class LoginResult {
  const LoginResult();
}

/// Authentication succeeded and the session is fully established.
final class LoginSuccess extends LoginResult {
  /// Creates a successful login result.
  const LoginSuccess();
}

/// Authentication succeeded but MFA verification is required before access.
final class LoginMfaPending extends LoginResult {
  /// Creates a MFA-pending login result.
  const LoginMfaPending();
}

/// No institutional account was found for this credential.
///
/// This occurs when:
///   • The email does not exist in Supabase Auth
///   • A Google OAuth sign-in hit an account with no [profiles] row
///   • A [profiles] row exists but [status] is [pending_verification]
final class LoginNoAccount extends LoginResult {
  /// Creates a no-account result with an optional [reason] code.
  const LoginNoAccount({this.reason = 'no_profile'});

  /// Machine-readable reason: 'no_profile' | 'pending_verification' | 'alumni'.
  final String reason;
}

/// The account exists but has been suspended by an administrator.
final class LoginSuspended extends LoginResult {
  /// Creates a suspended account result.
  const LoginSuspended();
}

/// The sign-in process encountered a recoverable or unrecoverable error.
final class LoginError extends LoginResult {
  /// Creates an error result with a human-readable [message].
  const LoginError(this.message);

  /// Human-readable error message for display.
  final String message;
}
