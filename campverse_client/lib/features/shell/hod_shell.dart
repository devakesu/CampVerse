import 'package:campverse/core/models/app_role.dart';
import 'package:campverse/features/shell/base_role_shell.dart';
import 'package:campverse/features/shell/widgets/role_dashboard_view.dart';
import 'package:flutter/material.dart';

/// Workspace shell for Head of Department management and instruction.
class HodShell extends StatelessWidget {
  /// Default constructor for HodShell.
  const HodShell({super.key});

  @override
  Widget build(BuildContext context) {
    return const BaseRoleShell(
      role: AppRole.hod,
      destinations: [
        NavDestinationItem(
          label: 'Department',
          icon: Icons.domain_verification_outlined,
          selectedIcon: Icons.domain_verification_rounded,
          body: RoleDashboardView(
            role: AppRole.hod,
            tabTitle: 'Department Management',
            description:
                'Staff allocations, course mappings, and class cohorts.',
            features: [
              'Assign primary & co-instructors to course allocations',
              'Appoint class staff advisors and monitor division advisors',
              'Publish department-scoped notices and updates',
              'Approve faculty course progress and duty leaves',
            ],
          ),
        ),
        NavDestinationItem(
          label: 'My Teaching',
          icon: Icons.auto_stories_outlined,
          selectedIcon: Icons.auto_stories_rounded,
          body: RoleDashboardView(
            role: AppRole.hod,
            tabTitle: 'Faculty Instruction Portal',
            description:
                'Your assigned course cohorts and student rosters.',
            features: [
              'View allocated theory & practical courses (Faculty privilege)',
              'Mark attendance and evaluate course assignments',
              'Post class announcements and share lecture materials',
            ],
          ),
        ),
        NavDestinationItem(
          label: 'Timetables',
          icon: Icons.calendar_month_outlined,
          selectedIcon: Icons.calendar_month_rounded,
          body: RoleDashboardView(
            role: AppRole.hod,
            tabTitle: 'Department Schedule Matrix',
            description: 'Configure and resolve period schedule collisions.',
            features: [
              'Build and publish semester class timetables',
              'Assign lecture halls and lab venues',
              'Manage faculty substitution schedules',
            ],
          ),
        ),
      ],
    );
  }
}
