import 'package:campverse/core/models/app_role.dart';
import 'package:campverse/core/models/institute.dart';
import 'package:campverse/core/providers/campus_admin_provider.dart';
import 'package:campverse/core/services/campus_admin_service.dart';
import 'package:campverse/core/theme/app_colors.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Role-aware campus dashboard overview shared between Office Admin (base)
/// and Principal (base + executive extras & approvals).
class CampusDashboardPage extends ConsumerWidget {
  /// Default constructor for CampusDashboardPage.
  const CampusDashboardPage({
    required this.role,
    this.onNavigateToTab,
    super.key,
  });

  /// The active administrative role viewing the dashboard.
  final AppRole role;

  /// Optional callback to switch parent tabs.
  final ValueChanged<int>? onNavigateToTab;

  /// Whether the current role perspective is Principal executive.
  bool get isPrincipal => role == AppRole.principal;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final instituteAsync = ref.watch(currentInstituteProvider);
    final metricsAsync = ref.watch(campusMetricsProvider);
    final isDark = AppColors.isDark(context);
    final roleColor = AppColors.roleColorOf(context, role);

    return RefreshIndicator(
      onRefresh: () async {
        await ref.read(currentInstituteProvider.notifier).reload();
        ref.invalidate(campusMetricsProvider);
      },
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // 1. Campus Identity Hero Banner
            instituteAsync.when(
              data: (institute) => _buildCampusHeroBanner(
                context,
                institute,
                roleColor,
                isDark,
              ),
              loading: () => _buildHeroLoadingPlaceholder(context, isDark),
              error: (err, _) => _buildHeroErrorCard(context, isDark),
            ),
            const SizedBox(height: 24),

            // 2. Role Distinction Cards (Approvals vs Ops Queue)
            metricsAsync.when(
              data: (metrics) => _buildRoleSpecializationSection(
                context,
                metrics,
                roleColor,
                isDark,
              ),
              loading: () => const SizedBox.shrink(),
              error: (error, stackTrace) => const SizedBox.shrink(),
            ),
            const SizedBox(height: 24),

            // 3. Real-Time Campus Metric Counters
            metricsAsync.when(
              data: (metrics) => _buildMetricsGrid(
                context,
                metrics,
                isDark,
              ),
              loading: () => _buildMetricsLoadingGrid(context, isDark),
              error: (error, stackTrace) => const SizedBox.shrink(),
            ),
            const SizedBox(height: 24),

            // 4. Operational Quick Actions Hub
            _buildQuickActionsSection(context, roleColor, isDark),
            const SizedBox(height: 24),

            // 5. Active Campus Branding Snapshot
            instituteAsync.when(
              data: (institute) {
                if (institute == null) {
                  return const SizedBox.shrink();
                }
                return _buildBrandingSnapshotCard(
                  context,
                  institute,
                  roleColor,
                  isDark,
                );
              },
              loading: () => const SizedBox.shrink(),
              error: (error, stackTrace) => const SizedBox.shrink(),
            ),
          ],
        ),
      ),
    );
  }

  /// Campus Header Hero with Name, Code, Logo, and Domain.
  Widget _buildCampusHeroBanner(
    BuildContext context,
    Institute? institute,
    Color roleColor,
    bool isDark,
  ) {
    final instName = institute?.name ?? 'Campus Operations Console';
    final instSlug = institute?.slug ?? 'CAMPUS';
    final tagline = institute?.branding.tagline;
    final uniName = institute?.universityName ?? 'Affiliated Institution';
    final isAutonomous = institute?.isAutonomous ?? false;

    return Container(
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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Campus Logo / Monogram
              _buildLogoAvatar(
                institute?.branding.logoUrl,
                instSlug,
                roleColor,
              ),
              const SizedBox(width: 18),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: roleColor.withValues(
                              alpha: isDark ? 0.22 : 0.12,
                            ),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(role.icon, size: 14, color: roleColor),
                              const SizedBox(width: 6),
                              Text(
                                role.displayName.toUpperCase(),
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w800,
                                  letterSpacing: 0.5,
                                  color: roleColor,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.surfaceElevatedOf(context),
                            borderRadius: BorderRadius.circular(6),
                            border: Border.all(
                              color: AppColors.surfaceBorderOf(context),
                            ),
                          ),
                          child: Text(
                            instSlug,
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                              color: AppColors.textSecondaryOf(context),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Text(
                      instName,
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.w800,
                        letterSpacing: -0.3,
                        color: AppColors.textPrimaryOf(context),
                      ),
                    ),
                    if (tagline != null && tagline.isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Text(
                        '“$tagline”',
                        style: TextStyle(
                          fontSize: 13,
                          fontStyle: FontStyle.italic,
                          color: AppColors.textSecondaryOf(context),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          const Divider(height: 1),
          const SizedBox(height: 14),
          Wrap(
            spacing: 16,
            runSpacing: 8,
            children: [
              _buildMetaTag(
                context,
                icon: Icons.account_balance_rounded,
                label: uniName,
              ),
              _buildMetaTag(
                context,
                icon: isAutonomous
                    ? Icons.stars_rounded
                    : Icons.link_rounded,
                label: isAutonomous
                    ? 'Autonomous Curriculum'
                    : 'University Affiliated',
                color: isAutonomous
                    ? const Color(0xFF059669)
                    : AppColors.textSecondaryOf(context),
              ),
              if (institute?.domain != null)
                _buildMetaTag(
                  context,
                  icon: Icons.language_rounded,
                  label: institute!.domain!,
                ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildLogoAvatar(String? logoUrl, String slug, Color roleColor) {
    if (logoUrl != null && logoUrl.trim().isNotEmpty) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: Image.network(
          logoUrl,
          width: 60,
          height: 60,
          fit: BoxFit.cover,
          errorBuilder: (context, error, stackTrace) =>
              _buildFallbackAvatar(slug, roleColor),
        ),
      );
    }
    return _buildFallbackAvatar(slug, roleColor);
  }

  Widget _buildFallbackAvatar(String slug, Color roleColor) {
    return Container(
      width: 60,
      height: 60,
      decoration: BoxDecoration(
        color: roleColor.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: roleColor.withValues(alpha: 0.3)),
      ),
      alignment: Alignment.center,
      child: Text(
        slug.isNotEmpty ? slug.substring(0, slug.length.clamp(1, 3)) : 'CV',
        style: TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.w800,
          color: roleColor,
        ),
      ),
    );
  }

  Widget _buildMetaTag(
    BuildContext context, {
    required IconData icon,
    required String label,
    Color? color,
  }) {
    final effectiveColor = color ?? AppColors.textSecondaryOf(context);
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 15, color: effectiveColor),
        const SizedBox(width: 6),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: effectiveColor,
          ),
        ),
      ],
    );
  }

  /// Conditional cards highlighting Principal executive powers or
  /// Office Admin operations.
  Widget _buildRoleSpecializationSection(
    BuildContext context,
    CampusMetrics metrics,
    Color roleColor,
    bool isDark,
  ) {
    if (isPrincipal) {
      return _buildPrincipalExecutiveCard(
        context,
        metrics,
        roleColor,
        isDark,
      );
    } else {
      return _buildOfficeAdminOpsCard(
        context,
        metrics,
        roleColor,
        isDark,
      );
    }
  }

  /// Principal Elevated Feature: Approvals Queue & Executive Seal.
  Widget _buildPrincipalExecutiveCard(
    BuildContext context,
    CampusMetrics metrics,
    Color roleColor,
    bool isDark,
  ) {
    final pendingCount = metrics.pendingApprovalsCount;
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: isDark
              ? [const Color(0xFF1E293B), const Color(0xFF0F172A)]
              : [const Color(0xFFEFF6FF), const Color(0xFFDBEAFE)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: const Color(0xFF3B82F6).withValues(
            alpha: isDark ? 0.35 : 0.4,
          ),
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: const Color(0xFF1D4ED8).withValues(alpha: 0.18),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.verified_user_rounded,
              color: Color(0xFF2563EB),
              size: 30,
            ),
          ),
          const SizedBox(width: 18),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      'Executive Approvals Vault',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                        color: AppColors.textPrimaryOf(context),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: pendingCount > 0
                            ? const Color(0xFFDC2626)
                            : const Color(0xFF059669),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        pendingCount > 0
                            ? '$pendingCount Pending'
                            : 'All Clear',
                        style: const TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w800,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  'Exclusive Principal authority: duty leaves, official event '
                  'sanctions, and digital certificate verification keys.',
                  style: TextStyle(
                    fontSize: 13,
                    color: AppColors.textSecondaryOf(context),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          ElevatedButton.icon(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF1D4ED8),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            icon: const Icon(Icons.approval_rounded, size: 16),
            label: const Text(
              'Approvals',
              style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13),
            ),
            onPressed: () {
              // Switch to Approvals tab in PrincipalShell (index 2)
              onNavigateToTab?.call(2);
            },
          ),
        ],
      ),
    );
  }

  /// Office Admin Base Feature: Operational Queue.
  Widget _buildOfficeAdminOpsCard(
    BuildContext context,
    CampusMetrics metrics,
    Color roleColor,
    bool isDark,
  ) {
    final pendingVerifications = metrics.pendingVerificationsCount;
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.surfaceOf(context),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: roleColor.withValues(alpha: isDark ? 0.35 : 0.25),
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: roleColor.withValues(alpha: 0.15),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.assignment_turned_in_rounded,
              color: roleColor,
              size: 30,
            ),
          ),
          const SizedBox(width: 18),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      'Campus Operations Queue',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                        color: AppColors.textPrimaryOf(context),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: pendingVerifications > 0
                            ? const Color(0xFFD97706)
                            : const Color(0xFF059669),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        pendingVerifications > 0
                            ? '$pendingVerifications Verifications'
                            : 'Synchronized',
                        style: const TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w800,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  'Student record verifications, register number allocation, '
                  'and institute data maintenance.',
                  style: TextStyle(
                    fontSize: 13,
                    color: AppColors.textSecondaryOf(context),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          OutlinedButton.icon(
            style: OutlinedButton.styleFrom(
              foregroundColor: roleColor,
              side: BorderSide(color: roleColor),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            icon: const Icon(Icons.tune_rounded, size: 16),
            label: const Text(
              'Manage Records',
              style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13),
            ),
            onPressed: () {
              // Navigate to Institute Management tab (index 1)
              onNavigateToTab?.call(1);
            },
          ),
        ],
      ),
    );
  }

  /// Real-Time Counts Grid.
  Widget _buildMetricsGrid(
    BuildContext context,
    CampusMetrics metrics,
    bool isDark,
  ) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final crossAxisCount = constraints.maxWidth > 900
            ? 5
            : (constraints.maxWidth > 600 ? 3 : 2);
        return GridView.count(
          crossAxisCount: crossAxisCount,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisSpacing: 16,
          mainAxisSpacing: 16,
          childAspectRatio: 1.4,
          children: [
            _buildMetricTile(
              context,
              title: 'Departments',
              value: metrics.departmentCount.toString(),
              icon: Icons.apartment_rounded,
              color: const Color(0xFF1D4ED8),
              isDark: isDark,
            ),
            _buildMetricTile(
              context,
              title: 'Faculty & Staff',
              value: metrics.facultyCount.toString(),
              icon: Icons.school_rounded,
              color: const Color(0xFF059669),
              isDark: isDark,
            ),
            _buildMetricTile(
              context,
              title: 'Students Enrolled',
              value: metrics.studentCount.toString(),
              icon: Icons.people_alt_rounded,
              color: const Color(0xFF0284C7),
              isDark: isDark,
            ),
            _buildMetricTile(
              context,
              title: 'Clubs & Union',
              value: metrics.clubCount.toString(),
              icon: Icons.celebration_rounded,
              color: const Color(0xFF9F1239),
              isDark: isDark,
            ),
            _buildMetricTile(
              context,
              title: 'Campus Events',
              value: metrics.eventCount.toString(),
              icon: Icons.event_available_rounded,
              color: const Color(0xFFD97706),
              isDark: isDark,
            ),
          ],
        );
      },
    );
  }

  Widget _buildMetricTile(
    BuildContext context, {
    required String title,
    required String value,
    required IconData icon,
    required Color color,
    required bool isDark,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surfaceOf(context),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.surfaceBorderOf(context)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  title,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textSecondaryOf(context),
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: 4),
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: isDark ? 0.2 : 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, size: 16, color: color),
              ),
            ],
          ),
          Text(
            value,
            style: TextStyle(
              fontSize: 26,
              fontWeight: FontWeight.w800,
              letterSpacing: -0.5,
              color: AppColors.textPrimaryOf(context),
            ),
          ),
        ],
      ),
    );
  }

  /// Action buttons to jump to other modules.
  Widget _buildQuickActionsSection(
    BuildContext context,
    Color roleColor,
    bool isDark,
  ) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.surfaceOf(context),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.surfaceBorderOf(context)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.bolt_rounded, size: 20, color: roleColor),
              const SizedBox(width: 8),
              Text(
                'Campus Administrative Actions',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimaryOf(context),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Wrap(
            spacing: 12,
            runSpacing: 12,
            children: [
              _buildActionButton(
                context,
                icon: Icons.edit_note_rounded,
                label: 'Edit Institute Info & Branding',
                color: roleColor,
                onPressed: () => onNavigateToTab?.call(1),
              ),
              _buildActionButton(
                context,
                icon: Icons.apartment_rounded,
                label: 'Department Hierarchy',
                color: const Color(0xFF1D4ED8),
                onPressed: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Department Management opens next.'),
                    ),
                  );
                },
              ),
              _buildActionButton(
                context,
                icon: Icons.badge_rounded,
                label: 'Faculty & Staff Roster',
                color: const Color(0xFF059669),
                onPressed: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Staff Directory opens next.'),
                    ),
                  );
                },
              ),
              _buildActionButton(
                context,
                icon: Icons.groups_rounded,
                label: 'Clubs & Student Bodies',
                color: const Color(0xFF9F1239),
                onPressed: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Clubs Management opens next.'),
                    ),
                  );
                },
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildActionButton(
    BuildContext context, {
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onPressed,
  }) {
    return InkWell(
      onTap: onPressed,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withValues(alpha: 0.2)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 16, color: color),
            const SizedBox(width: 8),
            Text(
              label,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Live Campus Brand Preview Snapshot on the dashboard.
  Widget _buildBrandingSnapshotCard(
    BuildContext context,
    Institute institute,
    Color roleColor,
    bool isDark,
  ) {
    final branding = institute.branding;
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.surfaceOf(context),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.surfaceBorderOf(context)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Icon(Icons.palette_outlined, size: 20, color: roleColor),
                  const SizedBox(width: 8),
                  Text(
                    'Campus Brand & Portal Persona',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textPrimaryOf(context),
                    ),
                  ),
                ],
              ),
              TextButton.icon(
                icon: const Icon(Icons.settings_outlined, size: 16),
                label: const Text('Customize'),
                onPressed: () => onNavigateToTab?.call(1),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            'This branding reflects across student portals, official '
            'transcripts, and academic notices generated by CampVerse.',
            style: TextStyle(
              fontSize: 13,
              color: AppColors.textSecondaryOf(context),
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              if (branding.primaryColor != null) ...[
                _buildColorSwatchChip(
                  context,
                  label: 'Accent Color',
                  colorHex: branding.primaryColor!,
                ),
                const SizedBox(width: 16),
              ],
              if (branding.website != null && branding.website!.isNotEmpty)
                _buildInfoBadge(
                  context,
                  icon: Icons.link_rounded,
                  label: branding.website!,
                ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildColorSwatchChip(
    BuildContext context, {
    required String label,
    required String colorHex,
  }) {
    Color? color;
    try {
      final hex = colorHex.replaceAll('#', '');
      color = Color(int.parse('FF$hex', radix: 16));
    } on Exception catch (_) {
      color = null;
    }

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (color != null)
          Container(
            width: 18,
            height: 18,
            decoration: BoxDecoration(
              color: color,
              shape: BoxShape.circle,
              border: Border.all(color: Colors.white, width: 1.5),
            ),
          ),
        const SizedBox(width: 6),
        Text(
          colorHex,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w700,
            color: AppColors.textPrimaryOf(context),
          ),
        ),
      ],
    );
  }

  Widget _buildInfoBadge(
    BuildContext context, {
    required IconData icon,
    required String label,
  }) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 16, color: AppColors.textSecondaryOf(context)),
        const SizedBox(width: 4),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: AppColors.textSecondaryOf(context),
          ),
        ),
      ],
    );
  }

  Widget _buildHeroLoadingPlaceholder(BuildContext context, bool isDark) {
    return Container(
      height: 140,
      decoration: BoxDecoration(
        color: AppColors.surfaceOf(context),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.surfaceBorderOf(context)),
      ),
      child: const Center(child: CircularProgressIndicator.adaptive()),
    );
  }

  Widget _buildHeroErrorCard(BuildContext context, bool isDark) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.surfaceOf(context),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFDC2626)),
      ),
      child: const Text('Failed to load institute information.'),
    );
  }

  Widget _buildMetricsLoadingGrid(BuildContext context, bool isDark) {
    return Container(
      height: 80,
      alignment: Alignment.center,
      child: const CircularProgressIndicator.adaptive(),
    );
  }
}
