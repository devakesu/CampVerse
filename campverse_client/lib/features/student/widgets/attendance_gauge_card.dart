import 'dart:math';

import 'package:campverse/core/theme/app_colors.dart';
import 'package:campverse/features/student/models/student_attendance.dart';
import 'package:flutter/material.dart';

/// Highly visual attendance gauge card with KTU 75% threshold indicator
/// and interactive bunk projection tool.
class AttendanceGaugeCard extends StatefulWidget {
  /// Default constructor.
  const AttendanceGaugeCard({
    required this.attendance,
    this.onViewDetails,
    super.key,
  });

  /// Attendance metrics dataset.
  final OverallAttendance attendance;

  /// Optional callback to view subject-wise breakdown.
  final VoidCallback? onViewDetails;

  @override
  State<AttendanceGaugeCard> createState() => _AttendanceGaugeCardState();
}

class _AttendanceGaugeCardState extends State<AttendanceGaugeCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _animCtrl;
  late Animation<double> _progressAnim;
  int _projectedMissed = 0;

  @override
  void initState() {
    super.initState();
    _animCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );
    _progressAnim = CurvedAnimation(
      parent: _animCtrl,
      curve: Curves.easeOutCubic,
    );
    _animCtrl.forward();
  }

  @override
  void dispose() {
    _animCtrl.dispose();
    super.dispose();
  }

  Color _getStatusColor(AttendanceStatus status) {
    switch (status) {
      case AttendanceStatus.safe:
        return const Color(0xFF16A34A);
      case AttendanceStatus.marginal:
        return const Color(0xFFD97706);
      case AttendanceStatus.critical:
        return AppColors.error;
    }
  }

  String _getStatusLabel(AttendanceStatus status) {
    switch (status) {
      case AttendanceStatus.safe:
        return 'Safe Zone (>=80%)';
      case AttendanceStatus.marginal:
        return 'Marginal (75-80%)';
      case AttendanceStatus.critical:
        return 'Shortage Alert (<75%)';
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = AppColors.isDark(context);
    final att = widget.attendance;
    final percentage = att.overallPercentage;
    final statusColor = _getStatusColor(att.status);

    // Projected calculation
    final totalAtt = att.totalAttended;
    final projectedTotal = att.totalConducted + _projectedMissed;
    final projectedPct = projectedTotal > 0
        ? (totalAtt / projectedTotal) * 100
        : 100.0;

    return DecoratedBox(
      decoration: BoxDecoration(
        color: AppColors.surfaceOf(context),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: AppColors.borderOf(context),
          width: 1.2,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.04),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Title & Status Tag
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: statusColor.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Icon(
                          Icons.donut_large_rounded,
                          color: statusColor,
                          size: 20,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Overall Attendance',
                              style: TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w700,
                                color: AppColors.textPrimaryOf(context),
                              ),
                            ),
                            Text(
                              'KTU Minimum 75% Requirement',
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                fontSize: 11,
                                color: AppColors.textSecondaryOf(context),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 5,
                  ),
                  decoration: BoxDecoration(
                    color: statusColor.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: statusColor.withValues(alpha: 0.4),
                    ),
                  ),
                  child: Text(
                    _getStatusLabel(att.status),
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: statusColor,
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 20),

            // Radial Gauge & Quick Stats Row
            Row(
              children: [
                // Animated Circular Radial Gauge
                SizedBox(
                  width: 110,
                  height: 110,
                  child: AnimatedBuilder(
                    animation: _progressAnim,
                    builder: (context, _) {
                      final currentVal =
                          percentage * _progressAnim.value / 100.0;
                      final displayPct = (percentage * _progressAnim.value)
                          .toStringAsFixed(1);
                      return CustomPaint(
                        painter: _RadialGaugePainter(
                          value: currentVal,
                          accentColor: statusColor,
                          trackColor: isDark
                              ? const Color(0xFF1E293B)
                              : const Color(0xFFE2E8F0),
                        ),
                        child: Center(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                '$displayPct%',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.w800,
                                  color: AppColors.textPrimaryOf(context),
                                ),
                              ),
                              Text(
                                '${att.totalAttended}/${att.totalConducted} hrs',
                                style: TextStyle(
                                  fontSize: 10,
                                  color: AppColors.textSecondaryOf(context),
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),

                const SizedBox(width: 20),

                // Stat metrics breakdown
                Expanded(
                  child: Column(
                    children: [
                      _buildMiniStat(
                        context,
                        'Classes Attended',
                        '${att.totalAttended} Hours',
                        Icons.check_circle_outline_rounded,
                        const Color(0xFF16A34A),
                      ),
                      const SizedBox(height: 8),
                      _buildMiniStat(
                        context,
                        'Classes Conducted',
                        '${att.totalConducted} Hours',
                        Icons.schedule_rounded,
                        AppColors.textSecondaryOf(context),
                      ),
                      const SizedBox(height: 8),
                      _buildMiniStat(
                        context,
                        'Risk Subjects',
                        att.shortageSubjectsCount > 0
                            ? '${att.shortageSubjectsCount} Subjects < 75%'
                            : 'All Subjects Safe',
                        Icons.warning_amber_rounded,
                        att.shortageSubjectsCount > 0
                            ? AppColors.error
                            : const Color(0xFF16A34A),
                      ),
                    ],
                  ),
                ),
              ],
            ),

            const SizedBox(height: 16),
            const Divider(height: 1),
            const SizedBox(height: 14),

            // Smart Projection Simulator
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Projection Simulator',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: AppColors.textPrimaryOf(context),
                        ),
                      ),
                      Text(
                        _projectedMissed == 0
                            ? 'If you miss upcoming classes, see your impact'
                            : 'Missing $_projectedMissed more classes brings '
                                'overall to '
                                '${projectedPct.toStringAsFixed(1)}%',
                        style: TextStyle(
                          fontSize: 11,
                          color: projectedPct < 75.0
                              ? AppColors.error
                              : AppColors.textSecondaryOf(context),
                        ),
                      ),
                    ],
                  ),
                ),
                Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.remove_circle_outline, size: 20),
                      onPressed: _projectedMissed > 0
                          ? () => setState(() => _projectedMissed--)
                          : null,
                      tooltip: 'Decrease missed classes',
                    ),
                    Text(
                      '$_projectedMissed hrs',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textPrimaryOf(context),
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.add_circle_outline, size: 20),
                      onPressed: () => setState(() => _projectedMissed++),
                      tooltip: 'Simulate missing another class',
                    ),
                  ],
                ),
              ],
            ),

            if (widget.onViewDetails != null) ...[
              const SizedBox(height: 10),
              Align(
                alignment: Alignment.centerRight,
                child: TextButton.icon(
                  onPressed: widget.onViewDetails,
                  icon: const Icon(Icons.arrow_forward_rounded, size: 16),
                  label: const Text('View Subject Breakdown'),
                  style: TextButton.styleFrom(
                    visualDensity: VisualDensity.compact,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildMiniStat(
    BuildContext context,
    String label,
    String value,
    IconData icon,
    Color color,
  ) {
    return Row(
      children: [
        Icon(icon, size: 14, color: color),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            label,
            style: TextStyle(
              fontSize: 11,
              color: AppColors.textSecondaryOf(context),
            ),
          ),
        ),
        Text(
          value,
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w700,
            color: AppColors.textPrimaryOf(context),
          ),
        ),
      ],
    );
  }
}

