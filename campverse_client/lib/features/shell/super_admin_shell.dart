import 'package:campverse/core/models/app_role.dart';
import 'package:campverse/features/shell/base_role_shell.dart';
import 'package:campverse/features/super_admin/audit/audit_log_page.dart';
import 'package:campverse/features/super_admin/dashboard/super_admin_dashboard_page.dart';
import 'package:campverse/features/super_admin/institutes/institutes_page.dart';
import 'package:campverse/features/super_admin/universities/universities_page.dart';
import 'package:flutter/material.dart';

/// Workspace shell for Super Administrator system governance.
class SuperAdminShell extends StatefulWidget {
  /// Default constructor for SuperAdminShell.
  const SuperAdminShell({super.key});

  @override
  State<SuperAdminShell> createState() => _SuperAdminShellState();
}

class _SuperAdminShellState extends State<SuperAdminShell> {
  final _pageController = PageController();

  void _onNavigateToTab(int index) {
    if (_pageController.hasClients) {
      _pageController.jumpToPage(index);
    }
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BaseRoleShell(
      role: AppRole.superAdmin,
      destinations: [
        NavDestinationItem(
          label: 'Dashboard',
          icon: Icons.dashboard_outlined,
          selectedIcon: Icons.dashboard_rounded,
          body: SuperAdminDashboardPage(
            onNavigateToTab: _onNavigateToTab,
          ),
        ),
        const NavDestinationItem(
          label: 'Universities',
          icon: Icons.account_balance_outlined,
          selectedIcon: Icons.account_balance_rounded,
          body: UniversitiesPage(),
        ),
        const NavDestinationItem(
          label: 'Institutes',
          icon: Icons.domain_outlined,
          selectedIcon: Icons.domain_rounded,
          body: InstitutesPage(),
        ),
        const NavDestinationItem(
          label: 'System Logs',
          icon: Icons.terminal_outlined,
          selectedIcon: Icons.terminal_rounded,
          body: AuditLogPage(),
        ),
      ],
    );
  }
}
