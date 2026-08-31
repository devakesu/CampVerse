import 'package:campverse/core/models/app_role.dart';
import 'package:campverse/features/shell/base_role_shell.dart';
import 'package:campverse/features/shell/widgets/role_dashboard_view.dart';
import 'package:flutter/material.dart';

/// Workspace shell for Office Administration records and operations.
class OfficeAdminShell extends StatelessWidget {
  /// Default constructor for OfficeAdminShell.
  const OfficeAdminShell({super.key});

  @override
  Widget build(BuildContext context) {
    return const BaseRoleShell(
      role: AppRole.officeAdmin,
      destinations: [
        NavDestinationItem(
          label: 'Admissions',
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
        NavDestinationItem(
          label: 'Certificates',
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
        NavDestinationItem(
          label: 'Fee & Ops',
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
