import 'dart:convert';

import 'package:campverse/core/config/app_config.dart';
import 'package:campverse/core/models/api_response.dart';
import 'package:campverse/core/models/app_role.dart';
import 'package:http/http.dart' as http;
import 'package:supabase_flutter/supabase_flutter.dart';

// ── Login Status Model ───────────────────────────────────────────────────────

/// Result from the /auth/login-status backend endpoint.
class LoginStatusResult {
  /// Default constructor.
  const LoginStatusResult({
    required this.allowed,
    required this.baseRole,
    required this.accountStatus,
    this.errorCode,
    this.message,
  });

  /// Whether this account is allowed to log in.
  final bool allowed;

  /// The user's base role from the profiles table.
  final AppRole? baseRole;

  /// The raw account status string from the server.
  final String? accountStatus;

  /// Machine-readable error code if [allowed] is false.
  /// e.g. 'no_profile', 'suspended', 'pending_verification', 'alumni'.
  final String? errorCode;

  /// Human-readable error message from server.
  final String? message;

  /// Whether the account has no profile row.
  bool get isNoProfile => errorCode == 'no_profile';

  /// Whether the account is suspended.
  bool get isSuspended => errorCode == 'suspended';

  /// Whether the account is pending admin verification.
  bool get isPendingVerification => errorCode == 'pending_verification';

  /// Whether the account belongs to an alumni (not permitted to log in).
  bool get isAlumni => errorCode == 'alumni';
}

// ── RoleService ──────────────────────────────────────────────────────────────

/// Service interfacing with the Deno API Gateway for role derivation,
/// login status validation, and active-role claim management.
class RoleService {
  /// Default constructor for RoleService.
  RoleService({
    http.Client? httpClient,
    SupabaseClient? supabaseClient,
  }) : _http = httpClient ?? http.Client(),
       _supabase = supabaseClient ?? Supabase.instance.client;

  final http.Client _http;
  final SupabaseClient _supabase;

  // ── Login Status ───────────────────────────────────────────────────────────

  /// Validates login eligibility after Supabase authentication succeeds.
  ///
  /// Returns [LoginStatusResult] indicating:
  ///   • Whether the account is allowed to proceed
  ///   • The user's base role (always used as session start role)
  ///   • Error codes for no_profile / suspended / pending_verification
  ///
  /// Falls back to a permissive check via Supabase RPC if the API gateway
  /// is unreachable (avoids locking users out during gateway downtime).
  Future<LoginStatusResult> checkLoginStatus(String accessToken) async {
    try {
      final url = Uri.parse('${AppConfig.apiBaseUrl}/auth/login-status');
      final response = await _http
          .post(
            url,
            headers: {
              'Content-Type': 'application/json',
              'Authorization': 'Bearer $accessToken',
            },
          )
          .timeout(const Duration(seconds: 8));

      final dynamic decoded = jsonDecode(response.body);
      if (decoded is! Map<String, dynamic>) {
        return const LoginStatusResult(
          allowed: false,
          baseRole: null,
          accountStatus: null,
          errorCode: 'parse_error',
          message: 'Unexpected response from login server.',
        );
      }

      final success = decoded['success'] as bool? ?? false;

      if (response.statusCode == 200 && success) {
        final data = decoded['data'] as Map<String, dynamic>?;
        final baseRoleStr = data?['base_role'] as String?;
        final accountStatus = data?['account_status'] as String?;

        return LoginStatusResult(
          allowed: true,
          baseRole: AppRole.fromDbString(baseRoleStr),
          accountStatus: accountStatus,
        );
      }

      // Non-200 → extract error code
      final errorCode = decoded['error'] as String? ?? 'unknown';
      final message =
          decoded['message'] as String? ?? decoded['error'] as String?;
      return LoginStatusResult(
        allowed: false,
        baseRole: null,
        accountStatus: null,
        errorCode: errorCode,
        message: message,
      );
    } on Exception {
      // Gateway unreachable — fall back to direct Supabase RPC
    }

    // Supabase RPC fallback
    try {
      final user = _supabase.auth.currentUser;
      if (user != null) {
        final result = await _supabase.rpc<List<dynamic>>(
          'get_user_login_status',
          params: {'target_uid': user.id},
        );

        if (result.isNotEmpty) {
          final row = result.first as Map<String, dynamic>;
          final profileExists = row['profile_exists'] as bool? ?? false;

          if (!profileExists) {
            return const LoginStatusResult(
              allowed: false,
              baseRole: null,
              accountStatus: null,
              errorCode: 'no_profile',
              message: 'No institutional profile found for this account.',
            );
          }

          final status = row['account_status'] as String?;
          final baseRoleStr = row['base_role'] as String?;

          if (status != 'active') {
            return LoginStatusResult(
              allowed: false,
              baseRole: null,
              accountStatus: status,
              errorCode: status,
              message: 'Account is not active (status: $status).',
            );
          }

          return LoginStatusResult(
            allowed: true,
            baseRole: AppRole.fromDbString(baseRoleStr),
            accountStatus: status,
          );
        }
      }
    } on Exception {
      // Both gateway and RPC failed — fail closed for security
    }

    return const LoginStatusResult(
      allowed: false,
      baseRole: null,
      accountStatus: null,
      errorCode: 'unreachable',
      message: 'Unable to verify account status. Please try again.',
    );
  }

