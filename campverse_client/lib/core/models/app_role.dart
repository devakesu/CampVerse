import 'package:campverse/core/theme/app_colors.dart';
import 'package:flutter/material.dart';

/// AppRole mirrors the PostgreSQL enum `app_role` exactly.
enum AppRole {
  /// System-wide administrator.
  superAdmin(
    'super_admin',
    'Super Admin',
    'System-wide administrator',
    Icons.admin_panel_settings_rounded,
  ),

  /// Institute head & executive administration.
  principal(
    'principal',
    'Principal',
    'Institute head & administration',
    Icons.account_balance_rounded,
  ),

  /// Campus operations & office management.
  officeAdmin(
    'office_admin',
    'Office Admin',
    'Campus operations & office management',
    Icons.business_center_rounded,
  ),

  /// Student government & union council.
  studentUnion(
    'student_union',
    'Student Union',
    'Student government & union council',
    Icons.groups_rounded,
  ),

  /// Departmental management & academics.
  hod(
    'hod',
    'Head of Department',
    'Departmental management & academics',
    Icons.workspace_premium_rounded,
  ),

  /// Staff advisor & course instruction.
  faculty(
    'faculty',
    'Faculty / Tutor',
    'Staff advisor & course instruction',
    Icons.school_rounded,
  ),

  /// Club leader & event coordinator.
  clubAdmin(
    'club_admin',
    'Club Admin',
    'Club leader & event coordinator',
    Icons.celebration_rounded,
  ),

  /// Student portal & coursework.
  student(
    'student',
    'Student',
    'Student portal & coursework',
    Icons.person_rounded,
  );

  const AppRole(
    this.dbValue,
    this.displayName,
    this.description,
    this.icon,
  );

  /// Database string literal in PostgreSQL.
  final String dbValue;

  /// User-facing role title.
  final String displayName;

  /// Role description for UI selectors.
  final String description;

  /// Representative Material icon.
  final IconData icon;

  /// Parse from DB or JWT claim string.
  static AppRole fromDbString(String? value) {
    if (value == null) {
      return AppRole.student;
    }
    for (final role in AppRole.values) {
      if (role.dbValue == value) {
        return role;
      }
    }
    return AppRole.student;
  }

  /// Parse from JWT claim (e.g. 'active_role').
  static AppRole? fromClaim(dynamic claim) {
    if (claim == null || claim is! String || claim.isEmpty) {
      return null;
    }
    return fromDbString(claim);
  }

  /// Color accent for role badges and UI elements.
  Color get badgeColor {
    switch (this) {
      case AppRole.superAdmin:
        return AppColors.roleSuperAdmin;
      case AppRole.principal:
        return AppColors.rolePrincipal;
      case AppRole.officeAdmin:
        return AppColors.roleOfficeAdmin;
      case AppRole.hod:
        return AppColors.roleHod;
      case AppRole.faculty:
        return AppColors.roleFaculty;
      case AppRole.studentUnion:
        return AppColors.roleStudentUnion;
      case AppRole.clubAdmin:
        return AppColors.roleClubAdmin;
      case AppRole.student:
        return AppColors.roleStudent;
    }
  }

  /// Root route prefix for this role workspace.
  String get routeRoot {
    switch (this) {
      case AppRole.superAdmin:
        return '/super-admin';
      case AppRole.principal:
        return '/principal';
      case AppRole.officeAdmin:
        return '/office-admin';
      case AppRole.studentUnion:
        return '/student-union';
      case AppRole.hod:
        return '/hod';
      case AppRole.faculty:
        return '/faculty';
      case AppRole.clubAdmin:
        return '/club-admin';
      case AppRole.student:
        return '/student';
    }
  }

  /// HOD role automatically includes faculty privileges.
  bool get impliesFaculty => this == AppRole.hod;
}
