import 'dart:async';

import 'package:campverse/core/providers/auth_provider.dart';
import 'package:campverse/features/student/models/student_attendance.dart';
import 'package:campverse/features/student/models/student_class_details.dart';
import 'package:campverse/features/student/models/student_club.dart';
import 'package:campverse/features/student/models/student_course.dart';
import 'package:campverse/features/student/models/student_event.dart';
import 'package:campverse/features/student/models/student_registration.dart';
import 'package:campverse/features/student/models/student_timetable_entry.dart';
import 'package:campverse/features/student/services/student_service.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Provider exposing the StudentService instance.
final studentServiceProvider = Provider<StudentService>((ref) {
  final authService = ref.watch(supabaseAuthServiceProvider);
  return StudentService(client: authService.client);
});

/// Provider resolving student's class and academic cohort information.
final studentClassDetailsProvider =
    FutureProvider<StudentClassDetails>((ref) async {
  final service = ref.watch(studentServiceProvider);
  final authState = ref.watch(authStateProvider);
  final instituteId = authState.instituteId;

  final res = await service.fetchClassDetails(
    instituteId: instituteId,
  );
  return res.data ??
      const StudentClassDetails(
        id: 'demo-class-1',
        programmeName: 'B.Tech. Computer Science & Engineering',
        programmeCode: 'CSE',
        departmentName: 'Computer Science & Engineering',
        departmentCode: 'CSE',
        admissionYear: 2023,
        gradYear: 2027,
        currentSemester: 6,
        division: 'A',
      );
});

/// Provider fetching enrolled academic courses for the student.
final studentCoursesProvider =
    FutureProvider<List<StudentCourse>>((ref) async {
  final service = ref.watch(studentServiceProvider);
  final authState = ref.watch(authStateProvider);
  final studentId = authState.user?.id ?? '';

  final res = await service.fetchEnrolledCourses(studentId: studentId);
  return res.data ?? const [];
});

/// Provider fetching full weekly timetable schedule matrix.
final studentTimetableProvider =
    FutureProvider<List<StudentTimetableEntry>>((ref) async {
  final service = ref.watch(studentServiceProvider);
  final res = await service.fetchTimetable();
  return res.data ?? const [];
});

/// Provider filtering timetable entries for the current weekday.
final studentTodayScheduleProvider =
    Provider<List<StudentTimetableEntry>>((ref) {
  final timetableAsync = ref.watch(studentTimetableProvider);
  final allEntries = timetableAsync.valueOrNull ?? const [];

  final weekdayMap = {
    DateTime.monday: 'monday',
    DateTime.tuesday: 'tuesday',
    DateTime.wednesday: 'wednesday',
    DateTime.thursday: 'thursday',
    DateTime.friday: 'friday',
    DateTime.saturday: 'saturday',
    DateTime.sunday: 'monday', // Fallback to Monday on Sunday
  };

  final todayDayName = weekdayMap[DateTime.now().weekday] ?? 'monday';
  final todayEntries =
      allEntries.where((e) => e.day == todayDayName).toList()
        ..sort((a, b) => a.periodNumber.compareTo(b.periodNumber));

  return todayEntries.isNotEmpty ? todayEntries : allEntries.take(5).toList();
});

/// State notifier for reactive campus events discovery.
class StudentEventsNotifier
    extends StateNotifier<AsyncValue<List<StudentEvent>>> {
  /// Default constructor.
  StudentEventsNotifier({
    required this.service,
    required this.studentId,
    this.instituteId,
  }) : super(const AsyncValue.loading()) {
    unawaited(loadEvents());
  }

  /// Student service.
  final StudentService service;

  /// Active student user ID.
  final String studentId;

  /// Active institute affiliation ID.
  final String? instituteId;

  /// Loads published campus events.
  Future<void> loadEvents() async {
    state = const AsyncValue.loading();
    final res = await service.fetchEvents(
      studentId: studentId,
      instituteId: instituteId,
    );
    if (!mounted) {
      return;
    }
    if (res.success) {
      state = AsyncValue.data(res.data ?? []);
    } else {
      state = AsyncValue.error(
        res.error ?? 'Failed to load events',
        StackTrace.current,
      );
    }
  }

  /// Registers current student for an event and marks it reactive.
  Future<bool> register(String eventId) async {
    final res = await service.registerForEvent(
      studentId: studentId,
      eventId: eventId,
    );
    if (!mounted) {
      return false;
    }
    if (res.success) {
      // Optimistically update list
      state = state.whenData((list) {
        return list.map((e) {
          if (e.id == eventId) {
            return e.copyWith(isRegisteredByMe: true);
          }
          return e;
        }).toList();
      });
      return true;
    }
    return false;
  }
}

/// Provider managing published campus events with instant registration.
final studentEventsProvider = StateNotifierProvider<StudentEventsNotifier,
    AsyncValue<List<StudentEvent>>>((ref) {
  final service = ref.watch(studentServiceProvider);
  final authState = ref.watch(authStateProvider);
  return StudentEventsNotifier(
    service: service,
    studentId: authState.user?.id ?? '',
    instituteId: authState.instituteId,
  );
});

/// State notifier for reactive event registrations and passes.
class StudentRegistrationsNotifier
    extends StateNotifier<AsyncValue<List<StudentRegistration>>> {
  /// Default constructor.
  StudentRegistrationsNotifier({
    required this.service,
    required this.studentId,
  }) : super(const AsyncValue.loading()) {
    unawaited(loadRegistrations());
  }

  /// Student service.
  final StudentService service;

  /// Active student user ID.
  final String studentId;

  /// Loads all registrations for the student.
  Future<void> loadRegistrations() async {
    state = const AsyncValue.loading();
    final res = await service.fetchMyRegistrations(studentId);
    if (!mounted) {
      return;
    }
    if (res.success) {
      state = AsyncValue.data(res.data ?? []);
    } else {
      state = AsyncValue.error(
        res.error ?? 'Failed to load registrations',
        StackTrace.current,
      );
    }
  }

  /// Cancels a pass registration.
  Future<bool> cancelPass(String registrationId) async {
    final res = await service.cancelRegistration(registrationId);
    if (!mounted) {
      return false;
    }
    if (res.success) {
      state = state.whenData((list) {
        return list.where((r) => r.id != registrationId).toList();
      });
      return true;
    }
    return false;
  }
}

/// Provider managing student digital passes.
final studentRegistrationsProvider = StateNotifierProvider<
    StudentRegistrationsNotifier,
    AsyncValue<List<StudentRegistration>>>((ref) {
  final service = ref.watch(studentServiceProvider);
  final authState = ref.watch(authStateProvider);
  return StudentRegistrationsNotifier(
    service: service,
    studentId: authState.user?.id ?? '',
  );
});

/// Provider fetching campus clubs and Student Union.
final studentClubsProvider =
    FutureProvider<List<StudentClub>>((ref) async {
  final service = ref.watch(studentServiceProvider);
  final authState = ref.watch(authStateProvider);
  final res = await service.fetchClubs(
    instituteId: authState.instituteId,
    studentId: authState.user?.id ?? '',
  );
  return res.data ?? const [];
});

/// Provider providing simulated attendance engine metrics.
final studentAttendanceProvider = Provider<OverallAttendance>((ref) {
  final service = ref.watch(studentServiceProvider);
  return service.getAttendanceMetrics();
});
