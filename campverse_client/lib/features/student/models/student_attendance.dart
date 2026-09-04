import 'package:flutter/foundation.dart';

/// Attendance compliance status.
enum AttendanceStatus {
  /// Well above the 75% threshold (>= 80%).
  safe,

  /// At border risk (75% - 79.9%).
  marginal,

  /// In dangerous shortage below minimum 75% criteria (< 75%).
  critical,
}

/// Course-wise attendance metrics for a student.
@immutable
class AttendanceSubject {
  /// Default constructor for AttendanceSubject.
  const AttendanceSubject({
    required this.courseCode,
    required this.courseTitle,
    required this.attendedHours,
    required this.totalHours,
  });

  /// Subject code (e.g. CST302).
  final String courseCode;

  /// Subject title (e.g. Compiler Design).
  final String courseTitle;

  /// Total classes attended by student.
  final int attendedHours;

  /// Total classes conducted.
  final int totalHours;

  /// Attendance percentage (0.0 to 100.0).
  double get percentage =>
      totalHours > 0 ? (attendedHours / totalHours) * 100 : 100.0;

  /// Current compliance status.
  AttendanceStatus get status {
    if (percentage >= 80.0) {
      return AttendanceStatus.safe;
    }
    if (percentage >= 75.0) {
      return AttendanceStatus.marginal;
    }
    return AttendanceStatus.critical;
  }

  /// Number of consecutive upcoming classes the student can miss
  /// while staying at or above 75%.
  int get safeBunkCount {
    if (percentage < 75.0) {
      return 0;
    }
    // (attended) / (total + x) >= 0.75  =>  x <= (attended / 0.75) - total
    final maxTotal = attendedHours / 0.75;
    final canMiss = (maxTotal - totalHours).floor();
    return canMiss > 0 ? canMiss : 0;
  }

  /// Number of consecutive upcoming classes the student MUST attend
  /// to bring attendance up to 75%.
  int get requiredToCatchUp {
    if (percentage >= 75.0) {
      return 0;
    }
    // (attended + y) / (total + y) >= 0.75 => y >= 3*total - 4*attended
    final req = (3 * totalHours) - (4 * attendedHours);
    return req > 0 ? req : 0;
  }
}

/// Aggregated student attendance statistics.
@immutable
class OverallAttendance {
  /// Default constructor for OverallAttendance.
  const OverallAttendance({
    required this.subjects,
  });

  /// Factory producing standard simulated demo data based on enrolled courses.
  factory OverallAttendance.mock() {
    return const OverallAttendance(
      subjects: [
        AttendanceSubject(
          courseCode: 'CST302',
          courseTitle: 'Compiler Design',
          attendedHours: 38,
          totalHours: 42,
        ),
        AttendanceSubject(
          courseCode: 'CST304',
          courseTitle: 'Computer Networks',
          attendedHours: 34,
          totalHours: 40,
        ),
        AttendanceSubject(
          courseCode: 'CST306',
          courseTitle: 'Algorithm Analysis & Design',
          attendedHours: 29,
          totalHours: 40,
        ),
        AttendanceSubject(
          courseCode: 'CST308',
          courseTitle: 'Comprehensive Course Work',
          attendedHours: 19,
          totalHours: 20,
        ),
        AttendanceSubject(
          courseCode: 'CSL332',
          courseTitle: 'Networking Lab',
          attendedHours: 14,
          totalHours: 15,
        ),
      ],
    );
  }

  /// List of enrolled course attendance subjects.
  final List<AttendanceSubject> subjects;

  /// Total classes attended across all subjects.
  int get totalAttended =>
      subjects.fold(0, (sum, s) => sum + s.attendedHours);

  /// Total classes conducted across all subjects.
  int get totalConducted =>
      subjects.fold(0, (sum, s) => sum + s.totalHours);

  /// Aggregated overall attendance percentage.
  double get overallPercentage =>
      totalConducted > 0 ? (totalAttended / totalConducted) * 100 : 100.0;

  /// Overall compliance status.
  AttendanceStatus get status {
    if (overallPercentage >= 80.0) {
      return AttendanceStatus.safe;
    }
    if (overallPercentage >= 75.0) {
      return AttendanceStatus.marginal;
    }
    return AttendanceStatus.critical;
  }

  /// Number of subjects currently at or below the 75% warning mark.
  int get shortageSubjectsCount =>
      subjects.where((s) => s.percentage < 75.0).length;
}
