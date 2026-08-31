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

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Welcome & Health Banner
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  AppColors.roleSuperAdmin.withValues(alpha: 0.18),
                  AppColors.surface,
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: AppColors.roleSuperAdmin.withValues(alpha: 0.3),
              ),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppColors.roleSuperAdmin.withValues(alpha: 0.2),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.admin_panel_settings_rounded,
                    size: 36,
                    color: AppColors.roleSuperAdmin,
                  ),
                ),
                const SizedBox(width: 20),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'CampVerse Multi-Tenant Console',
                        style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.w800,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 4),
                      const Text(
                        'System governance, platform-wide tenant management, '
                        'and FLE security.',
                        style: TextStyle(
                          fontSize: 14,
                          color: AppColors.textSecondary,
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
                          const SizedBox(width: 6),
                          const Flexible(
                            child: Text(
                              'All System Services Operational (FLE Active)',
                              style: TextStyle(
                                fontSize: 12,
                                color: AppColors.success,
                                fontWeight: FontWeight.w600,
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
          const SizedBox(height: 24),

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
                        color: AppColors.roleSuperAdmin,
                        onTap: () => onNavigateToTab(1),
                      ),
                      _StatCard(
                        title: 'Institutes',
                        count: '${metrics.totalInstitutes}',
                        icon: Icons.domain_rounded,
                        color: AppColors.rolePrincipal,
                        onTap: () => onNavigateToTab(2),
                      ),
                      _StatCard(
                        title: 'Departments',
                        count: '${metrics.totalDepartments}',
                        icon: Icons.apartment_rounded,
                        color: AppColors.roleHod,
                      ),
                      _StatCard(
                        title: 'User Profiles',
                        count: '${metrics.totalUsers}',
                        icon: Icons.people_alt_rounded,
                        color: AppColors.roleStudent,
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
                  icon: const Icon(
                    Icons.add_business_rounded,
                    color: AppColors.roleSuperAdmin,
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
                  icon: const Icon(
                    Icons.domain_add_rounded,
                    color: AppColors.rolePrincipal,
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
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppColors.surfaceBorder),
            ),
            child: const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(
                      Icons.shield_outlined,
                      color: AppColors.accent,
                      size: 20,
                    ),
                    SizedBox(width: 8),
                    Text(
                      'Zero-Knowledge & FLE Cryptography Status',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textPrimary,
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 12),
                Text(
                  'Student & Faculty identity fields (full names, mobile '
                  'numbers, emergency contacts, and certificates) are '
                  'encrypted client/gateway-side using AES-256-GCM. '
                  'Fast indexing is powered by deterministic HMAC-SHA256 '
                  'peppering.',
                  style: TextStyle(
                    fontSize: 13,
                    color: AppColors.textSecondary,
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

class _StatCard extends StatelessWidget {
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
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.surfaceBorder),
      ),
      child: InkWell(
        onTap: onTap,
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
                    title,
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textSecondary,
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: color.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(icon, size: 16, color: color),
                  ),
                ],
              ),
              Text(
                count,
                style: const TextStyle(
                  fontSize: 26,
                  fontWeight: FontWeight.w800,
                  color: AppColors.textPrimary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
