import 'dart:convert';
import 'package:campverse/core/config/app_config.dart';
import 'package:campverse/core/models/api_response.dart';
import 'package:campverse/core/models/app_role.dart';
import 'package:http/http.dart' as http;
import 'package:supabase_flutter/supabase_flutter.dart';

/// Service interfacing with the Deno API Gateway for role derivation
/// and claim validation.
class RoleService {
  /// Default constructor for RoleService.
  RoleService({
    http.Client? httpClient,
    SupabaseClient? supabaseClient,
  })  : _http = httpClient ?? http.Client(),
        _supabase = supabaseClient ?? Supabase.instance.client;

  final http.Client _http;
  final SupabaseClient _supabase;

  /// Derive all roles for the authenticated user from the backend.
  Future<List<AppRole>> resolveUserRoles(String accessToken) async {
    try {
      final url = Uri.parse('${AppConfig.apiBaseUrl}/auth/resolve-roles');
      final response = await _http.post(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $accessToken',
        },
      ).timeout(const Duration(seconds: 5));

      if (response.statusCode == 200) {
        final dynamic decoded = jsonDecode(response.body);
        if (decoded is Map<String, dynamic>) {
          final apiResp = ApiResponse<List<dynamic>>.fromJson(
            decoded,
            (d) => d as List<dynamic>,
          );
          if (apiResp.success && apiResp.data != null) {
            return apiResp.data!
                .map((r) => AppRole.fromDbString(r.toString()))
                .toSet()
                .toList();
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
        return result
            .map((r) => AppRole.fromDbString(r.toString()))
            .toSet()
            .toList();
      }
    } on Exception {
      // Return default student fallback
    }

    return [AppRole.student];
  }

  /// Request the backend to validate and set the user's active role.
  Future<ApiResponse<String>> setActiveRole({
    required String accessToken,
    required AppRole targetRole,
  }) async {
    try {
      final url = Uri.parse('${AppConfig.apiBaseUrl}/auth/set-active-role');
      final response = await _http.post(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $accessToken',
        },
        body: jsonEncode({'target_role': targetRole.dbValue}),
      ).timeout(const Duration(seconds: 5));

      if (response.statusCode == 200) {
        final dynamic decoded = jsonDecode(response.body);
        if (decoded is Map<String, dynamic>) {
          return ApiResponse<String>.fromJson(
            decoded,
            (d) => d.toString(),
          );
        }
      }
    } on Exception {
      // Fallback to metadata update
    }

    try {
      // Local fallback: update user metadata
      await _supabase.auth.updateUser(
        UserAttributes(
          data: {'active_role': targetRole.dbValue},
        ),
      );
      await _supabase.auth.refreshSession();
      return const ApiResponse<String>(
        success: true,
        message: 'Role set successfully',
      );
    } on Exception catch (e) {
      return ApiResponse<String>(success: false, error: e.toString());
    }
  }
}
