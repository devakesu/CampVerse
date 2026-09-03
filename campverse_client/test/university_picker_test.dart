import 'package:campverse/core/models/university.dart';
import 'package:campverse/core/providers/super_admin_provider.dart';
import 'package:campverse/core/widgets/university_picker_field.dart';
import 'package:campverse/features/super_admin/institutes/add_institute_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

class FakeUniversitiesNotifier extends UniversitiesNotifier {
  FakeUniversitiesNotifier(this._universities);
  final List<University> _universities;

  @override
  Future<List<University>> build() async => _universities;
}

void main() {
  final sampleUniversities = [
    const University(
      id: 'uni-1',
      name: 'APJ Abdul Kalam Technological University',
      slug: 'KTU',
      state: 'Kerala',
    ),
    const University(
      id: 'uni-2',
      name: 'Visvesvaraya Technological University',
      slug: 'VTU',
      state: 'Karnataka',
    ),
    const University(
      id: 'uni-3',
      name: 'Mahatma Gandhi University',
      slug: 'MGU',
      state: 'Kerala',
    ),
    const University(
      id: 'uni-4',
      name: 'Anna University',
      slug: 'AU',
      state: 'Tamil Nadu',
    ),
  ];

  group('UniversityPickerFormField Widget Tests', () {
    testWidgets('Renders label, hint text, and account balance icon',
        (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: UniversityPickerFormField(
              universities: sampleUniversities,
            ),
          ),
        ),
      );

      expect(find.text('Affiliated University'), findsOneWidget);
      expect(find.text('Select affiliating university'), findsOneWidget);
      expect(find.byIcon(Icons.account_balance_outlined), findsOneWidget);
    });

    testWidgets('Renders selected university with name, slug, and state badge',
        (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: UniversityPickerFormField(
              universities: sampleUniversities,
              initialValue: 'uni-1',
            ),
          ),
        ),
      );

      expect(
        find.text('APJ Abdul Kalam Technological University'),
        findsOneWidget,
      );
      expect(find.text('KTU'), findsOneWidget);
      expect(find.text('Kerala'), findsOneWidget);
      expect(find.byIcon(Icons.clear_rounded), findsOneWidget);
    });

    testWidgets('Clearing selected university resets to empty state',
        (tester) async {
      University? selectedUni = sampleUniversities.first;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: StatefulBuilder(
              builder: (context, setState) {
                return UniversityPickerFormField(
                  universities: sampleUniversities,
                  initialValue: selectedUni?.id,
                  onChanged: (u) => setState(() => selectedUni = u),
                );
              },
            ),
          ),
        ),
      );

      expect(
        find.text('APJ Abdul Kalam Technological University'),
        findsOneWidget,
      );

      // Tap the clear button
      await tester.tap(find.byIcon(Icons.clear_rounded));
      await tester.pumpAndSettle();

      expect(selectedUni, isNull);
      expect(find.text('Select affiliating university'), findsOneWidget);
    });
  });

  group('UniversityPickerModal Tests', () {
    testWidgets('Shows all universities and state filter chips',
        (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: UniversityPickerModal(
              universities: sampleUniversities,
            ),
          ),
        ),
      );

      // Header and description
      expect(find.text('Select Affiliating University'), findsOneWidget);

      // Filter chips: All States (4), Karnataka (1), Kerala (2), Tamil Nadu (1)
      expect(find.text('All States (4)'), findsOneWidget);
      expect(find.text('Kerala (2)'), findsOneWidget);
      expect(find.text('Karnataka (1)'), findsOneWidget);
      expect(find.text('Tamil Nadu (1)'), findsOneWidget);

      // Check university items
      expect(find.text('KTU'), findsWidgets);
      expect(find.text('VTU'), findsWidgets);
      expect(find.text('MGU'), findsWidgets);
      expect(find.text('AU'), findsWidgets);
    });

    testWidgets('Filters universities by search query', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: UniversityPickerModal(
              universities: sampleUniversities,
            ),
          ),
        ),
      );

      // Enter search query "Anna"
      await tester.enterText(find.byType(TextField), 'Anna');
      await tester.pumpAndSettle();

      expect(find.text('Anna University'), findsOneWidget);
      expect(
        find.text('APJ Abdul Kalam Technological University'),
        findsNothing,
      );
      expect(find.text('VTU'), findsNothing);
    });

    testWidgets('Filters universities by slug search', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: UniversityPickerModal(
              universities: sampleUniversities,
            ),
          ),
        ),
      );

      // Enter search query "VTU"
      await tester.enterText(find.byType(TextField), 'vtu');
      await tester.pumpAndSettle();

      expect(
        find.text('Visvesvaraya Technological University'),
        findsOneWidget,
      );
      expect(
        find.text('APJ Abdul Kalam Technological University'),
        findsNothing,
      );
    });

    testWidgets('Filters universities by clicking state chip', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: UniversityPickerModal(
              universities: sampleUniversities,
            ),
          ),
        ),
      );

      // Tap on Kerala (2) chip
      await tester.tap(find.text('Kerala (2)'));
      await tester.pumpAndSettle();

      // Only Kerala universities should be shown
      expect(
        find.text('APJ Abdul Kalam Technological University'),
        findsOneWidget,
      );
      expect(find.text('Mahatma Gandhi University'), findsOneWidget);
      expect(find.text('Visvesvaraya Technological University'), findsNothing);
      expect(find.text('Anna University'), findsNothing);
      expect(find.text('Clear State Filter'), findsOneWidget);

      // Tap "Clear State Filter"
      await tester.tap(find.text('Clear State Filter'));
      await tester.pumpAndSettle();

      // All universities should be shown again
      expect(
        find.text('Visvesvaraya Technological University'),
        findsOneWidget,
      );
      expect(find.text('Anna University'), findsOneWidget);
    });

    testWidgets('Combining state filter and search query', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: UniversityPickerModal(
              universities: sampleUniversities,
            ),
          ),
        ),
      );

      // Tap on Kerala (2) chip
      await tester.tap(find.text('Kerala (2)'));
      await tester.pumpAndSettle();

      // Search for Mahatma
      await tester.enterText(find.byType(TextField), 'Mahatma');
      await tester.pumpAndSettle();

      expect(find.text('Mahatma Gandhi University'), findsOneWidget);
      expect(
        find.text('APJ Abdul Kalam Technological University'),
        findsNothing,
      );

      // Now search for VTU (which is in Karnataka, not Kerala)
      await tester.enterText(find.byType(TextField), 'VTU');
      await tester.pumpAndSettle();

      expect(find.text('No matching universities found'), findsOneWidget);

      // Reset filters button
      await tester.tap(find.text('Reset filters'));
      await tester.pumpAndSettle();

      expect(find.text('Showing 4 of 4 universities'), findsOneWidget);
    });

    testWidgets('Selecting university pops modal with chosen university',
        (tester) async {
      University? picked;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (context) => ElevatedButton(
                onPressed: () async {
                  picked = await UniversityPickerModal.show(
                    context,
                    universities: sampleUniversities,
                  );
                },
                child: const Text('Open'),
              ),
            ),
          ),
        ),
      );

      // Open modal
      await tester.tap(find.text('Open'));
      await tester.pumpAndSettle();

      // Tap on Anna University
      await tester.tap(find.text('Anna University'));
      await tester.pumpAndSettle();

      expect(picked?.id, 'uni-4');
      expect(picked?.slug, 'AU');
    });
  });

  group('AddInstitutePage Integration Tests', () {
    testWidgets('Renders AddInstitutePage with UniversityPickerFormField',
        (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            universitiesProvider.overrideWith(
              () => FakeUniversitiesNotifier(sampleUniversities),
            ),
          ],
          child: const MaterialApp(
            home: AddInstitutePage(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Add Institute Campus'), findsOneWidget);
      expect(find.text('Institute Tenant Details'), findsOneWidget);
      expect(find.text('Affiliated University'), findsOneWidget);
      expect(find.text('Select affiliating university'), findsOneWidget);
    });
  });
}
