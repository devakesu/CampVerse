import 'package:flutter/foundation.dart';

/// Represents a student's academic class and cohort details.
@immutable
class StudentClassDetails {
  /// Default constructor for StudentClassDetails.
  const StudentClassDetails({
    required this.id,
    required this.programmeName,
    required this.programmeCode,
    required this.departmentName,
    required this.departmentCode,
    required this.admissionYear,
    required this.gradYear,
    required this.currentSemester,
    required this.division,
    this.schemeName = '2024 Scheme',
    this.staffAdvisorName,
    this.staffAdvisorEmail,
    this.classReps = const [],
  });

  /// Factory constructor parsing from Supabase joined query.
  factory StudentClassDetails.fromJson(Map<String, dynamic> json) {
    final programme = json['programmes'] as Map<String, dynamic>?;
    final department = programme?['departments'] as Map<String, dynamic>?;
    final scheme = json['curriculum_schemes'] as Map<String, dynamic>?;
    final advisor = json['profiles'] as Map<String, dynamic>?;

    final repsList = <String>[];
    if (json['class_reps'] is List) {
      for (final r in json['class_reps'] as List) {
        if (r is String) {
          repsList.add(r);
        }
      }
    }

    return StudentClassDetails(
      id: json['id'] as String? ?? '',
      programmeName: programme?['name'] as String? ?? 'Computer Science',
      programmeCode: programme?['programme_code'] as String? ?? 'CSE',
      departmentName: department?['name'] as String? ??
          'Computer Science & Engineering',
      departmentCode: department?['code'] as String? ?? 'CSE',
      admissionYear: json['admission_year'] as int? ?? 2022,
      gradYear: json['grad_year'] as int? ?? 2026,
      currentSemester: json['current_semester'] as int? ?? 6,
      division: json['division'] as String? ?? 'A',
      schemeName: scheme?['name'] as String? ?? 'KTU 2024 Scheme',
      staffAdvisorName: advisor?['full_name'] as String? ??
          'Dr. Elizabeth Varghese',
      staffAdvisorEmail: advisor?['email'] as String? ??
          'elizabeth.v@campverse.edu',
      classReps: repsList.isNotEmpty
          ? repsList
          : const ['Rahul S.', 'Ananya P.'],
    );
  }

  /// Class unique identifier.
  final String id;

  /// Full academic programme name (e.g. B.Tech Computer Science).
  final String programmeName;

  /// Programme code (e.g. CSBS, CSE).
  final String programmeCode;

  /// Academic department name.
  final String departmentName;

  /// Department code (e.g. CSE).
  final String departmentCode;

  /// Batch admission year.
  final int admissionYear;

  /// Expected graduation year.
  final int gradYear;

  /// Current semester number (e.g. 6).
  final int currentSemester;

  /// Division identifier (e.g. 'A', 'B', 'Alpha').
  final String division;

  /// Curriculum scheme name.
  final String schemeName;

  /// Primary staff advisor / class tutor name.
  final String? staffAdvisorName;

  /// Primary staff advisor contact email.
  final String? staffAdvisorEmail;

  /// Names or identifiers of student class representatives.
  final List<String> classReps;

  /// Display string for the cohort (e.g. 'S6 CSE - Div A').
  String get displayName => 'S$currentSemester $programmeCode - Div $division';

  /// Academic batch duration string (e.g. '2022 - 2026').
  String get batchYearString => '$admissionYear - $gradYear';
}
