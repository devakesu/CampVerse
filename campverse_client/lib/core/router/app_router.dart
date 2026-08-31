import 'package:campverse/core/models/app_role.dart';
import 'package:campverse/core/providers/auth_provider.dart';
import 'package:campverse/core/router/route_names.dart';
import 'package:campverse/features/auth/login/login_screen.dart';
import 'package:campverse/features/auth/role_picker/role_picker_screen.dart';
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

      // 1. If still resolving session, stay
      if (authState.isLoading && authState.session == null) {
        return null;
      }

      // 2. Unauthenticated -> force login
      if (authState.session == null) {
        if (currentLoc == RouteNames.login) {
          return null;
        }
        return RouteNames.login;
      }

      // 3. MFA pending -> force 2FA
      if (authState.isMfaPending) {
        if (currentLoc == RouteNames.twoFactor) {
          return null;
        }
        return RouteNames.twoFactor;
      }

      // 4. Authenticated, 2FA passed, but no active role selected
      if (authState.activeRole == null) {
        if (currentLoc == RouteNames.rolePicker) {
          return null;
        }
        return RouteNames.rolePicker;
      }

      final activeRole = authState.activeRole!;
      final expectedRoot = activeRole.routeRoot;

      // 5. If user is on an auth screen, route them to their workspace
      if (currentLoc == RouteNames.login ||
          currentLoc == RouteNames.twoFactor ||
          currentLoc == RouteNames.rolePicker) {
        return expectedRoot;
      }

      // 6. Security guard: prevent route spoofing across roles
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
      // Auth routes
      GoRoute(
        path: RouteNames.login,
        builder: (context, state) => const LoginScreen(),
      ),
      GoRoute(
        path: RouteNames.twoFactor,
        builder: (context, state) => const TwoFactorScreen(),
      ),
      GoRoute(
        path: RouteNames.rolePicker,
        builder: (context, state) => const RolePickerScreen(),
      ),

      // Role workspace shells
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
