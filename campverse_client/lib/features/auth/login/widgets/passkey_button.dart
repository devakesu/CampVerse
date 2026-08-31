import 'dart:async';
import 'package:campverse/core/providers/auth_provider.dart';
import 'package:campverse/core/theme/app_colors.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Button initiating device biometric or passkey authentication.
class PasskeyButton extends ConsumerWidget {
  /// Default constructor for PasskeyButton.
  const PasskeyButton({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authStateProvider);

    return OutlinedButton(
      onPressed: authState.isLoading
          ? null
          : () {
              unawaited(
                ref.read(authStateProvider.notifier).signInWithPasskey(),
              );
            },
      child: const Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.fingerprint_rounded, color: AppColors.accent, size: 22),
          SizedBox(width: 10),
          Text(
            'Sign in with Passkey / Biometrics',
            style: TextStyle(
              color: AppColors.textPrimary,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}
