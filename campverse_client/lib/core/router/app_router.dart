import 'package:campverse/core/models/app_role.dart';
import 'package:campverse/core/providers/auth_provider.dart';
import 'package:campverse/core/router/route_names.dart';
import 'package:campverse/features/auth/login/login_screen.dart';
import 'package:campverse/features/auth/role_picker/role_picker_screen.dart';
import 'package:campverse/features/auth/security/security_settings_screen.dart';
import 'package:campverse/features/auth/two_factor/two_factor_screen.dart';
import 'package:campverse/features/shell/club_admin_shell.dart';
import 'package:campverse/features/shell/faculty_shell.dart';
import 'package:campverse/features/shell/hod_shell.dart';
import 'package:campverse/features/shell/office_admin_shell.dart';
import 'package:campverse/features/shell/principal_shell.dart';
import 'package:campverse/features/shell/student_shell.dart';
import 'package:campverse/features/shell/student_union_shell.dart';
import 'package:campverse/features/shell/super_admin_shell.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

/// Provider for the global GoRouter configuration with security guards.
final appRouterProvider = Provider<GoRouter>((ref) {
  return GoRouter(
    initialLocation: RouteNames.login,
    debugLogDiagnostics: true,
    refreshListenable: _RouterRefreshNotifier(ref),
    redirect: (context, state) {
      final authState = ref.read(authStateProvider);
      final currentLoc = state.uri.path;

      // 1. Still resolving initial session → stay put
      if (authState.isLoading && authState.session == null) {
        return null;
      }

      // 2. Account flagged as "not found" or "suspended" → force back to login.
      //    This guards against a race where a session token exists but the
      //    profile check has already failed (e.g. mid-session suspension).
      if (authState.accountNotFound || authState.accountSuspended) {
        if (currentLoc == RouteNames.login) return null;
        return RouteNames.login;
      }

      // 3. Unauthenticated → force login
      if (authState.session == null) {
        if (currentLoc == RouteNames.login) return null;
        return RouteNames.login;
      }

      // 4. MFA pending → force 2FA screen
      if (authState.isMfaPending) {
        if (currentLoc == RouteNames.twoFactor) return null;
        return RouteNames.twoFactor;
      }

      // 5. Authenticated + MFA cleared but no active role resolved yet
      //    (This should be transient — _processSession sets activeRole = baseRole)
      if (authState.activeRole == null) {
        if (currentLoc == RouteNames.rolePicker) return null;
        return RouteNames.rolePicker;
      }

      final activeRole = authState.activeRole!;
      final expectedRoot = activeRole.routeRoot;

      // 6. Security settings are accessible from any authenticated role
      if (currentLoc == RouteNames.securitySettings) return null;

      // 7. Role picker accessible for multi-role users who want to switch
      if (currentLoc == RouteNames.rolePicker && authState.hasMultipleRoles) {
        return null;
      }

      // 8. If the user is on any auth/onboarding screen, route to workspace
      if (currentLoc == RouteNames.login ||
          currentLoc == RouteNames.twoFactor ||
          currentLoc == RouteNames.rolePicker) {
        return expectedRoot;
      }

      // 9. Cross-role route spoofing guard:
      //    Prevent a user from navigating to another role's workspace path.
      final allRoleRoots = AppRole.values.map((r) => r.routeRoot).toList();
      final isVisitingAnotherRole = allRoleRoots.any(
        (root) => currentLoc.startsWith(root) && root != expectedRoot,
      );

      if (isVisitingAnotherRole) {
        return expectedRoot;
      }

      return null;
    },
    routes: [
      // ── Auth routes ────────────────────────────────────────────────────────
      GoRoute(
        path: RouteNames.login,
        builder: (context, state) => const LoginScreen(),
      ),
      GoRoute(
        path: RouteNames.twoFactor,
        builder: (context, state) => const TwoFactorScreen(),
      ),
      GoRoute(
        path: RouteNames.securitySettings,
        builder: (context, state) => const SecuritySettingsScreen(),
      ),
      GoRoute(
        path: RouteNames.rolePicker,
        builder: (context, state) => const RolePickerScreen(),
      ),

      // ── Role workspace shells ──────────────────────────────────────────────
      GoRoute(
        path: RouteNames.superAdmin,
        builder: (context, state) => const SuperAdminShell(),
      ),
      GoRoute(
        path: RouteNames.principal,
        builder: (context, state) => const PrincipalShell(),
      ),
      GoRoute(
        path: RouteNames.officeAdmin,
        builder: (context, state) => const OfficeAdminShell(),
      ),
      GoRoute(
        path: RouteNames.studentUnion,
        builder: (context, state) => const StudentUnionShell(),
      ),
      GoRoute(
        path: RouteNames.hod,
        builder: (context, state) => const HodShell(),
      ),
      GoRoute(
        path: RouteNames.faculty,
        builder: (context, state) => const FacultyShell(),
      ),
      GoRoute(
        path: RouteNames.clubAdmin,
        builder: (context, state) => const ClubAdminShell(),
      ),
      GoRoute(
        path: RouteNames.student,
        builder: (context, state) => const StudentShell(),
      ),
    ],
  );
});

class _RouterRefreshNotifier extends ChangeNotifier {
  _RouterRefreshNotifier(Ref ref) {
    ref.listen(authStateProvider, (_, _) {
      notifyListeners();
    });
  }
}
