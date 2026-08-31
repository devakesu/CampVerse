import 'dart:async';
import 'package:campverse/core/models/institute.dart';
import 'package:campverse/core/models/university.dart';
import 'package:campverse/core/services/super_admin_service.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Provider exposing the SuperAdminService instance.
final superAdminServiceProvider = Provider<SuperAdminService>((ref) {
  return SuperAdminService();
});

/// AsyncNotifier managing the state and refresh of universities.
class UniversitiesNotifier extends AsyncNotifier<List<University>> {
  @override
  Future<List<University>> build() async {
    final service = ref.read(superAdminServiceProvider);
    return service.fetchUniversities();
  }

  /// Reload the list of universities.
  Future<void> refresh() async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      final service = ref.read(superAdminServiceProvider);
      return service.fetchUniversities();
    });
  }
}

/// Provider for the list of universities.
final universitiesProvider =
    AsyncNotifierProvider<UniversitiesNotifier, List<University>>(
  UniversitiesNotifier.new,
);

/// AsyncNotifier managing the state and refresh of institutes.
class InstitutesNotifier extends AsyncNotifier<List<Institute>> {
  @override
  Future<List<Institute>> build() async {
    final service = ref.read(superAdminServiceProvider);
    return service.fetchInstitutes();
  }

  /// Reload the list of institutes.
  Future<void> refresh() async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      final service = ref.read(superAdminServiceProvider);
      return service.fetchInstitutes();
    });
  }
}

/// Provider for the list of institutes.
final institutesProvider =
    AsyncNotifierProvider<InstitutesNotifier, List<Institute>>(
  InstitutesNotifier.new,
);

/// Provider fetching system metrics.
final systemMetricsProvider = FutureProvider<SystemMetrics>((ref) async {
  final service = ref.read(superAdminServiceProvider);
  return service.fetchSystemMetrics();
});
