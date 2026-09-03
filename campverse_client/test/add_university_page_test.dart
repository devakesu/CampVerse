import 'package:campverse/features/super_admin/universities/add_university_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('AddUniversityPage URL Immutable Prefix Tests', () {
    testWidgets('URL field renders with immutable https:// prefixText',
        (tester) async {
      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: AddUniversityPage(),
          ),
        ),
      );

      // Verify the Official Website URL label and immutable prefix
      expect(find.text('Official Website URL'), findsOneWidget);
      expect(find.text('https://'), findsOneWidget);
      expect(find.text('ktu.edu.in'), findsOneWidget);
    });

    testWidgets(
        'Pasting URL with https:// or http:// strips prefix to avoid duplication',
        (tester) async {
      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: AddUniversityPage(),
          ),
        ),
      );

      final urlField = find.widgetWithText(
        TextFormField,
        'Official Website URL',
      );
      expect(urlField, findsOneWidget);

      // Simulate entering/pasting full URL with https://
      await tester.enterText(urlField, 'https://ktu.edu.in');
      await tester.pumpAndSettle();

      // Formatter strips 'https://' from controller text, so input is 'ktu.edu.in'
      final editable = tester.widget<EditableText>(
        find.descendant(
          of: urlField,
          matching: find.byType(EditableText),
        ),
      );
      expect(editable.controller.text, 'ktu.edu.in');

      // Simulate entering/pasting with http://
      await tester.enterText(urlField, 'http://annauniv.edu');
      await tester.pumpAndSettle();

      expect(editable.controller.text, 'annauniv.edu');
    });
  });
}
