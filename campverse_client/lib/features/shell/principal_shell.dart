import 'package:campverse/core/models/app_role.dart';
import 'package:campverse/features/shell/base_role_shell.dart';
import 'package:campverse/features/shell/widgets/role_dashboard_view.dart';
import 'package:flutter/material.dart';

/// Workspace shell for Principal executive governance.
class PrincipalShell extends StatelessWidget {
  /// Default constructor for PrincipalShell.
  const PrincipalShell({super.key});

  @override
  Widget build(BuildContext context) {
    return const BaseRoleShell(
      role: AppRole.principal,
      destinations: [
        NavDestinationItem(
          label: 'Overview',
          icon: Icons.dashboard_outlined,
          selectedIcon: Icons.dashboard_rounded,
          body: RoleDashboardView(
            role: AppRole.principal,
            tabTitle: 'Institute Executive Dashboard',
            description:
                'Campus-wide metrics, departments, and oversight.',
            features: [
              'Review campus student & staff demographics',
              'Monitor overall academic attendance indicators',
              'Inspect college-wide calendar & sanctioned events',
            ],
          ),
        ),
        NavDestinationItem(
          label: 'Departments',
          icon: Icons.apartment_outlined,
          selectedIcon: Icons.apartment_rounded,
          body: RoleDashboardView(
            role: AppRole.principal,
            tabTitle: 'Departmental Governance',
            description:
                'Department heads, faculty allocations, and courses.',
            features: [
              'Appoint and manage Heads of Department (HOD)',
              'Approve new academic programmes & course schemes',
              'Review department accreditation & compliance documents',
            ],
          ),
        ),
        NavDestinationItem(
          label: 'Broadcasts',
          icon: Icons.campaign_outlined,
          selectedIcon: Icons.campaign_rounded,
          body: RoleDashboardView(
            role: AppRole.principal,
            tabTitle: 'Campus-Wide Notices',
            description:
                'Official institute announcements, circulars, and alerts.',
            features: [
              'Publish high-priority campus notices',
              'Send push notifications to all students & faculty',
              'Authorize duty leave and event circulars',
            ],
          ),
        ),
      ],
    );
  }
}
