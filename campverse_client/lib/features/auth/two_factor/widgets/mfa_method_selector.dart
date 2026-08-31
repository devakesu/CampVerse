import 'package:campverse/core/theme/app_colors.dart';
import 'package:flutter/material.dart';

/// Supported two-factor authentication verification channels.
enum MfaMethod {
  /// Time-based One-Time Password authenticator app.
  totp(
    'Authenticator App',
    'Use Google Authenticator, 1Password, or Authy',
    Icons.phonelink_lock_rounded,
  ),

  /// Email-delivered verification code.
  email(
    'Email OTP',
    'Send a 6-digit verification code to institutional email',
    Icons.mail_outline_rounded,
  ),

  /// SMS-delivered verification code.
  sms(
    'SMS OTP',
    'Send verification code to registered mobile number',
    Icons.sms_outlined,
  );

  const MfaMethod(this.title, this.subtitle, this.icon);

  /// User-facing method title.
  final String title;

  /// Explanatory guidance text.
  final String subtitle;

  /// Visual icon for the method.
  final IconData icon;
}

/// Selector card widget allowing user to switch MFA verification channels.
class MfaMethodSelector extends StatelessWidget {
  /// Default constructor for MfaMethodSelector.
  const MfaMethodSelector({
    required this.selectedMethod,
    required this.onMethodChanged,
    super.key,
  });

  /// The currently selected verification method.
  final MfaMethod selectedMethod;

  /// Callback when a different method is chosen.
  final ValueChanged<MfaMethod> onMethodChanged;

  @override
  Widget build(BuildContext context) {
    final isDark = AppColors.isDark(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: MfaMethod.values.map((method) {
        final isSelected = method == selectedMethod;
        return Padding(
          padding: const EdgeInsets.only(bottom: 10),
          child: InkWell(
            onTap: () => onMethodChanged(method),
            borderRadius: BorderRadius.circular(14),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              decoration: BoxDecoration(
                color: isSelected
                    ? AppColors.primary.withValues(alpha: isDark ? 0.16 : 0.1)
                    : AppColors.surfaceElevatedOf(context),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: isSelected
                      ? AppColors.primary
                      : AppColors.borderOf(context),
                  width: isSelected ? 1.5 : 1,
                ),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? AppColors.primary.withValues(
                              alpha: isDark ? 0.25 : 0.15,
                            )
                          : AppColors.surfaceOf(context),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(
                      method.icon,
                      color: isSelected
                          ? AppColors.primary
                          : AppColors.textSecondaryOf(context),
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          method.title,
                          style: TextStyle(
                            color: AppColors.textPrimaryOf(context),
                            fontWeight:
                                isSelected ? FontWeight.w700 : FontWeight.w500,
                            fontSize: 14,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          method.subtitle,
                          style: TextStyle(
                            color: AppColors.textSecondaryOf(context),
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (isSelected)
                    const Icon(
                      Icons.check_circle_rounded,
                      color: AppColors.primary,
                      size: 20,
                    ),
                ],
              ),
            ),
          ),
        );
      }).toList(),
    );
  }
}
