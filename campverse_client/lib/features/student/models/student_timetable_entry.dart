import 'package:flutter/foundation.dart';

/// Represents a single period in the class timetable schedule.
@immutable
class StudentTimetableEntry {
  /// Default constructor for StudentTimetableEntry.
  const StudentTimetableEntry({
    required this.id,
    required this.day,
    required this.periodNumber,
    required this.timeSlot,
    required this.courseCode,
    required this.courseTitle,
    required this.classroomHall,
    this.instructorName = 'Faculty',
    this.isLab = false,
  });

  /// Factory constructor parsing from Supabase joined query.
  factory StudentTimetableEntry.fromJson(Map<String, dynamic> json) {
    final allocation =
        json['class_course_allocations'] as Map<String, dynamic>?;
    final course = allocation?['courses'] as Map<String, dynamic>?;
    final faculty = allocation?['profiles'] as Map<String, dynamic>?;

    final period = json['period_number'] as int? ?? 1;

    return StudentTimetableEntry(
      id: json['id'] as String? ?? '',
      day: json['day'] as String? ?? 'monday',
      periodNumber: period,
      timeSlot: defaultPeriodTimeSlots[period] ?? '09:00 - 10:00',
      courseCode: course?['course_code'] as String? ?? 'CST302',
      courseTitle: course?['title'] as String? ?? 'Compiler Design',
      classroomHall: json['classroom_hall'] as String? ?? 'LH-302',
      instructorName: faculty?['full_name'] as String? ?? 'Prof. A. Kumar',
      isLab: (course?['course_type'] as String? ?? '').contains('practical'),
    );
  }

  /// Unique timetable slot identifier.
  final String id;

  /// Day of the week in lowercase ('monday'..'saturday').
  final String day;

  /// Period number slot (1 to 7).
  final int periodNumber;

  /// Time span string (e.g. '09:00 - 10:00 AM').
  final String timeSlot;

  /// Course code (e.g. CST302).
  final String courseCode;

  /// Full course title.
  final String courseTitle;

  /// Assigned lecture hall or laboratory (e.g. 'LH-302', 'Networks Lab').
  final String classroomHall;

  /// Instructor in charge.
  final String instructorName;

  /// Whether this session is a practical lab session.
  final bool isLab;

  /// Standard period timetable mapping.
  static const Map<int, String> defaultPeriodTimeSlots = {
    1: '09:00 - 10:00 AM',
    2: '10:00 - 11:00 AM',
    3: '11:15 - 12:15 PM',
    4: '12:15 - 01:15 PM',
    5: '02:00 - 03:00 PM',
    6: '03:00 - 04:00 PM',
    7: '04:00 - 05:00 PM',
  };
}
