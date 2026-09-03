import 'package:campverse/core/constants/india_states.dart';
import 'package:campverse/core/widgets/india_state_picker_field.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('India States & UTs Constant Dataset Tests', () {
    test('Dataset contains exactly 28 States and 8 UTs (36 total)', () {
      expect(kIndiaStatesAndUTs.length, 36);
      expect(kIndiaStates.length, 28);
      expect(kIndiaUnionTerritories.length, 8);
      expect(kIndiaStateNames.length, 36);
    });

    test('All states and UTs have valid names and 2-letter codes', () {
      for (final item in kIndiaStatesAndUTs) {
        expect(item.name.trim().isNotEmpty, isTrue);
        expect(item.code.length, 2);
        expect(item.code, item.code.toUpperCase());
        expect(
          item.categoryLabel,
          item.isUnionTerritory ? 'Union Territory' : 'State',
        );
      }
    });

    test('Search filters correctly by name and code (case-insensitive)', () {
      // By name
      final keralaResults = filterIndiaStates(query: 'kerala');
      expect(keralaResults.length, 1);
      expect(keralaResults.first.name, 'Kerala');
      expect(keralaResults.first.code, 'KL');

      // By code
      final klResults = filterIndiaStates(query: 'kl');
      expect(klResults.length, 1);
      expect(klResults.first.name, 'Kerala');

      final dlResults = filterIndiaStates(query: 'DL');
      expect(dlResults.length, 1);
      expect(dlResults.first.name, 'Delhi');
      expect(dlResults.first.isUnionTerritory, isTrue);

      // Partial name
      final pradeshResults = filterIndiaStates(query: 'pradesh');
      expect(pradeshResults.length, 5); // AP, AR, HP, MP, UP
    });

    test('Category filtering isolates states and union territories', () {
      final statesOnly = filterIndiaStates(
        category: IndiaStateCategory.states,
      );
      expect(statesOnly.length, 28);
      expect(statesOnly.every((s) => !s.isUnionTerritory), isTrue);

      final utOnly = filterIndiaStates(
        category: IndiaStateCategory.unionTerritories,
      );
      expect(utOnly.length, 8);
      expect(utOnly.every((s) => s.isUnionTerritory), isTrue);
    });
  });

  group('IndiaStatePickerFormField Widget Tests', () {
    testWidgets('Renders label, hint, and responds to controller',
        (tester) async {
      final controller = TextEditingController(text: 'Kerala');

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Form(
              child: IndiaStatePickerFormField(
                controller: controller,
              ),
            ),
          ),
        ),
      );

      expect(find.text('State / Province *'), findsOneWidget);
      expect(find.text('Kerala'), findsOneWidget);
      expect(find.text('KL'), findsOneWidget);
    });

    testWidgets('Tapping field opens modal, searches, and selects state',
        (tester) async {
      final controller = TextEditingController();

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Form(
              child: IndiaStatePickerFormField(
                controller: controller,
              ),
            ),
          ),
        ),
      );

      // Verify empty field hint
      expect(find.text('Select State or UT'), findsOneWidget);

      // Tap to open modal
      await tester.tap(find.byType(IndiaStatePickerFormField));
      await tester.pumpAndSettle();

      // Modal is open
      expect(find.text('Select State / UT'), findsOneWidget);
      expect(find.text('All (36)'), findsOneWidget);

      // Search for "Goa"
      await tester.enterText(find.byType(TextField), 'Goa');
      await tester.pumpAndSettle();

      // Tap "Goa" item from list
      final goaTile = find.widgetWithText(ListTile, 'Goa');
      expect(goaTile, findsOneWidget);
      await tester.tap(goaTile);
      await tester.pumpAndSettle();

      // Modal closes, controller updated
      expect(controller.text, 'Goa');
      expect(find.text('Goa'), findsOneWidget);
      expect(find.text('GA'), findsOneWidget);
    });

    testWidgets('Clear button resets value', (tester) async {
      final controller = TextEditingController(text: 'Goa');

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Form(
              child: IndiaStatePickerFormField(
                controller: controller,
              ),
            ),
          ),
        ),
      );

      expect(find.text('Goa'), findsOneWidget);

      // Tap clear icon
      await tester.tap(find.byIcon(Icons.clear_rounded));
      await tester.pumpAndSettle();

      expect(controller.text, '');
      expect(find.text('Select State or UT'), findsOneWidget);
    });

    testWidgets('Filter tabs switch between All, States, and UTs in modal',
        (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Form(
              child: IndiaStatePickerFormField(),
            ),
          ),
        ),
      );

      // Tap to open modal
      await tester.tap(find.byType(IndiaStatePickerFormField));
      await tester.pumpAndSettle();

      // Tap UTs tab
      await tester.tap(find.text('UTs (8)'));
      await tester.pumpAndSettle();

      // Verify Delhi is visible, Goa is not
      expect(find.text('Delhi'), findsOneWidget);
      expect(find.text('Goa'), findsNothing);
    });
  });
}
