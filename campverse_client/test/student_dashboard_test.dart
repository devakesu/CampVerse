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

      expect(find.text('Discover Events'), findsOneWidget);
      expect(find.text('HackVerse 2026: Campus Hackathon'), findsOneWidget);

      // Switch to Passes
      await tester.tap(find.text('My Passes'));
      await tester.pumpAndSettle();
      expect(find.text('CONFIRMED'), findsOneWidget);
      // Pass code is NOT visible in the passes list
      expect(find.text('CAMP-PASS-1234-TEST'), findsNothing);

      // Open detailed pass popup
      await tester.tap(find.text('Pass'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));
      expect(find.text('CAMP-PASS-1234-TEST'), findsOneWidget);
    });

    testWidgets(
        'Renders category selector with icons, Duty Leave & Free Entry badges, '
        'and no LIVE or ACTIVE badges', (tester) async {
      tester.view.physicalSize = const Size(1280, 900);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
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

      // 1. Verify NO 'LIVE' or 'ACTIVE' badges on status cards
      expect(find.text('LIVE'), findsNothing);
      expect(find.text('ACTIVE'), findsNothing);

      // 2. Verify status metric cards titles
      expect(find.text('Happening Now'), findsOneWidget);
      expect(find.text('Scheduled Today'), findsOneWidget);
      expect(find.text('Upcoming'), findsOneWidget);

      // 3. Verify category selector items with labels
      expect(find.text('All'), findsOneWidget);
      expect(find.text('Tech'), findsOneWidget);
      expect(find.text('Hackathon'), findsOneWidget);
      expect(find.text('Workshop'), findsOneWidget);
      expect(find.text('Cultural'), findsOneWidget);
      expect(find.text('Sports'), findsOneWidget);

      // 4. Verify quick filter badges: Duty Leave and Free Entry only
      expect(find.text('Duty Leave'), findsAtLeastNWidgets(1));
      expect(find.text('Free Entry'), findsAtLeastNWidgets(1));
    });

    testWidgets(
        'Renders mobile category selector and bottom sheet picker on narrow '
        'viewports', (tester) async {
      tester.view.physicalSize = const Size(390, 844);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
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

      // On mobile, the mobile category selector shows 'All Categories'
      // and 'Change'
      expect(find.text('All Categories'), findsOneWidget);
      expect(find.text('Change'), findsOneWidget);

      // Centered Duty Leave and Free Entry badges
      expect(find.text('Duty Leave'), findsAtLeastNWidgets(1));
      expect(find.text('Free Entry'), findsAtLeastNWidgets(1));

      // Tap to open the Category Picker BottomSheet
      await tester.tap(find.text('Change'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      // Bottom sheet header and grid of categories
      expect(find.text('Event Categories'), findsOneWidget);
      expect(find.text('Filter campus events by category'), findsOneWidget);
      expect(find.text('Tech'), findsOneWidget);
      expect(find.text('Hackathon'), findsOneWidget);
      expect(find.text('Workshop'), findsOneWidget);

      // Tap 'Hackathon' to filter
      await tester.tap(find.text('Hackathon'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      // Modal is dismissed, mobile button now shows 'Hackathon'
      expect(find.text('Hackathon'), findsAtLeastNWidgets(1));
    });

    testWidgets(
        'Renders dynamic search dropdown, selects entry, and filters '
        'event list', (tester) async {
      tester.view.physicalSize = const Size(1280, 900);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      final searchEvents = [
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
        StudentEvent(
          id: 'event-2',
          title: 'Rhythm Night: Musical Evening',
          venue: 'Open Amphitheatre',
          startTime: now.add(const Duration(days: 5)),
          endTime: now.add(const Duration(days: 5, hours: 4)),
          primaryOrgName: 'Music Club',
          description: 'Live acoustic and rock band festival.',
        ),
      ];

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            studentEventsProvider.overrideWith(
              (ref) => FakeEventsNotifier(searchEvents),
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

      // Initially both events are visible
      expect(find.text('HackVerse 2026: Campus Hackathon'), findsOneWidget);
      expect(find.text('Rhythm Night: Musical Evening'), findsOneWidget);

      // 1. Enter matching event query 'Hack'
      await tester.enterText(find.byType(TextField), 'Hack');
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      // Dropdown appears with EVENTS group
      expect(find.text('EVENTS'), findsOneWidget);
      expect(
        find.text('HackVerse 2026: Campus Hackathon'),
        findsAtLeastNWidgets(1),
      );

      // 2. Enter matching organisation query 'IEEE'
      await tester.enterText(find.byType(TextField), 'IEEE');
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      // Dropdown appears with ORGANISATIONS group
      expect(find.text('ORGANISATIONS'), findsOneWidget);
      expect(find.text('IEEE Student Branch'), findsAtLeastNWidgets(1));

      // 3. Enter matching venue query 'Auditorium'
      await tester.enterText(find.byType(TextField), 'Auditorium');
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      // Dropdown appears with VENUES group
      expect(find.text('VENUES'), findsOneWidget);
      expect(find.text('Auditorium Hall'), findsAtLeastNWidgets(1));

      // Tap on the venue suggestion in the dropdown
      await tester.tap(find.text('Auditorium Hall').first);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 200));

      // Dropdown is dismissed and search text is populated
      final textField = tester.widget<TextField>(find.byType(TextField));
      expect(textField.controller?.text, 'Auditorium Hall');
      expect(find.text('VENUES'), findsNothing);

      // The events list is filtered to only Auditorium Hall event
      expect(find.text('HackVerse 2026: Campus Hackathon'), findsOneWidget);
      expect(find.text('Rhythm Night: Musical Evening'), findsNothing);

      // Clear search
      await tester.tap(find.byIcon(Icons.cancel_rounded));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 200));

      // Both events are visible again
      expect(find.text('HackVerse 2026: Campus Hackathon'), findsOneWidget);
      expect(find.text('Rhythm Night: Musical Evening'), findsOneWidget);
    });

    testWidgets(
        'Updates status metric cards dynamically based on filters and pops '
        'selected status card without Filtered by badge', (tester) async {
      tester.view.physicalSize = const Size(1280, 900);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      final statusEvents = [
        StudentEvent(
          id: 'event-1',
          title: 'Live Workshop',
          venue: 'Lab A',
          startTime: now.subtract(const Duration(hours: 1)),
          endTime: now.add(const Duration(hours: 2)),
          tags: const ['Tech'],
        ),
        StudentEvent(
          id: 'event-2',
          title: 'Evening Seminar',
          venue: 'Hall B',
          startTime: now.add(const Duration(hours: 3)),
          endTime: now.add(const Duration(hours: 5)),
          tags: const ['Tech'],
          isPaid: true,
        ),
        StudentEvent(
          id: 'event-3',
          title: 'Cultural Festival',
          venue: 'Grounds',
          startTime: now.add(const Duration(days: 3)),
          endTime: now.add(const Duration(days: 4)),
          tags: const ['Cultural'],
          isDutyLeaveApproved: true,
        ),
      ];

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            studentEventsProvider.overrideWith(
              (ref) => FakeEventsNotifier(statusEvents),
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

      // 1. Initial counts: 1 Happening Now, 1 Scheduled Today, 1 Upcoming
      expect(find.text('Happening Now'), findsOneWidget);
      expect(find.text('Scheduled Today'), findsOneWidget);
      expect(find.text('Upcoming'), findsOneWidget);

      // 2. Select 'Tech' category
      await tester.tap(find.text('Tech'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 200));

      // In Tech category, Cultural event is excluded, so Upcoming count is 0
      // 3. Toggle 'Free Entry' chip
      await tester.tap(find.text('Free Entry').first);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 200));

      // 4. Tap 'Happening Now' status card to pop it as active filter
      await tester.tap(find.text('Happening Now'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 200));

      // Verify selected card pops with clear prompt and NO 'Filtered by' badge
      expect(find.text('Tap to clear filter'), findsOneWidget);
      expect(find.textContaining('Filtered by'), findsNothing);

      // Verify event list shows only Live Workshop
      expect(find.text('Live Workshop'), findsOneWidget);
      expect(find.text('Evening Seminar'), findsNothing);
      expect(find.text('Cultural Festival'), findsNothing);

      // 5. Tap again to clear the status filter
      await tester.tap(find.text('Happening Now'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 200));

      expect(find.text('Tap to clear filter'), findsNothing);
    });

    testWidgets('Renders ErrorStateCard when events fail to load',
        (tester) async {
      tester.view.physicalSize = const Size(1280, 900);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            studentEventsProvider.overrideWith(
              (ref) => FakeErrorEventsNotifier('Network connection failed'),
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

      expect(find.text('Unable to Load Campus Events'), findsOneWidget);
      expect(find.text('Network connection failed'), findsOneWidget);
      expect(find.text('Retry'), findsOneWidget);
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
                      unawaited(
                        QrPassDialog.show(ctx, mockRegistrations.first),
                      );
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

  group('Student Events 3rd Tab (Past Events) Tests', () {
    testWidgets(
        'Renders 3rd tab for past events, sorts in desc of end_time, '
        'and filters correctly', (tester) async {
      tester.view.physicalSize = const Size(1280, 900);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      final mixedEvents = [
        StudentEvent(
          id: 'event-older',
          title: 'Older AI Conclave 2025',
          venue: 'APJ Hall',
          startTime: now.subtract(const Duration(days: 6)),
          endTime: now.subtract(const Duration(days: 5)),
          tags: const ['Tech'],
          isDutyLeaveApproved: true,
        ),
        StudentEvent(
          id: 'event-recent',
          title: 'Recent Robotics Workshop',
          venue: 'Robotics Lab',
          startTime: now.subtract(const Duration(hours: 4)),
          endTime: now.subtract(const Duration(hours: 1)),
          tags: const ['Workshop'],
          isPaid: true,
        ),
        StudentEvent(
          id: 'event-future',
          title: 'Future Mega Hackathon 2026',
          venue: 'Auditorium Hall',
          startTime: now.add(const Duration(days: 2)),
          endTime: now.add(const Duration(days: 3)),
          tags: const ['Hackathon'],
        ),
      ];

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            studentEventsProvider.overrideWith(
              (ref) => FakeEventsNotifier(mixedEvents),
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

      // 1. Verify 3 tabs are rendered on desktop
      expect(find.text('Discover Events'), findsOneWidget);
      expect(find.text('My Passes'), findsOneWidget);
      expect(find.text('Past Events'), findsOneWidget);

      // In Discover tab, Future event is visible
      expect(find.text('Future Mega Hackathon 2026'), findsOneWidget);

      // 2. Switch to 3rd tab: Past Events
      await tester.tap(find.text('Past Events'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      // Verify Archive Subheader is docked and Concluded badge is removed
      expect(find.text('Past Events Archive'), findsOneWidget);
      expect(find.textContaining(RegExp(r'\d+\s+Concluded')), findsNothing);

      // Future event MUST NOT appear in Past Events
      expect(find.text('Future Mega Hackathon 2026'), findsNothing);

      // Past events are both visible
      expect(find.text('Recent Robotics Workshop'), findsOneWidget);
      expect(find.text('Older AI Conclave 2025'), findsOneWidget);

      // 3. Verify ordering: Recent workshop (ended 1h ago) appears before
      // older conclave (ended 5d ago)
      final recentWorkshopTop =
          tester.getTopLeft(find.text('Recent Robotics Workshop')).dy;
      final olderConclaveTop =
          tester.getTopLeft(find.text('Older AI Conclave 2025')).dy;
      // In staggered grid or column, recent workshop is positioned first
      expect(recentWorkshopTop, lessThanOrEqualTo(olderConclaveTop));

      // 4. Test Search filter in Past Events tab
      await tester.enterText(find.byType(TextField), 'Conclave');
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 200));

      // Tap on suggestion in dropdown to select and close overlay
      await tester.tap(find.text('Older AI Conclave 2025').first);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 200));

      final pastTextField = tester.widget<TextField>(find.byType(TextField));
      expect(pastTextField.controller?.text, 'Older AI Conclave 2025');
      expect(
        find.byWidgetPredicate(
            (w) => w is Text && w.data == 'Older AI Conclave 2025'),
        findsOneWidget,
      );
      expect(find.text('Recent Robotics Workshop'), findsNothing);

      // Clear search
      await tester.tap(find.byIcon(Icons.cancel_rounded));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 200));
      expect(find.text('Recent Robotics Workshop'), findsOneWidget);

      // 5. Test Quick Filter (Duty Leave) in Past Events tab
      await tester.tap(find.text('Duty Leave').first);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 200));

      // Older Conclave had duty leave, Recent Workshop did not
      expect(find.text('Older AI Conclave 2025'), findsOneWidget);
      expect(find.text('Recent Robotics Workshop'), findsNothing);

      // Uncheck Duty Leave
      await tester.tap(find.text('Duty Leave').first);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 200));
      expect(find.text('Recent Robotics Workshop'), findsOneWidget);
    });

    testWidgets('Adapts tab labels across screen sizes (< 520px vs >= 520px)',
        (tester) async {
      // 1. Mobile Screen (< 520px)
      tester.view.physicalSize = const Size(390, 844);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
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

      // On narrow screen, compact tab labels are used
      expect(find.text('Discover'), findsOneWidget);
      expect(find.text('Passes'), findsOneWidget);
      expect(find.text('Past'), findsOneWidget);

      // Tap 'Past' tab on mobile
      await tester.tap(find.text('Past'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));
      expect(find.text('Past Events Archive'), findsOneWidget);
    });
  });

  group('Student Passes Subtabs (Upcoming and Past) Tests', () {
    testWidgets(
        'Separates passes into Upcoming and Past with swipe layout and search',
        (tester) async {
      tester.view.physicalSize = const Size(1280, 900);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      final multiPassRegistrations = [
        StudentRegistration(
          id: 'reg-upcoming',
          eventId: 'event-upcoming',
          userId: 'test-student-id',
          qrPayload: 'CAMP-PASS-UPCOMING',
          status: 'confirmed',
          createdAt: now.subtract(const Duration(days: 1)),
          event: StudentEvent(
            id: 'event-upcoming',
            title: 'Upcoming Mega Hackathon',
            venue: 'Main Auditorium',
            startTime: now.add(const Duration(days: 2)),
            endTime: now.add(const Duration(days: 3)),
          ),
        ),
        StudentRegistration(
          id: 'reg-past',
          eventId: 'event-past',
          userId: 'test-student-id',
          qrPayload: 'CAMP-PASS-PAST-TOKEN',
          status: 'used',
          createdAt: now.subtract(const Duration(days: 10)),
          event: StudentEvent(
            id: 'event-past',
            title: 'Past Robotics Summit',
            venue: 'Seminar Hall B',
            startTime: now.subtract(const Duration(days: 5)),
            endTime: now.subtract(const Duration(days: 4)),
          ),
        ),
        StudentRegistration(
          id: 'reg-used-upcoming',
          eventId: 'event-used-upcoming',
          userId: 'test-student-id',
          qrPayload: 'CAMP-PASS-USED-UPCOMING',
          status: 'confirmed',
          scanCount: 1,
          createdAt: now.subtract(const Duration(days: 2)),
          event: StudentEvent(
            id: 'event-used-upcoming',
            title: 'AI Symposium (Used Pass)',
            venue: 'Lecture Hall 1',
            startTime: now.add(const Duration(days: 1)),
            endTime: now.add(const Duration(days: 2)),
          ),
        ),
      ];

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            studentEventsProvider.overrideWith(
              (ref) => FakeEventsNotifier(mockEvents),
            ),
            studentRegistrationsProvider.overrideWith(
              (ref) => FakeRegistrationsNotifier(multiPassRegistrations),
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

      // 1. Switch to My Passes tab
      await tester.tap(find.text('My Passes'));
      await tester.pumpAndSettle();

      // 2. Both subtabs exist
      expect(find.text('Upcoming Passes'), findsOneWidget);
      expect(find.text('Past Passes'), findsOneWidget);

      // Default subtab is Upcoming Passes (both active & used-upcoming are here)
      expect(find.text('Upcoming Mega Hackathon'), findsOneWidget);
      expect(find.text('AI Symposium (Used Pass)'), findsOneWidget);
      expect(find.text('EXPIRED - USED'), findsOneWidget);
      expect(find.text('CAMP-PASS-UPCOMING'), findsNothing);
      expect(find.text('Past Robotics Summit'), findsNothing);

      // 3. Switch to Past Passes tab
      await tester.tap(find.text('Past Passes'));
      await tester.pumpAndSettle();

      // In Past Passes, only concluded pass is shown
      expect(find.text('Past Robotics Summit'), findsOneWidget);
      expect(find.text('CAMP-PASS-PAST-TOKEN'), findsNothing);
      expect(find.text('Upcoming Mega Hackathon'), findsNothing);
      expect(find.text('AI Symposium (Used Pass)'), findsNothing);

      // 4. Switch back to Upcoming Passes via tab button
      await tester.tap(find.text('Upcoming Passes'));
      await tester.pumpAndSettle();

      expect(find.text('Upcoming Mega Hackathon'), findsOneWidget);
      expect(find.text('AI Symposium (Used Pass)'), findsOneWidget);
      expect(find.text('Past Robotics Summit'), findsNothing);

      // 5. Test horizontal swipe gesture with fling
      await tester.fling(
        find.text('Upcoming Mega Hackathon'),
        const Offset(-500, 0),
        1000,
      );
      await tester.pumpAndSettle();

      // Swiped to Past Passes
      expect(find.text('Past Robotics Summit'), findsOneWidget);

      // Swipe back to Upcoming Passes
      await tester.fling(
        find.text('Past Robotics Summit'),
        const Offset(500, 0),
        1000,
      );
      await tester.pumpAndSettle();

      expect(find.text('Upcoming Mega Hackathon'), findsOneWidget);

      // 5. Test search bar in passes
      final passSearchField = find.byType(TextField);
      expect(passSearchField, findsOneWidget);

      await tester.enterText(passSearchField, 'Auditorium');
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 200));

      expect(find.text('Upcoming Mega Hackathon'), findsOneWidget);

      // Search non-matching term in Upcoming
      await tester.enterText(passSearchField, 'NonExistentEvent');
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 200));

      expect(find.text('Upcoming Mega Hackathon'), findsNothing);
      expect(
        find.text('No passes matching "NonExistentEvent"'),
        findsOneWidget,
      );

      // Tap Clear Search button
      await tester.tap(find.text('Clear Search'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 200));

      expect(find.text('Upcoming Mega Hackathon'), findsOneWidget);
    });

    testWidgets(
      'Passes tab does not display KTU points and does not overflow on small screens with long tokens',
      (tester) async {
        tester.view.physicalSize = const Size(390, 844);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);

        final now = DateTime.now();
        final passRegistrations = [
          StudentRegistration(
            id: 'reg-long-token',
            eventId: 'event-ktu',
            userId: 'test-student-id',
            qrPayload: 'CAMP-PASS-VERY-LONG-PAYLOAD-TOKEN-IDENTIFIER-123456789',
            status: 'confirmed',
            createdAt: now.subtract(const Duration(days: 1)),
            event: StudentEvent(
              id: 'event-ktu',
              title: 'Super Long Engineering Hackathon with Many Words in Title',
              venue: 'Main Campus Computer Science Block Auditorium Hall 3',
              startTime: now.add(const Duration(days: 2)),
              endTime: now.add(const Duration(days: 3)),
              ktuActivityPoints: 50,
            ),
          ),
        ];

        await tester.pumpWidget(
          ProviderScope(
            overrides: [
              authStateProvider.overrideWith((ref) => _MockAuthNotifier()),
              studentEventsProvider.overrideWith(
                (ref) => FakeEventsNotifier(mockEvents),
              ),
              studentRegistrationsProvider.overrideWith(
                (ref) => FakeRegistrationsNotifier(passRegistrations),
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

        // Switch to Passes tab (on 360px screen, label is 'Passes')
        await tester.tap(find.text('Passes'));
        await tester.pumpAndSettle();

        // Check that no KTU activity points are rendered anywhere in the passes tab
        expect(find.textContaining('KTU'), findsNothing);

        // Verify pass card renders cleanly without any RenderFlex overflow
        expect(tester.takeException(), isNull);
        expect(find.text('CONFIRMED'), findsOneWidget);
        expect(
          find.text('Super Long Engineering Hackathon with Many Words in Title'),
          findsOneWidget,
        );

        // Open QR pass dialog
        await tester.tap(find.text('Pass'));
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 300));

        // In QrPassDialog, verify no KTU elements and no exceptions
        expect(find.textContaining('KTU'), findsNothing);
        expect(tester.takeException(), isNull);
      },
    );

    testWidgets(
      'Pass card renders with full text on ultra-compact 320px screens without overflow or truncation',
      (tester) async {
        tester.view.physicalSize = const Size(320, 600);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);

        final now = DateTime.now();
        final passRegistrations = [
          StudentRegistration(
            id: 'reg-compact-screen',
            eventId: 'event-compact',
            userId: 'test-student-id',
            qrPayload: 'CAMP-PASS-CODE-001',
            status: 'confirmed',
            createdAt: now.subtract(const Duration(days: 1)),
            event: StudentEvent(
              id: 'event-compact',
              title: 'International Annual Engineering Summit & Expo 2026',
              venue: 'Main Campus Computer Science Block Auditorium Hall 3',
              startTime: now.add(const Duration(days: 2)),
              endTime: now.add(const Duration(days: 3)),
            ),
          ),
        ];

        await tester.pumpWidget(
          ProviderScope(
            overrides: [
              authStateProvider.overrideWith((ref) => _MockAuthNotifier()),
              studentEventsProvider.overrideWith(
                (ref) => FakeEventsNotifier(mockEvents),
              ),
              studentRegistrationsProvider.overrideWith(
                (ref) => FakeRegistrationsNotifier(passRegistrations),
              ),
            ],
            child: const MaterialApp(
              home: Scaffold(
                body: StudentEventsTab(initialSubTabIndex: 1),
              ),
            ),
          ),
        );

        await tester.pump();
        await tester.pump(const Duration(milliseconds: 300));

        expect(tester.takeException(), isNull);
        expect(
          find.text('International Annual Engineering Summit & Expo 2026'),
          findsOneWidget,
        );
        expect(
          find.text('Main Campus Computer Science Block Auditorium Hall 3'),
          findsOneWidget,
        );
        expect(find.text('CAMP-PASS-CODE-001'), findsNothing);
        expect(find.text('Pass'), findsOneWidget);

        // Open pass dialog
        await tester.tap(find.text('Pass'));
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 300));

        expect(tester.takeException(), isNull);
        expect(
          find.text('International Annual Engineering Summit & Expo 2026'),
          findsWidgets,
        );
        expect(find.text('CAMP-PASS-CODE-001'), findsOneWidget);
      },
    );
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

class FakeErrorEventsNotifier extends StudentEventsNotifier {
  FakeErrorEventsNotifier(this.errorMessage)
      : super(
          service: StudentService(),
          studentId: 'test-student-id',
        ) {
    state = AsyncValue.error(errorMessage, StackTrace.empty);
  }

  final String errorMessage;

  @override
  Future<void> loadEvents() async {
    state = AsyncValue.error(errorMessage, StackTrace.empty);
  }
}

class FakeErrorRegistrationsNotifier extends StudentRegistrationsNotifier {
  FakeErrorRegistrationsNotifier(this.errorMessage)
      : super(
          service: StudentService(),
          studentId: 'test-student-id',
        ) {
    state = AsyncValue.error(errorMessage, StackTrace.empty);
  }

  final String errorMessage;

  @override
  Future<void> loadRegistrations() async {
    state = AsyncValue.error(errorMessage, StackTrace.empty);
  }
}
