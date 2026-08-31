import 'package:campverse/core/models/app_role.dart';
import 'package:campverse/core/providers/auth_provider.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Provider exposing the currently active workspace role.
final activeRoleProvider = Provider<AppRole?>((ref) {
  return ref.watch(authStateProvider.select((s) => s.activeRole));
});

/// Provider exposing all authorized roles for the current user.
final availableRolesProvider = Provider<List<AppRole>>((ref) {
  return ref.watch(authStateProvider.select((s) => s.availableRoles));
});

/// Provider exposing the primary base role of the user.
final baseRoleProvider = Provider<AppRole>((ref) {
  return ref.watch(authStateProvider.select((s) => s.baseRole));
});

/// Provider indicating whether the user holds multiple distinct roles.
final hasMultipleRolesProvider = Provider<bool>((ref) {
  return ref.watch(authStateProvider.select((s) => s.hasMultipleRoles));
});
