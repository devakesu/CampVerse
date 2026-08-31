import 'package:campverse/core/theme/app_colors.dart';
import 'package:flutter/material.dart';

/// Reusable brand logo widget supporting both wide and square logo assets.
/// Automatically renders custom image assets from `assets/images/`, and falls
/// back to the clean branded icon/wordmark if the asset is missing.
class BrandLogo extends StatelessWidget {
  /// Wide horizontal logo with wordmark.
  const BrandLogo.wide({
    this.height = 68,
    this.width,
    this.alignment = Alignment.centerLeft,
    this.fit = BoxFit.contain,
    super.key,
  })  : isWide = true,
        size = null,
        borderRadius = null;

  /// Compact square icon logo for rails, badges, and headers.
  const BrandLogo.square({
    this.size = 44,
    this.borderRadius = 10,
    this.alignment = Alignment.center,
    this.fit = BoxFit.contain,
    super.key,
  })  : isWide = false,
        height = null,
        width = null;

  /// True if rendering the horizontal wide logo.
  final bool isWide;

  /// Explicit height for wide logo.
  final double? height;

  /// Explicit width for wide logo.
  final double? width;

  /// Square dimensions for compact logo.
  final double? size;

  /// Optional border radius for square logo container.
  final double? borderRadius;

  /// Alignment of the logo within its box.
  final Alignment alignment;

  /// Image fit mode.
  final BoxFit fit;

  @override
  Widget build(BuildContext context) {
    if (isWide) {
      return Image.asset(
        'assets/images/campverse-wide-logo.png',
        height: height,
        width: width,
        alignment: alignment,
        fit: fit,
        errorBuilder: (context, error, stackTrace) {
          // Graceful fallback when logo asset is not found
          return Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  gradient: AppColors.primaryGradient,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.primary.withValues(alpha: 0.3),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: const Icon(
                  Icons.school_rounded,
                  size: 26,
                  color: Colors.white,
                ),
              ),
              const SizedBox(width: 14),
              Text(
                'CampVerse',
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                      fontWeight: FontWeight.w800,
                      letterSpacing: -0.5,
                      color: AppColors.textPrimaryOf(context),
                    ),
              ),
            ],
          );
        },
      );
    }

    final boxSize = size ?? 44;
    final radius = borderRadius ?? 10;

    return ClipRRect(
      borderRadius: BorderRadius.circular(radius),
      child: Image.asset(
        'assets/images/campverse-logo.png',
        width: boxSize,
        height: boxSize,
        alignment: alignment,
        fit: fit,
        errorBuilder: (context, error, stackTrace) {
          // Graceful fallback when square logo is not found
          return Container(
            width: boxSize,
            height: boxSize,
            decoration: BoxDecoration(
              gradient: AppColors.primaryGradient,
              borderRadius: BorderRadius.circular(radius),
              boxShadow: [
                BoxShadow(
                  color: AppColors.primary.withValues(alpha: 0.3),
                  blurRadius: 8,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
            child: Icon(
              Icons.school_rounded,
              size: boxSize * 0.55,
              color: Colors.white,
            ),
          );
        },
      ),
    );
  }
}
