import 'dart:async';
import 'package:campverse/core/models/institute.dart';
import 'package:campverse/core/models/university.dart';
import 'package:campverse/core/providers/auth_provider.dart';
import 'package:campverse/core/services/campus_admin_service.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Provider exposing CampusAdminService instance.
final campusAdminServiceProvider = Provider<CampusAdminService>((ref) {
  return CampusAdminService();
});

/// AsyncNotifier managing the current institute details for campus admins.
class CurrentInstituteNotifier extends AutoDisposeAsyncNotifier<Institute?> {
  @override
  Future<Institute?> build() async {
    final authState = ref.watch(authStateProvider);
    final instituteId = authState.instituteId;

    if (instituteId == null || instituteId.isEmpty) {
      return null;
    }

    final service = ref.read(campusAdminServiceProvider);
    final res = await service.fetchInstituteDetails(instituteId);
    if (res.success && res.data != null) {
      return res.data;
    }
    return null;
  }

  /// Reload the institute details from the server.
  Future<void> reload() async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      final authState = ref.read(authStateProvider);
      final instituteId = authState.instituteId;
      if (instituteId == null || instituteId.isEmpty) {
        return null;
      }
      final service = ref.read(campusAdminServiceProvider);
      final res = await service.fetchInstituteDetails(instituteId);
      return res.data;
    });
  }

  /// Locally update the institute record immediately after a mutation.
  void updateLocal(Institute updated) {
    state = AsyncValue.data(updated);
  }
}

/// Provider for the active user's institute details.
final currentInstituteProvider =
    AutoDisposeAsyncNotifierProvider<CurrentInstituteNotifier, Institute?>(
  CurrentInstituteNotifier.new,
);

/// Provider fetching real-time campus operational metrics.
final AutoDisposeFutureProvider<CampusMetrics> campusMetricsProvider =
    FutureProvider.autoDispose<CampusMetrics>((ref) async {
  final authState = ref.watch(authStateProvider);
  final instituteId = authState.instituteId;
  if (instituteId == null || instituteId.isEmpty) {
    return const CampusMetrics();
  }
  final service = ref.read(campusAdminServiceProvider);
  return service.fetchCampusMetrics(instituteId);
});

/// Provider fetching list of universities for affiliation dropdown.
final AutoDisposeFutureProvider<List<University>> campusUniversitiesProvider =
    FutureProvider.autoDispose<List<University>>((ref) async {
  final service = ref.read(campusAdminServiceProvider);
  return service.fetchUniversities();
});
