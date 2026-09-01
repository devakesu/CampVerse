import 'package:campverse/core/providers/auth_provider.dart';
import 'package:campverse/core/providers/theme_provider.dart';
import 'package:campverse/core/theme/app_colors.dart';
import 'package:campverse/features/auth/security/widgets/active_sessions_card.dart';
import 'package:campverse/features/auth/security/widgets/passkey_management_card.dart';
import 'package:campverse/features/auth/security/widgets/security_health_banner.dart';
import 'package:campverse/features/auth/security/widgets/two_factor_channels_card.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

/// Comprehensive 2FA and WebAuthn Passkeys security management page.
/// Universally accessible to all authenticated campus roles.
class SecuritySettingsScreen extends ConsumerWidget {
  /// Default constructor for SecuritySettingsScreen.
  const SecuritySettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authStateProvider);
    final themeMode = ref.watch(themeModeProvider);
    final isDark = AppColors.isDark(context);
    final activeRole = authState.activeRole ?? authState.baseRole;
    final roleColor = AppColors.roleColorOf(context, activeRole);

    final hasPasskeys = authState.userPasskeys.isNotEmpty;

    return Scaffold(
      backgroundColor: AppColors.backgroundOf(context),
      appBar: AppBar(
        backgroundColor: AppColors.surfaceOf(context),
        elevation: 0,
        scrolledUnderElevation: 0,
        leading: IconButton(
          icon: Icon(
            Icons.arrow_back_rounded,
            color: AppColors.textPrimaryOf(context),
          ),
          onPressed: () {
            if (context.canPop()) {
              context.pop();
            } else {
              context.go(activeRole.routeRoot);
            }
          },
          tooltip: 'Back to Workspace',
        ),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: roleColor.withValues(alpha: isDark ? 0.2 : 0.12),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(activeRole.icon, size: 18, color: roleColor),
            ),
            const SizedBox(width: 10),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Security & Authentication',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                    color: AppColors.textPrimaryOf(context),
                  ),
                ),
                Text(
                  '${activeRole.displayName} Account',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: roleColor,
                  ),
                ),
              ],
            ),
          ],
        ),
        actions: [
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
            tooltip: 'Toggle Theme Mode',
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 820),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Page Header Title
                Text(
                  'Account Security & 2FA',
                  style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                        fontWeight: FontWeight.w800,
                        letterSpacing: -0.5,
                        color: AppColors.textPrimaryOf(context),
                      ),
                ),
                const SizedBox(height: 6),
                Text(
                  'Protect your campus credentials, configure WebAuthn '
                  'biometric passkeys, and manage multi-factor authentication.',
                  style: TextStyle(
                    fontSize: 14,
                    color: AppColors.textSecondaryOf(context),
                    height: 1.4,
                  ),
                ),
                const SizedBox(height: 24),

                // Error Message if any
                if (authState.errorMessage != null) ...[
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: AppColors.error.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: AppColors.error.withValues(alpha: 0.35),
                      ),
                    ),
                    child: Row(
                      children: [
                        const Icon(
                          Icons.error_outline_rounded,
                          color: AppColors.error,
                          size: 20,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            authState.errorMessage!,
                            style: const TextStyle(
                              color: AppColors.error,
                              fontSize: 13,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                        IconButton(
                          icon: const Icon(
                            Icons.close_rounded,
                            color: AppColors.error,
                            size: 18,
                          ),
                          onPressed: () {
                            ref.read(authStateProvider.notifier).clearError();
                          },
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),
                ],

                // 1. Security Health Banner
                SecurityHealthBanner(
                  hasPasskeys: hasPasskeys,
                  hasTotp: false,
                ),
                const SizedBox(height: 20),

                // 2. Passkey Management Card (FIDO2 / WebAuthn)
                const PasskeyManagementCard(),
                const SizedBox(height: 20),

                // 3. Two-Factor Channels Card (TOTP, SMS, Email)
                const TwoFactorChannelsCard(),
                const SizedBox(height: 20),

                // 4. Active Sessions Card
                const ActiveSessionsCard(),
                const SizedBox(height: 32),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
