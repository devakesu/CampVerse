import 'dart:convert';

import 'package:campverse/core/config/app_config.dart';
import 'package:campverse/core/models/api_response.dart';
import 'package:campverse/core/models/institute.dart';
import 'package:campverse/core/models/university.dart';
import 'package:http/http.dart' as http;
import 'package:supabase_flutter/supabase_flutter.dart';

/// Data payload for creating an administrative user during institute
/// onboarding.
class AdminUserCreationData {
  /// Default constructor.
  const AdminUserCreationData({
    required this.name,
    required this.email,
    required this.password,
    this.phone,
  });

  /// Full name of the administrator.
  final String name;

  /// Institutional login email address.
  final String email;

  /// Initial login password.
  final String password;

  /// Optional telephone contact number.
  final String? phone;

  /// Serialize to JSON map.
  Map<String, dynamic> toJson() => {
        'name': name.trim(),
        'email': email.trim().toLowerCase(),
        'password': password,
        if (phone != null && phone!.trim().isNotEmpty) 'phone': phone!.trim(),
      };
}

/// Created credentials container returned to the Super Admin.
class AdminCredentialsSummary {
  /// Default constructor.
  const AdminCredentialsSummary({
    required this.id,
    required this.name,
    required this.email,
    required this.role,
  });

  /// Parse from JSON map.
  factory AdminCredentialsSummary.fromJson(Map<String, dynamic> json) {
    return AdminCredentialsSummary(
      id: json['id'] as String? ?? '',
      name: json['name'] as String? ?? '',
      email: json['email'] as String? ?? '',
      role: json['role'] as String? ?? '',
    );
  }

  /// User ID.
  final String id;

  /// Full name.
  final String name;

  /// Login email.
  final String email;

  /// Assigned role.
  final String role;
}

/// Result returned from onboarding an institute along with administrators.
class CreateInstituteResult {
  /// Default constructor.
  const CreateInstituteResult({
    required this.institute,
    required this.principal,
    required this.officeAdmin,
  });

  /// Created institute tenant entity.
  final Institute institute;

  /// Created principal executive account summary.
  final AdminCredentialsSummary principal;

  /// Created office admin account summary.
  final AdminCredentialsSummary officeAdmin;
}

/// System-wide metrics container.
class SystemMetrics {
  /// Default constructor for SystemMetrics.
  const SystemMetrics({
    this.totalUniversities = 0,
    this.totalInstitutes = 0,
    this.totalDepartments = 0,
    this.totalUsers = 0,
    this.systemHealthy = true,
  });

  /// Total registered universities.
  final int totalUniversities;

  /// Total registered institutes.
  final int totalInstitutes;

  /// Total departments count.
  final int totalDepartments;

  /// Total registered user profiles.
  final int totalUsers;

  /// System operational status.
  final bool systemHealthy;
}

/// Service managing Super Administrator operations and data queries.
class SuperAdminService {
  /// Default constructor for SuperAdminService.
  SuperAdminService({
    SupabaseClient? client,
    http.Client? httpClient,
    String? apiBaseUrl,
  })  : _client = client ?? Supabase.instance.client,
        _http = httpClient ?? http.Client(),
        _apiBaseUrl = apiBaseUrl ?? AppConfig.apiBaseUrl;

  final SupabaseClient _client;
  final http.Client _http;
  final String _apiBaseUrl;

  /// Fetch list of universities from database.
  Future<List<University>> fetchUniversities() async {
    try {
      final response = await _client
          .from('universities')
          .select()
          .order('name', ascending: true);

      final dataList = response as List<dynamic>;
      return dataList
          .map((item) => University.fromJson(item as Map<String, dynamic>))
          .toList();
    } on Exception {
      return [];
    }
  }

  /// Create a new university record.
  Future<ApiResponse<University>> createUniversity({
    required String name,
    required String slug,
    required String state,
    String? website,
  }) async {
    try {
      final payload = {
        'name': name.trim(),
        'slug': slug.trim().toUpperCase(),
        'state': state.trim(),
        if (website != null && website.trim().isNotEmpty)
          'website': website.trim(),
      };

      final response = await _client
          .from('universities')
          .insert(payload)
          .select()
          .single();

      final created = University.fromJson(response);
      return ApiResponse.success(created);
    } on Exception catch (e) {
      return ApiResponse.failure('Failed to create university: $e');
    }
  }

