import 'dart:async';
import 'package:campverse/core/providers/auth_provider.dart';
import 'package:campverse/core/theme/app_colors.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Interactive button initiating WebAuthn biometric or passkey authentication.
class PasskeyButton extends ConsumerStatefulWidget {
  /// Default constructor for PasskeyButton.
  const PasskeyButton({super.key});

  @override
  ConsumerState<PasskeyButton> createState() => _PasskeyButtonState();
}

class _PasskeyButtonState extends ConsumerState<PasskeyButton> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authStateProvider);
    final isDark = AppColors.isDark(context);
    final isLoading = authState.isLoading;

    final primaryAccent =
        isDark ? const Color(0xFF818CF8) : const Color(0xFF1D4ED8);

    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      cursor:
          isLoading ? SystemMouseCursors.basic : SystemMouseCursors.click,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 160),
        decoration: BoxDecoration(
          color: _isHovered
              ? (isDark ? const Color(0xFF1E293B) : const Color(0xFFEEF2FF))
              : AppColors.surfaceOf(context),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: _isHovered
                ? primaryAccent
                : AppColors.borderOf(context),
            width: _isHovered ? 1.5 : 1.2,
          ),
          boxShadow: [
            if (_isHovered)
              BoxShadow(
                color: primaryAccent.withValues(alpha: isDark ? 0.25 : 0.12),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
          ],
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            borderRadius: BorderRadius.circular(14),
            onTap: isLoading
                ? null
                : () {
                    unawaited(
                      ref.read(authStateProvider.notifier).signInWithPasskey(),
                    );
                  },
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  if (isLoading) ...[
                    SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2.2,
                        color: primaryAccent,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Text(
                      'Verifying Passkey...',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textPrimaryOf(context),
                      ),
                    ),
                  ] else ...[
                    Container(
                      padding: const EdgeInsets.all(4),
                      decoration: BoxDecoration(
                        color: primaryAccent.withValues(
                          alpha: isDark ? 0.2 : 0.1,
                        ),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(
                        Icons.fingerprint_rounded,
                        color: primaryAccent,
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Text(
                      'Sign in with Passkey / Biometrics',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textPrimaryOf(context),
                        letterSpacing: -0.2,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
