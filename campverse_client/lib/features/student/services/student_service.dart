import 'dart:math';

import 'package:campverse/core/models/api_response.dart';
import 'package:campverse/features/student/models/student_attendance.dart';
import 'package:campverse/features/student/models/student_class_details.dart';
import 'package:campverse/features/student/models/student_club.dart';
import 'package:campverse/features/student/models/student_course.dart';
import 'package:campverse/features/student/models/student_event.dart';
import 'package:campverse/features/student/models/student_registration.dart';
import 'package:campverse/features/student/models/student_timetable_entry.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Service coordinating student academic, timetable, event, and club
/// operations.
class StudentService {
  /// Default constructor for StudentService.
  StudentService({SupabaseClient? client}) : _customClient = client;

  final SupabaseClient? _customClient;

  SupabaseClient get _client => _customClient ?? Supabase.instance.client;

  // ── Class Details ──────────────────────────────────────────────────────────

  /// Fetches academic cohort information for a given class ID.
  Future<ApiResponse<StudentClassDetails>> fetchClassDetails({
    String? classId,
    String? instituteId,
  }) async {
    try {
      if (classId != null && classId.isNotEmpty) {
        final row = await _client
            .from('classes')
            .select(
              '*, programmes(*, departments(*)), '
              'curriculum_schemes(*), profiles:staff_advisor_id(*)',
            )
            .eq('id', classId)
            .maybeSingle();

        if (row != null) {
          return ApiResponse.success(StudentClassDetails.fromJson(row));
        }
      }

      // If classId is unset or not found, try to query any class in institute
      if (instituteId != null && instituteId.isNotEmpty) {
        final list = await _client
            .from('classes')
            .select(
              '*, programmes!inner(*, departments(*)), '
              'curriculum_schemes(*), profiles:staff_advisor_id(*)',
            )
            .eq('programmes.institute_id', instituteId)
            .limit(1);

        if (list.isNotEmpty) {
          return ApiResponse.success(
            StudentClassDetails.fromJson(list.first),
          );
        }
      }

      // Fallback demo cohort for development
      return ApiResponse.success(
        const StudentClassDetails(
          id: 'demo-class-1',
          programmeName: 'B.Tech. Computer Science & Engineering',
          programmeCode: 'CSE',
          departmentName: 'Department of Computer Science & Engineering',
          departmentCode: 'CSE',
          admissionYear: 2023,
          gradYear: 2027,
          currentSemester: 6,
          division: 'A',
          schemeName: 'KTU 2024 Scheme',
          staffAdvisorName: 'Dr. Elizabeth Varghese',
          staffAdvisorEmail: 'elizabeth.v@campverse.edu',
          classReps: ['Rahul S.', 'Ananya P.'],
        ),
      );
    } on Exception catch (e) {
      return ApiResponse.failure('Failed to load class details: $e');
    }
  }

  // ── Courses ────────────────────────────────────────────────────────────────