  // ── Derive Roles ───────────────────────────────────────────────────────────

  /// Derive all roles for the authenticated user from the backend.
  Future<List<AppRole>> resolveUserRoles(String accessToken) async {
    try {
      final url = Uri.parse('${AppConfig.apiBaseUrl}/auth/resolve-roles');
      final response = await _http
          .post(
            url,
            headers: {
              'Content-Type': 'application/json',
              'Authorization': 'Bearer $accessToken',
            },
          )
          .timeout(const Duration(seconds: 5));

      if (response.statusCode == 200) {
        final dynamic decoded = jsonDecode(response.body);
        if (decoded is Map<String, dynamic>) {
          final apiResp = ApiResponse<List<dynamic>>.fromJson(
            decoded,
            (d) => d as List<dynamic>,
          );
          if (apiResp.success && apiResp.data != null) {
            final roles = apiResp.data!
                .map((r) => AppRole.fromDbString(r.toString()))
                .toSet()
                .toList();
            if (roles.isNotEmpty) {
              return roles;
            }
          }
        }
      }
    } on Exception {
      // Fallback to Supabase RPC directly
    }

    // Direct Supabase RPC Fallback
    try {
      final user = _supabase.auth.currentUser;
      if (user != null) {
        final result = await _supabase.rpc<List<dynamic>>(
          'get_user_derived_roles',
          params: {'target_uid': user.id},
        );
        final roles = result
            .map((r) => AppRole.fromDbString(r.toString()))
            .toSet()
            .toList();
        if (roles.isNotEmpty) {
          return roles;
        }
      }
    } on Exception {
      // Fall through to empty return
    }

    return [];
  }

  // ── Set Active Role ────────────────────────────────────────────────────────

  /// Request the backend to validate and set the user's active role.
  Future<ApiResponse<String>> setActiveRole({
    required String accessToken,
    required AppRole targetRole,
  }) async {
    try {
      final url = Uri.parse('${AppConfig.apiBaseUrl}/auth/set-active-role');
      final response = await _http
          .post(
            url,
            headers: {
              'Content-Type': 'application/json',
              'Authorization': 'Bearer $accessToken',
            },
            body: jsonEncode({'target_role': targetRole.dbValue}),
          )
          .timeout(const Duration(seconds: 5));

      if (response.statusCode == 200) {
        final dynamic decoded = jsonDecode(response.body);
        if (decoded is Map<String, dynamic>) {
          return ApiResponse<String>.fromJson(
            decoded,
            (d) => d.toString(),
          );
        }
      }

      // Non-200 — extract error from body
      try {
        final dynamic decoded = jsonDecode(response.body);
        if (decoded is Map<String, dynamic>) {
          final error =
              decoded['error'] as String? ??
              decoded['message'] as String? ??
              'Failed to set active role (${response.statusCode})';
          return ApiResponse<String>(success: false, error: error);
        }
      } on Exception {
        // Ignore parse error
      }
    } on Exception {
      // Fallback to metadata update
    }

    try {
      // Local fallback: update user metadata (not in app_metadata, so not
      // server-authoritative, but keeps UI functional during gateway downtime)
      await _supabase.auth.updateUser(
        UserAttributes(
          data: {'active_role': targetRole.dbValue},
        ),
      );
      return const ApiResponse<String>(
        success: true,
        message: 'Role set successfully',
      );
    } on Exception catch (e) {
      return ApiResponse<String>(success: false, error: e.toString());
    }
  }
}
