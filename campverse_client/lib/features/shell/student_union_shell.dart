import 'package:campverse/core/models/app_role.dart';
import 'package:campverse/features/shell/base_role_shell.dart';
import 'package:campverse/features/shell/widgets/role_dashboard_view.dart';
import 'package:flutter/material.dart';

/// Workspace shell for Student Union government and campus events.
class StudentUnionShell extends StatelessWidget {
  /// Default constructor for StudentUnionShell.
  const StudentUnionShell({super.key});

  @override
  Widget build(BuildContext context) {
    return const BaseRoleShell(
      role: AppRole.studentUnion,
      destinations: [
        NavDestinationItem(
          label: 'Union Feed',
          shortLabel: 'Feed',
          accentColor: Color(0xFFEA580C),
          icon: Icons.newspaper_outlined,
          selectedIcon: Icons.newspaper_rounded,
          body: RoleDashboardView(
            role: AppRole.studentUnion,
            tabTitle: 'Student Union Council',
            description:
                'Campus advocacy, initiatives, and council announcements.',
            features: [
              'Publish campus-wide student union broadcasts',
              'Organize college festivals, arts, and cultural meets',
              'Address student grievances and senate motions',
            ],
          ),
        ),
        NavDestinationItem(
          label: 'Clubs Overview',
          shortLabel: 'Clubs',
          accentColor: Color(0xFF059669),
          icon: Icons.hub_outlined,
          selectedIcon: Icons.hub_rounded,
          body: RoleDashboardView(
            role: AppRole.studentUnion,
            tabTitle: 'Campus Clubs Federation',
            description:
                'Coordinate student bodies, approvals, and event budgets.',
            features: [
              'Review and sanction inter-club event proposals',
              'Track campus activity points and participation logs',
              'Manage union executive committee assignments',
            ],
          ),
        ),
      ],
    );
  }
}
