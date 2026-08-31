import 'package:campverse/core/models/app_role.dart';
import 'package:campverse/core/providers/super_admin_provider.dart';
import 'package:campverse/core/theme/app_colors.dart';
import 'package:campverse/features/super_admin/institutes/add_institute_page.dart';
import 'package:campverse/features/super_admin/universities/add_university_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Main Super Administrator executive dashboard overview.
class SuperAdminDashboardPage extends ConsumerWidget {
  /// Default constructor for SuperAdminDashboardPage.
  const SuperAdminDashboardPage({
    required this.onNavigateToTab,
    super.key,
  });

  /// Callback to switch parent tab index.
  final ValueChanged<int> onNavigateToTab;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final metricsAsync = ref.watch(systemMetricsProvider);
    final isDark = AppColors.isDark(context);
    final superAdminColor =
        AppColors.roleColorOf(context, AppRole.superAdmin);
    final principalColor =
        AppColors.roleColorOf(context, AppRole.principal);
    final hodColor = AppColors.roleColorOf(context, AppRole.hod);
    final studentColor = AppColors.roleColorOf(context, AppRole.student);

    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Welcome & Health Banner
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: AppColors.surfaceOf(context),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: superAdminColor.withValues(
                  alpha: isDark ? 0.35 : 0.2,
                ),
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
                    color: superAdminColor.withValues(
                      alpha: isDark ? 0.2 : 0.1,
                    ),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Icon(
                    Icons.admin_panel_settings_rounded,
                    size: 36,
                    color: superAdminColor,
                  ),
                ),
                const SizedBox(width: 20),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'CampVerse Multi-Tenant Console',
                        style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.w800,
                          letterSpacing: -0.3,
                          color: AppColors.textPrimaryOf(context),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'System governance, platform-wide tenant management, '
                        'and FLE security.',
                        style: TextStyle(
                          fontSize: 14,
                          color: AppColors.textSecondaryOf(context),
                        ),
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Container(
                            width: 8,
                            height: 8,
                            decoration: const BoxDecoration(
                              color: AppColors.success,
                              shape: BoxShape.circle,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            'All System Services Operational (FLE Enforced)',
                            style: TextStyle(
                              fontSize: 12,
                              color: isDark
                                  ? AppColors.success
                                  : const Color(0xFF047857),
                              fontWeight: FontWeight.w700,
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
          const SizedBox(height: 28),

          // Platform Stats Section
          Text(
            'System Architecture Overview',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                ),
          ),
          const SizedBox(height: 16),

          metricsAsync.when(
            data: (metrics) {
              return LayoutBuilder(
                builder: (context, constraints) {
                  final isWide = constraints.maxWidth > 700;
                  return GridView.count(
                    crossAxisCount: isWide ? 4 : 2,
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    crossAxisSpacing: 14,
                    mainAxisSpacing: 14,
                    childAspectRatio: isWide ? 1.4 : 1.3,
                    children: [
                      _StatCard(
                        title: 'Universities',
                        count: '${metrics.totalUniversities}',
                        icon: Icons.account_balance_rounded,
                        color: superAdminColor,
                        onTap: () => onNavigateToTab(1),
                      ),
                      _StatCard(
                        title: 'Institutes',
                        count: '${metrics.totalInstitutes}',
                        icon: Icons.domain_rounded,
                        color: principalColor,
                        onTap: () => onNavigateToTab(2),
                      ),
                      _StatCard(
                        title: 'Departments',
                        count: '${metrics.totalDepartments}',
                        icon: Icons.apartment_rounded,
                        color: hodColor,
                      ),
                      _StatCard(
                        title: 'User Profiles',
                        count: '${metrics.totalUsers}',
                        icon: Icons.people_alt_rounded,
                        color: studentColor,
                      ),
                    ],
                  );
                },
              );
            },
            loading: () => const Center(
              child: Padding(
                padding: EdgeInsets.all(20),
                child: CircularProgressIndicator(),
              ),
            ),
            error: (_, _) => const SizedBox.shrink(),
          ),
          const SizedBox(height: 28),

          // Quick Management Actions
          Text(
            'Quick Governance Actions',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                ),
          ),
          const SizedBox(height: 14),

          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () {
                    Navigator.of(context).push(
                      MaterialPageRoute<void>(
                        builder: (context) => const AddUniversityPage(),
                      ),
                    );
                  },
                  icon: Icon(
                    Icons.add_business_rounded,
                    color: superAdminColor,
                  ),
                  label: const Text('Add University'),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () {
                    Navigator.of(context).push(
                      MaterialPageRoute<void>(
                        builder: (context) => const AddInstitutePage(),
                      ),
                    );
                  },
                  icon: Icon(
                    Icons.domain_add_rounded,
                    color: principalColor,
                  ),
                  label: const Text('Onboard Institute'),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 28),

          // Cryptographic Security Telemetry Card
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: AppColors.surfaceOf(context),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppColors.borderOf(context)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(
                      Icons.shield_outlined,
                      color: AppColors.accent,
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Zero-Knowledge & FLE Cryptography Status',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textPrimaryOf(context),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Text(
                  'Student & Faculty identity fields (full names, mobile '
                  'numbers, emergency contacts, and certificates) are '
                  'encrypted client/gateway-side using AES-256-GCM. '
                  'Fast indexing is powered by deterministic HMAC-SHA256 '
                  'peppering.',
                  style: TextStyle(
                    fontSize: 13,
                    color: AppColors.textSecondaryOf(context),
                    height: 1.5,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _StatCard extends StatefulWidget {
  const _StatCard({
    required this.title,
    required this.count,
    required this.icon,
    required this.color,
    this.onTap,
  });

  final String title;
  final String count;
  final IconData icon;
  final Color color;
  final VoidCallback? onTap;

  @override
  State<_StatCard> createState() => _StatCardState();
}

class _StatCardState extends State<_StatCard> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    final isDark = AppColors.isDark(context);

    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        curve: Curves.easeOutCubic,
        transform: Matrix4.identity()
          ..translateByDouble(0, _isHovered ? -2.0 : 0.0, 0, 1),
        decoration: BoxDecoration(
          color: AppColors.surfaceOf(context),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: _isHovered
                ? widget.color.withValues(alpha: 0.6)
                : AppColors.borderOf(context),
            width: _isHovered ? 1.5 : 1,
          ),
          boxShadow: [
            if (_isHovered)
              BoxShadow(
                color: widget.color.withValues(alpha: isDark ? 0.2 : 0.08),
                blurRadius: 12,
                offset: const Offset(0, 4),
              )
            else
              BoxShadow(
                color: isDark
                    ? Colors.black.withValues(alpha: 0.2)
                    : Colors.black.withValues(alpha: 0.03),
                blurRadius: 6,
                offset: const Offset(0, 2),
              ),
          ],
        ),
        child: InkWell(
          onTap: widget.onTap,
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      widget.title,
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textSecondaryOf(context),
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: widget.color.withValues(
                          alpha: isDark ? 0.2 : 0.1,
                        ),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(widget.icon, size: 16, color: widget.color),
                    ),
                  ],
                ),
                Text(
                  widget.count,
                  style: TextStyle(
                    fontSize: 26,
                    fontWeight: FontWeight.w800,
                    color: AppColors.textPrimaryOf(context),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
