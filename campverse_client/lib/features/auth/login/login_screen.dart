import 'dart:async';

import 'package:campverse/core/config/app_config.dart';
import 'package:campverse/core/providers/auth_provider.dart';
import 'package:campverse/core/providers/theme_provider.dart';
import 'package:campverse/core/theme/app_colors.dart';
import 'package:campverse/core/utils/responsive_layout.dart';
import 'package:campverse/core/widgets/brand_logo.dart';
import 'package:campverse/features/auth/login/widgets/google_sign_in_button.dart';
import 'package:campverse/features/auth/login/widgets/login_form.dart';
import 'package:campverse/features/auth/login/widgets/passkey_button.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';

/// Launches a URL, silently ignoring failures.
Future<void> _launchUrl(String url) async {
  final uri = Uri.parse(url);
  if (await canLaunchUrl(uri)) {
    await launchUrl(uri, mode: LaunchMode.externalApplication);
  }
}

/// Redesigned adaptive login screen supporting credentials and passkeys.
class LoginScreen extends ConsumerWidget {
  /// Default constructor for LoginScreen.
  const LoginScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Show 2-pane split desktop layout on desktop screens
    // (width >= tabletBreakpoint: 1100). On tablets and mobile, use the
    // focused single-column layout.
    final isSplitScreen =
        MediaQuery.of(context).size.width >= ResponsiveLayout.tabletBreakpoint;
    final isDark = AppColors.isDark(context);
    final themeMode = ref.watch(themeModeProvider);

