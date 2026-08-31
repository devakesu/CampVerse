import 'package:campverse/core/models/app_role.dart';
import 'package:campverse/features/shell/base_role_shell.dart';
import 'package:campverse/features/shell/widgets/role_dashboard_view.dart';
import 'package:flutter/material.dart';

/// Workspace shell for Club Administrators, event ticketing, and gate passes.
class ClubAdminShell extends StatelessWidget {
  /// Default constructor for ClubAdminShell.
  const ClubAdminShell({super.key});

  @override
  Widget build(BuildContext context) {
    return const BaseRoleShell(
      role: AppRole.clubAdmin,
      destinations: [
        NavDestinationItem(
          label: 'Events',
          icon: Icons.event_available_outlined,
          selectedIcon: Icons.event_available_rounded,
          body: RoleDashboardView(
            role: AppRole.clubAdmin,
            tabTitle: 'Club Events Management',
            description:
                'Create events, registrations, and check-in attendees.',
            features: [
              'Draft and publish campus or inter-college events',
              'Configure custom registration questions & ticketing tiers',
              'Scan attendee QR passes with cryptographic verification',
              'Export registration rosters and issue digital certificates',
            ],
          ),
        ),
        NavDestinationItem(
          label: 'Members',
          icon: Icons.badge_outlined,
          selectedIcon: Icons.badge_rounded,
          body: RoleDashboardView(
            role: AppRole.clubAdmin,
            tabTitle: 'Club Team & Core Roster',
            description:
                'Executive committee, recruitments, and member management.',
            features: [
              'Manage club executives, core team, and volunteer leads',
              'Review recruitment applications and interview notes',
              'Assign custom designation titles for club members',
            ],
          ),
        ),
        NavDestinationItem(
          label: 'Broadcasts',
          icon: Icons.podcasts_outlined,
          selectedIcon: Icons.podcasts_rounded,
          body: RoleDashboardView(
            role: AppRole.clubAdmin,
            tabTitle: 'Club Announcements',
            description:
                'Post notices to club members and public campus feed.',
            features: [
              'Publish official club event updates and brochures',
              'Send targeted notices to verified club members',
            ],
          ),
        ),
      ],
    );
  }
}
