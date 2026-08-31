import 'package:campverse/core/models/app_role.dart';
import 'package:campverse/features/shell/base_role_shell.dart';
import 'package:campverse/features/shell/widgets/role_dashboard_view.dart';
import 'package:flutter/material.dart';

/// Workspace shell for Super Administrator system governance.
class SuperAdminShell extends StatelessWidget {
  /// Default constructor for SuperAdminShell.
  const SuperAdminShell({super.key});

  @override
  Widget build(BuildContext context) {
    return const BaseRoleShell(
      role: AppRole.superAdmin,
      destinations: [
        NavDestinationItem(
          label: 'Universities',
          icon: Icons.account_balance_outlined,
          selectedIcon: Icons.account_balance_rounded,
          body: RoleDashboardView(
            role: AppRole.superAdmin,
            tabTitle: 'System-Wide Governance',
            description:
                'Multi-tenant universities, schemes, and platform config.',
            features: [
              'Create & manage affiliated Universities',
              'Configure global curriculum schemes & syllabus definitions',
              'Tenant isolation & multi-institute onboarding',
              'Global security policies and audit logs',
            ],
          ),
        ),
        NavDestinationItem(
          label: 'Institutes',
          icon: Icons.domain_outlined,
          selectedIcon: Icons.domain_rounded,
          body: RoleDashboardView(
            role: AppRole.superAdmin,
            tabTitle: 'Institute Directory',
            description: 'Manage registered colleges, subdomains, and status.',
            features: [
              'Approve new college tenant registrations',
              'Configure custom domain mappings & SSL certificates',
              'Manage institutional license tiers',
            ],
          ),
        ),
        NavDestinationItem(
          label: 'System Logs',
          icon: Icons.terminal_outlined,
          selectedIcon: Icons.terminal_rounded,
          body: RoleDashboardView(
            role: AppRole.superAdmin,
            tabTitle: 'Audit & Telemetry',
            description:
                'Real-time FLE operations, security alerts, and health.',
            features: [
              'Inspect field-level encryption (FLE) blind-index health',
              'API Gateway rate-limiting & Go engine metrics',
              'Security alerts and anomalous access logs',
            ],
          ),
        ),
      ],
    );
  }
}
