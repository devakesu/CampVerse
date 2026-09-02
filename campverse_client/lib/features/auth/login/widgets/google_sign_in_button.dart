import 'dart:async';
import 'package:campverse/core/config/app_config.dart';
import 'package:campverse/core/models/auth_user.dart';
import 'package:campverse/core/providers/auth_provider.dart';
import 'package:campverse/core/theme/app_colors.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Cross-platform button initiating Google Sign-In (OAuth / Native ID token).
class GoogleSignInButton extends ConsumerStatefulWidget {
  /// Default constructor for GoogleSignInButton.
  const GoogleSignInButton({super.key});

  @override
  ConsumerState<GoogleSignInButton> createState() => _GoogleSignInButtonState();
}

class _GoogleSignInButtonState extends ConsumerState<GoogleSignInButton> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authStateProvider);
    final isDark = AppColors.isDark(context);
    final isGoogleLoading =
        authState.isLoading &&
        authState.loadingAction == AuthLoadingAction.google;
    final isAnyLoading = authState.isLoading;

    final hoverBorder =
        isDark ? const Color(0xFF4285F4) : const Color(0xFF2563EB);

    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      cursor:
          isAnyLoading ? SystemMouseCursors.basic : SystemMouseCursors.click,
      child: Opacity(
        opacity: isAnyLoading && !isGoogleLoading ? 0.55 : 1.0,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 160),
          decoration: BoxDecoration(
            color: _isHovered && !isAnyLoading
                ? (isDark ? const Color(0xFF1E293B) : const Color(0xFFF8FAFC))
                : AppColors.surfaceOf(context),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: _isHovered && !isAnyLoading
                  ? hoverBorder
                  : AppColors.borderOf(context),
              width: _isHovered && !isAnyLoading ? 1.4 : 1.2,
            ),
            boxShadow: [
              if (_isHovered && !isAnyLoading)
                BoxShadow(
                  color: hoverBorder.withValues(alpha: isDark ? 0.25 : 0.1),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
            ],
          ),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              borderRadius: BorderRadius.circular(14),
              onTap: isAnyLoading
                  ? null
                  : () {
                      unawaited(
                        ref.read(authStateProvider.notifier).signInWithGoogle(
                          webClientId: AppConfig.googleWebClientId.isNotEmpty
                              ? AppConfig.googleWebClientId
                              : null,
                          iosClientId: AppConfig.googleIosClientId.isNotEmpty
                              ? AppConfig.googleIosClientId
                              : null,
                        ),
                      );
                    },
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 14,
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    if (isGoogleLoading) ...[
                      const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2.2,
                          color: Color(0xFF4285F4),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Text(
                        'Connecting with Google...',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textPrimaryOf(context),
                        ),
                      ),
                    ] else ...[
                      const _GoogleIcon(),
                      const SizedBox(width: 12),
                      Flexible(
                        child: Text(
                          'Continue with Google',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                            color: AppColors.textPrimaryOf(context),
                            letterSpacing: -0.1,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}


class _GoogleIcon extends StatelessWidget {
  const _GoogleIcon();

  @override
  Widget build(BuildContext context) {
    return const SizedBox(
      width: 20,
      height: 20,
      child: CustomPaint(
        painter: _GoogleLogoPainter(),
      ),
    );
  }
}

class _GoogleLogoPainter extends CustomPainter {
  const _GoogleLogoPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    final cx = w / 2;
    final cy = h / 2;
    final radius = w / 2;
    final stroke = w * 0.22;

    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = stroke
      ..strokeCap = StrokeCap.square;

    final rect = Rect.fromCircle(
      center: Offset(cx, cy),
      radius: radius - stroke / 2,
    );

    // Red top arc: 225° to 315°
    paint.color = const Color(0xFFEA4335);
    canvas.drawArc(rect, -2.356, 1.571, false, paint);

    // Yellow left arc: 135° to 225°
    paint.color = const Color(0xFFFBBC05);
    canvas.drawArc(rect, 2.356, 1.571, false, paint);

    // Green bottom arc: 45° to 135°
    paint.color = const Color(0xFF34A853);
    canvas.drawArc(rect, 0.785, 1.571, false, paint);

    // Blue right arc: -45° to 45°
    paint.color = const Color(0xFF4285F4);
    canvas.drawArc(rect, -0.785, 1.571, false, paint);

    // Blue horizontal connector bar
    final barPaint = Paint()
      ..color = const Color(0xFF4285F4)
      ..style = PaintingStyle.fill;
    canvas.drawRect(
      Rect.fromLTWH(
        cx - 1,
        cy - stroke / 2,
        radius + stroke / 2 - (cx - 1),
        stroke,
      ),
      barPaint,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
