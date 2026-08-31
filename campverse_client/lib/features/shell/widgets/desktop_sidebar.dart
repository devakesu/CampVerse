import 'dart:async';
import 'package:campverse/core/models/app_role.dart';
import 'package:campverse/core/providers/auth_provider.dart';
import 'package:campverse/core/providers/theme_provider.dart';
import 'package:campverse/core/theme/app_colors.dart';
import 'package:campverse/features/shell/base_role_shell.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Permanent / collapsible desktop navigation sidebar.
class DesktopSidebar extends ConsumerStatefulWidget {
  /// Default constructor for DesktopSidebar.
  const DesktopSidebar({
    required this.role,
    required this.destinations,
    required this.selectedIndex,
    required this.onDestinationSelected,
    this.isCollapsed = false,
    this.onToggleCollapse,
    super.key,
  });

  /// Current workspace role.
  final AppRole role;

  /// List of navigation destination tabs.
  final List<NavDestinationItem> destinations;

  /// Active tab index.
  final int selectedIndex;

  /// Selection callback.
  final ValueChanged<int> onDestinationSelected;

  /// Whether the sidebar is collapsed to icon-only rail mode.
  final bool isCollapsed;

  /// Toggle collapse callback.
  final VoidCallback? onToggleCollapse;

  @override
  ConsumerState<DesktopSidebar> createState() => _DesktopSidebarState();
}

