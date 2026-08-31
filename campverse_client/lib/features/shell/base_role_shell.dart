import 'dart:async';
import 'package:campverse/core/models/app_role.dart';
import 'package:campverse/core/providers/auth_provider.dart';
import 'package:campverse/core/theme/app_colors.dart';
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

/// Generic base shell providing app bar with role badge and switcher.
class BaseRoleShell extends ConsumerStatefulWidget {
  /// Default constructor for BaseRoleShell.
  const BaseRoleShell({
    required this.role,
    required this.destinations,
    this.customActions = const [],
    super.key,
  });

  /// The workspace role perspective being rendered.
  final AppRole role;

  /// List of navigation tab destinations.
  final List<NavDestinationItem> destinations;

  /// Optional extra app bar action buttons.
  final List<Widget> customActions;

  @override
  ConsumerState<BaseRoleShell> createState() => _BaseRoleShellState();
}

class _BaseRoleShellState extends ConsumerState<BaseRoleShell> {
  int _selectedIndex = 0;

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authStateProvider);
    final hasMultipleRoles = authState.hasMultipleRoles;

    return Scaffold(
      appBar: AppBar(
        backgroundColor: AppColors.surface,
        elevation: 0,
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: widget.role.badgeColor.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(
                widget.role.icon,
                color: widget.role.badgeColor,
                size: 20,
              ),
            ),
            const SizedBox(width: 12),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.role.displayName,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                  ),
                ),
                Text(
                  'CampVerse Workspace',
                  style: TextStyle(
                    fontSize: 11,
                    color: widget.role.badgeColor,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ],
        ),
        actions: [
          ...widget.customActions,
          if (hasMultipleRoles)
            PopupMenuButton<AppRole>(
              tooltip: 'Switch Workspace Role',
              icon: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: AppColors.surfaceElevated,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: AppColors.surfaceBorder),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.swap_horiz_rounded,
                      size: 16,
                      color: widget.role.badgeColor,
                    ),
                    const SizedBox(width: 6),
                    const Text(
                      'Switch Role',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textPrimary,
                      ),
                    ),
                  ],
                ),
              ),
              onSelected: (selectedRole) {
                if (selectedRole != widget.role) {
                  unawaited(
                    ref
                        .read(authStateProvider.notifier)
                        .switchRole(selectedRole),
                  );
                }
              },
              itemBuilder: (context) {
                return authState.availableRoles.map((r) {
                  final isCurrent = r == widget.role;
                  return PopupMenuItem<AppRole>(
                    value: r,
                    child: Row(
                      children: [
                        Icon(r.icon, color: r.badgeColor, size: 18),
                        const SizedBox(width: 10),
                        Text(
                          r.displayName,
                          style: TextStyle(
                            fontWeight:
                                isCurrent ? FontWeight.w700 : FontWeight.w500,
                            color: isCurrent
                                ? r.badgeColor
                                : AppColors.textPrimary,
                          ),
                        ),
                        if (isCurrent) ...[
                          const Spacer(),
                          Icon(
                            Icons.check_rounded,
                            color: r.badgeColor,
                            size: 16,
                          ),
                        ],
                      ],
                    ),
                  );
                }).toList();
              },
            ),
          IconButton(
            icon: const Icon(
              Icons.logout_rounded,
              color: AppColors.textSecondary,
            ),
            onPressed: () {
              unawaited(ref.read(authStateProvider.notifier).signOut());
            },
            tooltip: 'Sign Out',
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: widget.destinations.isEmpty
          ? const Center(child: Text('No tabs configured'))
          : widget.destinations[_selectedIndex].body,
      bottomNavigationBar: widget.destinations.length > 1
          ? NavigationBar(
              selectedIndex: _selectedIndex,
              onDestinationSelected: (index) {
                setState(() => _selectedIndex = index);
              },
              destinations: widget.destinations.map((d) {
                return NavigationDestination(
                  icon: Icon(d.icon),
                  selectedIcon: Icon(d.selectedIcon),
                  label: d.label,
                );
              }).toList(),
            )
          : null,
    );
  }
}