  /// Fetches enrolled courses for the student or class.
  Future<ApiResponse<List<StudentCourse>>> fetchEnrolledCourses({
    required String studentId,
    String? classId,
  }) async {
    try {
      // 1. Try student_course_enrollments
      final enrollments = await _client
          .from('student_course_enrollments')
          .select('*, class_course_allocations(*, courses(*), profiles(*))')
          .eq('student_id', studentId);

      if (enrollments.isNotEmpty) {
        final courses = enrollments.map((e) {
          final alloc = e['class_course_allocations'] as Map<String, dynamic>?;
          return StudentCourse.fromJson(alloc ?? e);
        }).toList();
        return ApiResponse.success(courses);
      }

      // 2. Fallback to class allocations if student has not enrolled yet
      if (classId != null && classId.isNotEmpty) {
        final allocations = await _client
            .from('class_course_allocations')
            .select('*, courses(*), profiles(*)')
            .eq('class_id', classId);

        if (allocations.isNotEmpty) {
          final courses =
              allocations.map(StudentCourse.fromJson).toList();
          return ApiResponse.success(courses);
        }
      }

      // 3. Fallback standard demo curriculum
      return ApiResponse.success(const [
        StudentCourse(
          id: 'course-1',
          code: 'CST302',
          title: 'Compiler Design',
          credits: 4,
          courseType: 'theory',
          semester: 6,
          facultyName: 'Dr. Alexander Kumar',
          modules: [
            'Module 1: Introduction to Compilers & Lexical Analysis',
            'Module 2: Syntax Analysis, Top-down & Bottom-up Parsers',
            'Module 3: Type Checking & Intermediate Code Generation',
            'Module 4: Runtime Environments & Symbol Tables',
            'Module 5: Code Optimization & Target Code Generation',
          ],
        ),
        StudentCourse(
          id: 'course-2',
          code: 'CST304',
          title: 'Computer Networks',
          credits: 4,
          courseType: 'theory',
          semester: 6,
          facultyName: 'Prof. Mary Joseph',
          modules: [
            'Module 1: Physical Layer & Network Topologies',
            'Module 2: Data Link Layer & MAC Protocols',
            'Module 3: Routing Algorithms & IP Addressing',
            'Module 4: Transport Layer, TCP/UDP & Congestion Control',
            'Module 5: Application Layer Protocols: DNS, HTTP, SMTP',
          ],
        ),
        StudentCourse(
          id: 'course-3',
          code: 'CST306',
          title: 'Algorithm Analysis & Design',
          credits: 4,
          courseType: 'theory',
          semester: 6,
          facultyName: 'Dr. Ramesh Nair',
          modules: [
            'Module 1: Asymptotic Analysis & Recurrences',
            'Module 2: Divide & Conquer, Greedy Strategies',
            'Module 3: Dynamic Programming Paradigms',
            'Module 4: Graph Algorithms & Flow Networks',
            'Module 5: NP-Completeness & Approximation Algorithms',
          ],
        ),
        StudentCourse(
          id: 'course-4',
          code: 'CSL332',
          title: 'Networking & Systems Lab',
          credits: 2,
          courseType: 'practical',
          semester: 6,
          facultyName: 'Prof. Anitha George',
          modules: [
            'Lab 1: Socket Programming in C & Python',
            'Lab 2: Wireshark Packet Sniffing & Analysis',
            'Lab 3: Routing Protocol Simulation in NS3',
            'Lab 4: Client-Server Concurrent Architecture',
          ],
        ),
        StudentCourse(
          id: 'course-5',
          code: 'CST362',
          title: 'Machine Learning (Elective)',
          credits: 3,
          courseType: 'theory',
          semester: 6,
          isElective: true,
          facultyName: 'Dr. S. Radhakrishnan',
          modules: [
            'Module 1: Supervised Learning & Linear Regression',
            'Module 2: Classification, SVMs & Decision Trees',
            'Module 3: Neural Networks & Backpropagation',
            'Module 4: Unsupervised Learning & Dimensionality Reduction',
            'Module 5: Reinforcement Learning Fundamentals',
          ],
        ),
      ]);
    } on Exception catch (e) {
      return ApiResponse.failure('Failed to load courses: $e');
    }
  }

  // ── Timetable ──────────────────────────────────────────────────────────────

