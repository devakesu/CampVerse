import 'package:campverse/core/models/api_response.dart';
import 'package:campverse/core/models/institute.dart';
import 'package:campverse/core/models/university.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Aggregated real-time metrics for campus operations and governance.
class CampusMetrics {
  /// Default constructor for CampusMetrics.
  const CampusMetrics({
    this.departmentCount = 0,
    this.facultyCount = 0,
    this.studentCount = 0,
    this.clubCount = 0,
    this.eventCount = 0,
    this.pendingApprovalsCount = 0,
    this.pendingVerificationsCount = 0,
  });

  /// Total active academic departments in the institute.
  final int departmentCount;

  /// Total teaching and non-teaching faculty members.
  final int facultyCount;

  /// Total currently enrolled student body.
  final int studentCount;

  /// Total sanctioned student clubs, bodies, and student union.
  final int clubCount;

  /// Total campus events conducted and scheduled.
  final int eventCount;

  /// Number of files, duty leaves, and certificates awaiting Principal
  /// sign-off.
  final int pendingApprovalsCount;

  /// Number of student records / certificates awaiting Office Admin
  /// verification.
  final int pendingVerificationsCount;

  /// Creates a copy with optional overrides.
  CampusMetrics copyWith({
    int? departmentCount,
    int? facultyCount,
    int? studentCount,
    int? clubCount,
    int? eventCount,
    int? pendingApprovalsCount,
    int? pendingVerificationsCount,
  }) {
    return CampusMetrics(
      departmentCount: departmentCount ?? this.departmentCount,
      facultyCount: facultyCount ?? this.facultyCount,
      studentCount: studentCount ?? this.studentCount,
      clubCount: clubCount ?? this.clubCount,
      eventCount: eventCount ?? this.eventCount,
      pendingApprovalsCount:
          pendingApprovalsCount ?? this.pendingApprovalsCount,
      pendingVerificationsCount:
          pendingVerificationsCount ?? this.pendingVerificationsCount,
    );
  }
}

/// Service managing campus-level administration, institute profile,
/// branding, and real-time operational metrics for Principal and Office Admin.
class CampusAdminService {
  /// Default constructor for CampusAdminService.
  CampusAdminService({SupabaseClient? client})
      : _client = client ?? Supabase.instance.client;

  final SupabaseClient _client;

  /// Fetch full institute details including joined university name.
  Future<ApiResponse<Institute>> fetchInstituteDetails(
    String instituteId,
  ) async {
    try {
      final response = await _client
          .from('institutes')
          .select('*, universities(name)')
          .eq('id', instituteId)
          .single();

      final institute = Institute.fromJson(response);
      return ApiResponse.success(institute);
    } on Exception catch (e) {
      return ApiResponse.failure('Failed to load institute details: $e');
    }
  }

  /// Update general institute information, domain, autonomous status,
  /// and location settings.
  Future<ApiResponse<Institute>> updateInstituteInfo({
    required String instituteId,
    required String name,
    required String slug,
    String? domain,
    String? universityId,
    bool isAutonomous = false,
    InstituteSettings? settings,
  }) async {
    try {
      final payload = {
        'name': name.trim(),
        'slug': slug.trim().toUpperCase(),
        'is_autonomous': isAutonomous,
        if (domain != null && domain.trim().isNotEmpty)
          'domain': domain.trim().toLowerCase()
        else
          'domain': null,
        if (universityId != null && universityId.trim().isNotEmpty)
          'university_id': universityId.trim()
        else
          'university_id': null,
        if (settings != null) 'settings': settings.toJson(),
      };

      final response = await _client
          .from('institutes')
          .update(payload)
          .eq('id', instituteId)
          .select('*, universities(name)')
          .single();

      final updated = Institute.fromJson(response);
      return ApiResponse.success(updated);
    } on Exception catch (e) {
      return ApiResponse.failure('Failed to update institute: $e');
    }
  }

  /// Update visual identity, logo, banner, and theme styling for the campus.
  Future<ApiResponse<Institute>> updateInstituteBranding({
    required String instituteId,
    required InstituteBranding branding,
  }) async {
    try {
      final response = await _client
          .from('institutes')
          .update({'branding': branding.toJson()})
          .eq('id', instituteId)
          .select('*, universities(name)')
          .single();

      final updated = Institute.fromJson(response);
      return ApiResponse.success(updated);
    } on Exception catch (e) {
      return ApiResponse.failure('Failed to update campus branding: $e');
    }
  }

  /// Fetch list of universities for affiliation dropdown.
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

  /// Aggregate real-time campus statistics and pending queues.
  Future<CampusMetrics> fetchCampusMetrics(String instituteId) async {
    try {
      // 1. Department count
      final deptCount = await _client
          .from('departments')
          .count()
          .eq('institute_id', instituteId);

      // 2. Faculty & Staff count
      final facultyCount = await _client
          .from('profiles')
          .count()
          .eq('institute_id', instituteId)
          .inFilter('role', ['faculty', 'hod', 'office_admin']);

      // 3. Student count
      final studentCount = await _client
          .from('profiles')
          .count()
          .eq('institute_id', instituteId)
          .eq('role', 'student');

      // 4. Clubs / Organizations count
      final clubCount = await _client
          .from('organizations')
          .count()
          .eq('institute_id', instituteId);

      // 5. Events count
      final eventCount = await _client
          .from('events')
          .count()
          .eq('institute_id', instituteId);

      // 6. Pending approvals (events requiring duty leave / review)
      var pendingApprovals = 0;
      try {
        pendingApprovals = await _client
            .from('events')
            .count()
            .eq('institute_id', instituteId)
            .eq('status', 'draft');
      } on Exception {
        // Fall back gracefully
      }

      // 7. Pending verifications (profiles in pending_verification status)
      var pendingVerifications = 0;
      try {
        pendingVerifications = await _client
            .from('profiles')
            .count()
            .eq('institute_id', instituteId)
            .eq('status', 'pending_verification');
      } on Exception {
        // Fall back gracefully
      }

      return CampusMetrics(
        departmentCount: deptCount,
        facultyCount: facultyCount,
        studentCount: studentCount,
        clubCount: clubCount,
        eventCount: eventCount,
        pendingApprovalsCount: pendingApprovals,
        pendingVerificationsCount: pendingVerifications,
      );
    } on Exception {
      return const CampusMetrics();
    }
  }
}
