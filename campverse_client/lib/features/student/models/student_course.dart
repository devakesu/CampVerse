import 'package:flutter/foundation.dart';

/// Represents an enrolled academic course for a student.
@immutable
class StudentCourse {
  /// Default constructor for StudentCourse.
  const StudentCourse({
    required this.id,
    required this.code,
    required this.title,
    required this.credits,
    required this.courseType,
    required this.semester,
    this.allocationId = '',
    this.facultyName = 'Prof. Alexander Kumar',
    this.academicYear = '2026-2027',
    this.modules = const [],
    this.isElective = false,
  });

  /// Factory constructor parsing from Supabase joined query.
  factory StudentCourse.fromJson(Map<String, dynamic> json) {
    // Can arrive via class_course_allocations or directly courses
    final courseData = (json['courses'] as Map<String, dynamic>?) ?? json;
    final facultyData = json['profiles'] as Map<String, dynamic>?;

    final rawCredits = courseData['credits'];
    final creditsVal = rawCredits is num
        ? rawCredits.toDouble()
        : double.tryParse(rawCredits?.toString() ?? '4.0') ?? 4.0;

    final syllabusMeta = courseData['syllabus_meta'] as Map<String, dynamic>?;
    final modulesList = <String>[];
    if (syllabusMeta?['modules'] is List) {
      for (final m in syllabusMeta!['modules'] as List) {
        if (m is String) {
          modulesList.add(m);
        }
      }
    }

    return StudentCourse(
      id: courseData['id'] as String? ?? '',
      code: courseData['course_code'] as String? ?? 'CST302',
      title: courseData['title'] as String? ?? 'Compiler Design',
      credits: creditsVal,
      courseType: courseData['course_type'] as String? ?? 'theory',
      semester: json['semester'] as int? ?? 6,
      allocationId: json['id'] as String? ?? '',
      facultyName: facultyData?['full_name'] as String? ??
          'Prof. Alexander Kumar',
      academicYear: json['academic_year'] as String? ?? '2026-2027',
      modules: modulesList.isNotEmpty
          ? modulesList
          : const [
              'Module 1: Lexical Analysis & Finite Automata',
              'Module 2: Syntax Analysis & Parsing Techniques',
              'Module 3: Syntax Directed Translation',
              'Module 4: Intermediate Code Generation',
              'Module 5: Code Optimization & Target Generation',
            ],
      isElective: json['is_elective'] as bool? ?? false,
    );
  }

  /// Course unique identifier.
  final String id;

  /// Course syllabus code (e.g. CST302).
  final String code;

  /// Full title of the course.
  final String title;

  /// Academic credits value.
  final double credits;

  /// Course classification (e.g. theory, practical, project, mooc).
  final String courseType;

  /// Semester index.
  final int semester;

  /// Course allocation ID.
  final String allocationId;

  /// Primary faculty instructor name.
  final String facultyName;

  /// Academic year of enrollment.
  final String academicYear;

  /// List of syllabus modules / chapters.
  final List<String> modules;

  /// Whether the course is an elective slot.
  final bool isElective;
}
