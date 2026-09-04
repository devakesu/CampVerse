import 'dart:async';

import 'package:campverse/core/providers/auth_provider.dart';
import 'package:campverse/core/theme/app_colors.dart';
import 'package:campverse/core/utils/responsive_layout.dart';
import 'package:campverse/features/student/models/student_registration.dart';
import 'package:campverse/features/student/providers/student_providers.dart';
import 'package:campverse/features/student/widgets/attendance_gauge_card.dart';
import 'package:campverse/features/student/widgets/event_card.dart';
import 'package:campverse/features/student/widgets/qr_pass_dialog.dart';
import 'package:campverse/features/student/widgets/timetable_schedule_view.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Central student dashboard overview: hero greeting, quick stats,
/// today's schedule, active pass shortcut, and featured events.
class StudentOverviewTab extends ConsumerWidget {
  /// Default constructor.
  const StudentOverviewTab({
    this.onNavigateToAcademics,
    this.onNavigateToEvents,
    super.key,
  });

  /// Optional callback to navigate to the Academics tab.
  final VoidCallback? onNavigateToAcademics;

  /// Optional callback to navigate to the Events tab.
  final VoidCallback? onNavigateToEvents;

  String _getGreeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) {
      return 'Good Morning';
    }
    if (hour < 17) {
      return 'Good Afternoon';
    }
    return 'Good Evening';
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = AppColors.isDark(context);
    final isDesktop = ResponsiveLayout.isDesktop(context);
    final authState = ref.watch(authStateProvider);
    final user = authState.user;

    final userName = (user?.userMetadata?['full_name'] as String?) ??
        (user?.email?.split('@').first ?? 'Alex');

    final classAsync = ref.watch(studentClassDetailsProvider);
    final timetableAsync = ref.watch(studentTimetableProvider);
    final eventsAsync = ref.watch(studentEventsProvider);
    final regsAsync = ref.watch(studentRegistrationsProvider);
    final attendance = ref.watch(studentAttendanceProvider);

    final classDetails = classAsync.value;
    final activeRegistrations = regsAsync.value
            ?.where((r) => r.isActive)
            .toList() ??
        const <StudentRegistration>[];

    final featuredEvents = eventsAsync.value
            ?.where((e) => e.isFeatured)
            .toList() ??
        eventsAsync.value?.take(1).toList() ??
        const [];

    return RefreshIndicator(
      onRefresh: () async {
        ref
          ..invalidate(studentClassDetailsProvider)
          ..invalidate(studentTimetableProvider);
        await ref.read(studentEventsProvider.notifier).loadEvents();
        await ref
            .read(studentRegistrationsProvider.notifier)
            .loadRegistrations();
      },
      child: ListView(
        padding: EdgeInsets.symmetric(
          horizontal: isDesktop ? 32 : 18,
          vertical: 24,
        ),
        children: [
          // ── Hero Greeting Card ─────────────────────────────────────────────
          Container(
            padding: EdgeInsets.all(isDesktop ? 28 : 20),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: isDark
                    ? [
                        const Color(0xFF0F172A),
                        const Color(0xFF0369A1).withValues(alpha: 0.3),
                      ]
                    : [
                        const Color(0xFF0369A1),
                        const Color(0xFF0284C7),
                      ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(24),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF0369A1).withValues(alpha: 0.25),
                  blurRadius: 20,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            child: Row(
              children: [
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
                              color: Colors.white.withValues(alpha: 0.2),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(
                                  Icons.school_rounded,
                                  size: 13,
                                  color: Colors.white,
                                ),
                                const SizedBox(width: 6),
                                Text(
                                  classDetails?.displayName ??
                                      'S6 CSE - Div A',
                                  style: const TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w700,
                                    color: Colors.white,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 10),
                          Text(
                            classDetails?.departmentCode ?? 'CSE',
                            style: const TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: Colors.white70,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Text(
                        '${_getGreeting()}, $userName! 👋',
                        style: TextStyle(
                          fontSize: isDesktop ? 24 : 20,
                          fontWeight: FontWeight.w800,
                          color: Colors.white,
                          letterSpacing: -0.5,
                        ),
                      ),
                      const SizedBox(height: 6),
                      const Text(
                        "Campus Hub is active. Check today's timetable periods "
                        'and active event passes below.',
                        style: TextStyle(
                          fontSize: 13,
                          color: Colors.white70,
                          height: 1.4,
                        ),
                      ),
                    ],
                  ),
                ),
                if (isDesktop) ...[
                  const SizedBox(width: 24),
                  Container(
                    width: 72,
                    height: 72,
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.15),
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: Colors.white.withValues(alpha: 0.4),
                        width: 2,
                      ),
                    ),
                    child: Center(
                      child: Text(
                        userName.isNotEmpty ? userName[0].toUpperCase() : 'S',
                        style: const TextStyle(
                          fontSize: 32,
                          fontWeight: FontWeight.w800,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),

          const SizedBox(height: 24),

          // ── Quick Metric Stat Row ──────────────────────────────────────────
          LayoutBuilder(
            builder: (context, constraints) {
              final isWide = constraints.maxWidth > 700;
              return GridView.count(
                crossAxisCount: isWide ? 4 : 2,
                crossAxisSpacing: 14,
                mainAxisSpacing: 14,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                childAspectRatio: isWide ? 1.6 : 1.4,
                children: [
                  _buildStatCard(
                    context,
                    'Attendance',
                    '${attendance.overallPercentage.toStringAsFixed(1)}%',
                    'Safe Zone (>=75%)',
                    Icons.donut_large_rounded,
                    const Color(0xFF16A34A),
                    onTap: onNavigateToAcademics,
                  ),
                  _buildStatCard(
                    context,
                    "Today's Period",
                    'Period 3 (LH-302)',
                    'Networks • 11:15 AM',
                    Icons.access_time_rounded,
                    const Color(0xFF0284C7),
                    onTap: onNavigateToAcademics,
                  ),
                  _buildStatCard(
                    context,
                    'Active Passes',
                    '${activeRegistrations.length} Passes',
                    activeRegistrations.isNotEmpty
                        ? '1 Hackathon pass ready'
                        : 'No active tickets',
                    Icons.confirmation_number_rounded,
                    const Color(0xFF8B5CF6),
                    onTap: onNavigateToEvents,
                  ),
                  _buildStatCard(
                    context,
                    'KTU Activity',
                    '65 / 100 Pts',
                    '35 pts to graduation',
                    Icons.stars_rounded,
                    const Color(0xFFD97706),
                  ),
                ],
              );
            },
          ),

          const SizedBox(height: 28),

          // ── Active Pass Quick Ticket (if any) ──────────────────────────────
          if (activeRegistrations.isNotEmpty) ...[
            _buildActivePassBanner(context, activeRegistrations.first),
            const SizedBox(height: 28),
          ],

          // ── Dual Column: Today's Schedule & Attendance Gauge ───────────────
          if (isDesktop)
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  flex: 3,
                  child: _buildTodayScheduleSection(
                    context,
                    timetableAsync.value ?? const [],
                  ),
                ),
                const SizedBox(width: 24),
                Expanded(
                  flex: 2,
                  child: Column(
                    children: [
                      AttendanceGaugeCard(
                        attendance: attendance,
                        onViewDetails: onNavigateToAcademics,
                      ),
                      const SizedBox(height: 20),
                      if (featuredEvents.isNotEmpty)
                        EventCard(
                          event: featuredEvents.first,
                          onRegistered: () {
                            unawaited(
                              ref
                                  .read(studentRegistrationsProvider.notifier)
                                  .loadRegistrations(),
                            );
                          },
                        ),
                    ],
                  ),
                ),
              ],
            )
          else ...[
            AttendanceGaugeCard(
              attendance: attendance,
              onViewDetails: onNavigateToAcademics,
            ),
            const SizedBox(height: 24),
            _buildTodayScheduleSection(
              context,
              timetableAsync.value ?? const [],
            ),
            if (featuredEvents.isNotEmpty) ...[
              const SizedBox(height: 24),
              Text(
                'Featured Campus Event',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                  color: AppColors.textPrimaryOf(context),
                ),
              ),
              const SizedBox(height: 12),
              EventCard(
                event: featuredEvents.first,
                onRegistered: () {
                  unawaited(
                    ref
                        .read(studentRegistrationsProvider.notifier)
                        .loadRegistrations(),
                  );
                },
              ),
            ],
          ],

          const SizedBox(height: 32),
        ],
      ),
    );
  }

  Widget _buildStatCard(
    BuildContext context,
    String label,
    String value,
    String subtitle,
    IconData icon,
    Color color, {
    VoidCallback? onTap,
  }) {
    final isDark = AppColors.isDark(context);

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(18),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.surfaceOf(context),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: AppColors.borderOf(context)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.03),
              blurRadius: 10,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textSecondaryOf(context),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.12),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(icon, color: color, size: 16),
                ),
              ],
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  value,
                  style: TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w800,
                    color: AppColors.textPrimaryOf(context),
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: TextStyle(
                    fontSize: 10,
                    color: AppColors.textSecondaryOf(context),
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActivePassBanner(
    BuildContext context,
    StudentRegistration reg,
  ) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF16A34A).withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: const Color(0xFF16A34A).withValues(alpha: 0.4),
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: const BoxDecoration(
              color: Color(0xFF16A34A),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.qr_code_rounded,
              color: Colors.white,
              size: 20,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Text(
                      'ACTIVE DIGITAL ENTRY PASS',
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 0.8,
                        color: Color(0xFF16A34A),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 6,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFF16A34A).withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        reg.qrPayload,
                        style: const TextStyle(
                          fontSize: 9,
                          fontFamily: 'monospace',
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF16A34A),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  reg.event?.title ?? 'Campus Entry Pass',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimaryOf(context),
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          ElevatedButton.icon(
            onPressed: () => QrPassDialog.show(context, reg),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF16A34A),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(
                horizontal: 12,
                vertical: 8,
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            icon: const Icon(Icons.fullscreen_rounded, size: 16),
            label: const Text(
              'Show Pass',
              style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTodayScheduleSection(
    BuildContext context,
    List<dynamic> allTimetables,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              "Today's Class Schedule",
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w800,
                color: AppColors.textPrimaryOf(context),
              ),
            ),
            if (onNavigateToAcademics != null)
              TextButton.icon(
                onPressed: onNavigateToAcademics,
                icon: const Icon(Icons.calendar_month_outlined, size: 16),
                label: const Text('Full Timetable'),
                style: TextButton.styleFrom(
                  visualDensity: VisualDensity.compact,
                ),
              ),
          ],
        ),
        const SizedBox(height: 12),
        TimetableScheduleView(
          entries: allTimetables.cast(),
        ),
      ],
    );
  }
}
