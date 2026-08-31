import 'package:campverse/core/models/app_role.dart';
import 'package:campverse/core/models/university.dart';
import 'package:campverse/core/theme/app_colors.dart';
import 'package:flutter/material.dart';

/// Card widget displaying university details and status.
class UniversityCard extends StatelessWidget {
  /// Default constructor for UniversityCard.
  const UniversityCard({
    required this.university,
    this.onTap,
    super.key,
  });

  /// University model instance.
  final University university;

  /// Optional tap callback.
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final isDark = AppColors.isDark(context);
    final superAdminColor = AppColors.roleColorOf(context, AppRole.superAdmin);

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
                  color: superAdminColor.withValues(
                    alpha: isDark ? 0.2 : 0.1,
                  ),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  Icons.account_balance_rounded,
                  color: superAdminColor,
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
                            university.name,
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
                            university.slug,
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                              color: superAdminColor,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        Icon(
                          Icons.location_on_outlined,
                          size: 14,
                          color: AppColors.textSecondaryOf(context),
                        ),
                        const SizedBox(width: 4),
                        Text(
                          university.state,
                          style: TextStyle(
                            fontSize: 13,
                            color: AppColors.textSecondaryOf(context),
                          ),
                        ),
                        if (university.website != null &&
                            university.website!.isNotEmpty) ...[
                          const SizedBox(width: 12),
                          Icon(
                            Icons.language_rounded,
                            size: 14,
                            color: AppColors.textMutedOf(context),
                          ),
                          const SizedBox(width: 4),
                          Flexible(
                            child: Text(
                              university.website!,
                              style: TextStyle(
                                fontSize: 13,
                                color: AppColors.primaryOf(context),
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
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
