import 'package:campverse/core/providers/auth_provider.dart';
import 'package:campverse/core/providers/theme_provider.dart';
import 'package:campverse/core/theme/app_colors.dart';
import 'package:campverse/core/utils/responsive_layout.dart';
import 'package:campverse/features/auth/login/widgets/login_form.dart';
import 'package:campverse/features/auth/login/widgets/passkey_button.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Redesigned adaptive login screen supporting credentials and passkeys.
class LoginScreen extends ConsumerWidget {
  /// Default constructor for LoginScreen.
  const LoginScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDesktop = ResponsiveLayout.isDesktop(context);
    final isDark = AppColors.isDark(context);
    final themeMode = ref.watch(themeModeProvider);

    return Scaffold(
      backgroundColor: AppColors.backgroundOf(context),
      body: Stack(
        children: [
          if (isDesktop)
            _buildDesktopLayout(context, ref)
          else
            _buildMobileLayout(context, ref),

          // Top right theme switcher
          Positioned(
            top: 20,
            right: 20,
            child: SafeArea(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  color: AppColors.surfaceOf(context),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.borderOf(context)),
                  boxShadow: [
                    BoxShadow(
                      color: isDark
                          ? Colors.black.withValues(alpha: 0.2)
                          : Colors.black.withValues(alpha: 0.05),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: IconButton(
                  icon: Icon(
                    themeMode == ThemeMode.dark
                        ? Icons.light_mode_rounded
                        : Icons.dark_mode_rounded,
                    size: 20,
                    color: AppColors.textSecondaryOf(context),
                  ),
                  tooltip: 'Toggle Theme',
                  onPressed: () {
                    ref.read(themeModeProvider.notifier).toggleTheme();
                  },
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Desktop split layout: Left brand showcase + Right authentication card.
  Widget _buildDesktopLayout(BuildContext context, WidgetRef ref) {
    final isDark = AppColors.isDark(context);

    return Row(
      children: [
        // Left Branding & Metrics Panel
        Expanded(
          flex: 5,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 48, vertical: 48),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF0F172A) : const Color(0xFFEEF2FF),
              border: Border(
                right: BorderSide(
                  color: AppColors.borderOf(context),
                  width: 1.2,
                ),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                // Brand Header
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        gradient: AppColors.primaryGradient,
                        borderRadius: BorderRadius.circular(14),
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.primary.withValues(alpha: 0.35),
                            blurRadius: 16,
                            offset: const Offset(0, 6),
                          ),
                        ],
                      ),
                      child: const Icon(
                        Icons.school_rounded,
                        size: 28,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'CampVerse',
                          style: Theme.of(context)
                              .textTheme
                              .headlineMedium
                              ?.copyWith(
                                fontWeight: FontWeight.w800,
                                letterSpacing: -0.5,
                              ),
                        ),
                        const Text(
                          'Campus Operating Ecosystem',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: AppColors.primary,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),

                // Center Value Prop & Highlights
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Unified Campus Life,\nAcademics & Governance',
                      style: Theme.of(context)
                          .textTheme
                          .displayMedium
                          ?.copyWith(
                            fontWeight: FontWeight.w800,
                            height: 1.2,
                            letterSpacing: -1,
                          ),
                    ),
                    const SizedBox(height: 18),
                    Text(
                      'Empowering universities, institutes, departments, '
                      'faculty, and students with role-tailored workspaces and '
                      'real-time collaboration.',
                      style: TextStyle(
                        fontSize: 15,
                        height: 1.6,
                        color: AppColors.textSecondaryOf(context),
                      ),
                    ),
                    const SizedBox(height: 36),

                    // Feature highlights list
                    _buildFeatureItem(
                      context,
                      icon: Icons.hub_rounded,
                      title: '8 Dedicated Role Workspaces',
                      description:
                          'Tailored dashboards for Super Admin, Principals, '
                          'HODs, Faculty, Unions, Clubs, and Students.',
                    ),
                    const SizedBox(height: 16),
                    _buildFeatureItem(
                      context,
                      icon: Icons.shield_rounded,
                      title: 'Hardware Passkeys & MFA',
                      description:
                          'Enterprise WebAuthn biometrics, TOTP '
                          'verification, and Row-Level Security isolation.',
                    ),
                    const SizedBox(height: 16),
                    _buildFeatureItem(
                      context,
                      icon: Icons.devices_rounded,
                      title: 'Adaptive Multiplatform Experience',
                      description:
                          'Consistent high-density operations across desktop '
                          'web, Linux, Windows, macOS, iOS, and Android.',
                    ),
                  ],
                ),

                // Footer legal / security info
                Row(
                  children: [
                    Icon(
                      Icons.lock_clock_rounded,
                      size: 16,
                      color: AppColors.textMutedOf(context),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'CampVerse Enterprise OS v1.0 • AES-256 FLE Enforced',
                      style: TextStyle(
                        fontSize: 12,
                        color: AppColors.textMutedOf(context),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),

        // Right Authentication Form Area
        Expanded(
          flex: 5,
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 48, vertical: 32),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 440),
                child: _buildAuthCard(context, ref),
              ),
            ),
          ),
        ),
      ],
    );
  }

  /// Mobile layout: Centered card with top brand mark.
  Widget _buildMobileLayout(BuildContext context, WidgetRef ref) {
    return SafeArea(
      child: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 420),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Mobile Brand Header
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    gradient: AppColors.primaryGradient,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.primary.withValues(alpha: 0.3),
                        blurRadius: 18,
                        offset: const Offset(0, 6),
                      ),
                    ],
                  ),
                  child: const Icon(
                    Icons.school_rounded,
                    size: 32,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  'CampVerse',
                  style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                        fontWeight: FontWeight.w800,
                        letterSpacing: -0.5,
                      ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Campus Operating Ecosystem',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                    color: AppColors.textSecondaryOf(context),
                  ),
                ),
                const SizedBox(height: 28),

                // Auth Card
                _buildAuthCard(context, ref),

                const SizedBox(height: 24),
                // Security indicator footer
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.shield_outlined,
                      size: 15,
                      color: AppColors.textMutedOf(context),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      'Secured with Passkey & Role Guard',
                      style: TextStyle(
                        color: AppColors.textMutedOf(context),
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// Core authentication card containing credentials form and passkey button.
  Widget _buildAuthCard(BuildContext context, WidgetRef ref) {
    final isDark = AppColors.isDark(context);
    final authState = ref.watch(authStateProvider);

    return Container(
      padding: const EdgeInsets.all(30),
      decoration: BoxDecoration(
        color: AppColors.surfaceOf(context),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.borderOf(context)),
        boxShadow: [
          BoxShadow(
            color: isDark
                ? Colors.black.withValues(alpha: 0.3)
                : Colors.black.withValues(alpha: 0.06),
            blurRadius: 24,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'Sign In',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.w800,
                  fontSize: 22,
                ),
          ),
          const SizedBox(height: 6),
          Text(
            'Enter your credentials or use your registered passkey.',
            style: TextStyle(
              fontSize: 13,
              color: AppColors.textSecondaryOf(context),
            ),
          ),
          const SizedBox(height: 24),

          // Error message banner if any
          if (authState.errorMessage != null) ...[
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.error.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color: AppColors.error.withValues(alpha: 0.35),
                ),
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.error_outline_rounded,
                    color: AppColors.error,
                    size: 18,
                  ),
                  const SizedBox(width: 10),
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
                ],
              ),
            ),
            const SizedBox(height: 20),
          ],

          const LoginForm(),

          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(
                child: Divider(color: AppColors.borderOf(context)),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                child: Text(
                  'OR',
                  style: TextStyle(
                    color: AppColors.textMutedOf(context),
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              Expanded(
                child: Divider(color: AppColors.borderOf(context)),
              ),
            ],
          ),
          const SizedBox(height: 20),
          const PasskeyButton(),
        ],
      ),
    );
  }

  Widget _buildFeatureItem(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String description,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: AppColors.primary.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, size: 20, color: AppColors.primary),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimaryOf(context),
                ),
              ),
              const SizedBox(height: 2),
              Text(
                description,
                style: TextStyle(
                  fontSize: 13,
                  color: AppColors.textSecondaryOf(context),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