  /// Fetches class timetable slots ordered by period.
  Future<ApiResponse<List<StudentTimetableEntry>>> fetchTimetable({
    String? classId,
  }) async {
    try {
      if (classId != null && classId.isNotEmpty) {
        final rows = await _client
            .from('class_timetables')
            .select('*, class_course_allocations(*, courses(*), profiles(*))')
            .eq('class_id', classId)
            .order('period_number');

        if (rows.isNotEmpty) {
          final entries =
              rows.map(StudentTimetableEntry.fromJson).toList();
          return ApiResponse.success(entries);
        }
      }

      // Generate standard weekday schedule fallback
      final days = ['monday', 'tuesday', 'wednesday', 'thursday', 'friday'];
      final mockEntries = <StudentTimetableEntry>[];

      final coursePool = [
        ('CST302', 'Compiler Design', 'LH-302', 'Dr. A. Kumar', false),
        ('CST304', 'Computer Networks', 'LH-302', 'Prof. M. Joseph', false),
        ('CST306', 'Algorithms Design', 'LH-302', 'Dr. R. Nair', false),
        ('CSL332', 'Networking Lab', 'CS Lab 2', 'Prof. A. George', true),
        ('CST362', 'Machine Learning', 'LH-302', 'Dr. S. Radhakrishnan', false),
      ];

      for (var d = 0; d < days.length; d++) {
        final dayName = days[d];
        for (var p = 1; p <= 6; p++) {
          final c = coursePool[(d + p) % coursePool.length];
          mockEntries.add(
            StudentTimetableEntry(
              id: 'slot-$dayName-$p',
              day: dayName,
              periodNumber: p,
              timeSlot: StudentTimetableEntry.defaultPeriodTimeSlots[p] ??
                  '09:00 - 10:00 AM',
              courseCode: c.$1,
              courseTitle: c.$2,
              classroomHall: c.$3,
              instructorName: c.$4,
              isLab: c.$5,
            ),
          );
        }
      }

      return ApiResponse.success(mockEntries);
    } on Exception catch (e) {
      return ApiResponse.failure('Failed to load timetable: $e');
    }
  }

  // ── Campus Events ──────────────────────────────────────────────────────────

  /// Fetches published campus events and matches student registration status.
  Future<ApiResponse<List<StudentEvent>>> fetchEvents({
    required String studentId,
    String? instituteId,
  }) async {
    try {
      var query = _client
          .from('events')
          .select('*, organizations(*)')
          .eq('status', 'published');

      if (instituteId != null && instituteId.isNotEmpty) {
        query = query.eq('institute_id', instituteId);
      }

      final rows = await query.order('start_time');

      // Fetch user's active registrations to tag isRegisteredByMe
      final myRegs = await _client
          .from('event_registrations')
          .select('event_id')
          .eq('user_id', studentId)
          .neq('status', 'cancelled');

      final registeredEventIds = myRegs
          .map((r) => r['event_id'] as String)
          .toSet();

      if (rows.isNotEmpty) {
        final events = rows.map((e) {
          final eventId = e['id'] as String? ?? '';
          return StudentEvent.fromJson(
            e,
            isRegistered: registeredEventIds.contains(eventId),
          );
        }).toList();
        return ApiResponse.success(events);
      }

      // Default demo campus events
      final now = DateTime.now();
      return ApiResponse.success([
        StudentEvent(
          id: 'event-hack-1',
          title: 'HackVerse 2026: 24hr Campus Hackathon',
          venue: 'Campus Innovation Center, Auditorium Hall',
          startTime: now.add(const Duration(days: 2, hours: 9)),
          endTime: now.add(const Duration(days: 3, hours: 10)),
          primaryOrgName: 'IEEE Student Branch',
          isFeatured: true,
          tags: const ['Hackathon', 'Tech', 'AI'],
          ktuActivityPoints: 20,
          isDutyLeaveApproved: true,
          description:
              'Build groundbreaking multiplatform, AI, and IoT solutions in '
              'a 24-hour non-stop development sprint. Food, mentorship, and '
              'exciting cash prizes provided!',
        ),
        StudentEvent(
          id: 'event-workshop-2',
          title: 'Quantum Computing & Cryptography Workshop',
          venue: 'Seminar Hall 3, Department Block',
          startTime: now.add(const Duration(days: 5, hours: 14)),
          endTime: now.add(const Duration(days: 5, hours: 17)),
          primaryOrgName: 'FOSS Cell & ACM',
          tags: const ['Workshop', 'Cybersecurity', 'Research'],
          ktuActivityPoints: 10,
          isDutyLeaveApproved: true,
          description:
              'Hands-on session exploring post-quantum cryptography, lattice '
              'schemes, and modern security architectures.',
          isRegisteredByMe: true,
        ),
        StudentEvent(
          id: 'event-fest-3',
          title: 'Sargam 2026: Annual Campus Cultural Fest',
          venue: 'Open Air Amphitheatre',
          startTime: now.add(const Duration(days: 12, hours: 16)),
          endTime: now.add(const Duration(days: 14, hours: 22)),
          primaryOrgName: 'Student Union 2026',
          tags: const ['Cultural', 'Music', 'Arts'],
          ktuActivityPoints: 15,
          isDutyLeaveApproved: true,
          description:
              'Three days of music bands, dance performances, fine arts '
              'competitions, and campus celebrity nights.',
        ),
        StudentEvent(
          id: 'event-sports-4',
          title: 'Inter-Department Football Championship',
          venue: 'Main Sports Complex Football Turf',
          startTime: now.add(const Duration(days: 8, hours: 8)),
          endTime: now.add(const Duration(days: 9, hours: 18)),
          primaryOrgName: 'Campus Sports Council',
          tags: const ['Sports', 'Football', 'Athletics'],
          ktuActivityPoints: 10,
          isDutyLeaveApproved: true,
          description:
              'Battle for the prestigious Campus Rolling Trophy. 16 department '
              'teams competing in knockout rounds.',
        ),
      ]);
    } on Exception catch (e) {
      return ApiResponse.failure('Failed to load events: $e');
    }
  }

