import 'package:campverse/core/theme/app_colors.dart';
import 'package:flutter/material.dart';

/// Banner highlighting the overall security strength and protection score.
class SecurityHealthBanner extends StatelessWidget {
  /// Default constructor for SecurityHealthBanner.
  const SecurityHealthBanner({
    required this.hasPasskeys,
    required this.hasTotp,
    super.key,
  });

  /// Whether the user has at least one registered passkey.
  final bool hasPasskeys;

  /// Whether the user has TOTP authenticator enabled.
  final bool hasTotp;

  @override
  Widget build(BuildContext context) {
    final isDark = AppColors.isDark(context);

    final isHighSecurity = hasPasskeys || hasTotp;
    final scoreTitle = isHighSecurity
        ? 'High Security Protected'
        : 'Basic Security (Action Recommended)';
    final scoreDescription = isHighSecurity
        ? 'Your account is fortified with multi-factor authentication '
            'and phishing-resistant hardware credentials.'
        : 'Protect your campus identity from credential theft by registering '
            'a biometric Passkey or Authenticator app.';

    final badgeColor = isHighSecurity ? AppColors.success : AppColors.warning;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF131D2F) : const Color(0xFFEFF6FF),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark
              ? const Color(0xFF1E3A8A).withValues(alpha: 0.6)
              : const Color(0xFFBFDBFE),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: badgeColor.withValues(alpha: isDark ? 0.2 : 0.12),
              shape: BoxShape.circle,
            ),
            child: Icon(
              isHighSecurity
                  ? Icons.verified_user_rounded
                  : Icons.gpp_maybe_rounded,
              color: badgeColor,
              size: 26,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Flexible(
                      child: Text(
                        scoreTitle,
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: AppColors.textPrimaryOf(context),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 3,
                      ),
                      decoration: BoxDecoration(
                        color:
                            badgeColor.withValues(alpha: isDark ? 0.25 : 0.15),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        isHighSecurity ? 'STRONG' : 'RECOMMENDED',
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w800,
                          color: badgeColor,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Text(
                  scoreDescription,
                  style: TextStyle(
                    fontSize: 13,
                    height: 1.45,
                    color: AppColors.textSecondaryOf(context),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
