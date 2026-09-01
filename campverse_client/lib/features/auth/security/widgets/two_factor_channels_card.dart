import 'dart:async';
import 'package:campverse/core/providers/auth_provider.dart';
import 'package:campverse/core/theme/app_colors.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Card presenting available Two-Factor Authentication channels and statuses.
class TwoFactorChannelsCard extends ConsumerWidget {
  /// Default constructor for TwoFactorChannelsCard.
  const TwoFactorChannelsCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = AppColors.isDark(context);
    final authState = ref.watch(authStateProvider);
    final userEmail = authState.user?.email ?? 'campus-user@institution.edu';

    final primaryAccent =
        isDark ? const Color(0xFF818CF8) : const Color(0xFF1D4ED8);

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppColors.surfaceOf(context),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.borderOf(context)),
        boxShadow: [
          BoxShadow(
            color: isDark
                ? Colors.black.withValues(alpha: 0.25)
                : Colors.black.withValues(alpha: 0.04),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Header Row
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: primaryAccent.withValues(alpha: isDark ? 0.2 : 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  Icons.shield_outlined,
                  color: primaryAccent,
                  size: 22,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Two-Factor Authentication Channels',
                      style: TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textPrimaryOf(context),
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Manage second-factor verification methods for sign-in.',
                      style: TextStyle(
                        fontSize: 13,
                        color: AppColors.textSecondaryOf(context),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: 20),
          Divider(color: AppColors.borderOf(context), height: 1),
          const SizedBox(height: 16),

          // Channel 1: Authenticator App (TOTP)
          _buildChannelTile(
            context,
            icon: Icons.phonelink_lock_rounded,
            title: 'Authenticator App (TOTP)',
            subtitle:
                'Google Authenticator, Microsoft Authenticator, 1Password',
            statusBadge: 'Recommended',
            badgeColor: AppColors.primary,
            isDark: isDark,
            actionLabel: 'Configure App',
            onAction: () => _showMfaChannelInfoDialog(
              context,
              title: 'Authenticator App (TOTP)',
              description:
                  'TOTP verification requires scanning a QR code with an '
                  'authenticator app. This backend connector will be activated '
                  'in the upcoming backend implementation step.',
            ),
          ),

          const SizedBox(height: 12),

          // Channel 2: SMS Verification
          _buildChannelTile(
            context,
            icon: Icons.sms_outlined,
            title: 'SMS Text Verification',
            subtitle: 'Receive 6-digit security codes via mobile text message',
            statusBadge: 'Backup Channel',
            badgeColor: AppColors.accent,
            isDark: isDark,
            actionLabel: 'Manage Phone',
            onAction: () => _showMfaChannelInfoDialog(
              context,
              title: 'SMS Phone Verification',
              description:
                  'SMS OTP verification sends time-limited codes to your '
                  'registered mobile number. Full SMS gateway routing will be '
                  'connected during the backend integration phase.',
            ),
          ),

          const SizedBox(height: 12),

          // Channel 3: Email OTP
          _buildChannelTile(
            context,
            icon: Icons.email_outlined,
            title: 'Institutional Email OTP',
            subtitle: userEmail,
            statusBadge: 'Active (Default)',
            badgeColor: AppColors.success,
            isDark: isDark,
            actionLabel: 'Settings',
            onAction: () => _showMfaChannelInfoDialog(
              context,
              title: 'Institutional Email OTP',
              description:
                  'Institutional email verification is active by default on '
                  'all campus accounts as an authorized recovery channel.',
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildChannelTile(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String subtitle,
    required String statusBadge,
    required Color badgeColor,
    required bool isDark,
    required String actionLabel,
    required VoidCallback onAction,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.borderOf(context)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: AppColors.surfaceOf(context),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: AppColors.borderOf(context)),
            ),
            child: Icon(icon, size: 20, color: badgeColor),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Flexible(
                      child: Text(
                        title,
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: AppColors.textPrimaryOf(context),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 6,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: badgeColor.withValues(alpha: isDark ? 0.2 : 0.1),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        statusBadge,
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                          color: badgeColor,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 12,
                    color: AppColors.textSecondaryOf(context),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 10),
          OutlinedButton(
            onPressed: onAction,
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: Text(
              actionLabel,
              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }

  void _showMfaChannelInfoDialog(
    BuildContext context, {
    required String title,
    required String description,
  }) {
    unawaited(
      showDialog<void>(
        context: context,
        builder: (ctx) => AlertDialog(
          backgroundColor: AppColors.surfaceOf(ctx),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: Row(
            children: [
              const Icon(
                Icons.info_outline_rounded,
                color: AppColors.primary,
                size: 20,
              ),
              const SizedBox(width: 8),
              Text(
                title,
                style: TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimaryOf(ctx),
                ),
              ),
            ],
          ),
          content: Text(
            description,
            style: TextStyle(
              fontSize: 13,
              height: 1.5,
              color: AppColors.textSecondaryOf(ctx),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(),
              child: const Text('Got it'),
            ),
          ],
        ),
      ),
    );
  }
}
