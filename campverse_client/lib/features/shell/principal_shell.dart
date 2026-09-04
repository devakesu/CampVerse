import 'package:campverse/core/models/app_role.dart';
import 'package:campverse/features/campus_admin/dashboard/campus_dashboard_page.dart';
import 'package:campverse/features/campus_admin/institute/institute_management_page.dart';
import 'package:campverse/features/shell/base_role_shell.dart';
import 'package:campverse/features/shell/widgets/role_dashboard_view.dart';
import 'package:flutter/material.dart';

/// Workspace shell for Principal executive governance.
class PrincipalShell extends StatefulWidget {
  /// Default constructor for PrincipalShell.
  const PrincipalShell({super.key});

  @override
  State<PrincipalShell> createState() => _PrincipalShellState();
}

class _PrincipalShellState extends State<PrincipalShell> {
  int _selectedIndex = 0;

  void _onNavigateToTab(int index) {
    setState(() => _selectedIndex = index);
  }

  @override
  Widget build(BuildContext context) {
    return BaseRoleShell(
      role: AppRole.principal,
      selectedIndex: _selectedIndex,
      onDestinationSelected: (index) {
        setState(() => _selectedIndex = index);
      },
      destinations: [
        NavDestinationItem(
          label: 'Dashboard',
          icon: Icons.dashboard_outlined,
          selectedIcon: Icons.dashboard_rounded,
          body: CampusDashboardPage(
            role: AppRole.principal,
            onNavigateToTab: _onNavigateToTab,
          ),
        ),
        const NavDestinationItem(
          label: 'Institute',
          icon: Icons.domain_outlined,
          selectedIcon: Icons.domain_rounded,
          body: InstituteManagementPage(role: AppRole.principal),
        ),
        const NavDestinationItem(
          label: 'Approvals',
          icon: Icons.verified_user_outlined,
          selectedIcon: Icons.verified_user_rounded,
          body: RoleDashboardView(
            role: AppRole.principal,
            tabTitle: 'Executive Approvals Vault',
            description:
                'Statutory file authorizations, sanctioned event approvals, '
                'and duty leaves.',
            features: [
              'Review & sign duty leave applications from students & faculty',
              'Authorize club budget requests, guest lectures, & campus events',
              'Principal-only cryptographic signature for official degrees',
            ],
          ),
        ),
        const NavDestinationItem(
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
        const NavDestinationItem(
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
