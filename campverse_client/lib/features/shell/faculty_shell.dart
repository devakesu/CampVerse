import 'package:campverse/core/models/app_role.dart';
import 'package:campverse/features/shell/base_role_shell.dart';
import 'package:campverse/features/shell/widgets/role_dashboard_view.dart';
import 'package:flutter/material.dart';

/// Workspace shell for Faculty instruction, advisory, and course materials.
class FacultyShell extends StatelessWidget {
  /// Default constructor for FacultyShell.
  const FacultyShell({super.key});

  @override
  Widget build(BuildContext context) {
    return const BaseRoleShell(
      role: AppRole.faculty,
      destinations: [
        NavDestinationItem(
          label: 'Courses',
          accentColor: Color(0xFF2563EB),
          icon: Icons.menu_book_outlined,
          selectedIcon: Icons.menu_book_rounded,
          body: RoleDashboardView(
            role: AppRole.faculty,
            tabTitle: 'Allocated Courses',
            description:
                'Course syllabi, lecture slides, and student rosters.',
            features: [
              'View semester-allocated courses & practical labs',
              'Upload lecture notes, assignment briefs, and study guides',
              'Record daily period attendance and course progress',
            ],
          ),
        ),
        NavDestinationItem(
          label: 'Advisory',
          accentColor: Color(0xFF059669),
          icon: Icons.supervised_user_circle_outlined,
          selectedIcon: Icons.supervised_user_circle_rounded,
          body: RoleDashboardView(
            role: AppRole.faculty,
            tabTitle: 'Class Tutor / Staff Advisor',
            description:
                'Mentorship cohort, attendance, and student approvals.',
            features: [
              'Review advisory class students and academic performance',
              'Approve event duty leave and certificate requests',
              'Publish class-scoped announcements & notices',
            ],
          ),
        ),
        NavDestinationItem(
          label: 'Schedule',
          accentColor: Color(0xFF7C3AED),
          icon: Icons.schedule_outlined,
          selectedIcon: Icons.schedule_rounded,
          body: RoleDashboardView(
            role: AppRole.faculty,
            tabTitle: 'Weekly Timetable',
            description: 'Your weekly teaching periods and room assignments.',
            features: [
              'Personal weekly period schedule with venue halls',
              'Request timetable adjustments and view adjustments',
            ],
          ),
        ),
      ],
    );
  }
}
