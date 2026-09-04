import 'package:campverse/core/models/app_role.dart';
import 'package:campverse/core/models/institute.dart';
import 'package:campverse/core/providers/campus_admin_provider.dart';
import 'package:campverse/core/services/campus_admin_service.dart';
import 'package:campverse/features/campus_admin/dashboard/campus_dashboard_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

class FakeCurrentInstituteNotifier extends CurrentInstituteNotifier {
  FakeCurrentInstituteNotifier(this._testInstitute);
  final Institute? _testInstitute;

  @override
  Future<Institute?> build() async => _testInstitute;
}

void main() {
  const sampleInstitute = Institute(
    id: 'inst-1',
    name: 'Model Engineering College',
    slug: 'MEC',
    domain: 'mec.ac.in',
    universityName: 'KTU',
    isAutonomous: true,
    branding: InstituteBranding(
      tagline: 'Moulding Engineers with Distinction',
      primaryColor: '#1E3A8A',
      website: 'https://mec.ac.in',
    ),
  );

  const sampleMetrics = CampusMetrics(
    departmentCount: 6,
    facultyCount: 54,
    studentCount: 1450,
    clubCount: 12,
    eventCount: 28,
    pendingApprovalsCount: 5,
    pendingVerificationsCount: 9,
  );

  group('CampusDashboardPage Widget Tests', () {
    testWidgets('Office Admin sees Operational Queue and Metric Cards',
        (tester) async {
      await tester.binding.setSurfaceSize(const Size(1200, 900));

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            currentInstituteProvider.overrideWith(
              () => FakeCurrentInstituteNotifier(sampleInstitute),
            ),
            campusMetricsProvider.overrideWith(
              (ref) async => sampleMetrics,
            ),
          ],
          child: const MaterialApp(
            home: Scaffold(
              body: CampusDashboardPage(role: AppRole.officeAdmin),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Verify Campus Name and Slug
      expect(find.text('Model Engineering College'), findsOneWidget);
      expect(find.text('MEC'), findsAtLeastNWidgets(1));
      expect(find.text('“Moulding Engineers with Distinction”'),
          findsOneWidget);

      // Verify Office Admin Operational Queue card is present
      expect(find.text('Campus Operations Queue'), findsOneWidget);
      expect(find.text('9 Verifications'), findsOneWidget);

      // Verify Principal Executive Approvals is NOT shown
      expect(find.text('Executive Approvals Vault'), findsNothing);

      // Verify Metrics are rendered
      expect(find.text('6'), findsOneWidget); // Departments
      expect(find.text('54'), findsOneWidget); // Faculty
      expect(find.text('1450'), findsOneWidget); // Students
      expect(find.text('12'), findsOneWidget); // Clubs
      expect(find.text('28'), findsOneWidget); // Events
    });

    testWidgets(
        'Principal sees Executive Approvals Vault and can trigger callback',
        (tester) async {
      await tester.binding.setSurfaceSize(const Size(1200, 900));
      int? navigatedIndex;

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            currentInstituteProvider.overrideWith(
              () => FakeCurrentInstituteNotifier(sampleInstitute),
            ),
            campusMetricsProvider.overrideWith(
              (ref) async => sampleMetrics,
            ),
          ],
          child: MaterialApp(
            home: Scaffold(
              body: CampusDashboardPage(
                role: AppRole.principal,
                onNavigateToTab: (index) => navigatedIndex = index,
              ),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Verify Executive Approvals Vault is present
      expect(find.text('Executive Approvals Vault'), findsOneWidget);
      expect(find.text('5 Pending'), findsOneWidget);

      // Verify Office Admin Ops Queue is NOT shown
      expect(find.text('Campus Operations Queue'), findsNothing);

      // Tap on Approvals button
      await tester.tap(find.text('Approvals'));
      await tester.pumpAndSettle();

      // Should have navigated to tab index 2 (Approvals tab)
      expect(navigatedIndex, 2);
    });
  });
}
