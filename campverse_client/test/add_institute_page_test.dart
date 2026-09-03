import 'package:campverse/core/models/university.dart';
import 'package:campverse/core/providers/super_admin_provider.dart';
import 'package:campverse/features/super_admin/institutes/add_institute_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

class FakeUniversitiesNotifier extends UniversitiesNotifier {
  FakeUniversitiesNotifier(this._data);
  final List<University> _data;

  @override
  Future<List<University>> build() async => _data;
}

void main() {
  const sampleUniversities = [
    University(
      id: 'uni-1',
      name: 'APJ Abdul Kalam Technological University',
      slug: 'KTU',
      state: 'Kerala',
    ),
  ];

  Widget buildSubject() {
    return ProviderScope(
      overrides: [
        universitiesProvider.overrideWith(
          () => FakeUniversitiesNotifier(sampleUniversities),
        ),
      ],
      child: const MaterialApp(
        home: AddInstitutePage(),
      ),
    );
  }

  group('AddInstitutePage Form & Executive Onboarding Tests', () {
    testWidgets('Renders all tenant, principal, and office admin fields',
        (tester) async {
      await tester.binding.setSurfaceSize(const Size(1200, 1800));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      await tester.pumpWidget(buildSubject());
      await tester.pumpAndSettle();

      // Tenant details
      expect(find.text('Add Institute Campus'), findsOneWidget);
      expect(find.text('Institute Tenant Details'), findsOneWidget);
      expect(find.text('Institute Name *'), findsOneWidget);
      expect(find.text('Slug / Code *'), findsOneWidget);
      expect(find.text('Campus Domain'), findsOneWidget);
      expect(find.text('Affiliated University'), findsOneWidget);
      expect(find.text('Autonomous Syllabus Structure'), findsOneWidget);
      expect(find.text('Tenant Active Status'), findsOneWidget);

      // Principal details
      expect(find.text('Principal Executive Account'), findsOneWidget);
      expect(find.text('Principal Full Name *'), findsOneWidget);
      expect(find.text('Principal Login Email *'), findsOneWidget);
      expect(find.widgetWithText(TextFormField, 'Principal Full Name *'),
          findsOneWidget);

      // Office Admin details
      expect(find.text('Office Administrator Account'), findsOneWidget);
      expect(find.text('Office Admin Full Name *'), findsOneWidget);
      expect(find.text('Office Admin Login Email *'), findsOneWidget);

      // Submit action button
      expect(
        find.text('Register Institute & Onboard Administrators'),
        findsOneWidget,
      );
    });

    testWidgets('Validates required fields on submission attempt',
        (tester) async {
      await tester.binding.setSurfaceSize(const Size(1200, 1800));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      await tester.pumpWidget(buildSubject());
      await tester.pumpAndSettle();

      // Clear the auto-generated password fields to trigger empty password validation
      final passwordFields =
          find.widgetWithText(TextFormField, 'Initial Password *');
      for (final field in passwordFields.evaluate()) {
        final widget = field.widget as TextFormField;
        widget.controller?.clear();
      }
      await tester.pumpAndSettle();

      // Tap submit button
      await tester.tap(find.text('Register Institute & Onboard Administrators'));
      await tester.pumpAndSettle();

      // Verify validation error messages
      expect(find.text('Please enter institute name'), findsOneWidget);
      expect(find.text('Slug required'), findsOneWidget);
      expect(find.text('Enter Principal name'), findsOneWidget);
      expect(find.text('Enter Principal email'), findsOneWidget);
      expect(find.text('Enter Office Admin name'), findsOneWidget);
      expect(find.text('Enter Office Admin email'), findsOneWidget);
    });

    testWidgets('Validates duplicate emails between principal and office admin',
        (tester) async {
      await tester.binding.setSurfaceSize(const Size(1200, 1800));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      await tester.pumpWidget(buildSubject());
      await tester.pumpAndSettle();

      // Fill identical emails
      final principalEmail =
          find.widgetWithText(TextFormField, 'Principal Login Email *');
      final officeAdminEmail =
          find.widgetWithText(TextFormField, 'Office Admin Login Email *');

      await tester.enterText(principalEmail, 'admin@college.ac.in');
      await tester.enterText(officeAdminEmail, 'admin@college.ac.in');
      await tester.pumpAndSettle();

      await tester.tap(find.text('Register Institute & Onboard Administrators'));
      await tester.pumpAndSettle();

      expect(find.text('Must differ from Principal email'), findsOneWidget);
    });
  });
}