    return Scaffold(
      backgroundColor: AppColors.backgroundOf(context),
      body: Stack(
        children: [
          if (isSplitScreen)
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
          child: DecoratedBox(
            decoration: BoxDecoration(
              color: isDark
                  ? const Color(0xFF0F172A)
                  : const Color(0xFFEEF2FF),
              border: Border(
                right: BorderSide(
                  color: AppColors.borderOf(context),
                  width: 1.2,
                ),
              ),
            ),
            child: Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(
                  horizontal: 48,
                  vertical: 40,
                ),
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 580),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Brand Header
                      const BrandLogo.wide(height: 120),
                      const SizedBox(height: 36),

                      // Center Value Prop & Highlights
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
                        'The all-in-one system engineered for '
                        'modern institutions, seamless event workflows, '
                        'secure operations, and connected campus '
                        'communities.',
                        style: TextStyle(
                          fontSize: 15,
                          height: 1.6,
                          color: AppColors.textSecondaryOf(context),
                        ),
                      ),
                      const SizedBox(height: 32),

                      // Feature highlights list
                      _buildFeatureItem(
                        context,
                        icon: Icons.hub_rounded,
                        title: 'Dedicated Role Workspaces',
                        description:
                            'Tailored dashboards for Principals, HODs, '
                            'Faculty, Unions, Clubs, and Students.',
                      ),
                      const SizedBox(height: 16),
                      _buildFeatureItem(
                        context,
                        icon: Icons.shield_rounded,
                        title: 'Zero-Knowledge Security & Privacy',
                        description:
                            'Field-level encryption, Tamper-proof passes, '
                            'biometric MFA, cryptographically signed records.',
                      ),
                      const SizedBox(height: 16),
                      _buildFeatureItem(
                        context,
                        icon: Icons.devices_rounded,
                        title: 'Adaptive Multiplatform Experience',
                        description:
                            'Consistent high-density operations across web, '
                            'Linux, Windows, macOS, Android & iOS.',
                      ),
                      const SizedBox(height: 48),

                      // Footer attribution & links
                      _buildDesktopFooter(context),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),

        // Right Authentication Form Area
        Expanded(
          flex: 5,
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
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
                const BrandLogo.wide(
                  height: 56,
                  alignment: Alignment.center,
                ),
                const SizedBox(height: 28),

                // Auth Card
                _buildAuthCard(context, ref),

                const SizedBox(height: 24),
                // Footer attribution & links
                _buildMobileFooter(context),
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
    final width = MediaQuery.of(context).size.width;
    final cardHorizontalPadding = width < 360
        ? 14.0
        : (width < 900 ? 20.0 : 30.0);

    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: cardHorizontalPadding,
        vertical: width < 360 ? 20.0 : 30.0,
      ),
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

          // ── Account-not-found banner ───────────────────────────────────────
          if (authState.accountNotFound) ...[
            _buildNoAccountBanner(context),
            const SizedBox(height: 16),
          ],

          // ── Account suspended banner ───────────────────────────────────────
          if (authState.accountSuspended) ...[
            _buildSuspendedBanner(context),
            const SizedBox(height: 16),
          ],

          // ── Generic error banner ───────────────────────────────────────────
          if (!authState.accountNotFound &&
              !authState.accountSuspended &&
              authState.errorMessage != null) ...[
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

          const PasskeyButton(),
          const SizedBox(height: 12),
          const GoogleSignInButton(),

          const SizedBox(height: 18),
          Row(
            children: [
              Expanded(
                child: Divider(color: AppColors.borderOf(context)),
              ),
              Flexible(
                flex: 3,
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Text(
                      'OR CONTINUE WITH PASSWORD',
                      maxLines: 1,
                      style: TextStyle(
                        color: AppColors.textMutedOf(context),
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ),
                ),
              ),
              Expanded(
                child: Divider(color: AppColors.borderOf(context)),
              ),
            ],
          ),

          const SizedBox(height: 18),

          const LoginForm(),
        ],
      ),
    );
  }

  // ── Institutional Contact Banners ─────────────────────────────────────────

  /// Banner shown when no institutional profile was found for the credential.
  Widget _buildNoAccountBanner(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFF3B82F6).withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: const Color(0xFF3B82F6).withValues(alpha: 0.3),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(
            Icons.info_outline_rounded,
            color: Color(0xFF3B82F6),
            size: 18,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: RichText(
              text: TextSpan(
                style: const TextStyle(
                  fontSize: 13,
                  height: 1.5,
                  color: Color(0xFF3B82F6),
                  fontWeight: FontWeight.w500,
                ),
                children: [
                  const TextSpan(
                    text:
                        "No account found. If you're a student or faculty, "
                        'contact your institution admin. '
                        'Otherwise, ',
                  ),
                  TextSpan(
                    text: 'Contact Us →',
                    style: const TextStyle(
                      fontWeight: FontWeight.w700,
                      decoration: TextDecoration.underline,
                    ),
                    recognizer: TapGestureRecognizer()
                      ..onTap = () => unawaited(
                        _launchUrl(AppConfig.contactUsUrl),
                      ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Banner shown when the account has been suspended by an administrator.
  Widget _buildSuspendedBanner(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.amber.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Colors.amber.withValues(alpha: 0.4),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(
            Icons.block_rounded,
            color: Colors.amber,
            size: 18,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: RichText(
              text: TextSpan(
                style: const TextStyle(
                  fontSize: 13,
                  height: 1.5,
                  color: Colors.amber,
                  fontWeight: FontWeight.w500,
                ),
                children: [
                  const TextSpan(
                    text:
                        'Your account has been suspended. '
                        'Please contact your institution admin or ',
                  ),
                  TextSpan(
                    text: 'reach out to us →',
                    style: const TextStyle(
                      fontWeight: FontWeight.w700,
                      decoration: TextDecoration.underline,
                    ),
                    recognizer: TapGestureRecognizer()
                      ..onTap = () => unawaited(
                        _launchUrl(AppConfig.contactUsUrl),
                      ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── Shared UI Helpers ─────────────────────────────────────────────────────

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

  Widget _buildVersionBadge(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
      decoration: BoxDecoration(
        color: AppColors.primaryOf(context).withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(
          color: AppColors.primaryOf(context).withValues(alpha: 0.22),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.sell_outlined,
            size: 11,
            color: AppColors.primaryOf(context),
          ),
          const SizedBox(width: 4),
          Text(
            'v${AppConfig.appVersion}',
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: AppColors.primaryOf(context),
              letterSpacing: 0.2,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSeparator(BuildContext context) {
    return Text(
      '•',
      style: TextStyle(
        fontSize: 12,
        color: AppColors.textMutedOf(context).withValues(alpha: 0.5),
      ),
    );
  }

  Widget _buildMadeWithSection(
    BuildContext context, {
    WrapAlignment alignment = WrapAlignment.center,
  }) {
    return Wrap(
      alignment: alignment,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        Text(
          'Made with ',
          style: TextStyle(
            fontSize: 12,
            color: AppColors.textMutedOf(context),
          ),
        ),
        const Icon(
          Icons.favorite_rounded,
          size: 14,
          color: Colors.redAccent,
        ),
        Text(
          ' by ',
          style: TextStyle(
            fontSize: 12,
            color: AppColors.textMutedOf(context),
          ),
        ),
        MouseRegion(
          cursor: SystemMouseCursors.click,
          child: GestureDetector(
            onTap: () => unawaited(_launchUrl('https://devakesu.com')),
            child: Text(
              '@devakesu',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: AppColors.primaryOf(context),
                decoration: TextDecoration.underline,
                decorationColor: AppColors.primaryOf(context)
                    .withValues(alpha: 0.5),
              ),
            ),
          ),
        ),
      ],
    );
  }

  /// A footer link that opens a URL directly (or a placeholder dialog
  /// if empty).
  Widget _buildFooterLink(
    BuildContext context, {
    required IconData icon,
    required String label,
    String? url,
    String? placeholderDialogTitle,
  }) {
    Future<void> onTap() async {
      if (url != null && url.isNotEmpty) {
        await _launchUrl(url);
        return;
      }
      // Fallback placeholder dialog
      await showDialog<void>(
        context: context,
        builder: (ctx) => AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          backgroundColor: AppColors.surfaceOf(ctx),
          title: Row(
            children: [
              Icon(icon, size: 20, color: AppColors.primaryOf(ctx)),
              const SizedBox(width: 8),
              Text(
                placeholderDialogTitle ?? label,
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimaryOf(ctx),
                ),
              ),
            ],
          ),
          content: Text(
            '${placeholderDialogTitle ?? label} documentation is currently '
            'being finalized. Please check back in an upcoming release.',
            style: TextStyle(
              fontSize: 13,
              height: 1.5,
              color: AppColors.textSecondaryOf(ctx),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(),
              child: const Text('Close'),
            ),
          ],
        ),
      );
    }

    return MouseRegion(
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                icon,
                size: 13,
                color: AppColors.textMutedOf(context),
              ),
              const SizedBox(width: 4),
              Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  color: AppColors.textMutedOf(context),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDesktopFooter(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        _buildVersionBadge(context),
        Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          mainAxisSize: MainAxisSize.min,
          children: [
            Wrap(
              alignment: WrapAlignment.end,
              crossAxisAlignment: WrapCrossAlignment.center,
              spacing: 4,
              runSpacing: 4,
              children: [
                _buildFooterLink(
                  context,
                  icon: Icons.description_outlined,
                  label: 'Terms',
                  placeholderDialogTitle: 'Terms of Service',
                ),
                _buildSeparator(context),
                _buildFooterLink(
                  context,
                  icon: Icons.privacy_tip_outlined,
                  label: 'Privacy',
                  placeholderDialogTitle: 'Privacy Policy',
                ),
                _buildSeparator(context),
                _buildFooterLink(
                  context,
                  icon: Icons.support_agent_rounded,
                  label: 'Contact Us',
                  url: AppConfig.contactUsUrl,
                ),
              ],
            ),
            const SizedBox(height: 8),
            _buildMadeWithSection(
              context,
              alignment: WrapAlignment.end,
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildMobileFooter(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        _buildVersionBadge(context),
        const SizedBox(height: 10),
        Wrap(
          alignment: WrapAlignment.center,
          crossAxisAlignment: WrapCrossAlignment.center,
          spacing: 6,
          runSpacing: 4,
          children: [
            _buildFooterLink(
              context,
              icon: Icons.description_outlined,
              label: 'Terms',
              placeholderDialogTitle: 'Terms of Service',
            ),
            _buildSeparator(context),
            _buildFooterLink(
              context,
              icon: Icons.privacy_tip_outlined,
              label: 'Privacy',
              placeholderDialogTitle: 'Privacy Policy',
            ),
            _buildSeparator(context),
            _buildFooterLink(
              context,
              icon: Icons.support_agent_rounded,
              label: 'Contact Us',
              url: AppConfig.contactUsUrl,
            ),
          ],
        ),
        const SizedBox(height: 8),
        _buildMadeWithSection(context),
      ],
    );
  }
}
