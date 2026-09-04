import 'package:campverse/core/theme/app_colors.dart';
import 'package:campverse/core/utils/responsive_layout.dart';
import 'package:campverse/features/student/models/student_attendance.dart';
import 'package:campverse/features/student/models/student_class_details.dart';
import 'package:campverse/features/student/models/student_course.dart';
import 'package:campverse/features/student/providers/student_providers.dart';
import 'package:campverse/features/student/widgets/attendance_gauge_card.dart';
import 'package:campverse/features/student/widgets/course_card.dart';
import 'package:campverse/features/student/widgets/timetable_schedule_view.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Academics tab offering deep navigation between Class Cohort details,
/// Enrolled Courses, Weekly Timetable matrix, and Attendance Engine.
class StudentAcademicsTab extends ConsumerStatefulWidget {
  /// Default constructor.
  const StudentAcademicsTab({
    this.initialSubTabIndex = 0,
    super.key,
  });

  /// Initial subtab index (0: Class, 1: Courses, 2: Timetable, 3: Attendance).
  final int initialSubTabIndex;

  @override
  ConsumerState<StudentAcademicsTab> createState() =>
      _StudentAcademicsTabState();
}

class _StudentAcademicsTabState extends ConsumerState<StudentAcademicsTab>
    with SingleTickerProviderStateMixin {
  late TabController _tabCtrl;

  @override
  void initState() {
    super.initState();
    _tabCtrl = TabController(
      length: 4,
      vsync: this,
      initialIndex: widget.initialSubTabIndex,
    );
  }

  @override
  void dispose() {
    _tabCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDesktop = ResponsiveLayout.isDesktop(context);

    final classAsync = ref.watch(studentClassDetailsProvider);
    final coursesAsync = ref.watch(studentCoursesProvider);
    final timetableAsync = ref.watch(studentTimetableProvider);
    final attendance = ref.watch(studentAttendanceProvider);

    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(60),
        child: Container(
          padding: EdgeInsets.symmetric(
            horizontal: isDesktop ? 32 : 16,
            vertical: 6,
          ),
          decoration: BoxDecoration(
            color: AppColors.surfaceOf(context),
            border: Border(
              bottom: BorderSide(
                color: AppColors.borderOf(context),
              ),
            ),
          ),
          child: TabBar(
            controller: _tabCtrl,
            isScrollable: true,
            tabAlignment: TabAlignment.start,
            labelColor: const Color(0xFF0369A1),
            unselectedLabelColor: AppColors.textSecondaryOf(context),
            indicatorColor: const Color(0xFF0369A1),
            indicatorWeight: 3,
            labelStyle: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w700,
            ),
            unselectedLabelStyle: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w500,
            ),
            tabs: const [
              Tab(
                icon: Icon(Icons.groups_outlined, size: 18),
                text: 'Class Cohort',
              ),
              Tab(
                icon: Icon(Icons.book_outlined, size: 18),
                text: 'Enrolled Courses',
              ),
              Tab(
                icon: Icon(Icons.calendar_month_outlined, size: 18),
                text: 'Weekly Timetable',
              ),
              Tab(
                icon: Icon(Icons.donut_large_outlined, size: 18),
                text: 'Attendance',
              ),
            ],
          ),
        ),
      ),
      body: TabBarView(
        controller: _tabCtrl,
        children: [
          _buildClassCohortView(
            context,
            classAsync.value ??
                const StudentClassDetails(
                  id: 'demo',
                  programmeName: 'B.Tech. Computer Science & Engineering',
                  programmeCode: 'CSE',
                  departmentName: 'Computer Science & Engineering',
                  departmentCode: 'CSE',
                  admissionYear: 2023,
                  gradYear: 2027,
                  currentSemester: 6,
                  division: 'A',
                ),
          ),
          _buildCoursesView(context, coursesAsync.value ?? const []),
          _buildTimetableView(context, timetableAsync.value ?? const []),
          _buildAttendanceView(context, attendance),
        ],
      ),
    );
  }

  // ── 1. Class & Cohort Subview ──────────────────────────────────────────────

  Widget _buildClassCohortView(
    BuildContext context,
    StudentClassDetails classDetails,
  ) {
    final isDark = AppColors.isDark(context);
    final isDesktop = ResponsiveLayout.isDesktop(context);

    return ListView(
      padding: EdgeInsets.symmetric(
        horizontal: isDesktop ? 32 : 18,
        vertical: 24,
      ),
      children: [
        // Class Header Banner
        Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: AppColors.surfaceOf(context),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: AppColors.borderOf(context)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 5,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFF0369A1).withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      'DIVISION ${classDetails.division}',
                      style: const TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 0.8,
                        color: Color(0xFF0284C7),
                      ),
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 5,
                    ),
                    decoration: BoxDecoration(
                      color: isDark
                          ? const Color(0xFF1E293B)
                          : const Color(0xFFF1F5F9),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      'Semester ${classDetails.currentSemester}',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textPrimaryOf(context),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              Text(
                classDetails.programmeName,
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w800,
                  color: AppColors.textPrimaryOf(context),
                ),
              ),
              const SizedBox(height: 4),
              Text(
                classDetails.departmentName,
                style: TextStyle(
                  fontSize: 13,
                  color: AppColors.textSecondaryOf(context),
                ),
              ),
              const SizedBox(height: 16),
              Wrap(
                spacing: 12,
                runSpacing: 8,
                children: [
                  _buildTag(context, 'Scheme', classDetails.schemeName),
                  _buildTag(
                    context,
                    'Academic Batch',
                    classDetails.batchYearString,
                  ),
                  _buildTag(context, 'Degree', 'Undergraduate (UG)'),
                ],
              ),
            ],
          ),
        ),

        const SizedBox(height: 20),

        // Staff Advisor Card
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: AppColors.surfaceOf(context),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: AppColors.borderOf(context)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: const Color(0xFF065F46).withValues(alpha: 0.12),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.supervisor_account_rounded,
                      color: Color(0xFF059669),
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Class Tutor & Staff Advisor',
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          color: AppColors.textPrimaryOf(context),
                        ),
                      ),
                      Text(
                        'Academic Guidance & Attendance Approver',
                        style: TextStyle(
                          fontSize: 11,
                          color: AppColors.textSecondaryOf(context),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        classDetails.staffAdvisorName ??
                            'Dr. Elizabeth Varghese',
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          color: AppColors.textPrimaryOf(context),
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        classDetails.staffAdvisorEmail ??
                            'elizabeth.v@campverse.edu',
                        style: TextStyle(
                          fontSize: 12,
                          color: AppColors.textSecondaryOf(context),
                        ),
                      ),
                    ],
                  ),
                  OutlinedButton.icon(
                    onPressed: () {
                      final email = classDetails.staffAdvisorEmail ??
                          'elizabeth.v@campverse.edu';
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('Email advisor: $email'),
                        ),
                      );
                    },
                    icon: const Icon(Icons.email_outlined, size: 16),
                    label: const Text('Contact Advisor'),
                  ),
                ],
              ),
            ],
          ),
        ),

        const SizedBox(height: 20),

        // Class Representatives
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: AppColors.surfaceOf(context),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: AppColors.borderOf(context)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Student Class Representatives',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimaryOf(context),
                ),
              ),
              const SizedBox(height: 12),
              Wrap(
                spacing: 12,
                children: classDetails.classReps.map((rep) {
                  return Chip(
                    avatar: CircleAvatar(
                      backgroundColor: const Color(0xFF0369A1),
                      child: Text(
                        rep[0],
                        style: const TextStyle(
                          fontSize: 11,
                          color: Colors.white,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                    label: Text(rep),
                  );
                }).toList(),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildTag(BuildContext context, String label, String value) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: AppColors.isDark(context)
            ? const Color(0xFF1E293B)
            : const Color(0xFFF1F5F9),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            '$label: ',
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w500,
              color: AppColors.textSecondaryOf(context),
            ),
          ),
          Text(
            value,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimaryOf(context),
            ),
          ),
        ],
      ),
    );
  }

  // ── 2. Enrolled Courses Subview ────────────────────────────────────────────

  Widget _buildCoursesView(
    BuildContext context,
    List<StudentCourse> courses,
  ) {
    final isDesktop = ResponsiveLayout.isDesktop(context);
    final totalCredits = courses.fold<double>(0, (sum, c) => sum + c.credits);

    return ListView(
      padding: EdgeInsets.symmetric(
        horizontal: isDesktop ? 32 : 18,
        vertical: 24,
      ),
      children: [
        // Summary Header Card
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: AppColors.surfaceOf(context),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: AppColors.borderOf(context)),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Curriculum Allocation',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                      color: AppColors.textPrimaryOf(context),
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '${courses.length} Registered Courses for Current Semester',
                    style: TextStyle(
                      fontSize: 12,
                      color: AppColors.textSecondaryOf(context),
                    ),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: const Color(0xFF0369A1).withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  children: [
                    Text(
                      totalCredits.toStringAsFixed(1),
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                        color: Color(0xFF0284C7),
                      ),
                    ),
                    const Text(
                      'TOTAL CREDITS',
                      style: TextStyle(
                        fontSize: 8,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 0.5,
                        color: Color(0xFF0284C7),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),

        const SizedBox(height: 20),

        // Courses List
        if (courses.isEmpty)
          const Center(child: Text('No courses registered for this semester'))
        else
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: courses.length,
            separatorBuilder: (context, _) => const SizedBox(height: 12),
            itemBuilder: (context, index) {
              return CourseCard(course: courses[index]);
            },
          ),
      ],
    );
  }

  // ── 3. Weekly Timetable Subview ────────────────────────────────────────────

  Widget _buildTimetableView(
    BuildContext context,
    List<dynamic> timetableEntries,
  ) {
    final isDesktop = ResponsiveLayout.isDesktop(context);

    return ListView(
      padding: EdgeInsets.symmetric(
        horizontal: isDesktop ? 32 : 18,
        vertical: 24,
      ),
      children: [
        TimetableScheduleView(
          entries: timetableEntries.cast(),
        ),
      ],
    );
  }

  // ── 4. Attendance Tracker Subview ──────────────────────────────────────────

  Widget _buildAttendanceView(
    BuildContext context,
    OverallAttendance attendance,
  ) {
    final isDark = AppColors.isDark(context);
    final isDesktop = ResponsiveLayout.isDesktop(context);

    return ListView(
      padding: EdgeInsets.symmetric(
        horizontal: isDesktop ? 32 : 18,
        vertical: 24,
      ),
      children: [
        AttendanceGaugeCard(attendance: attendance),
        const SizedBox(height: 24),
        Text(
          'Subject-wise Breakdown',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w800,
            color: AppColors.textPrimaryOf(context),
          ),
        ),
        const SizedBox(height: 12),
        ListView.separated(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: attendance.subjects.length,
          separatorBuilder: (context, _) => const SizedBox(height: 12),
          itemBuilder: (context, index) {
            final sub = attendance.subjects[index];
            final isSafe = sub.percentage >= 80.0;
            final isMarginal =
                sub.percentage >= 75.0 && sub.percentage < 80.0;
            final color = isSafe
                ? const Color(0xFF16A34A)
                : (isMarginal ? const Color(0xFFD97706) : AppColors.error);

            return Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: AppColors.surfaceOf(context),
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: AppColors.borderOf(context)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 6,
                                  vertical: 2,
                                ),
                                decoration: BoxDecoration(
                                  color: const Color(0xFF0369A1)
                                      .withValues(alpha: 0.12),
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: Text(
                                  sub.courseCode,
                                  style: const TextStyle(
                                    fontSize: 10,
                                    fontWeight: FontWeight.w800,
                                    color: Color(0xFF0284C7),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 8),
                              Text(
                                '${sub.attendedHours} / ${sub.totalHours} Hours',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: AppColors.textSecondaryOf(context),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Text(
                            sub.courseTitle,
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w700,
                              color: AppColors.textPrimaryOf(context),
                            ),
                          ),
                        ],
                      ),
                      Text(
                        '${sub.percentage.toStringAsFixed(1)}%',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w800,
                          color: color,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  LinearProgressIndicator(
                    value: sub.percentage / 100.0,
                    backgroundColor: isDark
                        ? const Color(0xFF1E293B)
                        : const Color(0xFFE2E8F0),
                    color: color,
                    minHeight: 6,
                    borderRadius: BorderRadius.circular(4),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    sub.percentage >= 75.0
                        ? (sub.safeBunkCount > 0
                            ? 'You can miss ${sub.safeBunkCount} '
                                'more classes safely.'
                            : 'Borderline: Cannot miss any classes!')
                        : 'Action required: Attend next '
                            '${sub.requiredToCatchUp} consecutive classes '
                            'to reach 75%.',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: sub.percentage < 75.0
                          ? AppColors.error
                          : AppColors.textSecondaryOf(context),
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ],
    );
  }
}
