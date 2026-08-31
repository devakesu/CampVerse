import 'dart:async';
import 'package:campverse/core/models/app_role.dart';
import 'package:campverse/core/providers/auth_provider.dart';
import 'package:campverse/core/providers/theme_provider.dart';
import 'package:campverse/core/theme/app_colors.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Mobile slide-out drawer providing secondary workspace tools and role
/// switching.
class AdaptiveDrawer extends ConsumerWidget {
  /// Default constructor for AdaptiveDrawer.
  const AdaptiveDrawer({
    required this.role,
    super.key,
  });

  /// The active workspace role.
  final AppRole role;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = AppColors.isDark(context);
    final themeMode = ref.watch(themeModeProvider);
    final authState = ref.watch(authStateProvider);
    final user = authState.user;
    final roleColor = AppColors.roleColorOf(context, role);

    final userName = (user?.userMetadata?['full_name'] as String?) ??
        (user?.email?.split('@').first ?? 'Campus User');

    return Drawer(
      backgroundColor: AppColors.surfaceOf(context),
      child: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Header: User & Role profile
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: roleColor.withValues(alpha: isDark ? 0.12 : 0.06),
                border: Border(
                  bottom: BorderSide(
                    color: AppColors.borderOf(context),
                  ),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          gradient: AppColors.primaryGradient,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(
                          Icons.school_rounded,
                          size: 24,
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
                                .titleMedium
                                ?.copyWith(
                                  fontWeight: FontWeight.w800,
                                ),
                          ),
                          Text(
                            'Campus Ecosystem',
                            style: TextStyle(
                              fontSize: 11,
                              color: AppColors.textSecondaryOf(context),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 18),
                  Text(
                    userName,
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textPrimaryOf(context),
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    user?.email ?? '',
                    style: TextStyle(
                      fontSize: 12,
                      color: AppColors.textSecondaryOf(context),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 5,
                    ),
                    decoration: BoxDecoration(
                      color: roleColor.withValues(alpha: isDark ? 0.2 : 0.12),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: roleColor.withValues(alpha: isDark ? 0.4 : 0.3),
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(role.icon, size: 14, color: roleColor),
                        const SizedBox(width: 6),
                        Text(
                          role.displayName,
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: roleColor,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            // Role Switcher Section (if user has multiple roles)
            if (authState.hasMultipleRoles) ...[
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                child: Text(
                  'SWITCH ROLE',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.8,
                    color: AppColors.textMutedOf(context),
                  ),
                ),
              ),
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  children: authState.availableRoles.map((r) {
                    final isCurrent = r == role;
                    final rColor = AppColors.roleColorOf(context, r);
                    return ListTile(
                      dense: true,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                      tileColor: isCurrent
                          ? rColor.withValues(alpha: isDark ? 0.15 : 0.1)
                          : null,
                      leading: Icon(
                        r.icon,
                        color: isCurrent
                            ? rColor
                            : AppColors.textSecondaryOf(context),
                        size: 20,
                      ),
                      title: Text(
                        r.displayName,
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight:
                              isCurrent ? FontWeight.w700 : FontWeight.w500,
                          color: isCurrent
                              ? rColor
                              : AppColors.textPrimaryOf(context),
                        ),
                      ),
                      trailing: isCurrent
                          ? Icon(
                              Icons.check_circle_rounded,
                              size: 16,
                              color: rColor,
                            )
                          : null,
                      onTap: () {
                        Navigator.of(context).pop();
                        if (!isCurrent) {
                          unawaited(
                            ref
                                .read(authStateProvider.notifier)
                                .switchRole(r),
                          );
                        }
                      },
                    );
                  }).toList(),
                ),
              ),
            ] else ...[
              const Spacer(),
            ],

            // Footer Tools
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                border: Border(
                  top: BorderSide(
                    color: AppColors.borderOf(context),
                  ),
                ),
              ),
              child: Column(
                children: [
                  ListTile(
                    dense: true,
                    leading: Icon(
                      themeMode == ThemeMode.dark
                          ? Icons.light_mode_rounded
                          : Icons.dark_mode_rounded,
                      color: AppColors.textSecondaryOf(context),
                    ),
                    title: Text(
                      themeMode == ThemeMode.dark ? 'Light Mode' : 'Dark Mode',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textPrimaryOf(context),
                      ),
                    ),
                    onTap: () {
                      ref.read(themeModeProvider.notifier).toggleTheme();
                    },
                  ),
                  ListTile(
                    dense: true,
                    leading: const Icon(
                      Icons.logout_rounded,
                      color: AppColors.error,
                    ),
                    title: const Text(
                      'Sign Out',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: AppColors.error,
                      ),
                    ),
                    onTap: () {
                      Navigator.of(context).pop();
                      unawaited(
                        ref.read(authStateProvider.notifier).signOut(),
                      );
                    },
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
