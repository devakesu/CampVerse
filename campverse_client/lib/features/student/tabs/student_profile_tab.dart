import 'dart:async';

import 'package:campverse/core/providers/auth_provider.dart';
import 'package:campverse/core/providers/theme_provider.dart';
import 'package:campverse/core/router/route_names.dart';
import 'package:campverse/core/theme/app_colors.dart';
import 'package:campverse/core/utils/responsive_layout.dart';
import 'package:campverse/features/student/models/student_class_details.dart';
import 'package:campverse/features/student/providers/student_providers.dart';
import 'package:campverse/features/student/widgets/student_id_card.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

/// Student Profile tab featuring interactive digital campus ID card,
/// KTU activity points meter, and account settings.
class StudentProfileTab extends ConsumerWidget {
  /// Default constructor.
  const StudentProfileTab({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = AppColors.isDark(context);
    final isDesktop = ResponsiveLayout.isDesktop(context);
    final themeMode = ref.watch(themeModeProvider);
    final authState = ref.watch(authStateProvider);
    final user = authState.user;

    final userName = (user?.userMetadata?['full_name'] as String?) ??
        (user?.email?.split('@').first ?? 'Alex Kumar');
    final userEmail = user?.email ?? 'alex.k@campverse.edu';

    final classAsync = ref.watch(studentClassDetailsProvider);
    final classDetails = classAsync.value ??
        const StudentClassDetails(
          id: 'demo',
          programmeName: 'B.Tech. Computer Science & Engineering',
          programmeCode: 'CSE',
          departmentName: 'Computer Science & Engineering',
          departmentCode: 'CSE',
          admissionYear: 2023,
          gradYear: 2027,
          currentSemester: 6,
          division: 'A',
        );

    return ListView(
      padding: EdgeInsets.symmetric(
        horizontal: isDesktop ? 32 : 18,
        vertical: 24,
      ),
      children: [
        // Digital ID Card
        Center(
          child: StudentIdCard(
            studentName: userName,
            studentEmail: userEmail,
            classDetails: classDetails,
          ),
        ),

        const SizedBox(height: 28),

        // KTU Activity Points Meter (100 Pts graduation mandate)
        Container(
          padding: const EdgeInsets.all(22),
          decoration: BoxDecoration(
            color: AppColors.surfaceOf(context),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: AppColors.borderOf(context)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: const Color(0xFFD97706)
                              .withValues(alpha: 0.12),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.military_tech_rounded,
                          color: Color(0xFFD97706),
                          size: 22,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'KTU Activity Points',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w800,
                              color: AppColors.textPrimaryOf(context),
                            ),
                          ),
                          Text(
                            'Mandatory 100 Points for B.Tech Degree',
                            style: TextStyle(
                              fontSize: 11,
                              color: AppColors.textSecondaryOf(context),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  const Text(
                    '65 / 100',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                      color: Color(0xFFD97706),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              LinearProgressIndicator(
                value: 0.65,
                backgroundColor: isDark
                    ? const Color(0xFF1E293B)
                    : const Color(0xFFE2E8F0),
                color: const Color(0xFFD97706),
                minHeight: 8,
                borderRadius: BorderRadius.circular(4),
              ),
              const SizedBox(height: 12),
              Wrap(
                spacing: 12,
                runSpacing: 8,
                children: [
                  _buildPointsChip(context, 'Hackathons & Events: 35 pts'),
                  _buildPointsChip(context, 'Club Office Bearer: 15 pts'),
                  _buildPointsChip(context, 'Workshops & NPTEL: 15 pts'),
                ],
              ),
            ],
          ),
        ),

        const SizedBox(height: 24),

        // Account & Security Settings Card
        Material(
          color: AppColors.surfaceOf(context),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
            side: BorderSide(color: AppColors.borderOf(context)),
          ),
          child: Padding(
            padding: const EdgeInsets.all(22),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
              Text(
                'Security & Preferences',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                  color: AppColors.textPrimaryOf(context),
                ),
              ),
              const SizedBox(height: 16),

              // Theme Mode Toggle
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: const Color(0xFF0369A1).withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(
                    themeMode == ThemeMode.dark
                        ? Icons.light_mode_rounded
                        : Icons.dark_mode_rounded,
                    color: const Color(0xFF0284C7),
                    size: 20,
                  ),
                ),
                title: const Text('Theme Appearance'),
                subtitle: Text(
                  themeMode == ThemeMode.dark ? 'Dark Mode' : 'Light Mode',
                  style: TextStyle(
                    fontSize: 12,
                    color: AppColors.textSecondaryOf(context),
                  ),
                ),
                trailing: Switch(
                  value: themeMode == ThemeMode.dark,
                  onChanged: (val) {
                    ref.read(themeModeProvider.notifier).toggleTheme();
                  },
                ),
              ),

              const Divider(height: 20),

              // Security & 2FA Settings
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: const Color(0xFF16A34A).withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(
                    Icons.shield_outlined,
                    color: Color(0xFF16A34A),
                    size: 20,
                  ),
                ),
                title: const Text('Passkeys & 2FA Settings'),
                subtitle: Text(
                  'Hardware security keys & authenticator apps',
                  style: TextStyle(
                    fontSize: 12,
                    color: AppColors.textSecondaryOf(context),
                  ),
                ),
                trailing: const Icon(Icons.chevron_right_rounded),
                onTap: () {
                  unawaited(context.push(RouteNames.securitySettings));
                },
              ),

              const Divider(height: 20),

              // Sign Out Action
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppColors.error.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(
                    Icons.logout_rounded,
                    color: AppColors.error,
                    size: 20,
                  ),
                ),
                title: const Text(
                  'Sign Out of Campus Portal',
                  style: TextStyle(color: AppColors.error),
                ),
                subtitle: Text(
                  'Clears cached sessions and active tokens',
                  style: TextStyle(
                    fontSize: 12,
                    color: AppColors.textSecondaryOf(context),
                  ),
                ),
                trailing: const Icon(
                  Icons.arrow_forward_rounded,
                  color: AppColors.error,
                ),
                onTap: () async {
                  await ref.read(authStateProvider.notifier).signOut();
                },
              ),
            ],
          ),
        ),
      ),
    ],
  );
  }

  Widget _buildPointsChip(BuildContext context, String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: AppColors.isDark(context)
            ? const Color(0xFF1E293B)
            : const Color(0xFFF1F5F9),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w600,
          color: AppColors.textSecondaryOf(context),
        ),
      ),
    );
  }
}