class _RadialGaugePainter extends CustomPainter {
  const _RadialGaugePainter({
    required this.value,
    required this.accentColor,
    required this.trackColor,
  });

  final double value; // 0.0 to 1.0
  final Color accentColor;
  final Color trackColor;

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = (size.width / 2) - 8;
    const strokeWidth = 8.5;

    // Track circle
    final trackPaint = Paint()
      ..color = trackColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;

    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      -pi / 2,
      2 * pi,
      false,
      trackPaint,
    );

    // 75% minimum marker tick
    const markerAngle = pi;
    final tickInner = Offset(
      center.dx + (radius - strokeWidth / 2 - 2) * cos(markerAngle),
      center.dy + (radius - strokeWidth / 2 - 2) * sin(markerAngle),
    );
    final tickOuter = Offset(
      center.dx + (radius + strokeWidth / 2 + 2) * cos(markerAngle),
      center.dy + (radius + strokeWidth / 2 + 2) * sin(markerAngle),
    );
    canvas.drawLine(
      tickInner,
      tickOuter,
      Paint()
        ..color = const Color(0xFFDC2626)
        ..strokeWidth = 2,
    );

    // Progress arc
    final progressPaint = Paint()
      ..color = accentColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;

    final sweepAngle = (2 * pi) * value.clamp(0.0, 1.0);
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      -pi / 2,
      sweepAngle,
      false,
      progressPaint,
    );
  }

  @override
  bool shouldRepaint(covariant _RadialGaugePainter oldDelegate) =>
      oldDelegate.value != value ||
      oldDelegate.accentColor != accentColor ||
      oldDelegate.trackColor != trackColor;
}
