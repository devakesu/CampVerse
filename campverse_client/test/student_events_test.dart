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
    'reg_start': '2026-09-01T00:00:00.000Z',
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
      'allowed_sex': <String>[],
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
    'collaborators': <String, dynamic>{
      'IEEE MEC SB': <dynamic>[
        {'logo': 'https://example.com/ieee.png', 'title': 'Technical Partner'},
      ],
      'Kerala Blockchain Academy': <dynamic>[
        {'logo': 'https://example.com/kba.png'},
      ],
      'Rotaract Club MEC': <dynamic>[
        {'title': 'Outreach Partner'},
      ],
      'FOSS MEC': <dynamic>[],
    },
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

      // Registration Timing
      expect(event.regStart, isNotNull);
      expect(event.regStart, DateTime.parse('2026-09-01T00:00:00.000Z'));
      expect(event.regEnd, isNotNull);

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

      // Collaborator Title & Logo Cases
      expect(event.collaborators.length, 4);
      final ieee = event.collaborators
          .firstWhere((c) => c.name == 'IEEE MEC SB');
      expect(ieee.hasLogo, isTrue);
      expect(ieee.hasTitle, isTrue);
      expect(ieee.title, 'Technical Partner');
      expect(ieee.logo, 'https://example.com/ieee.png');

      final kba = event.collaborators
          .firstWhere((c) => c.name == 'Kerala Blockchain Academy');
      expect(kba.hasLogo, isTrue);
      expect(kba.hasTitle, isFalse);
      expect(kba.title, isNull);

      final rotaract = event.collaborators
          .firstWhere((c) => c.name == 'Rotaract Club MEC');
      expect(rotaract.hasLogo, isFalse);
      expect(rotaract.hasTitle, isTrue);
      expect(rotaract.title, 'Outreach Partner');
      expect(rotaract.logo, isNull);

      final foss = event.collaborators.firstWhere((c) => c.name == 'FOSS MEC');
      expect(foss.hasLogo, isFalse);
      expect(foss.hasTitle, isFalse);
      expect(foss.title, isNull);
      expect(foss.logo, isNull);
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

    test(
      'Parses reg_start_time fallback and calculates upcoming/open states',
      () {
        final now = DateTime.now();
        final upcomingJson = <String, dynamic>{
          'id': 'upcoming-01',
          'title': 'Upcoming Event',
          'status': 'published',
          'reg_config': true,
          'reg_start_time': now.add(const Duration(days: 3)).toIso8601String(),
          'reg_end': now.add(const Duration(days: 10)).toIso8601String(),
          'start_time': now.add(const Duration(days: 12)).toIso8601String(),
        };
        final event = StudentEvent.fromJson(upcomingJson);
        expect(event.regStart, isNotNull);
        expect(event.isRegistrationUpcoming, isTrue);
        expect(event.isRegistrationOpen, isFalse);
        expect(event.isRegistrationClosed, isFalse);
      },
    );

    test(
      'Eligibility helpers display correct text when empty and non-empty',
      () {
        final emptyEligibility = EventEligibility.fromJson(const {
          'allowed_programmes': <String>[],
          'allowed_semesters': <int>[],
          'allowed_sex': <String>[],
        });
        expect(emptyEligibility.isOpenToAll, isTrue);
        expect(emptyEligibility.isAllSemesters, isTrue);
        expect(emptyEligibility.isAllProgrammes, isTrue);
        expect(emptyEligibility.isAllSex, isTrue);
        expect(emptyEligibility.isAllGenders, isTrue);
        expect(emptyEligibility.semesterDisplay, 'Semesters: All Semesters');
        expect(emptyEligibility.programmeDisplay, 'Branches: All Programmes');
        expect(emptyEligibility.sexDisplay, 'Sex: Open to All');
        expect(emptyEligibility.isAllowedForSex('F'), isTrue);
        expect(emptyEligibility.isAllowedForSex('M'), isTrue);

        // Combo 1: F Only
        final femaleEligibility = EventEligibility.fromJson(const {
          'allowed_programmes': ['CSE', 'ECE'],
          'allowed_semesters': [4, 6],
          'allowed_sex': ['F'],
        });
        expect(femaleEligibility.isOpenToAll, isFalse);
        expect(femaleEligibility.isAllSex, isFalse);
        expect(femaleEligibility.sexDisplay, 'Sex: Female Only');
        expect(femaleEligibility.summaryText, contains('Female Only'));
        expect(femaleEligibility.isAllowedForSex('F'), isTrue);
        expect(femaleEligibility.isAllowedForSex('M'), isFalse);

        // Combo 2: M Only
        final maleEligibility = EventEligibility.fromJson(const {
          'allowed_programmes': ['CSE'],
          'allowed_semesters': [4],
          'allowed_sex': ['M'],
        });
        expect(maleEligibility.isAllSex, isFalse);
        expect(maleEligibility.sexDisplay, 'Sex: Male Only');
        expect(maleEligibility.summaryText, contains('Male Only'));
        expect(maleEligibility.isAllowedForSex('M'), isTrue);
        expect(maleEligibility.isAllowedForSex('F'), isFalse);

        // Combo 3: F & T Cross Cases
        final crossEligibility = EventEligibility.fromJson(const {
          'allowed_programmes': <String>[],
          'allowed_semesters': [4, 6, 8],
          'allowed_sex': ['F', 'T'],
        });
        expect(crossEligibility.isAllSex, isFalse);
        expect(crossEligibility.sexDisplay, 'Sex: Female & Transgender');
        expect(crossEligibility.summaryText, contains('Female / Transgender'));
        expect(crossEligibility.isAllowedForSex('F'), isTrue);
        expect(crossEligibility.isAllowedForSex('T'), isTrue);
        expect(crossEligibility.isAllowedForSex('M'), isFalse);

        // Combo 4: M, F, T all explicitly allowed
        final allExplicit = EventEligibility.fromJson(const {
          'allowed_programmes': <String>[],
          'allowed_semesters': <int>[],
          'allowed_sex': ['M', 'F', 'T'],
        });
        expect(allExplicit.isAllSex, isTrue);
        expect(allExplicit.sexDisplay, 'Sex: Open to All');
        expect(allExplicit.isAllowedForSex('M'), isTrue);
        expect(allExplicit.isAllowedForSex('F'), isTrue);
      },
    );
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

      // Verify bottom sheet appeared
      expect(find.byType(EventDetailsSheet), findsOneWidget);

      // Verify Registration Starts is shown above Registration Deadline
      expect(find.text('Registration Starts'), findsOneWidget);
      expect(find.text('Registration Deadline'), findsOneWidget);

      // Verify Countdown Timer units are present
      expect(find.text('DAYS'), findsWidgets);
      expect(find.text('HOURS'), findsWidgets);
      expect(find.text('MINS'), findsWidgets);
      expect(find.text('SECS'), findsWidgets);

      // Scroll to About the Event section (now before Incentives)
      await tester.scrollUntilVisible(
        find.text('About the Event'),
        150,
        scrollable: find.byType(Scrollable).last,
      );
      expect(
        find.text('Deep dive hackathon focusing on AI and Web3 technologies.'),
        findsOneWidget,
      );

      // Scroll to Academic & Attendance Incentives section
      await tester.scrollUntilVisible(
        find.text('ACADEMIC & ATTENDANCE INCENTIVES'),
        150,
        scrollable: find.byType(Scrollable).last,
      );
      expect(
        find.text('+25 KTU Activity Points Awarded'),
        findsOneWidget,
      );
      expect(
        find.text('Duty Leave Approved for Class Hours'),
        findsOneWidget,
      );

      // Scroll to Eligibility section
      await tester.scrollUntilVisible(
        find.text('Eligibility Criteria'),
        150,
        scrollable: find.byType(Scrollable).last,
      );
      expect(find.text('Eligibility Criteria'), findsOneWidget);

      // Scroll to Co-Organizers
      await tester.scrollUntilVisible(
        find.text('Co-Organizers'),
        150,
        scrollable: find.byType(Scrollable).last,
      );
      expect(find.text('Co-Organizers'), findsOneWidget);
      expect(find.text('IEEE MEC SB'), findsOneWidget);
      expect(find.text('Technical Partner'), findsOneWidget);
      expect(find.text('Kerala Blockchain Academy'), findsOneWidget);
      expect(find.text('Rotaract Club MEC'), findsOneWidget);
      expect(find.text('Outreach Partner'), findsOneWidget);
      expect(find.text('FOSS MEC'), findsOneWidget);

      // Scroll to Coordinators
      await tester.scrollUntilVisible(
        find.text('Event Coordinators'),
        150,
        scrollable: find.byType(Scrollable).last,
      );
      expect(find.text('Aditya R.'), findsOneWidget);
    });

    testWidgets(
      'Renders all eligibility fields with All and Everyone when empty',
      (tester) async {
      tester.view.physicalSize = const Size(1280, 900);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      final openEventJson = Map<String, dynamic>.from(testEventJson);
      openEventJson['eligibility'] = <String, dynamic>{
        'allowed_programmes': <String>[],
        'allowed_semesters': <int>[],
        'allowed_sex': <String>[],
      };

      final event = StudentEvent.fromJson(openEventJson);

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

      // Tap on event card title to open bottom sheet
      await tester.tap(find.text('HackMEC 2026: 36-Hour Hackathon'));
      await tester.pumpAndSettle();

      // Scroll to Eligibility Criteria section
      await tester.scrollUntilVisible(
        find.text('Eligibility Criteria'),
        150,
        scrollable: find.byType(Scrollable).last,
      );
      expect(find.text('Eligibility Criteria'), findsOneWidget);

      // Verify all three fields are displayed
      expect(find.text('All Semesters'), findsOneWidget);
      expect(find.text('All Programmes'), findsOneWidget);
      expect(find.text('Sex: Open to All'), findsOneWidget);
    });

    testWidgets(
      'Hides KTU points when field is absent or 0 (RoboQuest case)',
      (tester) async {
        tester.view.physicalSize = const Size(1280, 900);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);

        final roboJson = <String, dynamic>{
          'id': 'robo-01',
          'title': 'RoboQuest: Autonomous Line Tracer',
          'venue': 'Indoor Sports Complex',
          'start_time': '2026-09-25T10:00:00.000Z',
          'end_time': '2026-09-25T17:30:00.000Z',
          'reg_config': true,
          'reg_start': '2026-08-28T00:00:00.000Z',
          'reg_end': '2026-09-24T08:00:00.000Z',
          'incentives': <String, dynamic>{
            'duty_leave_approved': true,
            'certificate_provided': true,
            // ktu_activity_points is absent!
          },
          'pricing': {
            'is_paid': true,
            'base_price_cents': 15000,
            'currency': 'INR',
          },
        };

        final event = StudentEvent.fromJson(roboJson);
        expect(event.ktuActivityPoints, 0);
        expect(event.isDutyLeaveApproved, isTrue);
        expect(event.isCertificateProvided, isTrue);
        expect(event.hasIncentives, isTrue);

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

        // Check EventCard does NOT render +0 KTU
        expect(find.text('+0 KTU'), findsNothing);
        expect(find.text('+0 KTU Pts'), findsNothing);
        expect(find.text('Duty Leave'), findsOneWidget);

        // Tap to open sheet
        await tester.tap(find.text('RoboQuest: Autonomous Line Tracer'));
        await tester.pumpAndSettle();

        // Scroll to Incentives section
        await tester.scrollUntilVisible(
          find.text('ACADEMIC & ATTENDANCE INCENTIVES'),
          150,
          scrollable: find.byType(Scrollable).last,
        );

        // Verify +0 KTU is NOT present in sheet
        expect(find.text('+0 KTU Activity Points Awarded'), findsNothing);
        expect(
          find.textContaining('KTU Activity Points Awarded'),
          findsNothing,
        );

        // Verify Duty Leave and Certificate ARE present
        expect(
          find.text('Duty Leave Approved for Class Hours'),
          findsOneWidget,
        );
        expect(
          find.text('Verified Digital Certificate in Student Vault'),
          findsOneWidget,
        );
      },
    );

    testWidgets(
      'Completely omits incentives card when an event has no incentives at all',
      (tester) async {
        tester.view.physicalSize = const Size(1280, 900);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);

        final noIncentivesJson = <String, dynamic>{
          'id': 'seminar-01',
          'title': 'General Campus Gathering',
          'venue': 'Open Amphitheatre',
          'start_time': '2026-10-01T10:00:00.000Z',
          'end_time': '2026-10-01T12:00:00.000Z',
          'incentives': <String, dynamic>{
            'ktu_activity_points': 0,
            'duty_leave_approved': false,
            'certificate_provided': false,
          },
        };

        final event = StudentEvent.fromJson(noIncentivesJson);
        expect(event.hasIncentives, isFalse);

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

        // Open sheet
        await tester.tap(find.text('General Campus Gathering'));
        await tester.pumpAndSettle();

        // Incentives card should NOT exist
        expect(find.text('ACADEMIC & ATTENDANCE INCENTIVES'), findsNothing);
      },
    );

    testWidgets(
      'Renders Walk-in entry views when reg_config is false',
      (tester) async {
        tester.view.physicalSize = const Size(1280, 900);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);

        final walkInJson = <String, dynamic>{
          'id': 'walkin-01',
          'title': 'Open Campus Debate',
          'venue': 'College Central Lawn',
          'start_time': '2026-10-05T15:00:00.000Z',
          'end_time': '2026-10-05T17:00:00.000Z',
          'reg_config': false,
        };

        final event = StudentEvent.fromJson(walkInJson);
        expect(event.regConfig, isFalse);

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

        // Card should display Walk-in, NOT Reg closed
        expect(find.text('Walk-in'), findsWidgets);
        expect(find.text('Reg closed'), findsNothing);
        expect(find.text('Closed'), findsNothing);

        // Tap card to open sheet
        await tester.tap(find.text('Open Campus Debate'));
        await tester.pumpAndSettle();

        // Sheet should state walk-in admission
        expect(
          find.text('Open Walk-in (No Prior Registration Needed)'),
          findsOneWidget,
        );
        expect(
          find.text('Walk-in Entry • No Pass Needed'),
          findsOneWidget,
        );
      },
    );

    testWidgets(
      'Renders cancelled banner & disabled button when status is cancelled',
      (tester) async {
        tester.view.physicalSize = const Size(1280, 900);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);

        final cancelledJson = <String, dynamic>{
          'id': 'canc-01',
          'title': 'Postponed Drone Race',
          'venue': 'College Grounds',
          'status': 'cancelled',
          'start_time': '2026-10-10T09:00:00.000Z',
          'end_time': '2026-10-10T12:00:00.000Z',
        };

        final event = StudentEvent.fromJson(cancelledJson);
        expect(event.isCancelled, isTrue);

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

        // Card shows Cancelled
        expect(find.text('Cancelled'), findsWidgets);

        // Tap card to open sheet
        await tester.tap(find.text('Postponed Drone Race'));
        await tester.pumpAndSettle();

        // Cancellation banner and CTA
        expect(
          find.text(
            'This event has been officially cancelled by the organizers.',
          ),
          findsOneWidget,
        );
        expect(find.text('Event Cancelled'), findsOneWidget);
      },
    );

    testWidgets(
      'Renders top close button and FEATURED badge when poster is absent',
      (tester) async {
        tester.view.physicalSize = const Size(1280, 900);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);

        final noPosterJson = <String, dynamic>{
          'id': 'noposter-01',
          'title': 'Featured Tech Colloquium',
          'venue': 'Seminar Hall 1',
          'is_featured': true,
          'poster_url': null,
          'start_time': '2026-10-12T10:00:00.000Z',
          'end_time': '2026-10-12T13:00:00.000Z',
          'tags': ['Tech', 'Symposium'],
          'media_urls': ['https://example.com/photo1.jpg'],
          'contacts': [
            {
              'name': 'Prof. Sharma',
              'role': 'Faculty Lead',
              'phone': '+91 9999999999',
              'email': 'sharma@mec.ac.in',
            },
          ],
        };

        final event = StudentEvent.fromJson(noPosterJson);
        expect(event.isFeatured, isTrue);
        expect(event.posterUrl, isNull);
        expect(event.tags, ['Tech', 'Symposium']);
        expect(event.mediaUrls.length, 1);
        expect(event.contacts.first.email, 'sharma@mec.ac.in');

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

        // Card top row shows FEATURED badge
        expect(find.text('FEATURED'), findsOneWidget);

        // Tap card to open sheet
        await tester.tap(find.text('Featured Tech Colloquium'));
        await tester.pumpAndSettle();

        // Sheet displays FEATURED badge and top close button
        expect(find.text('FEATURED'), findsWidgets);
        expect(find.byTooltip('Close'), findsOneWidget);

        // Sheet displays tags
        expect(find.text('#Tech'), findsOneWidget);
        expect(find.text('#Symposium'), findsOneWidget);

        // Scroll down to check Gallery and Contact email button
        await tester.scrollUntilVisible(
          find.text('Event Gallery'),
          150,
          scrollable: find.byType(Scrollable).last,
        );
        expect(find.text('Event Gallery'), findsOneWidget);

        await tester.scrollUntilVisible(
          find.text('Event Coordinators'),
          150,
          scrollable: find.byType(Scrollable).last,
        );
        expect(find.byTooltip('Email Prof. Sharma'), findsOneWidget);
      },
    );
  });
}
