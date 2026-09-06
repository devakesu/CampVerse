import 'dart:async';
import 'package:campverse/core/models/app_role.dart';
import 'package:campverse/core/providers/auth_provider.dart';
import 'package:campverse/core/providers/theme_provider.dart';
import 'package:campverse/core/router/route_names.dart';
import 'package:campverse/core/theme/app_colors.dart';
import 'package:campverse/core/widgets/brand_logo.dart';
import 'package:campverse/features/shell/base_role_shell.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

/// Permanent / collapsible desktop navigation sidebar with modern colorful aesthetic.
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
  int? _hoveredIndex;

  @override
  Widget build(BuildContext context) {
    final isDark = AppColors.isDark(context);
    final themeMode = ref.watch(themeModeProvider);
    final authState = ref.watch(authStateProvider);
    final currentUser = authState.user;
    final roleColor = AppColors.roleColorOf(context, widget.role);
    final width = widget.isCollapsed ? 82.0 : 268.0;

    final userName = (currentUser?.userMetadata?['full_name'] as String?) ??
        (currentUser?.email?.split('@').first ?? 'Campus User');

    return AnimatedContainer(
      duration: const Duration(milliseconds: 220),
      curve: Curves.easeOutCubic,
      width: width,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: isDark
              ? [const Color(0xFF0F172A), const Color(0xFF0B0F19)]
              : [Colors.white, const Color(0xFFF8FAFC)],
        ),
        border: Border(
          right: BorderSide(
            color: isDark ? const Color(0xFF1E293B) : const Color(0xFFE2E8F0),
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
              horizontal: widget.isCollapsed ? 12 : 18,
              vertical: 18,
            ),
            decoration: BoxDecoration(
              border: Border(
                bottom: BorderSide(
                  color: isDark
                      ? const Color(0xFF1E293B)
                      : const Color(0xFFE2E8F0),
                  width: 1,
                ),
              ),
            ),
            child: Row(
              mainAxisAlignment: widget.isCollapsed
                  ? MainAxisAlignment.center
                  : MainAxisAlignment.spaceBetween,
              children: [
                if (!widget.isCollapsed) ...[
                  const BrandLogo.wide(height: 40),
                ] else ...[
                  const BrandLogo.square(size: 38),
                ],
                if (widget.onToggleCollapse != null && !widget.isCollapsed)
                  Material(
                    color: Colors.transparent,
                    borderRadius: BorderRadius.circular(8),
                    child: IconButton(
                      icon: Icon(
                        Icons.menu_open_rounded,
                        size: 20,
                        color: AppColors.textSecondaryOf(context),
                      ),
                      onPressed: widget.onToggleCollapse,
                      tooltip: 'Collapse sidebar',
                      hoverColor: roleColor.withValues(alpha: 0.1),
                    ),
                  ),
              ],
            ),
          ),

          // Role Badge Box (Expanded)
          if (!widget.isCollapsed) ...[
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 14, 16, 6),
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 10,
                ),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      roleColor.withValues(alpha: isDark ? 0.16 : 0.10),
                      roleColor.withValues(alpha: isDark ? 0.06 : 0.03),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: roleColor.withValues(alpha: isDark ? 0.32 : 0.22),
                    width: 1.2,
                  ),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 32,
                      height: 32,
                      decoration: BoxDecoration(
                        color: roleColor.withValues(alpha: isDark ? 0.25 : 0.18),
                        borderRadius: BorderRadius.circular(9),
                      ),
                      child: Icon(widget.role.icon, size: 17, color: roleColor),
                    ),
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
                              color: isDark ? Colors.white : roleColor,
                            ),
                          ),
                          Row(
                            children: [
                              Container(
                                width: 6,
                                height: 6,
                                decoration: BoxDecoration(
                                  color: const Color(0xFF10B981),
                                  shape: BoxShape.circle,
                                  boxShadow: [
                                    BoxShadow(
                                      color: const Color(0xFF10B981)
                                          .withValues(alpha: 0.6),
                                      blurRadius: 4,
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(width: 5),
                              Flexible(
                                child: Text(
                                  'Active Workspace',
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(
                                    fontSize: 10,
                                    fontWeight: FontWeight.w500,
                                    color: AppColors.textSecondaryOf(context),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ] else if (widget.onToggleCollapse != null) ...[
            // Collapsed mode: Expand button
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Center(
                child: IconButton(
                  icon: Icon(
                    Icons.menu_rounded,
                    size: 20,
                    color: AppColors.textSecondaryOf(context),
                  ),
                  onPressed: widget.onToggleCollapse,
                  tooltip: 'Expand sidebar',
                ),
              ),
            ),
          ],

          const SizedBox(height: 6),

          // Navigation list with colorful modern items
          Expanded(
            child: ListView.separated(
              padding: EdgeInsets.symmetric(
                horizontal: widget.isCollapsed ? 10 : 14,
                vertical: 4,
              ),
              itemCount: widget.destinations.length,
              separatorBuilder: (context, index) => const SizedBox(height: 6),
              itemBuilder: (context, index) {
                final item = widget.destinations[index];
                final isSelected = index == widget.selectedIndex;
                final isHovered = index == _hoveredIndex;
                final itemColor = item.accentColor ?? roleColor;

                // Collapsed Rail Item
                if (widget.isCollapsed) {
                  return Tooltip(
                    message: item.label,
                    preferBelow: false,
                    child: MouseRegion(
                      onEnter: (_) => setState(() => _hoveredIndex = index),
                      onExit: (_) => setState(() => _hoveredIndex = null),
                      child: InkWell(
                        onTap: () => widget.onDestinationSelected(index),
                        borderRadius: BorderRadius.circular(14),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          height: 50,
                          decoration: BoxDecoration(
                            color: isSelected
                                ? itemColor.withValues(
                                    alpha: isDark ? 0.22 : 0.14,
                                  )
                                : (isHovered
                                    ? itemColor.withValues(
                                        alpha: isDark ? 0.12 : 0.07,
                                      )
                                    : Colors.transparent),
                            borderRadius: BorderRadius.circular(14),
                            border: isSelected
                                ? Border.all(
                                    color: itemColor.withValues(
                                      alpha: isDark ? 0.45 : 0.32,
                                    ),
                                    width: 1.2,
                                  )
                                : null,
                          ),
                          child: Center(
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 200),
                              width: 38,
                              height: 38,
                              decoration: BoxDecoration(
                                gradient: isSelected
                                    ? LinearGradient(
                                        begin: Alignment.topLeft,
                                        end: Alignment.bottomRight,
                                        colors: [
                                          itemColor,
                                          itemColor.withValues(alpha: 0.85),
                                        ],
                                      )
                                    : null,
                                color: isSelected
                                    ? null
                                    : itemColor.withValues(
                                        alpha: isDark ? 0.14 : 0.08,
                                      ),
                                borderRadius: BorderRadius.circular(10),
                                border: isSelected
                                    ? null
                                    : Border.all(
                                        color: itemColor.withValues(
                                          alpha: isDark ? 0.22 : 0.14,
                                        ),
                                        width: 1,
                                      ),
                                boxShadow: isSelected
                                    ? [
                                        BoxShadow(
                                          color: itemColor.withValues(
                                            alpha: 0.45,
                                          ),
                                          blurRadius: 8,
                                          offset: const Offset(0, 2),
                                        ),
                                      ]
                                    : null,
                              ),
                              child: Icon(
                                isSelected ? item.selectedIcon : item.icon,
                                size: 20,
                                color: isSelected ? Colors.white : itemColor,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  );
                }

                // Expanded Item
                return MouseRegion(
                  onEnter: (_) => setState(() => _hoveredIndex = index),
                  onExit: (_) => setState(() => _hoveredIndex = null),
                  child: InkWell(
                    onTap: () => widget.onDestinationSelected(index),
                    borderRadius: BorderRadius.circular(14),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 9,
                      ),
                      decoration: BoxDecoration(
                        gradient: isSelected
                            ? LinearGradient(
                                begin: Alignment.centerLeft,
                                end: Alignment.centerRight,
                                colors: [
                                  itemColor.withValues(
                                    alpha: isDark ? 0.20 : 0.14,
                                  ),
                                  itemColor.withValues(
                                    alpha: isDark ? 0.06 : 0.02,
                                  ),
                                ],
                              )
                            : (isHovered
                                ? LinearGradient(
                                    begin: Alignment.centerLeft,
                                    end: Alignment.centerRight,
                                    colors: [
                                      itemColor.withValues(
                                        alpha: isDark ? 0.10 : 0.06,
                                      ),
                                      itemColor.withValues(
                                        alpha: isDark ? 0.03 : 0.01,
                                      ),
                                    ],
                                  )
                                : null),
                        borderRadius: BorderRadius.circular(14),
                        border: isSelected
                            ? Border.all(
                                color: itemColor.withValues(
                                  alpha: isDark ? 0.40 : 0.26,
                                ),
                                width: 1.2,
                              )
                            : Border.all(
                                color: isHovered
                                    ? itemColor.withValues(
                                        alpha: isDark ? 0.20 : 0.12,
                                      )
                                    : Colors.transparent,
                                width: 1.2,
                              ),
                      ),
                      child: Row(
                        children: [
                          // Left glowing vertical pill indicator
                          AnimatedContainer(
                            duration: const Duration(milliseconds: 200),
                            width: 3.5,
                            height: isSelected ? 22 : 0,
                            decoration: BoxDecoration(
                              color: isSelected
                                  ? itemColor
                                  : Colors.transparent,
                              borderRadius: BorderRadius.circular(2),
                              boxShadow: isSelected
                                  ? [
                                      BoxShadow(
                                        color: itemColor.withValues(alpha: 0.7),
                                        blurRadius: 6,
                                        spreadRadius: 0.5,
                                      ),
                                    ]
                                  : null,
                            ),
                          ),
                          SizedBox(width: isSelected ? 8 : 4),

                          // Jewel-tone colorful icon badge
                          AnimatedContainer(
                            duration: const Duration(milliseconds: 200),
                            width: 36,
                            height: 36,
                            decoration: BoxDecoration(
                              gradient: isSelected
                                  ? LinearGradient(
                                      begin: Alignment.topLeft,
                                      end: Alignment.bottomRight,
                                      colors: [
                                        itemColor,
                                        itemColor.withValues(alpha: 0.85),
                                      ],
                                    )
                                  : null,
                              color: isSelected
                                  ? null
                                  : itemColor.withValues(
                                      alpha: isDark ? 0.14 : 0.08,
                                    ),
                              borderRadius: BorderRadius.circular(10),
                              border: isSelected
                                  ? null
                                  : Border.all(
                                      color: itemColor.withValues(
                                        alpha: isDark ? 0.22 : 0.14,
                                      ),
                                      width: 1,
                                    ),
                              boxShadow: isSelected
                                  ? [
                                      BoxShadow(
                                        color: itemColor.withValues(
                                          alpha: 0.45,
                                        ),
                                        blurRadius: 8,
                                        offset: const Offset(0, 2),
                                      ),
                                    ]
                                  : null,
                            ),
                            child: Icon(
                              isSelected ? item.selectedIcon : item.icon,
                              size: 19,
                              color: isSelected ? Colors.white : itemColor,
                            ),
                          ),
                          const SizedBox(width: 12),

                          // Full form destination label
                          Expanded(
                            child: Text(
                              item.label,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                fontSize: 13.5,
                                fontWeight: isSelected
                                    ? FontWeight.w700
                                    : FontWeight.w500,
                                color: isSelected
                                    ? (isDark ? Colors.white : itemColor)
                                    : AppColors.textPrimaryOf(context),
                              ),
                            ),
                          ),

                          // Active glowing dot indicator
                          if (isSelected)
                            Container(
                              width: 7,
                              height: 7,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: itemColor,
                                boxShadow: [
                                  BoxShadow(
                                    color: itemColor.withValues(alpha: 0.6),
                                    blurRadius: 6,
                                  ),
                                ],
                              ),
                            ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
          ),

          // Footer: User profile & quick tools
          Container(
            padding: EdgeInsets.all(widget.isCollapsed ? 8 : 14),
            decoration: BoxDecoration(
              border: Border(
                top: BorderSide(
                  color: isDark
                      ? const Color(0xFF1E293B)
                      : const Color(0xFFE2E8F0),
                  width: 1,
                ),
              ),
            ),
            child: widget.isCollapsed
                ? Column(
                    children: [
                      _buildMiniIconButton(
                        icon: Icons.shield_outlined,
                        tooltip: 'Security & 2FA',
                        color: AppColors.textSecondaryOf(context),
                        onPressed: () {
                          unawaited(context.push(RouteNames.securitySettings));
                        },
                      ),
                      const SizedBox(height: 4),
                      _buildMiniIconButton(
                        icon: themeMode == ThemeMode.dark
                            ? Icons.light_mode_rounded
                            : Icons.dark_mode_rounded,
                        tooltip: 'Toggle Theme',
                        color: AppColors.textSecondaryOf(context),
                        onPressed: () {
                          ref.read(themeModeProvider.notifier).toggleTheme();
                        },
                      ),
                      const SizedBox(height: 4),
                      _buildMiniIconButton(
                        icon: Icons.logout_rounded,
                        tooltip: 'Sign Out',
                        color: AppColors.error,
                        onPressed: () {
                          unawaited(
                            ref.read(authStateProvider.notifier).signOut(),
                          );
                        },
                      ),
                    ],
                  )
                : Row(
                    children: [
                      // Gradient avatar with status badge
                      Stack(
                        children: [
                          Container(
                            width: 36,
                            height: 36,
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: [
                                  roleColor,
                                  roleColor.withValues(alpha: 0.7),
                                ],
                              ),
                              shape: BoxShape.circle,
                              boxShadow: [
                                BoxShadow(
                                  color: roleColor.withValues(alpha: 0.35),
                                  blurRadius: 6,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                            ),
                            child: Center(
                              child: Text(
                                userName.isNotEmpty
                                    ? userName[0].toUpperCase()
                                    : 'U',
                                style: const TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w700,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                          ),
                          Positioned(
                            right: 0,
                            bottom: 0,
                            child: Container(
                              width: 9,
                              height: 9,
                              decoration: BoxDecoration(
                                color: const Color(0xFF10B981),
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: isDark
                                      ? const Color(0xFF0F172A)
                                      : Colors.white,
                                  width: 1.5,
                                ),
                              ),
                            ),
                          ),
                        ],
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
                      _buildMiniIconButton(
                        icon: Icons.shield_outlined,
                        tooltip: 'Security & 2FA',
                        color: AppColors.textSecondaryOf(context),
                        onPressed: () {
                          unawaited(context.push(RouteNames.securitySettings));
                        },
                      ),
                      _buildMiniIconButton(
                        icon: themeMode == ThemeMode.dark
                            ? Icons.light_mode_rounded
                            : Icons.dark_mode_rounded,
                        tooltip: 'Toggle Theme',
                        color: AppColors.textSecondaryOf(context),
                        onPressed: () {
                          ref.read(themeModeProvider.notifier).toggleTheme();
                        },
                      ),
                    ],
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildMiniIconButton({
    required IconData icon,
    required String tooltip,
    required Color color,
    required VoidCallback onPressed,
  }) {
    return Tooltip(
      message: tooltip,
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(8),
        child: InkWell(
          borderRadius: BorderRadius.circular(8),
          onTap: onPressed,
          child: Padding(
            padding: const EdgeInsets.all(6),
            child: Icon(icon, size: 18, color: color),
          ),
        ),
      ),
    );
  }
}

