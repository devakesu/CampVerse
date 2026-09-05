import 'dart:async';

import 'package:campverse/core/models/auth_user.dart';
import 'package:campverse/core/providers/auth_provider.dart';
import 'package:campverse/features/student/models/student_attendance.dart';
import 'package:campverse/features/student/models/student_class_details.dart';
import 'package:campverse/features/student/models/student_club.dart';
import 'package:campverse/features/student/models/student_course.dart';
import 'package:campverse/features/student/models/student_event.dart';
import 'package:campverse/features/student/models/student_registration.dart';
import 'package:campverse/features/student/models/student_timetable_entry.dart';
import 'package:campverse/features/student/providers/student_providers.dart';
import 'package:campverse/features/student/services/student_service.dart';
import 'package:campverse/features/student/tabs/student_academics_tab.dart';
import 'package:campverse/features/student/tabs/student_clubs_tab.dart';
import 'package:campverse/features/student/tabs/student_events_tab.dart';
import 'package:campverse/features/student/tabs/student_overview_tab.dart';
import 'package:campverse/features/student/tabs/student_profile_tab.dart';
import 'package:campverse/features/student/widgets/attendance_gauge_card.dart';
import 'package:campverse/features/student/widgets/qr_pass_dialog.dart';
import 'package:campverse/features/student/widgets/student_id_card.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const mockClass = StudentClassDetails(
    id: 'test-class-1',
    programmeName: 'B.Tech Computer Science & Engineering',
    programmeCode: 'CSE',
    departmentName: 'Computer Science',
    departmentCode: 'CSE',
    admissionYear: 2023,
    gradYear: 2027,
    currentSemester: 6,
    division: 'A',
    staffAdvisorName: 'Dr. Elizabeth Varghese',
    staffAdvisorEmail: 'elizabeth.v@campverse.edu',
    classReps: ['Rahul S.', 'Ananya P.'],
  );

  const mockCourses = [
    StudentCourse(
      id: 'course-1',
      code: 'CST302',
      title: 'Compiler Design',
      credits: 4,
      courseType: 'theory',
      semester: 6,
      facultyName: 'Dr. Alexander Kumar',
      modules: [
        'Module 1: Lexical Analysis',
        'Module 2: Syntax Analysis',
      ],
    ),
    StudentCourse(
      id: 'course-2',
      code: 'CSL332',
      title: 'Networking Lab',
      credits: 2,
      courseType: 'practical',
      semester: 6,
      facultyName: 'Prof. Anitha George',
    ),
  ];

  final now = DateTime.now();

  final mockEntries = [
    const StudentTimetableEntry(
      id: 'tt-1',
      day: 'monday',
      periodNumber: 1,
      timeSlot: '09:00 - 09:55 AM',
      courseCode: 'CST302',
      courseTitle: 'Compiler Design',
      classroomHall: 'LH-302',
      instructorName: 'Dr. A. Kumar',
    ),
    const StudentTimetableEntry(
      id: 'tt-2',
      day: 'monday',
      periodNumber: 2,
      timeSlot: '10:00 - 10:55 AM',
      courseCode: 'CSL332',
      courseTitle: 'Networking Lab',
      classroomHall: 'CS Lab 2',
      instructorName: 'Prof. A. George',
      isLab: true,
    ),
  ];

  final mockEvents = [
    StudentEvent(
      id: 'event-1',
      title: 'HackVerse 2026: Campus Hackathon',
      venue: 'Auditorium Hall',
      startTime: now.add(const Duration(days: 2)),
      endTime: now.add(const Duration(days: 3)),
      primaryOrgName: 'IEEE Student Branch',
      isFeatured: true,
      ktuActivityPoints: 20,
      description: '24-hour non-stop hackathon sprint.',
    ),
  ];

  final mockRegistrations = [
    StudentRegistration(
      id: 'reg-1',
      eventId: 'event-1',
      userId: 'test-student-id',
      qrPayload: 'CAMP-PASS-1234-TEST',
      status: 'confirmed',
      createdAt: now.subtract(const Duration(days: 1)),
      event: mockEvents.first,
    ),
  ];

  const mockClubs = [
    StudentClub(
      id: 'club-1',
      name: 'College Student Union (CSU)',
      slug: 'student-union',
      orgType: 'student_union',
      category: 'Governance',
      leadName: 'Gokul Mohan (Chairman)',
      memberCount: 24,
      description: 'Student governing body.',
    ),
    StudentClub(
      id: 'club-2',
      name: 'IEEE Student Branch',
      slug: 'ieee-sb',
      orgType: 'club',
      category: 'Technical',
      leadName: 'Nandana K. (Chair)',
      memberCount: 145,
      description: 'Technical society.',
      myMembershipRole: 'core_member',
    ),
  ];

  final mockAttendance = OverallAttendance.mock();

  group('Student Attendance Mathematics Engine Tests', () {
    test('Calculates percentage, status, and KTU safe bunks accurately', () {
      // 40 attended out of 48 = 83.33% (Safe)
      const safeSubject = AttendanceSubject(
        courseCode: 'CST302',
        courseTitle: 'Compiler Design',
        attendedHours: 40,
        totalHours: 48,
      );

      expect(safeSubject.percentage, closeTo(83.33, 0.01));
      expect(safeSubject.status, AttendanceStatus.safe);
      // Safe bunk: floor(40 / 0.75) - 48 = floor(53.33) - 48 = 5 classes
      expect(safeSubject.safeBunkCount, 5);
      expect(safeSubject.requiredToCatchUp, 0);
    });

    test('Identifies marginal status and catch-up classes when below 75%', () {
      // 28 attended out of 40 = 70.0% (Critical)
      const lowSubject = AttendanceSubject(
        courseCode: 'CST304',
        courseTitle: 'Computer Networks',
        attendedHours: 28,
        totalHours: 40,
      );

      expect(lowSubject.percentage, closeTo(70.0, 0.01));
      expect(lowSubject.status, AttendanceStatus.critical);
      expect(lowSubject.safeBunkCount, 0);
      // Required to catch up: (3 * 40) - (4 * 28) = 120 - 112 = 8 classes
      expect(lowSubject.requiredToCatchUp, 8);

      // Verify catch-up: (28 + 8) / (40 + 8) = 36 / 48 = 75.0%
      const attendedAfterCatchup = 28 + 8;
      const totalAfterCatchup = 40 + 8;
      expect((attendedAfterCatchup / totalAfterCatchup) * 100, 75.0);
    });
  });

  group('Student Overview Tab Widget Tests', () {
    testWidgets('Renders greeting, quick stats, and timetable preview',
        (tester) async {
      tester.view.physicalSize = const Size(1280, 900);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            authStateProvider.overrideWith((ref) => _MockAuthNotifier()),
            studentClassDetailsProvider.overrideWith((ref) async => mockClass),
            studentCoursesProvider.overrideWith((ref) async => mockCourses),
            studentTimetableProvider.overrideWith((ref) async => mockEntries),
            studentTodayScheduleProvider.overrideWithValue(mockEntries),
            studentAttendanceProvider.overrideWithValue(mockAttendance),
            studentRegistrationsProvider.overrideWith(
              (ref) => FakeRegistrationsNotifier(mockRegistrations),
            ),
            studentEventsProvider.overrideWith(
              (ref) => FakeEventsNotifier(mockEvents),
            ),
            studentClubsProvider.overrideWith((ref) async => mockClubs),
          ],
          child: const MaterialApp(
            home: Scaffold(
              body: StudentOverviewTab(),
            ),
          ),
        ),
      );

      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      // Greeting & Stats check
      expect(find.text('S6 CSE - Div A'), findsOneWidget);
      expect(find.text('Attendance'), findsOneWidget);
      expect(find.text('Active Passes'), findsOneWidget);
      expect(find.text('KTU Activity'), findsOneWidget);
    });
  });

  group('Student Academics Tab Widget Tests', () {
    testWidgets('Renders all 4 subtabs: Cohort, Courses, Timetable, Attendance',
        (tester) async {
      tester.view.physicalSize = const Size(1280, 900);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            authStateProvider.overrideWith((ref) => _MockAuthNotifier()),
            studentClassDetailsProvider.overrideWith((ref) async => mockClass),
            studentCoursesProvider.overrideWith((ref) async => mockCourses),
            studentTimetableProvider.overrideWith((ref) async => mockEntries),
            studentTodayScheduleProvider.overrideWithValue(mockEntries),
            studentAttendanceProvider.overrideWithValue(mockAttendance),
          ],
          child: const MaterialApp(
            home: Scaffold(
              body: StudentAcademicsTab(),
            ),
          ),
        ),
      );

      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      // Check subtabs
      expect(find.text('Class Cohort'), findsOneWidget);
      expect(find.text('Enrolled Courses'), findsOneWidget);
      expect(find.text('Weekly Timetable'), findsOneWidget);
      expect(find.text('Attendance'), findsOneWidget);

      // Verify Class details
      expect(find.text('Dr. Elizabeth Varghese'), findsOneWidget);
      expect(find.text('Rahul S.'), findsOneWidget);

      // Tap on Courses tab
      await tester.tap(find.text('Enrolled Courses'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));
      expect(find.text('Compiler Design'), findsOneWidget);
      expect(find.text('Networking Lab'), findsOneWidget);

      // Tap on Timetable tab
      await tester.tap(find.text('Weekly Timetable'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));
      expect(find.text('Mon'), findsOneWidget);

      // Tap on Attendance tab
      await tester.tap(find.text('Attendance'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));
      expect(find.text('Overall Attendance'), findsOneWidget);
    });
  });

  group('Student Events & Passes Tab Tests', () {
    testWidgets('Switches between Discover Events and My Entry Passes',
        (tester) async {
      tester.view.physicalSize = const Size(1280, 900);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            authStateProvider.overrideWith((ref) => _MockAuthNotifier()),
            studentEventsProvider.overrideWith(
              (ref) => FakeEventsNotifier(mockEvents),
            ),
            studentRegistrationsProvider.overrideWith(
              (ref) => FakeRegistrationsNotifier(mockRegistrations),
            ),
          ],
          child: const MaterialApp(
            home: Scaffold(
              body: StudentEventsTab(),
            ),
          ),
        ),
      );

      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      expect(find.text('Discover Events (1)'), findsOneWidget);
      expect(find.text('HackVerse 2026: Campus Hackathon'), findsOneWidget);

      // Switch to Passes
      await tester.tap(find.text('My Passes (1)'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));
      expect(find.text('CONFIRMED'), findsOneWidget);
      expect(find.text('CAMP-PASS-1234-TEST'), findsOneWidget);
    });
  });

  group('Student Clubs Tab Tests', () {
    testWidgets('Renders Student Union spotlight and Technical Clubs',
        (tester) async {
      tester.view.physicalSize = const Size(1280, 900);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            authStateProvider.overrideWith((ref) => _MockAuthNotifier()),
            studentClubsProvider.overrideWith((ref) async => mockClubs),
          ],
          child: const MaterialApp(
            home: Scaffold(
              body: StudentClubsTab(),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.text('STUDENT GOVERNANCE BODY'), findsOneWidget);
      expect(find.text('College Student Union (CSU)'), findsOneWidget);
      expect(find.text('IEEE Student Branch'), findsOneWidget);
    });
  });

  group('Student Profile & ID Card Tests', () {
    testWidgets('Renders Holographic Virtual ID Card and KTU Meter',
        (tester) async {
      tester.view.physicalSize = const Size(1280, 900);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            authStateProvider.overrideWith((ref) => _MockAuthNotifier()),
            studentClassDetailsProvider.overrideWith((ref) async => mockClass),
            studentAttendanceProvider.overrideWithValue(mockAttendance),
          ],
          child: const MaterialApp(
            home: Scaffold(
              body: StudentProfileTab(),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.text('CAMPUS STUDENT IDENTITY PASS'), findsOneWidget);
      expect(find.text('KTU Activity Points'), findsOneWidget);
      expect(find.byType(StudentIdCard), findsOneWidget);
    });
  });

  group('Interactive QR Pass Dialog Tests', () {
    testWidgets('Opens dialog, paints vector QR matrix and scanline',
        (tester) async {
      tester.view.physicalSize = const Size(800, 800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            authStateProvider.overrideWith((ref) => _MockAuthNotifier()),
          ],
          child: MaterialApp(
            home: Scaffold(
              body: Builder(
                builder: (ctx) => Center(
                  child: ElevatedButton(
                    onPressed: () {
                      unawaited(QrPassDialog.show(ctx, mockRegistrations.first));
                    },
                    child: const Text('Open Pass'),
                  ),
                ),
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.text('Open Pass'));
      // Pump initial frame of dialog without waiting for infinite repeat
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      expect(
        find.text('HackVerse 2026: Campus Hackathon'),
        findsOneWidget,
      );
      expect(find.text('CAMP-PASS-1234-TEST'), findsOneWidget);
      expect(
        find.text('Present this pass at the gate for instant NFC/QR check-in'),
        findsOneWidget,
      );
    });
  });

  group('Attendance Gauge Card Tests', () {
    testWidgets('Renders interactive bunk slider and updates projection',
        (tester) async {
      tester.view.physicalSize = const Size(800, 800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      final attendance = OverallAttendance.mock();

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SingleChildScrollView(
              child: AttendanceGaugeCard(attendance: attendance),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.text('Overall Attendance'), findsOneWidget);
      expect(find.text('KTU Minimum 75% Requirement'), findsOneWidget);
      expect(find.byIcon(Icons.add_circle_outline), findsOneWidget);
      expect(find.byIcon(Icons.remove_circle_outline), findsOneWidget);

      // Tap to simulate missing 1 class
      await tester.tap(find.byIcon(Icons.add_circle_outline));
      await tester.pumpAndSettle();

      expect(find.text('1 hrs'), findsOneWidget);
    });
  });
}

class _MockAuthNotifier extends StateNotifier<AuthUserState>
    implements AuthNotifier {
  _MockAuthNotifier() : super(const AuthUserState());

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class FakeEventsNotifier extends StudentEventsNotifier {
  FakeEventsNotifier(this._initialData)
      : super(
          service: StudentService(),
          studentId: 'test-student-id',
        ) {
    state = AsyncValue.data(_initialData);
  }

  final List<StudentEvent> _initialData;

  @override
  Future<void> loadEvents() async {
    state = AsyncValue.data(_initialData);
  }
}

class FakeRegistrationsNotifier extends StudentRegistrationsNotifier {
  FakeRegistrationsNotifier(this._initialData)
      : super(
          service: StudentService(),
          studentId: 'test-student-id',
        ) {
    state = AsyncValue.data(_initialData);
  }

  final List<StudentRegistration> _initialData;

  @override
  Future<void> loadRegistrations() async {
    state = AsyncValue.data(_initialData);
  }
}
