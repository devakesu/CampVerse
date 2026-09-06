import 'package:campverse/core/models/app_role.dart';
import 'package:campverse/features/campus_admin/dashboard/campus_dashboard_page.dart';
import 'package:campverse/features/campus_admin/institute/institute_management_page.dart';
import 'package:campverse/features/shell/base_role_shell.dart';
import 'package:campverse/features/shell/widgets/role_dashboard_view.dart';
import 'package:flutter/material.dart';

/// Workspace shell for Office Administration records and operations.
class OfficeAdminShell extends StatefulWidget {
  /// Default constructor for OfficeAdminShell.
  const OfficeAdminShell({super.key});

  @override
  State<OfficeAdminShell> createState() => _OfficeAdminShellState();
}

class _OfficeAdminShellState extends State<OfficeAdminShell> {
  int _selectedIndex = 0;

  void _onNavigateToTab(int index) {
    setState(() => _selectedIndex = index);
  }

  @override
  Widget build(BuildContext context) {
    return BaseRoleShell(
      role: AppRole.officeAdmin,
      selectedIndex: _selectedIndex,
      onDestinationSelected: (index) {
        setState(() => _selectedIndex = index);
      },
      destinations: [
        NavDestinationItem(
          label: 'Dashboard',
          accentColor: const Color(0xFF2563EB),
          icon: Icons.dashboard_outlined,
          selectedIcon: Icons.dashboard_rounded,
          body: CampusDashboardPage(
            role: AppRole.officeAdmin,
            onNavigateToTab: _onNavigateToTab,
          ),
        ),
        const NavDestinationItem(
          label: 'Institute',
          accentColor: Color(0xFF0284C7),
          icon: Icons.domain_outlined,
          selectedIcon: Icons.domain_rounded,
          body: InstituteManagementPage(role: AppRole.officeAdmin),
        ),
        const NavDestinationItem(
          label: 'Admissions',
          accentColor: Color(0xFF059669),
          icon: Icons.how_to_reg_outlined,
          selectedIcon: Icons.how_to_reg_rounded,
          body: RoleDashboardView(
            role: AppRole.officeAdmin,
            tabTitle: 'Student Admissions & Records',
            description:
                'Enrollment registry, register number allocations, batches.',
            features: [
              'Verify student identity documentation & records',
              'Allocate university registration numbers & IDs',
              'Manage class cohorts, divisions, and batches',
            ],
          ),
        ),
        const NavDestinationItem(
          label: 'Certificates',
          shortLabel: 'Certs',
          accentColor: Color(0xFF7C3AED),
          icon: Icons.verified_outlined,
          selectedIcon: Icons.verified_rounded,
          body: RoleDashboardView(
            role: AppRole.officeAdmin,
            tabTitle: 'Digital Certificate Vault',
            description:
                'Issue digitally signed transfer & bonafide certificates.',
            features: [
              'Generate verifiable SHA-256 certificate hashes',
              'Issue Bonafide, Duty Leave & Conduct certificates',
              'Verify digital credential authenticity via QR verification',
            ],
          ),
        ),
        const NavDestinationItem(
          label: 'Fee & Ops',
          shortLabel: 'Fees',
          accentColor: Color(0xFFEA580C),
          icon: Icons.receipt_long_outlined,
          selectedIcon: Icons.receipt_long_rounded,
          body: RoleDashboardView(
            role: AppRole.officeAdmin,
            tabTitle: 'Operations & Fee Tracking',
            description:
                'Manage institutional dues, bus routes, and hostel rooms.',
            features: [
              'Track institutional fee dues and transaction tokens',
              'Manage hostel room allocations and bus routes',
              'Export regulatory compliance rosters',
            ],
          ),
        ),
      ],
    );
  }
}
