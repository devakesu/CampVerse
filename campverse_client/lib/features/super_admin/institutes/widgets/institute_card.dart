import 'package:campverse/core/models/app_role.dart';
import 'package:campverse/core/models/institute.dart';
import 'package:campverse/core/theme/app_colors.dart';
import 'package:flutter/material.dart';

/// Card widget displaying institute tenant information and status flags.
class InstituteCard extends StatelessWidget {
  /// Default constructor for InstituteCard.
  const InstituteCard({
    required this.institute,
    this.onTap,
    super.key,
  });

  /// Institute entity model.
  final Institute institute;

  /// Optional tap callback.
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final isDark = AppColors.isDark(context);
    final principalColor = AppColors.roleColorOf(context, AppRole.principal);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: AppColors.surfaceOf(context),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.borderOf(context)),
        boxShadow: [
          BoxShadow(
            color: isDark
                ? Colors.black.withValues(alpha: 0.15)
                : Colors.black.withValues(alpha: 0.03),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(18),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: principalColor.withValues(
                    alpha: isDark ? 0.2 : 0.1,
                  ),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  Icons.domain_rounded,
                  color: principalColor,
                  size: 24,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            institute.name,
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                              color: AppColors.textPrimaryOf(context),
                            ),
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.surfaceElevatedOf(context),
                            borderRadius: BorderRadius.circular(8),
                            border:
                                Border.all(color: AppColors.borderOf(context)),
                          ),
                          child: Text(
                            institute.slug,
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                              color: principalColor,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        if (institute.universityName != null &&
                            institute.universityName!.isNotEmpty) ...[
                          Icon(
                            Icons.school_outlined,
                            size: 14,
                            color: AppColors.textSecondaryOf(context),
                          ),
                          const SizedBox(width: 4),
                          Text(
                            institute.universityName!,
                            style: TextStyle(
                              fontSize: 13,
                              color: AppColors.textSecondaryOf(context),
                            ),
                          ),
                          const SizedBox(width: 12),
                        ],
                        if (institute.domain != null &&
                            institute.domain!.isNotEmpty) ...[
                          Icon(
                            Icons.public_rounded,
                            size: 14,
                            color: AppColors.textMutedOf(context),
                          ),
                          const SizedBox(width: 4),
                          Text(
                            institute.domain!,
                            style: TextStyle(
                              fontSize: 13,
                              color: AppColors.primaryOf(context),
                            ),
                          ),
                          const SizedBox(width: 12),
                        ],
                        if (institute.isAutonomous)
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 6,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: AppColors.accent.withValues(
                                alpha: isDark ? 0.2 : 0.12,
                              ),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: const Text(
                              'Autonomous',
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                                color: AppColors.accent,
                              ),
                            ),
                          ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