class _DesktopSidebarState extends ConsumerState<DesktopSidebar> {
  @override
  Widget build(BuildContext context) {
    final isDark = AppColors.isDark(context);
    final themeMode = ref.watch(themeModeProvider);
    final authState = ref.watch(authStateProvider);
    final currentUser = authState.user;
    final roleColor = AppColors.roleColorOf(context, widget.role);
    final width = widget.isCollapsed ? 80.0 : 260.0;

    final userName = (currentUser?.userMetadata?['full_name'] as String?) ??
        (currentUser?.email?.split('@').first ?? 'Campus User');

    return AnimatedContainer(
      duration: const Duration(milliseconds: 220),
      curve: Curves.easeOutCubic,
      width: width,
      decoration: BoxDecoration(
        color: AppColors.surfaceOf(context),
        border: Border(
          right: BorderSide(
            color: AppColors.borderOf(context),
            width: 1.2,
          ),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Header & Brand
          Container(
            padding: EdgeInsets.symmetric(
              horizontal: widget.isCollapsed ? 12 : 20,
              vertical: 20,
            ),
            decoration: BoxDecoration(
              border: Border(
                bottom: BorderSide(
                  color: AppColors.borderOf(context),
                ),
              ),
            ),
            child: Row(
              mainAxisAlignment: widget.isCollapsed
                  ? MainAxisAlignment.center
                  : MainAxisAlignment.spaceBetween,
              children: [
                if (!widget.isCollapsed) ...[
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          gradient: AppColors.primaryGradient,
                          borderRadius: BorderRadius.circular(10),
                          boxShadow: [
                            BoxShadow(
                              color: AppColors.primary.withValues(alpha: 0.3),
                              blurRadius: 10,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: const Icon(
                          Icons.school_rounded,
                          size: 20,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'CampVerse',
                            style: Theme.of(context)
                                .textTheme
                                .titleLarge
                                ?.copyWith(
                                  fontWeight: FontWeight.w800,
                                  fontSize: 17,
                                  letterSpacing: -0.3,
                                ),
                          ),
                          Text(
                            'Campus OS',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: AppColors.textSecondaryOf(context),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ] else ...[
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      gradient: AppColors.primaryGradient,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(
                      Icons.school_rounded,
                      size: 20,
                      color: Colors.white,
                    ),
                  ),
                ],
                if (widget.onToggleCollapse != null && !widget.isCollapsed)
                  IconButton(
                    icon: Icon(
                      Icons.menu_open_rounded,
                      size: 20,
                      color: AppColors.textSecondaryOf(context),
                    ),
                    onPressed: widget.onToggleCollapse,
                    tooltip: 'Collapse sidebar',
                  ),
              ],
            ),
          ),

          // Role Badge Box
          if (!widget.isCollapsed) ...[
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                decoration: BoxDecoration(
                  color: roleColor.withValues(alpha: isDark ? 0.12 : 0.08),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: roleColor.withValues(alpha: isDark ? 0.3 : 0.2),
                  ),
                ),
                child: Row(
                  children: [
                    Icon(widget.role.icon, size: 18, color: roleColor),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            widget.role.displayName,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                              color: roleColor,
                            ),
                          ),
                          Text(
                            'Active Workspace',
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w500,
                              color: AppColors.textSecondaryOf(context),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],

          const SizedBox(height: 8),

          // Navigation list
          Expanded(
            child: ListView.separated(
              padding: EdgeInsets.symmetric(
                horizontal: widget.isCollapsed ? 8 : 12,
                vertical: 4,
              ),
              itemCount: widget.destinations.length,
              separatorBuilder: (context, index) => const SizedBox(height: 4),
              itemBuilder: (context, index) {
                final item = widget.destinations[index];
                final isSelected = index == widget.selectedIndex;

                if (widget.isCollapsed) {
                  return Tooltip(
                    message: item.label,
                    preferBelow: false,
                    child: InkWell(
                      onTap: () => widget.onDestinationSelected(index),
                      borderRadius: BorderRadius.circular(12),
                      child: Container(
                        height: 48,
                        decoration: BoxDecoration(
                          color: isSelected
                              ? roleColor.withValues(alpha: isDark ? 0.2 : 0.12)
                              : Colors.transparent,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Center(
                          child: Icon(
                            isSelected ? item.selectedIcon : item.icon,
                            size: 22,
                            color: isSelected
                                ? roleColor
                                : AppColors.textSecondaryOf(context),
                          ),
                        ),
                      ),
                    ),
                  );
                }

                return InkWell(
                  onTap: () => widget.onDestinationSelected(index),
                  borderRadius: BorderRadius.circular(12),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 11,
                    ),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? roleColor.withValues(alpha: isDark ? 0.16 : 0.1)
                          : Colors.transparent,
                      borderRadius: BorderRadius.circular(12),
                      border: isSelected
                          ? Border.all(
                              color: roleColor.withValues(
                                alpha: isDark ? 0.35 : 0.25,
                              ),
                            )
                          : null,
                    ),
                    child: Row(
                      children: [
                        Icon(
                          isSelected ? item.selectedIcon : item.icon,
                          size: 20,
                          color: isSelected
                              ? roleColor
                              : AppColors.textSecondaryOf(context),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            item.label,
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: isSelected
                                  ? FontWeight.w700
                                  : FontWeight.w500,
                              color: isSelected
                                  ? (isDark ? Colors.white : roleColor)
                                  : AppColors.textPrimaryOf(context),
                            ),
                          ),
                        ),
                        if (isSelected)
                          Container(
                            width: 6,
                            height: 6,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: roleColor,
                            ),
                          ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),

          // Footer: User profile & quick tools
          Container(
            padding: EdgeInsets.all(widget.isCollapsed ? 8 : 16),
            decoration: BoxDecoration(
              border: Border(
                top: BorderSide(
                  color: AppColors.borderOf(context),
                ),
              ),
            ),
            child: widget.isCollapsed
                ? Column(
                    children: [
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
                      IconButton(
                        icon: const Icon(
                          Icons.logout_rounded,
                          size: 20,
                          color: AppColors.error,
                        ),
                        onPressed: () {
                          unawaited(
                            ref.read(authStateProvider.notifier).signOut(),
                          );
                        },
                        tooltip: 'Sign Out',
                      ),
                    ],
                  )
                : Row(
                    children: [
                      CircleAvatar(
                        radius: 18,
                        backgroundColor: roleColor.withValues(alpha: 0.2),
                        child: Text(
                          userName.isNotEmpty ? userName[0].toUpperCase() : 'U',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                            color: roleColor,
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              userName,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                color: AppColors.textPrimaryOf(context),
                              ),
                            ),
                            Text(
                              currentUser?.email ?? '',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                fontSize: 11,
                                color: AppColors.textSecondaryOf(context),
                              ),
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        icon: Icon(
                          themeMode == ThemeMode.dark
                              ? Icons.light_mode_rounded
                              : Icons.dark_mode_rounded,
                          size: 19,
                          color: AppColors.textSecondaryOf(context),
                        ),
                        onPressed: () {
                          ref.read(themeModeProvider.notifier).toggleTheme();
                        },
                        tooltip: 'Toggle Theme Mode',
                      ),
                    ],
                  ),
          ),
        ],
      ),
    );
  }
}
