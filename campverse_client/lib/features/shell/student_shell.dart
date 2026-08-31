import 'package:campverse/core/models/app_role.dart';
import 'package:campverse/features/shell/base_role_shell.dart';
import 'package:campverse/features/shell/widgets/role_dashboard_view.dart';
import 'package:flutter/material.dart';

/// Workspace shell for Students: feed, event tickets, courses, and vault.
class StudentShell extends StatelessWidget {
  /// Default constructor for StudentShell.
  const StudentShell({super.key});

  @override
  Widget build(BuildContext context) {
    return const BaseRoleShell(
      role: AppRole.student,
      destinations: [
        NavDestinationItem(
          label: 'Campus Feed',
          icon: Icons.dynamic_feed_outlined,
          selectedIcon: Icons.dynamic_feed_rounded,
          body: RoleDashboardView(
            role: AppRole.student,
            tabTitle: 'Campus Feed & Announcements',
            description:
                'Notices from institute, dept, tutor, and student union.',
            features: [
              'Stay updated with official college notices & circulars',
              'Class-specific homework and exam schedule notices',
              'Discover upcoming campus club festivals and hackathons',
            ],
          ),
        ),
        NavDestinationItem(
          label: 'Events & Passes',
          icon: Icons.confirmation_number_outlined,
          selectedIcon: Icons.confirmation_number_rounded,
          body: RoleDashboardView(
            role: AppRole.student,
            tabTitle: 'Events & Digital Passes',
            description:
                'Browse events, register, and access QR entry passes.',
            features: [
              'Register for cultural, technical, and sports events',
              'Cryptographic QR entry pass for gate check-ins',
              'Claim verified KTU activity points upon attendance',
            ],
          ),
        ),
        NavDestinationItem(
          label: 'Academics',
          icon: Icons.school_outlined,
          selectedIcon: Icons.school_rounded,
          body: RoleDashboardView(
            role: AppRole.student,
            tabTitle: 'Academics & Timetable',
            description:
                'Enrolled courses, daily timetable, and attendance.',
            features: [
              'Real-time class timetable matrix with classroom halls',
              'View registered theory and elective courses',
              'Course syllabus tracking and class attendance logs',
            ],
          ),
        ),
        NavDestinationItem(
          label: 'Vault',
          icon: Icons.workspace_premium_outlined,
          selectedIcon: Icons.workspace_premium_rounded,
          body: RoleDashboardView(
            role: AppRole.student,
            tabTitle: 'Digital Certificate Vault',
            description:
                'Your verified achievement and participation certificates.',
            features: [
              'Access encrypted certificates with verification hashes',
              'Share one-click public verification links with employers',
              'Export signed PDF credentials securely',
            ],
          ),
        ),
      ],
    );
  }
}
