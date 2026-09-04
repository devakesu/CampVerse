import 'package:campverse/core/theme/app_colors.dart';
import 'package:campverse/features/student/models/student_timetable_entry.dart';
import 'package:flutter/material.dart';

/// Weekly and daily timetable schedule matrix with live active period
/// indicator.
class TimetableScheduleView extends StatefulWidget {
  /// Default constructor.
  const TimetableScheduleView({
    required this.entries,
    this.initialDay,
    super.key,
  });

  /// All weekly timetable entries.
  final List<StudentTimetableEntry> entries;

  /// Optional initial day in lowercase ('monday'..'saturday').
  final String? initialDay;

  @override
  State<TimetableScheduleView> createState() => _TimetableScheduleViewState();
}

class _TimetableScheduleViewState extends State<TimetableScheduleView>
    with SingleTickerProviderStateMixin {
  late String _selectedDay;
  late AnimationController _pulseCtrl;

  static const List<(String, String)> _weekdays = [
    ('monday', 'Mon'),
    ('tuesday', 'Tue'),
    ('wednesday', 'Wed'),
    ('thursday', 'Thu'),
    ('friday', 'Fri'),
  ];

  @override
  void initState() {
    super.initState();
    final weekdayMap = {
      DateTime.monday: 'monday',
      DateTime.tuesday: 'tuesday',
      DateTime.wednesday: 'wednesday',
      DateTime.thursday: 'thursday',
      DateTime.friday: 'friday',
      DateTime.saturday: 'saturday',
      DateTime.sunday: 'monday',
    };
    _selectedDay =
        widget.initialDay ?? weekdayMap[DateTime.now().weekday] ?? 'monday';

    _pulseCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _pulseCtrl.dispose();
    super.dispose();
  }

  /// Calculates which period slot is currently active based on system hour.
  int? _getCurrentPeriodNumber() {
    final now = DateTime.now();
    final hour = now.hour;
    // Map standard college hours
    if (hour == 9) {
      return 1;
    }
    if (hour == 10) {
      return 2;
    }
    if (hour == 11) {
      return 3;
    }
    if (hour == 12) {
      return 4;
    }
    if (hour == 14) {
      return 5;
    }
    if (hour == 15) {
      return 6;
    }
    if (hour == 16) {
      return 7;
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final isDark = AppColors.isDark(context);
    final activePeriod = _getCurrentPeriodNumber();

    final dayEntries = widget.entries
        .where((e) => e.day == _selectedDay)
        .toList()
      ..sort((a, b) => a.periodNumber.compareTo(b.periodNumber));

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Day Switcher Filter Bar
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: _weekdays.map((day) {
              final isSelected = _selectedDay == day.$1;
              return Padding(
                padding: const EdgeInsets.only(right: 8),
                child: FilterChip(
                  selected: isSelected,
                  label: Text(day.$2),
                  labelStyle: TextStyle(
                    fontSize: 13,
                    fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                    color: isSelected
                        ? Colors.white
                        : AppColors.textPrimaryOf(context),
                  ),
                  backgroundColor: AppColors.surfaceOf(context),
                  selectedColor: const Color(0xFF0369A1),
                  checkmarkColor: Colors.white,
                  showCheckmark: false,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 8,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                    side: BorderSide(
                      color: isSelected
                          ? const Color(0xFF0369A1)
                          : AppColors.borderOf(context),
                    ),
                  ),
                  onSelected: (val) {
                    if (val) {
                      setState(() => _selectedDay = day.$1);
                    }
                  },
                ),
              );
            }).toList(),
          ),
        ),

        const SizedBox(height: 18),

        // Period Slots List
        if (dayEntries.isEmpty)
          Container(
            padding: const EdgeInsets.all(32),
            decoration: BoxDecoration(
              color: AppColors.surfaceOf(context),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppColors.borderOf(context)),
            ),
            child: Center(
              child: Column(
                children: [
                  Icon(
                    Icons.event_busy_rounded,
                    size: 36,
                    color: AppColors.textSecondaryOf(context),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    'No scheduled classes for this day',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textSecondaryOf(context),
                    ),
                  ),
                ],
              ),
            ),
          )
        else
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: dayEntries.length,
            separatorBuilder: (context, _) => const SizedBox(height: 10),
            itemBuilder: (context, index) {
              final slot = dayEntries[index];
              final isNow =
                  slot.periodNumber == activePeriod &&
                  _selectedDay ==
                      const [
                        'monday',
                        'tuesday',
                        'wednesday',
                        'thursday',
                        'friday',
                      ][DateTime.now().weekday - 1];

              return AnimatedContainer(
                duration: const Duration(milliseconds: 250),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: isNow
                      ? const Color(0xFF0369A1)
                          .withValues(alpha: isDark ? 0.2 : 0.08)
                      : AppColors.surfaceOf(context),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: isNow
                        ? const Color(0xFF0369A1)
                        : AppColors.borderOf(context),
                    width: isNow ? 2 : 1,
                  ),
                  boxShadow: isNow
                      ? [
                          BoxShadow(
                            color: const Color(0xFF0369A1)
                                .withValues(alpha: 0.15),
                            blurRadius: 12,
                            offset: const Offset(0, 4),
                          ),
                        ]
                      : null,
                ),
                child: Row(
                  children: [
                    // Period Number & Time
                    Container(
                      width: 65,
                      padding: const EdgeInsets.symmetric(
                        vertical: 6,
                        horizontal: 8,
                      ),
                      decoration: BoxDecoration(
                        color: isNow
                            ? const Color(0xFF0369A1)
                            : isDark
                                ? const Color(0xFF1E293B)
                                : const Color(0xFFF1F5F9),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            'P${slot.periodNumber}',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w800,
                              color: isNow
                                  ? Colors.white
                                  : AppColors.textPrimaryOf(context),
                            ),
                          ),
                          Text(
                            'PERIOD',
                            style: TextStyle(
                              fontSize: 8,
                              fontWeight: FontWeight.w700,
                              letterSpacing: 0.5,
                              color: isNow
                                  ? Colors.white70
                                  : AppColors.textSecondaryOf(context),
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(width: 14),

                    // Course Details
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 6,
                                  vertical: 2,
                                ),
                                decoration: BoxDecoration(
                                  color: slot.isLab
                                      ? const Color(0xFF059669)
                                          .withValues(alpha: 0.12)
                                      : const Color(0xFF0284C7)
                                          .withValues(alpha: 0.12),
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: Text(
                                  slot.courseCode,
                                  style: TextStyle(
                                    fontSize: 10,
                                    fontWeight: FontWeight.w700,
                                    color: slot.isLab
                                        ? const Color(0xFF059669)
                                        : const Color(0xFF0284C7),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  slot.timeSlot,
                                  style: TextStyle(
                                    fontSize: 11,
                                    color: AppColors.textSecondaryOf(context),
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Text(
                            slot.courseTitle,
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                              color: AppColors.textPrimaryOf(context),
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 3),
                          Text(
                            slot.instructorName,
                            style: TextStyle(
                              fontSize: 11,
                              color: AppColors.textSecondaryOf(context),
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(width: 10),

                    // Classroom / Lab Hall Badge & Live pulse
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 5,
                          ),
                          decoration: BoxDecoration(
                            color: isDark
                                ? const Color(0xFF1E293B)
                                : const Color(0xFFF1F5F9),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                              color: AppColors.borderOf(context),
                            ),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                slot.isLab
                                    ? Icons.biotech_rounded
                                    : Icons.meeting_room_outlined,
                                size: 13,
                                color: AppColors.textSecondaryOf(context),
                              ),
                              const SizedBox(width: 5),
                              Text(
                                slot.classroomHall,
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w700,
                                  color: AppColors.textPrimaryOf(context),
                                ),
                              ),
                            ],
                          ),
                        ),
                        if (isNow) ...[
                          const SizedBox(height: 6),
                          AnimatedBuilder(
                            animation: _pulseCtrl,
                            builder: (context, child) {
                              return Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Container(
                                    width: 8,
                                    height: 8,
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      color: const Color(0xFF16A34A),
                                      boxShadow: [
                                        BoxShadow(
                                          color: const Color(0xFF16A34A)
                                              .withValues(
                                            alpha: _pulseCtrl.value * 0.8,
                                          ),
                                          blurRadius: 6,
                                          spreadRadius: 2,
                                        ),
                                      ],
                                    ),
                                  ),
                                  const SizedBox(width: 4),
                                  const Text(
                                    'LIVE NOW',
                                    style: TextStyle(
                                      fontSize: 9,
                                      fontWeight: FontWeight.w800,
                                      letterSpacing: 0.6,
                                      color: Color(0xFF16A34A),
                                    ),
                                  ),
                                ],
                              );
                            },
                          ),
                        ],
                      ],
                    ),
                  ],
                ),
              );
            },
          ),
      ],
    );
  }
}