  /// Fetch list of institutes with joined university data.
  Future<List<Institute>> fetchInstitutes() async {
    try {
      final response = await _client
          .from('institutes')
          .select('*, universities(name)')
          .order('name', ascending: true);

      final dataList = response as List<dynamic>;
      return dataList
          .map((item) => Institute.fromJson(item as Map<String, dynamic>))
          .toList();
    } on Exception {
      return [];
    }
  }

  /// Create a new institute tenant.
  Future<ApiResponse<Institute>> createInstitute({
    required String name,
    required String slug,
    String? universityId,
    String? domain,
    bool isAutonomous = false,
    bool isActive = true,
  }) async {
    try {
      final payload = {
        'name': name.trim(),
        'slug': slug.trim().toUpperCase(),
        'is_autonomous': isAutonomous,
        'is_active': isActive,
        if (universityId != null && universityId.trim().isNotEmpty)
          'university_id': universityId.trim(),
        if (domain != null && domain.trim().isNotEmpty)
          'domain': domain.trim().toLowerCase(),
      };

      final response =
          await _client.from('institutes').insert(payload).select().single();

      final created = Institute.fromJson(response);
      return ApiResponse.success(created);
    } on Exception catch (e) {
      return ApiResponse.failure('Failed to create institute: $e');
    }
  }

  /// Create a new institute tenant along with initial Principal and Office
  /// Admin authentication accounts and FLE-encrypted profile records.
  Future<ApiResponse<CreateInstituteResult>> createInstituteWithAdmins({
    required String name,
    required String slug,
    required AdminUserCreationData principal,
    required AdminUserCreationData officeAdmin,
    String? universityId,
    String? domain,
    bool isAutonomous = false,
    bool isActive = true,
  }) async {
    try {
      final session =
          await _client.auth.getSession() ?? _client.auth.currentSession;
      final token = session?.accessToken;
      if (token == null) {
        return ApiResponse.failure(
          'Authentication required. Please sign in as Super Administrator.',
        );
      }

      final uri = Uri.parse('$_apiBaseUrl/institutes');
      final payload = {
        'institute': {
          'name': name.trim(),
          'slug': slug.trim().toUpperCase(),
          'is_autonomous': isAutonomous,
          'is_active': isActive,
          if (universityId != null && universityId.trim().isNotEmpty)
            'university_id': universityId.trim(),
          if (domain != null && domain.trim().isNotEmpty)
            'domain': domain.trim().toLowerCase(),
        },
        'principal': principal.toJson(),
        'office_admin': officeAdmin.toJson(),
      };

      final response = await _http.post(
        uri,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode(payload),
      );

      final body = jsonDecode(response.body) as Map<String, dynamic>;

      if (response.statusCode >= 200 &&
          response.statusCode < 300 &&
          body['success'] == true) {
        final data = body['data'] as Map<String, dynamic>;
        final instJson = data['institute'] as Map<String, dynamic>;
        final pJson = data['principal'] as Map<String, dynamic>;
        final aJson = data['office_admin'] as Map<String, dynamic>;

        final result = CreateInstituteResult(
          institute: Institute.fromJson(instJson),
          principal: AdminCredentialsSummary.fromJson(pJson),
          officeAdmin: AdminCredentialsSummary.fromJson(aJson),
        );
        return ApiResponse.success(result);
      } else {
        final errorMsg =
            body['error'] as String? ?? 'Failed to register institute.';
        return ApiResponse.failure(errorMsg);
      }
    } on Exception catch (e) {
      return ApiResponse.failure(
        'Network error onboarding institute tenant: $e',
      );
    }
  }

  /// Fetch high-level platform statistics.
  Future<SystemMetrics> fetchSystemMetrics() async {
    try {
      final unisCount = await _client.from('universities').count();
      final instsCount = await _client.from('institutes').count();
      final deptsCount = await _client.from('departments').count();
      final usersCount = await _client.from('profiles').count();

      return SystemMetrics(
        totalUniversities: unisCount,
        totalInstitutes: instsCount,
        totalDepartments: deptsCount,
        totalUsers: usersCount,
      );
    } on Exception {
      return const SystemMetrics();
    }
  }
}
