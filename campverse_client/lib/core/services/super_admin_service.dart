import 'package:campverse/core/models/api_response.dart';
import 'package:campverse/core/models/institute.dart';
import 'package:campverse/core/models/university.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

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
  SuperAdminService({SupabaseClient? client})
      : _client = client ?? Supabase.instance.client;

  final SupabaseClient _client;

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