  // ── Event Registrations & QR Passes ────────────────────────────────────────

  /// Fetches a student's active and historical event registrations.
  Future<ApiResponse<List<StudentRegistration>>> fetchMyRegistrations(
    String studentId,
  ) async {
    try {
      final rows = await _client
          .from('event_registrations')
          .select('*, events(*, organizations(*))')
          .eq('user_id', studentId)
          .order('created_at', ascending: false);

      if (rows.isNotEmpty) {
        final regs = rows.map(StudentRegistration.fromJson).toList();
        return ApiResponse.success(regs);
      }

      // Default mock pass for development
      final now = DateTime.now();
      return ApiResponse.success([
        StudentRegistration(
          id: 'reg-demo-1',
          eventId: 'event-workshop-2',
          userId: studentId,
          qrPayload: 'CAMP-PASS-9982-QC-2026',
          status: 'confirmed',
          createdAt: now.subtract(const Duration(days: 1)),
          event: StudentEvent(
            id: 'event-workshop-2',
            title: 'Quantum Computing & Cryptography Workshop',
            venue: 'Seminar Hall 3, Department Block',
            startTime: now.add(const Duration(days: 5, hours: 14)),
            endTime: now.add(const Duration(days: 5, hours: 17)),
            primaryOrgName: 'FOSS Cell & ACM',
            tags: const ['Workshop', 'Cybersecurity'],
            ktuActivityPoints: 10,
            isRegisteredByMe: true,
          ),
        ),
      ]);
    } on Exception catch (e) {
      return ApiResponse.failure('Failed to load registrations: $e');
    }
  }

  /// Registers the student for an event, generating a cryptographic pass.
  Future<ApiResponse<StudentRegistration>> registerForEvent({
    required String studentId,
    required String eventId,
  }) async {
    try {
      final randomPassId = _generateQrToken(studentId, eventId);

      final inserted = await _client
          .from('event_registrations')
          .insert({
            'event_id': eventId,
            'user_id': studentId,
            'qr_payload': randomPassId,
            'status': 'confirmed',
          })
          .select('*, events(*, organizations(*))')
          .single();

      return ApiResponse.success(StudentRegistration.fromJson(inserted));
    } on PostgrestException catch (pe) {
      if (pe.code == '23505') {
        return ApiResponse.failure(
          'You are already registered for this event.',
        );
      }
      return ApiResponse.failure('Registration failed: ${pe.message}');
    } on Exception catch (e) {
      return ApiResponse.failure('Could not complete registration: $e');
    }
  }

  /// Cancels an existing event registration.
  Future<ApiResponse<bool>> cancelRegistration(String registrationId) async {
    try {
      await _client
          .from('event_registrations')
          .update({'status': 'cancelled'})
          .eq('id', registrationId);

      return ApiResponse.success(true);
    } on Exception catch (e) {
      return ApiResponse.failure('Failed to cancel registration: $e');
    }
  }

  // ── Clubs & Organizations ──────────────────────────────────────────────────

