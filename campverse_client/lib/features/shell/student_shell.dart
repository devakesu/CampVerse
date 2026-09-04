import 'dart:async';

import 'package:campverse/core/models/app_role.dart';
import 'package:campverse/features/shell/base_role_shell.dart';
import 'package:campverse/features/student/models/student_registration.dart';
import 'package:campverse/features/student/providers/student_providers.dart';
import 'package:campverse/features/student/tabs/student_academics_tab.dart';
import 'package:campverse/features/student/tabs/student_clubs_tab.dart';
import 'package:campverse/features/student/tabs/student_events_tab.dart';
import 'package:campverse/features/student/tabs/student_overview_tab.dart';
import 'package:campverse/features/student/tabs/student_profile_tab.dart';
import 'package:campverse/features/student/widgets/qr_pass_dialog.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Workspace shell for Students: Overview, Academics, Events & Passes,
/// Clubs, and Profile.
class StudentShell extends ConsumerStatefulWidget {
  /// Default constructor for StudentShell.
  const StudentShell({super.key});

  @override
  ConsumerState<StudentShell> createState() => _StudentShellState();
}

class _StudentShellState extends ConsumerState<StudentShell> {
  int _currentIndex = 0;

  void _navigateToTab(int index) {
    setState(() => _currentIndex = index);
  }

  @override
  Widget build(BuildContext context) {
    final regsAsync = ref.watch(studentRegistrationsProvider);
    final activePasses = regsAsync.value
            ?.where((r) => r.isActive)
            .toList() ??
        const <StudentRegistration>[];

    return BaseRoleShell(
      role: AppRole.student,
      selectedIndex: _currentIndex,
      onDestinationSelected: _navigateToTab,
      customActions: [
        if (activePasses.isNotEmpty)
          IconButton(
            icon: const Icon(
              Icons.qr_code_rounded,
              color: Color(0xFF16A34A),
              size: 22,
            ),
            tooltip: 'My Active Entry Pass',
            onPressed: () {
              unawaited(QrPassDialog.show(context, activePasses.first));
            },
          ),
      ],
      destinations: [
        NavDestinationItem(
          label: 'Overview',
          icon: Icons.dashboard_outlined,
          selectedIcon: Icons.dashboard_rounded,
          body: StudentOverviewTab(
            onNavigateToAcademics: () => _navigateToTab(1),
            onNavigateToEvents: () => _navigateToTab(2),
          ),
        ),
        const NavDestinationItem(
          label: 'Academics',
          icon: Icons.school_outlined,
          selectedIcon: Icons.school_rounded,
          body: StudentAcademicsTab(),
        ),
        const NavDestinationItem(
          label: 'Events & Passes',
          icon: Icons.confirmation_number_outlined,
          selectedIcon: Icons.confirmation_number_rounded,
          body: StudentEventsTab(),
        ),
        const NavDestinationItem(
          label: 'Clubs & Union',
          icon: Icons.groups_outlined,
          selectedIcon: Icons.groups_rounded,
          body: StudentClubsTab(),
        ),
        const NavDestinationItem(
          label: 'My Profile',
          icon: Icons.person_outline_rounded,
          selectedIcon: Icons.person_rounded,
          body: StudentProfileTab(),
        ),
      ],
    );
  }
}
