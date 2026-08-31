import 'dart:async';
import 'package:campverse/core/providers/auth_provider.dart';
import 'package:campverse/core/theme/app_colors.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pinput/pinput.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Pin input widget for Email and SMS OTP verification.
class EmailOtpInput extends ConsumerStatefulWidget {
  /// Default constructor for EmailOtpInput.
  const EmailOtpInput({
    required this.isSms,
    super.key,
  });

  /// True if SMS channel is used, false for email.
  final bool isSms;

  @override
  ConsumerState<EmailOtpInput> createState() => _EmailOtpInputState();
}

class _EmailOtpInputState extends ConsumerState<EmailOtpInput> {
  final _pinController = TextEditingController();
  final _focusNode = FocusNode();
  int _countdown = 45;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _startCountdown();
  }

  void _startCountdown() {
    setState(() => _countdown = 45);
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_countdown > 0) {
        setState(() => _countdown--);
      } else {
        timer.cancel();
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    _pinController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  Future<void> _submit(String pin) async {
    if (pin.length != 6) {
      return;
    }

    final authState = ref.read(authStateProvider);
    final destination = widget.isSms
        ? (authState.user?.phone ?? '')
        : (authState.user?.email ?? '');

    await ref.read(authStateProvider.notifier).verifyEmailOrSmsOtp(
          emailOrPhone: destination,
          code: pin,
          type: widget.isSms ? OtpType.sms : OtpType.email,
        );
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authStateProvider);
    final destination = widget.isSms
        ? (authState.user?.phone ?? 'registered phone')
        : (authState.user?.email ?? 'registered institutional email');

    final defaultPinTheme = PinTheme(
      width: 52,
      height: 56,
      textStyle: TextStyle(
        fontSize: 22,
        fontWeight: FontWeight.w700,
        color: AppColors.textPrimaryOf(context),
      ),
      decoration: BoxDecoration(
        color: AppColors.surfaceElevatedOf(context),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.borderOf(context)),
      ),
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          'A 6-digit code has been sent to $destination.',
          style: TextStyle(
            color: AppColors.textSecondaryOf(context),
            fontSize: 13,
          ),
        ),
        const SizedBox(height: 20),
        Center(
          child: Pinput(
            controller: _pinController,
            focusNode: _focusNode,
            length: 6,
            defaultPinTheme: defaultPinTheme,
            autofocus: true,
            onCompleted: _submit,
          ),
        ),
        const SizedBox(height: 18),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              "Didn't receive code? ",
              style: TextStyle(
                color: AppColors.textSecondaryOf(context),
                fontSize: 13,
              ),
            ),
            if (_countdown > 0)
              Text(
                'Resend in ${_countdown}s',
                style: TextStyle(
                  color: AppColors.textMutedOf(context),
                  fontSize: 13,
                ),
              )
            else
              TextButton(
                onPressed: () {
                  _startCountdown();
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('A fresh code was sent to $destination'),
                    ),
                  );
                },
                child: const Text(
                  'Resend Code',
                  style: TextStyle(
                    color: AppColors.primary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
          ],
        ),
        const SizedBox(height: 16),
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
              : const Text('Verify Code'),
        ),
      ],
    );
  }
}
