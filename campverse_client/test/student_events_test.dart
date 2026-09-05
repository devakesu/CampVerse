import 'package:campverse/core/models/auth_user.dart';
import 'package:campverse/core/providers/auth_provider.dart';
import 'package:campverse/features/student/models/student_event.dart';
import 'package:campverse/features/student/models/student_registration.dart';
import 'package:campverse/features/student/widgets/event_card.dart';
import 'package:campverse/features/student/widgets/event_details_sheet.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

class _MockAuthNotifier extends StateNotifier<AuthUserState>
    implements AuthNotifier {
  _MockAuthNotifier() : super(const AuthUserState());

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  final testEventJson = <String, dynamic>{
    'id': 'evt-sample-01',
    'title': 'HackMEC 2026: 36-Hour Hackathon',
    'category': 'technical',
    'status': 'published',
    'venue': 'APJ Hall & Labs',
    'start_time': '2026-10-15T09:00:00.000Z',
    'end_time': '2026-10-16T21:00:00.000Z',
    'primary_org_name': 'MEC Computer Society',
    'poster_url': 'https://example.com/poster.jpg',
    'short_description': 'Premier 36-hour hackathon with cash pool of ₹1 Lakh.',
    'description': 'Deep dive hackathon focusing on AI and Web3 technologies.',
    'max_capacity': 250,
    'reg_config': true,
    'reg_end': '2026-10-10T23:59:59.000Z',
    'incentives': {
      'ktu_activity_points': 25,
      'duty_leave_approved': true,
      'certificate_provided': true,
    },
    'eligibility': {
      'is_open_to_all': false,
      'allowed_programmes': ['CSE', 'ECE', 'AI & DS'],
      'allowed_semesters': [4, 6, 8],
      'gender_restriction': 'All',
    },
    'pricing': {
      'is_paid': true,
      'base_price_cents': 29900,
      'currency': 'INR',
      'tiers': [
        {
          'name': 'Early Bird Student',
          'price_cents': 29900,
        },
      ],
    },
    'itinerary': [
      {
        'time': '09:00 AM - 10:30 AM',
        'activity': 'Opening Ceremony & Keynote',
      },
    ],
    'contacts': [
      {
        'name': 'Aditya R.',
        'role': 'Lead Organizer',
        'phone': '+91 9876543210',
        'email': 'aditya@mec.ac.in',
      },
    ],
    'links': {
      'website': 'https://hackmec2026.com',
      'discord': 'https://discord.gg/hackmec',
    },
    'collaborators': ['IEEE MEC SB', 'FOSS MEC'],
  };

  group('StudentEvent Model Tests', () {
    test('Correctly parses all database fields and nested JSON structures', () {
      final event = StudentEvent.fromJson(testEventJson);

      expect(event.id, 'evt-sample-01');
      expect(event.title, 'HackMEC 2026: 36-Hour Hackathon');
      expect(
        event.shortDescription,
        'Premier 36-hour hackathon with cash pool of ₹1 Lakh.',
      );
      expect(
        event.description,
        'Deep dive hackathon focusing on AI and Web3 technologies.',
      );
      expect(event.ktuActivityPoints, 25);
      expect(event.isDutyLeaveApproved, isTrue);
      expect(event.isCertificateProvided, isTrue);
      expect(event.formattedPrice, '₹299');

      // Eligibility
      expect(event.eligibility, isNotNull);
      expect(event.eligibility!.isOpenToAll, isFalse);
      expect(event.eligibility!.allowedProgrammes, ['CSE', 'ECE', 'AI & DS']);
      expect(event.eligibility!.allowedSemesters, [4, 6, 8]);

      // Itinerary
      expect(event.itinerary.length, 1);
      expect(event.itinerary.first.activity, 'Opening Ceremony & Keynote');

      // Pricing Tiers
      expect(event.pricingTiers.length, 1);
      expect(event.pricingTiers.first.name, 'Early Bird Student');
      expect(event.pricingTiers.first.priceCents, 29900);

      // Contacts & Links
      expect(event.contacts.length, 1);
      expect(event.contacts.first.name, 'Aditya R.');
      expect(event.contacts.first.phone, '+91 9876543210');
      expect(event.links['website'], 'https://hackmec2026.com');
      expect(event.collaborators, contains('IEEE MEC SB'));
    });

    test('Free event formatting defaults', () {
      final freeJson = <String, dynamic>{
        'id': 'free-01',
        'title': 'Free Workshop',
        'pricing': {'is_paid': false},
        'start_time': '2026-10-15T09:00:00.000Z',
        'end_time': '2026-10-15T12:00:00.000Z',
      };
      final event = StudentEvent.fromJson(freeJson);
      expect(event.isPaid, isFalse);
      expect(event.formattedPrice, 'Free Entry');
    });
  });

  group('StudentRegistration Model Tests', () {
    test('Parses registration status and QR payload with associated event', () {
      final regJson = <String, dynamic>{
        'id': 'reg-01',
        'event_id': 'evt-sample-01',
        'user_id': 'usr-01',
        'qr_payload': 'CAMP-PASS-HACKMEC-01',
        'status': 'confirmed',
        'created_at': '2026-09-01T12:00:00.000Z',
        'events': testEventJson,
      };

      final reg = StudentRegistration.fromJson(regJson);
      expect(reg.id, 'reg-01');
      expect(reg.qrPayload, 'CAMP-PASS-HACKMEC-01');
      expect(reg.status, 'confirmed');
      expect(reg.isActive, isTrue);
      expect(reg.event, isNotNull);
      expect(reg.event!.title, 'HackMEC 2026: 36-Hour Hackathon');
    });
  });

  group('EventCard & EventDetailsSheet Widget Tests', () {
    testWidgets('Renders rich EventCard badges and opens EventDetailsSheet',
        (tester) async {
      tester.view.physicalSize = const Size(1280, 900);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      final event = StudentEvent.fromJson(testEventJson);

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            authStateProvider.overrideWith((ref) => _MockAuthNotifier()),
          ],
          child: MaterialApp(
            home: Scaffold(
              body: SingleChildScrollView(
                child: EventCard(event: event),
              ),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Check card contents
      expect(find.text('HackMEC 2026: 36-Hour Hackathon'), findsOneWidget);
      expect(find.text('+25 KTU'), findsOneWidget);
      expect(find.text('Duty Leave'), findsOneWidget);
      expect(find.text('APJ Hall & Labs'), findsOneWidget);
      expect(
        find.text('Premier 36-hour hackathon with cash pool of ₹1 Lakh.'),
        findsOneWidget,
      );

      // Tap on event card title to open bottom sheet
      await tester.tap(find.text('HackMEC 2026: 36-Hour Hackathon'));
      await tester.pumpAndSettle();

      // Verify bottom sheet appeared with detailed info
      expect(find.byType(EventDetailsSheet), findsOneWidget);
      expect(find.text('ACADEMIC & ATTENDANCE INCENTIVES'), findsOneWidget);
      expect(
        find.text('+25 KTU Activity Points Awarded'),
        findsOneWidget,
      );
      expect(
        find.text('Duty Leave Approved for Class Hours'),
        findsOneWidget,
      );

      // Scroll to About the Event section
      await tester.scrollUntilVisible(
        find.text('About the Event'),
        150,
        scrollable: find.byType(Scrollable).last,
      );
      expect(
        find.text('Deep dive hackathon focusing on AI and Web3 technologies.'),
        findsOneWidget,
      );

      // Scroll to Coordinators
      await tester.scrollUntilVisible(
        find.text('Event Coordinators'),
        150,
        scrollable: find.byType(Scrollable).last,
      );
      expect(find.text('Aditya R.'), findsOneWidget);
    });
  });
}
