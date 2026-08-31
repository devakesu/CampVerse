import 'package:campverse/core/providers/auth_provider.dart';
import 'package:campverse/core/theme/app_colors.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pinput/pinput.dart';

/// Pin input widget for Time-based One-Time Password verification.
class TotpInput extends ConsumerStatefulWidget {
  /// Default constructor for TotpInput.
  const TotpInput({super.key});

  @override
  ConsumerState<TotpInput> createState() => _TotpInputState();
}

class _TotpInputState extends ConsumerState<TotpInput> {
  final _pinController = TextEditingController();
  final _focusNode = FocusNode();

  @override
  void dispose() {
    _pinController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  Future<void> _submit(String pin) async {
    if (pin.length != 6) {
      return;
    }

    final authService = ref.read(supabaseAuthServiceProvider);
    final factors = await authService.getEnrolledMfaFactors();
    final factorId = factors.isNotEmpty ? factors.first.id : 'default_factor';

    await ref.read(authStateProvider.notifier).verifyTotp(
          factorId: factorId,
          code: pin,
        );
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authStateProvider);

    final defaultPinTheme = PinTheme(
      width: 52,
      height: 56,
      textStyle: const TextStyle(
        fontSize: 22,
        fontWeight: FontWeight.w700,
        color: AppColors.textPrimary,
      ),
      decoration: BoxDecoration(
        color: AppColors.surfaceElevated,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.surfaceBorder),
      ),
    );

    final focusedPinTheme = defaultPinTheme.copyWith(
      decoration: BoxDecoration(
        color: AppColors.surfaceElevated,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.primary, width: 2),
      ),
    );

    final errorPinTheme = defaultPinTheme.copyWith(
      decoration: BoxDecoration(
        color: AppColors.surfaceElevated,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.error, width: 1.5),
      ),
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Text(
          'Enter the 6-digit code from your authenticator app:',
          style: TextStyle(color: AppColors.textSecondary, fontSize: 13),
        ),
        const SizedBox(height: 20),
        Center(
          child: Pinput(
            controller: _pinController,
            focusNode: _focusNode,
            length: 6,
            defaultPinTheme: defaultPinTheme,
            focusedPinTheme: focusedPinTheme,
            errorPinTheme: errorPinTheme,
            autofocus: true,
            onCompleted: _submit,
          ),
        ),
        const SizedBox(height: 24),
        ElevatedButton(
          onPressed:
              authState.isLoading ? null : () => _submit(_pinController.text),
          child: authState.isLoading
              ? const SizedBox(
                  height: 20,
                  width: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Colors.white,
                  ),
                )
              : const Text('Verify & Proceed'),
        ),
      ],
    );
  }
}