  /// Fetches campus clubs, Student Union, and current student's membership.
  Future<ApiResponse<List<StudentClub>>> fetchClubs({
    required String studentId,
    String? instituteId,
  }) async {
    try {
      var query = _client.from('organizations').select();

      if (instituteId != null && instituteId.isNotEmpty) {
        query = query.eq('institute_id', instituteId);
      }

      final rows = await query.order('name');

      // Fetch user's memberships
      final myMemberships = await _client
          .from('organization_members')
          .select('org_id, role')
          .eq('user_id', studentId)
          .eq('is_active', true);

      final membershipMap = <String, String>{};
      for (final m in myMemberships) {
        final orgId = m['org_id'] as String?;
        final role = m['role'] as String?;
        if (orgId != null && role != null) {
          membershipMap[orgId] = role;
        }
      }

      if (rows.isNotEmpty) {
        final clubs = rows.map((r) {
          final orgId = r['id'] as String? ?? '';
          return StudentClub.fromJson(
            r,
            userRole: membershipMap[orgId],
          );
        }).toList();
        return ApiResponse.success(clubs);
      }

      // Default mock clubs
      return ApiResponse.success([
        const StudentClub(
          id: 'org-union',
          name: 'College Student Union (CSU)',
          slug: 'student-union',
          orgType: 'student_union',
          category: 'Governance',
          leadName: 'Gokul Mohan (Chairman)',
          memberCount: 24,
          description:
              'Official democratically elected student governing body '
              'representing student rights, campus welfare, and university '
              'coordination.',
        ),
        const StudentClub(
          id: 'org-ieee',
          name: 'IEEE Student Branch',
          slug: 'ieee-sb',
          orgType: 'club',
          category: 'Technical',
          leadName: 'Nandana K. (Chair)',
          memberCount: 145,
          description:
              'Premier technical society hosting global hackathons, research '
              'symposiums, hardware robotics labs, and networking nights.',
          myMembershipRole: 'core_member',
        ),
        const StudentClub(
          id: 'org-foss',
          name: 'FOSS Cell & GNU Community',
          slug: 'foss-cell',
          orgType: 'club',
          category: 'Technical',
          leadName: 'Adithya R. (Lead)',
          memberCount: 88,
          description:
              'Championing open source software, Linux distributions, kernel '
              'contributions, and collaborative developer meetups.',
          myMembershipRole: 'member',
        ),
        const StudentClub(
          id: 'org-music',
          name: 'Symphony: The Music & Arts Society',
          slug: 'symphony-club',
          orgType: 'club',
          category: 'Cultural',
          leadName: 'Meera Menon (Secretary)',
          memberCount: 65,
          description:
              'Campus acoustic, rock, and fusion band conducting unplugged '
              'sessions, jam competitions, and festival headliners.',
        ),
        const StudentClub(
          id: 'org-sports',
          name: 'Campus Sports & Fitness Council',
          slug: 'sports-council',
          orgType: 'club',
          category: 'Sports',
          leadName: 'Sanjay V. (Captain)',
          memberCount: 110,
          description:
              'Overseeing football, cricket, badminton, basketball, and '
              'annual inter-collegiate athletic championships.',
        ),
      ]);
    } on Exception catch (e) {
      return ApiResponse.failure('Failed to load clubs: $e');
    }
  }

  // ── Attendance (Simulated Engine) ──────────────────────────────────────────

  /// Fetches simulated attendance tracking for enrolled courses.
  OverallAttendance getAttendanceMetrics() {
    return OverallAttendance.mock();
  }

  // ── Helpers ────────────────────────────────────────────────────────────────

  String _generateQrToken(String studentId, String eventId) {
    final rand = Random();
    const chars = 'ABCDEFGHJKLMNPQRSTUVWXYZ23456789';
    final randomSuffix = List.generate(
      6,
      (_) => chars[rand.nextInt(chars.length)],
    ).join();
    final epoch = DateTime.now().millisecondsSinceEpoch % 10000;
    return 'CAMP-PASS-$epoch-$randomSuffix';
  }
}
