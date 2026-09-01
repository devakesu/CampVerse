import 'dart:async';
import 'package:campverse/core/models/app_role.dart';
import 'package:campverse/core/providers/auth_provider.dart';
import 'package:campverse/core/router/route_names.dart';
import 'package:campverse/core/theme/app_colors.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

/// Sleek top action bar for desktop / web workspace views.
class DesktopTopBar extends ConsumerWidget implements PreferredSizeWidget {
  /// Default constructor for DesktopTopBar.
  const DesktopTopBar({
    required this.role,
    required this.pageTitle,
    this.customActions = const [],
    this.onSearch,
    super.key,
  });

  /// The active role perspective.
  final AppRole role;

  /// Current active section / page title.
  final String pageTitle;

  /// Optional custom action widgets.
  final List<Widget> customActions;

  /// Search query callback.
  final ValueChanged<String>? onSearch;

  @override
  Size get preferredSize => const Size.fromHeight(68);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = AppColors.isDark(context);
    final authState = ref.watch(authStateProvider);
    final roleColor = AppColors.roleColorOf(context, role);

    return Container(
      height: preferredSize.height,
      padding: const EdgeInsets.symmetric(horizontal: 24),
      decoration: BoxDecoration(
        color: AppColors.surfaceOf(context),
        border: Border(
          bottom: BorderSide(
            color: AppColors.borderOf(context),
            width: 1.2,
          ),
        ),
      ),
      child: Row(
        children: [
          // Breadcrumb / Page Title
          Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Text(
                    role.displayName,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: roleColor,
                    ),
                  ),
                  Icon(
                    Icons.chevron_right_rounded,
                    size: 16,
                    color: AppColors.textMutedOf(context),
                  ),
                  Text(
                    pageTitle,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      color: AppColors.textSecondaryOf(context),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 2),
              Text(
                pageTitle,
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w700,
                      fontSize: 18,
                    ),
              ),
            ],
          ),

          const SizedBox(width: 32),

          // Global Search Field
          Expanded(
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 460),
                child: Container(
                  height: 40,
                  decoration: BoxDecoration(
                    color: AppColors.surfaceElevatedOf(context),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: AppColors.borderOf(context),
                    ),
                  ),
                  child: TextField(
                    onChanged: onSearch,
                    style: TextStyle(
                      fontSize: 13,
                      color: AppColors.textPrimaryOf(context),
                    ),
                    decoration: InputDecoration(
                      hintText: 'Search resources, users, courses (Ctrl+K)...',
                      hintStyle: TextStyle(
                        fontSize: 13,
                        color: AppColors.textMutedOf(context),
                      ),
                      prefixIcon: Icon(
                        Icons.search_rounded,
                        size: 18,
                        color: AppColors.textSecondaryOf(context),
                      ),
                      contentPadding: const EdgeInsets.symmetric(vertical: 10),
                      border: InputBorder.none,
                      enabledBorder: InputBorder.none,
                      focusedBorder: InputBorder.none,
                    ),
                  ),
                ),
              ),
            ),
          ),

          const SizedBox(width: 16),

          // Custom Actions
          ...customActions,

          // Multi-Role Switcher Menu
          if (authState.hasMultipleRoles) ...[
            PopupMenuButton<AppRole>(
              tooltip: 'Switch Workspace Role',
              offset: const Offset(0, 48),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
                side: BorderSide(color: AppColors.borderOf(context)),
              ),
              color: AppColors.surfaceOf(context),
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
                decoration: BoxDecoration(
                  color: roleColor.withValues(alpha: isDark ? 0.15 : 0.1),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: roleColor.withValues(alpha: isDark ? 0.35 : 0.25),
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(role.icon, size: 16, color: roleColor),
                    const SizedBox(width: 8),
                    Text(
                      role.displayName,
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: roleColor,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Icon(
                      Icons.keyboard_arrow_down_rounded,
                      size: 16,
                      color: roleColor,
                    ),
                  ],
                ),
              ),
              onSelected: (selectedRole) {
                if (selectedRole != role) {
                  unawaited(
                    ref
                        .read(authStateProvider.notifier)
                        .switchRole(selectedRole),
                  );
                }
              },
              itemBuilder: (context) {
                return authState.availableRoles.map((r) {
                  final isCurrent = r == role;
                  final rColor = AppColors.roleColorOf(context, r);
                  return PopupMenuItem<AppRole>(
                    value: r,
                    child: Row(
                      children: [
                        Icon(r.icon, color: rColor, size: 18),
                        const SizedBox(width: 12),
                        Text(
                          r.displayName,
                          style: TextStyle(
                            fontWeight:
                                isCurrent ? FontWeight.w700 : FontWeight.w500,
                            color: isCurrent
                                ? rColor
                                : AppColors.textPrimaryOf(context),
                          ),
                        ),
                        if (isCurrent) ...[
                          const Spacer(),
                          Icon(
                            Icons.check_rounded,
                            color: rColor,
                            size: 16,
                          ),
                        ],
                      ],
                    ),
                  );
                }).toList();
              },
            ),
            const SizedBox(width: 12),
          ],

          // Security & 2FA Management Button
          IconButton(
            icon: const Icon(Icons.shield_outlined, size: 20),
            color: AppColors.textSecondaryOf(context),
            tooltip: 'Security & 2FA Settings',
            onPressed: () {
              unawaited(context.push(RouteNames.securitySettings));
            },
          ),
          const SizedBox(width: 4),

          // Sign Out Button
          IconButton(
            icon: const Icon(Icons.logout_rounded, size: 20),
            color: AppColors.textSecondaryOf(context),
            tooltip: 'Sign Out',
            onPressed: () {
              unawaited(ref.read(authStateProvider.notifier).signOut());
            },
          ),
        ],
      ),
    );
  }
}
