import 'package:campverse/core/models/app_role.dart';
import 'package:campverse/core/models/institute.dart';
import 'package:campverse/core/models/university.dart';
import 'package:campverse/core/providers/campus_admin_provider.dart';
import 'package:campverse/features/campus_admin/institute/institute_management_page.dart';
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
    settings: InstituteSettings(
      city: 'Kochi',
      state: 'Kerala',
      pincode: '682021',
      contactEmail: 'office@mec.ac.in',
    ),
  );

  const sampleUniversities = [
    University(id: 'uni-1', name: 'KTU', slug: 'KTU', state: 'Kerala'),
  ];

  group('InstituteManagementPage Widget Tests', () {
    testWidgets('Renders Campus Information and populates initial values',
        (tester) async {
      tester.view.physicalSize = const Size(1280, 900);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            currentInstituteProvider.overrideWith(
              () => FakeCurrentInstituteNotifier(sampleInstitute),
            ),
            campusUniversitiesProvider.overrideWith(
              (ref) async => sampleUniversities,
            ),
          ],
          child: const MaterialApp(
            home: InstituteManagementPage(role: AppRole.principal),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Verify Console Title
      expect(find.text('Institute Management Console'), findsOneWidget);

      // Verify Tabs
      expect(find.text('Campus Profile & Information'), findsOneWidget);
      expect(find.text('Branding & Visual Identity'), findsOneWidget);

      // Verify Prepopulated Form Fields
      expect(find.widgetWithText(TextFormField, 'Model Engineering College'),
          findsOneWidget);
      expect(find.widgetWithText(TextFormField, 'MEC'), findsOneWidget);
      expect(find.widgetWithText(TextFormField, 'mec.ac.in'), findsOneWidget);
      expect(find.widgetWithText(TextFormField, 'Kochi'), findsOneWidget);
      expect(
        find.widgetWithText(TextFormField, 'office@mec.ac.in'),
        findsOneWidget,
      );

      // Verify Principal Executive Governance Badge
      expect(find.text('Principal Executive Governance'), findsOneWidget);
    });

    testWidgets('Switches to Branding tab and displays Live Brand Card',
        (tester) async {
      tester.view.physicalSize = const Size(1280, 900);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            currentInstituteProvider.overrideWith(
              () => FakeCurrentInstituteNotifier(sampleInstitute),
            ),
            campusUniversitiesProvider.overrideWith(
              (ref) async => sampleUniversities,
            ),
          ],
          child: const MaterialApp(
            home: InstituteManagementPage(role: AppRole.officeAdmin),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Switch to Branding tab
      await tester.tap(find.text('Branding & Visual Identity'));
      await tester.pumpAndSettle();

      // Verify Live Portal Preview is rendered
      expect(find.text('Live Portal Preview'), findsOneWidget);

      // Verify Tagline field is prepopulated
      expect(
        find.widgetWithText(
            TextFormField, 'Moulding Engineers with Distinction'),
        findsOneWidget,
      );

      // Verify Active Brand Accent text
      expect(find.text('Active Brand Accent: #1E3A8A'), findsOneWidget);

      // Verify Save Branding Button
      expect(find.text('Save Campus Branding'), findsOneWidget);
    });
  });
}
