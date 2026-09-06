import 'dart:ui';
import 'package:campverse/core/models/app_role.dart';
import 'package:campverse/core/models/auth_user.dart';
import 'package:campverse/core/providers/auth_provider.dart';
import 'package:campverse/features/shell/base_role_shell.dart';
import 'package:campverse/features/shell/widgets/desktop_sidebar.dart';
import 'package:campverse/features/shell/widgets/floating_glass_bottom_bar.dart';
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
  final studentDestinations = [
    const NavDestinationItem(
      label: 'Overview',
      shortLabel: 'Home',
      accentColor: Color(0xFF2563EB),
      icon: Icons.dashboard_outlined,
      selectedIcon: Icons.dashboard_rounded,
      body: Center(child: Text('Home Content')),
    ),
    const NavDestinationItem(
      label: 'Academics',
      shortLabel: 'Academics',
      accentColor: Color(0xFF7C3AED),
      icon: Icons.school_outlined,
      selectedIcon: Icons.school_rounded,
      body: Center(child: Text('Academics Content')),
    ),
    const NavDestinationItem(
      label: 'Events & Passes',
      shortLabel: 'Events',
      accentColor: Color(0xFFEA580C),
      icon: Icons.confirmation_number_outlined,
      selectedIcon: Icons.confirmation_number_rounded,
      body: Center(child: Text('Events Content')),
    ),
    const NavDestinationItem(
      label: 'Clubs & Union',
      shortLabel: 'Clubs',
      accentColor: Color(0xFF059669),
      icon: Icons.groups_outlined,
      selectedIcon: Icons.groups_rounded,
      body: Center(child: Text('Clubs Content')),
    ),
    const NavDestinationItem(
      label: 'My Profile',
      shortLabel: 'Profile',
      accentColor: Color(0xFFDB2777),
      icon: Icons.person_outline_rounded,
      selectedIcon: Icons.person_rounded,
      body: Center(child: Text('Profile Content')),
    ),
  ];

  group('FloatingGlassBottomBar Aesthetic & Short Titles Tests', () {
    testWidgets(
        'Renders short titles: Home, Academics, Events, Clubs, Profile',
        (tester) async {
      int selectedIdx = 0;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: StatefulBuilder(
              builder: (context, setState) {
                return FloatingGlassBottomBar(
                  selectedIndex: selectedIdx,
                  onTap: (idx) => setState(() => selectedIdx = idx),
                  tabs: studentDestinations.map((d) {
                    return FloatingNavTab(
                      label: d.label,
                      shortLabel: d.shortLabel,
                      accentColor: d.accentColor,
                      icon: d.icon,
                      selectedIcon: d.selectedIcon,
                    );
                  }).toList(),
                );
              },
            ),
          ),
        ),
      );

      // Verify that the short labels are rendered
      expect(find.text('Home'), findsOneWidget);
      expect(find.text('Academics'), findsOneWidget);
      expect(find.text('Events'), findsOneWidget);
      expect(find.text('Clubs'), findsOneWidget);
      expect(find.text('Profile'), findsOneWidget);

      // Verify full-form labels are NOT displayed in the bottom bar
      expect(find.text('Overview'), findsNothing);
      expect(find.text('Events & Passes'), findsNothing);
      expect(find.text('Clubs & Union'), findsNothing);
      expect(find.text('My Profile'), findsNothing);

      // Verify BackdropFilter with blur exists for glass effect
      expect(find.byType(BackdropFilter), findsOneWidget);

      // Tap on 'Events' tab (index 2)
      await tester.tap(find.text('Events'));
      await tester.pumpAndSettle();

      expect(selectedIdx, 2);
    });
  });

  group('DesktopSidebar Modern Colorful Aesthetic Tests', () {
    testWidgets(
        'Renders full-form labels, role badge, and colorful jewel icon containers',
        (tester) async {
      int selectedIdx = 0;
      bool isCollapsed = false;

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            authStateProvider.overrideWith((ref) => _MockAuthNotifier()),
          ],
          child: MaterialApp(
            home: Scaffold(
              body: StatefulBuilder(
                builder: (context, setState) {
                  return DesktopSidebar(
                    role: AppRole.student,
                    destinations: studentDestinations,
                    selectedIndex: selectedIdx,
                    isCollapsed: isCollapsed,
                    onToggleCollapse: () {
                      setState(() => isCollapsed = !isCollapsed);
                    },
                    onDestinationSelected: (idx) {
                      setState(() => selectedIdx = idx);
                    },
                  );
                },
              ),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Verify full-form labels on desktop sidebar
      expect(find.text('Overview'), findsOneWidget);
      expect(find.text('Academics'), findsOneWidget);
      expect(find.text('Events & Passes'), findsOneWidget);
      expect(find.text('Clubs & Union'), findsOneWidget);
      expect(find.text('My Profile'), findsOneWidget);

      // Role badge and user profile
      expect(find.text('Student'), findsOneWidget);
      expect(find.text('Active Workspace'), findsOneWidget);
      expect(find.text('Campus User'), findsOneWidget);

      // Tap on 'Events & Passes'
      await tester.tap(find.text('Events & Passes'));
      await tester.pumpAndSettle();
      expect(selectedIdx, 2);

      // Test collapse toggle
      await tester.tap(find.byTooltip('Collapse sidebar'));
      await tester.pumpAndSettle();

      expect(isCollapsed, true);
      // When collapsed, text labels are no longer rendered
      expect(find.text('Overview'), findsNothing);
      expect(find.text('Events & Passes'), findsNothing);
    });
  });

  group('BaseRoleShell Adaptive Viewport Tests', () {
    testWidgets(
        'Mobile viewport renders FloatingGlassBottomBar with short labels',
        (tester) async {
      tester.view.physicalSize = const Size(390, 844);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            authStateProvider.overrideWith((ref) => _MockAuthNotifier()),
          ],
          child: MaterialApp(
            home: BaseRoleShell(
              role: AppRole.student,
              destinations: studentDestinations,
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // On mobile viewport: FloatingGlassBottomBar is rendered with short titles
      expect(find.byType(FloatingGlassBottomBar), findsOneWidget);
      expect(find.byType(DesktopSidebar), findsNothing);
      expect(find.text('Home'), findsOneWidget);
      expect(find.text('Events'), findsOneWidget);
      expect(find.text('Clubs'), findsOneWidget);
      expect(find.text('Profile'), findsOneWidget);
    });

    testWidgets(
        'Desktop viewport renders DesktopSidebar with full-form labels',
        (tester) async {
      tester.view.physicalSize = const Size(1280, 900);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            authStateProvider.overrideWith((ref) => _MockAuthNotifier()),
          ],
          child: MaterialApp(
            home: BaseRoleShell(
              role: AppRole.student,
              destinations: studentDestinations,
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // On desktop viewport: DesktopSidebar is rendered with full labels
      expect(find.byType(DesktopSidebar), findsOneWidget);
      expect(find.byType(FloatingGlassBottomBar), findsNothing);
      expect(
        find.descendant(
          of: find.byType(DesktopSidebar),
          matching: find.text('Overview'),
        ),
        findsOneWidget,
      );
      expect(
        find.descendant(
          of: find.byType(DesktopSidebar),
          matching: find.text('Events & Passes'),
        ),
        findsOneWidget,
      );
      expect(
        find.descendant(
          of: find.byType(DesktopSidebar),
          matching: find.text('Clubs & Union'),
        ),
        findsOneWidget,
      );
      expect(
        find.descendant(
          of: find.byType(DesktopSidebar),
          matching: find.text('My Profile'),
        ),
        findsOneWidget,
      );
    });
  });
}
