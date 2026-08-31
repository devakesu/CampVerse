import 'package:campverse/core/models/app_role.dart';
import 'package:campverse/core/theme/app_colors.dart';
import 'package:flutter/material.dart';

/// Reusable dashboard preview widget showing role capabilities and hero cards.
class RoleDashboardView extends StatelessWidget {
  /// Default constructor for RoleDashboardView.
  const RoleDashboardView({
    required this.role,
    required this.tabTitle,
    required this.description,
    required this.features,
    super.key,
  });

  /// Associated workspace role.
  final AppRole role;

  /// Title of the selected navigation tab.
  final String tabTitle;

  /// Explanatory description of the workspace view.
  final String description;

  /// Highlighted capability list for this module.
  final List<String> features;

  @override
  Widget build(BuildContext context) {
    final roleColor = AppColors.roleColorOf(context, role);
    final isDark = AppColors.isDark(context);

    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 880),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Welcome Hero Card
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: AppColors.surfaceOf(context),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: roleColor.withValues(alpha: isDark ? 0.35 : 0.2),
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: isDark
                          ? Colors.black.withValues(alpha: 0.25)
                          : Colors.black.withValues(alpha: 0.04),
                      blurRadius: 16,
                      offset: const Offset(0, 6),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: roleColor.withValues(
                          alpha: isDark ? 0.2 : 0.12,
                        ),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(role.icon, size: 36, color: roleColor),
                    ),
                    const SizedBox(width: 20),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            tabTitle,
                            style: TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.w800,
                              letterSpacing: -0.3,
                              color: AppColors.textPrimaryOf(context),
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            description,
                            style: TextStyle(
                              fontSize: 14,
                              color: AppColors.textSecondaryOf(context),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 28),

              Text(
                'Available Management Modules',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                    ),
              ),
              const SizedBox(height: 16),

              // Feature Cards List
              ...features.map((feature) {
                return Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 18,
                      vertical: 16,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.surfaceOf(context),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: AppColors.borderOf(context)),
                      boxShadow: [
                        BoxShadow(
                          color: isDark
                              ? Colors.black.withValues(alpha: 0.15)
                              : Colors.black.withValues(alpha: 0.02),
                          blurRadius: 6,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: roleColor.withValues(
                              alpha: isDark ? 0.18 : 0.1,
                            ),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Icon(
                            Icons.check_circle_outline_rounded,
                            color: roleColor,
                            size: 18,
                          ),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Text(
                            feature,
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: AppColors.textPrimaryOf(context),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }),
            ],
          ),
        ),
      ),
    );
  }
}
