import 'package:campverse/core/models/app_role.dart';
import 'package:campverse/core/providers/auth_provider.dart';
import 'package:campverse/core/providers/theme_provider.dart';
import 'package:campverse/core/theme/app_colors.dart';
import 'package:campverse/core/utils/responsive_layout.dart';
import 'package:campverse/features/shell/widgets/adaptive_drawer.dart';
import 'package:campverse/features/shell/widgets/desktop_sidebar.dart';
import 'package:campverse/features/shell/widgets/desktop_top_bar.dart';
import 'package:campverse/features/shell/widgets/floating_glass_bottom_bar.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Navigation destination descriptor representing a workspace tab.
class NavDestinationItem {
  /// Default constructor for NavDestinationItem.
  const NavDestinationItem({
    required this.label,
    required this.icon,
    required this.selectedIcon,
    required this.body,
  });

  /// Tab label displayed in navigation bars.
  final String label;

  /// Default icon.
  final IconData icon;

  /// Selected state icon.
  final IconData selectedIcon;

  /// Content widget rendered when this tab is selected.
  final Widget body;
}

/// Adaptive base shell providing multiplatform desktop/mobile workspace
/// layout.
class BaseRoleShell extends ConsumerStatefulWidget {
  /// Default constructor for BaseRoleShell.
  const BaseRoleShell({
    required this.role,
    required this.destinations,
    this.customActions = const [],
    this.selectedIndex,
    this.onDestinationSelected,
    super.key,
  });

  /// The workspace role perspective being rendered.
  final AppRole role;

  /// List of navigation tab destinations.
  final List<NavDestinationItem> destinations;

  /// Optional extra app bar action buttons.
  final List<Widget> customActions;

  /// Optional controlled tab index.
  final int? selectedIndex;

  /// Optional callback when a navigation destination is selected.
  final ValueChanged<int>? onDestinationSelected;

  @override
  ConsumerState<BaseRoleShell> createState() => _BaseRoleShellState();
}

class _BaseRoleShellState extends ConsumerState<BaseRoleShell> {
  int _internalSelectedIndex = 0;
  bool _isSidebarCollapsed = false;

  int get _selectedIndex => widget.selectedIndex ?? _internalSelectedIndex;

  void _handleDestinationSelected(int index) {
    if (widget.onDestinationSelected != null) {
      widget.onDestinationSelected!(index);
    } else {
      setState(() => _internalSelectedIndex = index);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDesktop = ResponsiveLayout.isDesktop(context);

    if (isDesktop) {
      return _buildDesktopLayout(context);
    } else {
      return _buildMobileLayout(context);
    }
  }

  /// Builds the desktop multiplatform layout with permanent sidebar & top bar.
  Widget _buildDesktopLayout(BuildContext context) {
    final currentTab = widget.destinations.isNotEmpty
        ? widget.destinations[_selectedIndex]
        : null;

    return Scaffold(
      backgroundColor: AppColors.backgroundOf(context),
      body: Row(
        children: [
          DesktopSidebar(
            role: widget.role,
            destinations: widget.destinations,
            selectedIndex: _selectedIndex,
            isCollapsed: _isSidebarCollapsed,
            onToggleCollapse: () {
              setState(() => _isSidebarCollapsed = !_isSidebarCollapsed);
            },
            onDestinationSelected: _handleDestinationSelected,
          ),
          Expanded(
            child: Column(
              children: [
                DesktopTopBar(
                  role: widget.role,
                  pageTitle: currentTab?.label ?? 'Workspace',
                  customActions: widget.customActions,
                ),
                Expanded(
                  child: currentTab != null
                      ? AnimatedSwitcher(
                          duration: const Duration(milliseconds: 180),
                          child: KeyedSubtree(
                            key: ValueKey(_selectedIndex),
                            child: currentTab.body,
                          ),
                        )
                      : const Center(child: Text('No tabs configured')),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// Builds the mobile layout with floating glass bottom bar & drawer sidebar.
  Widget _buildMobileLayout(BuildContext context) {
    final authState = ref.watch(authStateProvider);
    final themeMode = ref.watch(themeModeProvider);
    final isDark = AppColors.isDark(context);
    final roleColor = AppColors.roleColorOf(context, widget.role);

    final currentTab = widget.destinations.isNotEmpty
        ? widget.destinations[_selectedIndex]
        : null;

    return Scaffold(
      backgroundColor: AppColors.backgroundOf(context),
      drawer: AdaptiveDrawer(role: widget.role),
      appBar: AppBar(
        backgroundColor: AppColors.surfaceOf(context),
        elevation: 0,
        scrolledUnderElevation: 0,
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: roleColor.withValues(alpha: isDark ? 0.18 : 0.12),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                widget.role.icon,
                color: roleColor,
                size: 18,
              ),
            ),
            const SizedBox(width: 10),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.role.displayName,
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimaryOf(context),
                  ),
                ),
                Text(
                  currentTab?.label ?? 'Workspace',
                  style: TextStyle(
                    fontSize: 11,
                    color: roleColor,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ],
        ),
        actions: [
          ...widget.customActions,
          IconButton(
            icon: Icon(
              themeMode == ThemeMode.dark
                  ? Icons.light_mode_rounded
                  : Icons.dark_mode_rounded,
              size: 20,
              color: AppColors.textSecondaryOf(context),
            ),
            onPressed: () {
              ref.read(themeModeProvider.notifier).toggleTheme();
            },
            tooltip: 'Toggle Theme',
          ),
          if (authState.hasMultipleRoles)
            IconButton(
              icon: Icon(
                Icons.swap_horiz_rounded,
                color: roleColor,
                size: 22,
              ),
              tooltip: 'Switch Workspace Role',
              onPressed: () {
                Scaffold.of(context).openDrawer();
              },
            ),
          const SizedBox(width: 4),
        ],
      ),
      body: Stack(
        children: [
          // Content Area with bottom inset padding for floating bar
          Positioned.fill(
            child: Padding(
              padding: EdgeInsets.only(
                bottom: widget.destinations.length > 1 ? 80 : 0,
              ),
              child: currentTab != null
                  ? currentTab.body
                  : const Center(child: Text('No tabs configured')),
            ),
          ),

          // Floating Glass Bottom Navigation Bar
          if (widget.destinations.length > 1)
            Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              child: FloatingGlassBottomBar(
                accentColor: roleColor,
                selectedIndex: _selectedIndex,
                onTap: _handleDestinationSelected,
                tabs: widget.destinations.map((d) {
                  return FloatingNavTab(
                    label: d.label,
                    icon: d.icon,
                    selectedIcon: d.selectedIcon,
                  );
                }).toList(),
              ),
            ),
        ],
      ),
    );
  }
}
