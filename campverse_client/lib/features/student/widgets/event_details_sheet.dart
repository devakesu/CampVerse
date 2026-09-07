import 'dart:async';

import 'package:campverse/core/theme/app_colors.dart';
import 'package:campverse/features/student/models/student_event.dart';
import 'package:campverse/features/student/models/student_registration.dart';
import 'package:campverse/features/student/providers/student_providers.dart';
import 'package:campverse/features/student/widgets/qr_pass_dialog.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:url_launcher/url_launcher.dart';

/// Comprehensive modal bottom sheet rendering the complete event dossier.
class EventDetailsSheet extends ConsumerStatefulWidget {
  /// Default constructor.
  const EventDetailsSheet({
    required this.event,
    this.onRegistered,
    super.key,
  });

  /// Event dataset.
  final StudentEvent event;

  /// Callback executed upon successful registration.
  final VoidCallback? onRegistered;

  /// Convenience helper to display the sheet modally.
  static Future<void> show(
    BuildContext context,
    StudentEvent event, {
    VoidCallback? onRegistered,
  }) {
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => EventDetailsSheet(
        event: event,
        onRegistered: onRegistered,
      ),
    );
  }

  @override
  ConsumerState<EventDetailsSheet> createState() => _EventDetailsSheetState();
}

class _EventDetailsSheetState extends ConsumerState<EventDetailsSheet> {
  bool _isRegistering = false;
  Timer? _countdownTimer;

  @override
  void initState() {
    super.initState();
    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) {
        setState(() {});
      }
    });
  }

  @override
  void dispose() {
    _countdownTimer?.cancel();
    super.dispose();
  }

  Future<void> _handleRegister() async {
    setState(() => _isRegistering = true);
    final success = await ref
        .read(studentEventsProvider.notifier)
        .register(widget.event.id);

    setState(() => _isRegistering = false);

    if (!mounted) {
      return;
    }

    if (success) {
      await ref
          .read(studentRegistrationsProvider.notifier)
          .loadRegistrations();

      if (!mounted) {
        return;
      }

      Navigator.of(context).pop();

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Registration confirmed! Digital Pass generated.'),
          backgroundColor: Color(0xFF16A34A),
        ),
      );

      widget.onRegistered?.call();
      _openMyPass();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Registration could not be completed. Try again.'),
          backgroundColor: Color(0xFFDC2626),
        ),
      );
    }
  }

  void _openMyPass() {
    final allRegs = ref.read(studentRegistrationsProvider).value ?? const [];
    final existing = allRegs.where((r) => r.eventId == widget.event.id);
    final pass = existing.isNotEmpty
        ? existing.first
        : StudentRegistration(
            id: 'reg-${widget.event.id}',
            eventId: widget.event.id,
            userId: 'me',
            qrPayload: 'CAMP-PASS-${widget.event.id.hashCode.abs()}',
            status: 'confirmed',
            createdAt: DateTime.now(),
            event: widget.event,
          );

    unawaited(QrPassDialog.show(context, pass));
  }

  Future<void> _launchExternalUrl(String url) async {
    final uri = Uri.tryParse(url);
    if (uri != null) {
      try {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      } on Object catch (_) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Could not open $url')),
          );
        }
      }
    }
  }

  Future<void> _callPhone(String phone) async {
    final cleanPhone = phone.replaceAll(RegExp(r'\s+'), '');
    final uri = Uri(scheme: 'tel', path: cleanPhone);
    try {
      await launchUrl(uri);
    } on Object catch (_) {
      await Clipboard.setData(ClipboardData(text: phone));
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Copied $phone to clipboard')),
        );
      }
    }
  }

  Future<void> _sendEmail(String email) async {
    final uri = Uri(scheme: 'mailto', path: email.trim());
    try {
      await launchUrl(uri);
    } on Object catch (_) {
      await Clipboard.setData(ClipboardData(text: email));
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Copied $email to clipboard')),
        );
      }
    }
  }

  IconData _getCtaIcon(StudentEvent event) {
    if (event.isCancelled) {
      return Icons.cancel_outlined;
    }
    if (event.isCompleted) {
      return Icons.event_available_outlined;
    }
    if (event.isRegistrationOpen) {
      return Icons.confirmation_number_rounded;
    }
    if (event.isRegistrationUpcoming) {
      return Icons.schedule_outlined;
    }
    return Icons.lock_clock_outlined;
  }

  String _getCtaLabel(StudentEvent event) {
    if (_isRegistering) {
      return 'Generating Pass...';
    }
    if (event.isCancelled) {
      return 'Event Cancelled';
    }
    if (event.isCompleted) {
      return 'Event Concluded';
    }
    if (event.isRegistrationOpen) {
      return 'One-Click Pass Registration';
    }
    if (event.isRegistrationUpcoming) {
      return 'Registration Opens Soon';
    }
    return 'Registration Closed';
  }

  String _formatDateTimeRange(DateTime start, DateTime end) {
    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
    ];
    final startMonth = months[start.month - 1];
    final endMonth = months[end.month - 1];

    final startHour = start.hour > 12
        ? start.hour - 12
        : (start.hour == 0 ? 12 : start.hour);
    final startPeriod = start.hour >= 12 ? 'PM' : 'AM';
    final startMin = start.minute.toString().padLeft(2, '0');

    final endHour = end.hour > 12
        ? end.hour - 12
        : (end.hour == 0 ? 12 : end.hour);
    final endPeriod = end.hour >= 12 ? 'PM' : 'AM';
    final endMin = end.minute.toString().padLeft(2, '0');

    if (start.day == end.day && start.month == end.month) {
      return '$startMonth ${start.day}, ${start.year} • '
          '$startHour:$startMin $startPeriod – $endHour:$endMin $endPeriod';
    }
    return '$startMonth ${start.day} – $endMonth ${end.day}, ${end.year}';
  }

  String _formatDeadline(DateTime dt) {
    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
    ];
    final hour = dt.hour > 12 ? dt.hour - 12 : (dt.hour == 0 ? 12 : dt.hour);
    final period = dt.hour >= 12 ? 'PM' : 'AM';
    final min = dt.minute.toString().padLeft(2, '0');
    return '${months[dt.month - 1]} ${dt.day}, ${dt.year} • $hour:$min $period';
  }

  @override
  Widget build(BuildContext context) {
    final isDark = AppColors.isDark(context);
    final event = widget.event;
    final surface = AppColors.surfaceOf(context);
    final textPrimary = AppColors.textPrimaryOf(context);
    final textSecondary = AppColors.textSecondaryOf(context);
    final border = AppColors.borderOf(context);

    final size = MediaQuery.of(context).size;
    final maxSheetHeight = size.height * 0.90;

    return Center(
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxWidth: 720,
          maxHeight: maxSheetHeight,
        ),
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: surface,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
            border: Border.all(color: border),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: isDark ? 0.4 : 0.15),
                blurRadius: 36,
                offset: const Offset(0, -4),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius:
                const BorderRadius.vertical(top: Radius.circular(28)),
            child: Column(
              children: [
                // Drag handle
                Center(
                  child: Container(
                    margin: const EdgeInsets.only(top: 10, bottom: 6),
                    width: 44,
                    height: 4,
                    decoration: BoxDecoration(
                      color: border,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),

                // Scrollable Content
                Expanded(
                  child: ListView(
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    children: [
                      // Poster Image Banner if available
                      if (event.posterUrl != null &&
                          event.posterUrl!.isNotEmpty) ...[
                        const SizedBox(height: 8),
                        ClipRRect(
                          borderRadius: BorderRadius.circular(20),
                          child: Stack(
                            children: [
                              Image.network(
                                event.posterUrl!,
                                height: 200,
                                width: double.infinity,
                                fit: BoxFit.cover,
                                errorBuilder: (context, error, stackTrace) =>
                                    const SizedBox(),
                              ),
                              Positioned(
                                top: 12,
                                right: 12,
                                child: IconButton.filled(
                                  style: IconButton.styleFrom(
                                    backgroundColor:
                                        Colors.black.withValues(alpha: 0.5),
                                    foregroundColor: Colors.white,
                                  ),
                                  icon: const Icon(
                                    Icons.close_rounded,
                                    size: 18,
                                  ),
                                  onPressed: () => Navigator.of(context).pop(),
                                ),
                              ),
                              if (event.isFeatured)
                                Positioned(
                                  top: 12,
                                  left: 12,
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 10,
                                      vertical: 4,
                                    ),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFF0369A1),
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        const Icon(
                                          Icons.bolt_rounded,
                                          color: Colors.white,
                                          size: 14,
                                        ),
                                        const SizedBox(width: 4),
                                        Text(
                                          'FEATURED',
                                          style: GoogleFonts.inter(
                                            fontSize: 10,
                                            fontWeight: FontWeight.w800,
                                            color: Colors.white,
                                            letterSpacing: 0.6,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 16),
                      ] else ...[
                        // Top Navigation / Close Row when no poster exists
                        const SizedBox(height: 4),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            if (event.isFeatured)
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 10,
                                  vertical: 4,
                                ),
                                decoration: BoxDecoration(
                                  color: const Color(0xFF0369A1),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    const Icon(
                                      Icons.bolt_rounded,
                                      color: Colors.white,
                                      size: 14,
                                    ),
                                    const SizedBox(width: 4),
                                    Text(
                                      'FEATURED',
                                      style: GoogleFonts.inter(
                                        fontSize: 10,
                                        fontWeight: FontWeight.w800,
                                        color: Colors.white,
                                        letterSpacing: 0.6,
                                      ),
                                    ),
                                  ],
                                ),
                              )
                            else
                              const SizedBox.shrink(),
                            IconButton(
                              icon: const Icon(Icons.close_rounded),
                              color: textSecondary,
                              tooltip: 'Close',
                              onPressed: () => Navigator.of(context).pop(),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                      ],

                      // Cancellation or Completion Status Banner
                      if (event.isCancelled) ...[
                        Container(
                          width: double.infinity,
                          margin: const EdgeInsets.only(bottom: 16),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 14,
                            vertical: 10,
                          ),
                          decoration: BoxDecoration(
                            color: const Color(0xFFDC2626)
                                .withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: const Color(0xFFDC2626)
                                  .withValues(alpha: 0.3),
                            ),
                          ),
                          child: Row(
                            children: [
                              const Icon(
                                Icons.cancel_outlined,
                                color: Color(0xFFDC2626),
                                size: 20,
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Text(
                                  'This event has been officially cancelled by '
                                  'the organizers.',
                                  style: GoogleFonts.inter(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                    color: const Color(0xFFDC2626),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ] else if (event.isCompleted) ...[
                        Container(
                          width: double.infinity,
                          margin: const EdgeInsets.only(bottom: 16),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 14,
                            vertical: 10,
                          ),
                          decoration: BoxDecoration(
                            color: isDark
                                ? const Color(0xFF334155).withValues(alpha: 0.4)
                                : const Color(0xFFE2E8F0),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: border),
                          ),
                          child: Row(
                            children: [
                              Icon(
                                Icons.check_circle_outline_rounded,
                                color: textSecondary,
                                size: 20,
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Text(
                                  'This event has concluded.',
                                  style: GoogleFonts.inter(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                    color: textSecondary,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],

                      // Host Organization Header
                      Row(
                        children: [
                          if (event.primaryOrgLogo != null &&
                              event.primaryOrgLogo!.isNotEmpty)
                            Padding(
                              padding: const EdgeInsets.only(right: 10),
                              child: CircleAvatar(
                                radius: 14,
                                backgroundColor: isDark
                                    ? const Color(0xFF1E293B)
                                    : const Color(0xFFF1F5F9),
                                backgroundImage:
                                    NetworkImage(event.primaryOrgLogo!),
                              ),
                            ),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: const Color(0xFF0369A1)
                                  .withValues(alpha: 0.12),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              event.primaryOrgName.toUpperCase(),
                              style: GoogleFonts.inter(
                                fontSize: 11,
                                fontWeight: FontWeight.w800,
                                color: const Color(0xFF0284C7),
                              ),
                            ),
                          ),
                          if (event.primaryOrgCategory != null) ...[
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: isDark
                                    ? const Color(0xFF1E293B)
                                    : const Color(0xFFF1F5F9),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(
                                event.primaryOrgCategory!,
                                style: GoogleFonts.inter(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w600,
                                  color: textSecondary,
                                ),
                              ),
                            ),
                          ],
                          const Spacer(),
                          if (event.isRegisteredByMe)
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 10,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: const Color(0xFF16A34A)
                                    .withValues(alpha: 0.12),
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Icon(
                                    Icons.verified_rounded,
                                    size: 13,
                                    color: Color(0xFF16A34A),
                                  ),
                                  const SizedBox(width: 5),
                                  Text(
                                    'REGISTERED',
                                    style: GoogleFonts.inter(
                                      fontSize: 10,
                                      fontWeight: FontWeight.w800,
                                      color: const Color(0xFF16A34A),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                        ],
                      ),

                      const SizedBox(height: 12),

                      // Title
                      Text(
                        event.title,
                        style: GoogleFonts.outfit(
                          fontSize: 22,
                          fontWeight: FontWeight.w800,
                          color: textPrimary,
                          letterSpacing: -0.4,
                          height: 1.25,
                        ),
                      ),

                      if (event.shortDescription != null &&
                          event.shortDescription!.isNotEmpty) ...[
                        const SizedBox(height: 8),
                        Text(
                          event.shortDescription!,
                          style: GoogleFonts.inter(
                            fontSize: 13,
                            fontWeight: FontWeight.w500,
                            color: textSecondary,
                            height: 1.5,
                          ),
                        ),
                      ],

                      // Classification Tags Chips
                      if (event.tags.isNotEmpty) ...[
                        const SizedBox(height: 10),
                        Wrap(
                          spacing: 6,
                          runSpacing: 6,
                          children: event.tags.map((tag) {
                            return Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 3,
                              ),
                              decoration: BoxDecoration(
                                color: isDark
                                    ? const Color(0xFF1E293B)
                                    : const Color(0xFFF1F5F9),
                                borderRadius: BorderRadius.circular(6),
                                border: Border.all(color: border),
                              ),
                              child: Text(
                                '#$tag',
                                style: GoogleFonts.inter(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600,
                                  color: textSecondary,
                                ),
                              ),
                            );
                          }).toList(),
                        ),
                      ],

                      const SizedBox(height: 16),

                      // Venue & Schedule Card
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: isDark
                              ? const Color(0xFF1E293B).withValues(alpha: 0.6)
                              : const Color(0xFFF8FAFC),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: border),
                        ),
                        child: Column(
                          children: [
                            _buildInfoRow(
                              Icons.calendar_month_outlined,
                              'Schedule',
                              _formatDateTimeRange(
                                event.startTime,
                                event.endTime,
                              ),
                              textPrimary,
                              textSecondary,
                            ),
                            Divider(height: 20, color: border),
                            _buildInfoRow(
                              Icons.location_on_outlined,
                              'Venue',
                              event.venue,
                              textPrimary,
                              textSecondary,
                            ),
                            if (event.maxCapacity != null &&
                                event.maxCapacity! > 0) ...[
                              Divider(height: 20, color: border),
                              _buildInfoRow(
                                Icons.groups_outlined,
                                'Max Capacity',
                                '${event.maxCapacity} Attendees',
                                textPrimary,
                                textSecondary,
                              ),
                            ],
                            if (!event.regConfig) ...[
                              Divider(height: 20, color: border),
                              _buildInfoRow(
                                Icons.door_front_door_outlined,
                                'Admission',
                                'Open Walk-in (No Prior Registration Needed)',
                                textPrimary,
                                textSecondary,
                              ),
                            ] else ...[
                              if (event.regStart != null) ...[
                                Divider(height: 20, color: border),
                                _buildInfoRow(
                                  Icons.how_to_reg_outlined,
                                  'Registration Starts',
                                  _formatDeadline(event.regStart!),
                                  textPrimary,
                                  textSecondary,
                                ),
                              ],
                              if (event.regEnd != null) ...[
                                Divider(height: 20, color: border),
                                _buildRegistrationDeadlineSection(
                                  context: context,
                                  event: event,
                                  isDark: isDark,
                                  textPrimary: textPrimary,
                                  textSecondary: textSecondary,
                                  border: border,
                                ),
                              ] else if (event.regStart == null) ...[
                                Divider(height: 20, color: border),
                                _buildInfoRow(
                                  Icons.how_to_reg_outlined,
                                  'Registration Status',
                                  event.isRegistrationOpen
                                      ? 'Registration Open (Ongoing)'
                                      : 'Registration Closed',
                                  textPrimary,
                                  textSecondary,
                                ),
                              ],
                            ],
                          ],
                        ),
                      ),

                      // Full Detailed Description
                      if (event.description != null &&
                          event.description!.isNotEmpty) ...[
                        const SizedBox(height: 20),
                        _buildSectionHeader('About the Event', textPrimary),
                        const SizedBox(height: 8),
                        Text(
                          event.description!,
                          style: GoogleFonts.inter(
                            fontSize: 13,
                            height: 1.6,
                            color: textSecondary,
                          ),
                        ),
                      ],

                      const SizedBox(height: 20),

                      // Official Incentives Vault
                      if (event.hasIncentives) ...[
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: const Color(0xFF8B5CF6)
                                .withValues(alpha: 0.08),
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color: const Color(0xFF8B5CF6)
                                  .withValues(alpha: 0.25),
                            ),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  const Icon(
                                    Icons.verified_outlined,
                                    size: 16,
                                    color: Color(0xFF8B5CF6),
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    'ACADEMIC & ATTENDANCE INCENTIVES',
                                    style: GoogleFonts.inter(
                                      fontSize: 11,
                                      fontWeight: FontWeight.w800,
                                      letterSpacing: 0.6,
                                      color: const Color(0xFF8B5CF6),
                                    ),
                                  ),
                                ],
                              ),
                              if (event.ktuActivityPoints > 0) ...[
                                const SizedBox(height: 12),
                                Row(
                                  children: [
                                    const Icon(
                                      Icons.stars_rounded,
                                      size: 18,
                                      color: Color(0xFF8B5CF6),
                                    ),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      child: Text(
                                        '+${event.ktuActivityPoints} '
                                        'KTU Activity Points Awarded',
                                        style: GoogleFonts.inter(
                                          fontSize: 13,
                                          fontWeight: FontWeight.w700,
                                          color: textPrimary,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                              const SizedBox(height: 8),
                              Row(
                                children: [
                                  Icon(
                                    event.isDutyLeaveApproved
                                        ? Icons.check_circle_outline_rounded
                                        : Icons.remove_circle_outline_rounded,
                                    size: 18,
                                    color: event.isDutyLeaveApproved
                                        ? const Color(0xFF16A34A)
                                        : Colors.grey,
                                  ),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Text(
                                      event.isDutyLeaveApproved
                                          ? 'Duty Leave Approved for '
                                              'Class Hours'
                                          : 'Duty Leave Not Applicable',
                                      style: GoogleFonts.inter(
                                        fontSize: 12,
                                        fontWeight: FontWeight.w600,
                                        color: textPrimary,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              if (event.isCertificateProvided) ...[
                                const SizedBox(height: 8),
                                Row(
                                  children: [
                                    const Icon(
                                      Icons.workspace_premium_outlined,
                                      size: 18,
                                      color: Color(0xFF0284C7),
                                    ),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      child: Text(
                                        'Verified Digital Certificate in '
                                        'Student Vault',
                                        style: GoogleFonts.inter(
                                          fontSize: 12,
                                          fontWeight: FontWeight.w600,
                                          color: textPrimary,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ],
                          ),
                        ),
                        const SizedBox(height: 20),
                      ],

                      // Eligibility Section
                      const SizedBox(height: 20),
                      _buildSectionHeader('Eligibility Criteria', textPrimary),
                      const SizedBox(height: 8),
                      _buildEligibilitySection(
                        context: context,
                        eligibility: event.eligibility,
                        isDark: isDark,
                        textPrimary: textPrimary,
                        textSecondary: textSecondary,
                        border: border,
                      ),

                      // Itinerary Timeline
                      if (event.itinerary.isNotEmpty) ...[
                        const SizedBox(height: 24),
                        _buildSectionHeader('Event Itinerary', textPrimary),
                        const SizedBox(height: 12),
                        ...event.itinerary.asMap().entries.map((entry) {
                          final i = entry.key;
                          final item = entry.value;
                          final isLast = i == event.itinerary.length - 1;

                          return Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Column(
                                children: [
                                  Container(
                                    width: 12,
                                    height: 12,
                                    decoration: const BoxDecoration(
                                      color: Color(0xFF0369A1),
                                      shape: BoxShape.circle,
                                    ),
                                  ),
                                  if (!isLast)
                                    Container(
                                      width: 2,
                                      height: 42,
                                      color: border,
                                    ),
                                ],
                              ),
                              const SizedBox(width: 14),
                              Expanded(
                                child: Padding(
                                  padding: const EdgeInsets.only(bottom: 14),
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        item.time,
                                        style: GoogleFonts.inter(
                                          fontSize: 11,
                                          fontWeight: FontWeight.w700,
                                          color: const Color(0xFF0284C7),
                                        ),
                                      ),
                                      const SizedBox(height: 2),
                                      Text(
                                        item.activity,
                                        style: GoogleFonts.inter(
                                          fontSize: 13,
                                          fontWeight: FontWeight.w500,
                                          color: textPrimary,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          );
                        }),
                      ],

                      // Pricing Tiers if Paid
                      if (event.isPaid &&
                          event.pricingTiers.isNotEmpty) ...[
                        const SizedBox(height: 20),
                        _buildSectionHeader('Ticket Passes', textPrimary),
                        const SizedBox(height: 10),
                        ...event.pricingTiers.map((tier) {
                          return Container(
                            margin: const EdgeInsets.only(bottom: 8),
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 12,
                            ),
                            decoration: BoxDecoration(
                              color: isDark
                                  ? const Color(0xFF1E293B)
                                  : const Color(0xFFF8FAFC),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: border),
                            ),
                            child: Row(
                              mainAxisAlignment:
                                  MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  tier.name,
                                  style: GoogleFonts.inter(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w600,
                                    color: textPrimary,
                                  ),
                                ),
                                Text(
                                  tier.formattedPrice(event.currency),
                                  style: GoogleFonts.inter(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w800,
                                    color: const Color(0xFF0369A1),
                                  ),
                                ),
                              ],
                            ),
                          );
                        }),
                      ],

                      // Collaborators
                      if (event.collaborators.isNotEmpty) ...[
                        const SizedBox(height: 20),
                        _buildSectionHeader('Co-Organizers', textPrimary),
                        const SizedBox(height: 10),
                        Wrap(
                          spacing: 12,
                          runSpacing: 10,
                          children: event.collaborators.map((collab) {
                            return _buildCollaboratorCard(
                              collab: collab,
                              isDark: isDark,
                              textPrimary: textPrimary,
                              textSecondary: textSecondary,
                              border: border,
                            );
                          }).toList(),
                        ),
                      ],

                      // Event Coordinators / Contacts
                      if (event.contacts.isNotEmpty) ...[
                        const SizedBox(height: 20),
                        _buildSectionHeader(
                          'Event Coordinators',
                          textPrimary,
                        ),
                        const SizedBox(height: 10),
                        ...event.contacts.map((contact) {
                          return Container(
                            margin: const EdgeInsets.only(bottom: 8),
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: isDark
                                  ? const Color(0xFF1E293B)
                                  : const Color(0xFFF8FAFC),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: border),
                            ),
                            child: Row(
                              children: [
                                CircleAvatar(
                                  radius: 16,
                                  backgroundColor: const Color(0xFF0369A1)
                                      .withValues(alpha: 0.15),
                                  child: const Icon(
                                    Icons.person_rounded,
                                    size: 18,
                                    color: Color(0xFF0284C7),
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        contact.name,
                                        style: GoogleFonts.inter(
                                          fontSize: 13,
                                          fontWeight: FontWeight.w700,
                                          color: textPrimary,
                                        ),
                                      ),
                                      Text(
                                        contact.role,
                                        style: GoogleFonts.inter(
                                          fontSize: 11,
                                          color: textSecondary,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                if (contact.phone.isNotEmpty)
                                  IconButton(
                                    icon: const Icon(
                                      Icons.phone_outlined,
                                      color: Color(0xFF16A34A),
                                      size: 20,
                                    ),
                                    tooltip: 'Call ${contact.name}',
                                    onPressed: () =>
                                        _callPhone(contact.phone),
                                  ),
                                if (contact.email != null &&
                                    contact.email!.isNotEmpty)
                                  IconButton(
                                    icon: const Icon(
                                      Icons.email_outlined,
                                      color: Color(0xFF0284C7),
                                      size: 20,
                                    ),
                                    tooltip: 'Email ${contact.name}',
                                    onPressed: () =>
                                        _sendEmail(contact.email!),
                                  ),
                              ],
                            ),
                          );
                        }),
                      ],

                      // External Links & Resources
                      if (event.links.isNotEmpty) ...[
                        const SizedBox(height: 20),
                        _buildSectionHeader(
                          'Official Links & Resources',
                          textPrimary,
                        ),
                        const SizedBox(height: 8),
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: event.links.entries.map((entry) {
                            final label = entry.key
                                .replaceAll('_', ' ')
                                .toUpperCase();
                            return OutlinedButton.icon(
                              onPressed: () =>
                                  _launchExternalUrl(entry.value),
                              style: OutlinedButton.styleFrom(
                                side: BorderSide(color: border),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 8,
                                ),
                              ),
                              icon: const Icon(
                                Icons.open_in_new_rounded,
                                size: 14,
                              ),
                              label: Text(
                                label,
                                style: GoogleFonts.inter(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            );
                          }).toList(),
                        ),
                      ],

                      // Event Media Gallery if available
                      if (event.mediaUrls.isNotEmpty) ...[
                        const SizedBox(height: 20),
                        _buildSectionHeader(
                          'Event Gallery',
                          textPrimary,
                        ),
                        const SizedBox(height: 10),
                        SizedBox(
                          height: 120,
                          child: ListView.separated(
                            scrollDirection: Axis.horizontal,
                            itemCount: event.mediaUrls.length,
                            separatorBuilder: (context, _) =>
                                const SizedBox(width: 10),
                            itemBuilder: (context, index) {
                              final url = event.mediaUrls[index];
                              return ClipRRect(
                                borderRadius: BorderRadius.circular(12),
                                child: Image.network(
                                  url,
                                  width: 160,
                                  height: 120,
                                  fit: BoxFit.cover,
                                  errorBuilder:
                                      (context, error, stackTrace) => Container(
                                    width: 160,
                                    height: 120,
                                    color: isDark
                                        ? const Color(0xFF1E293B)
                                        : const Color(0xFFF1F5F9),
                                    child: Icon(
                                      Icons.broken_image_outlined,
                                      color: textSecondary,
                                    ),
                                  ),
                                ),
                              );
                            },
                          ),
                        ),
                      ],

                      const SizedBox(height: 32),
                    ],
                  ),
                ),

                // Bottom CTA Action Bar
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: surface,
                    border: Border(top: BorderSide(color: border)),
                  ),
                  child: Row(
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            'REGISTRATION',
                            style: GoogleFonts.inter(
                              fontSize: 10,
                              fontWeight: FontWeight.w800,
                              color: textSecondary,
                              letterSpacing: 0.6,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            event.formattedPrice,
                            style: GoogleFonts.inter(
                              fontSize: 16,
                              fontWeight: FontWeight.w800,
                              color: event.isPaid
                                  ? textPrimary
                                  : const Color(0xFF16A34A),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(width: 24),
                      Expanded(
                        child: event.isRegisteredByMe
                            ? ElevatedButton.icon(
                                onPressed: _openMyPass,
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: const Color(0xFF16A34A),
                                  foregroundColor: Colors.white,
                                  padding: const EdgeInsets.symmetric(
                                    vertical: 14,
                                  ),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(14),
                                  ),
                                ),
                                icon: const Icon(
                                  Icons.qr_code_rounded,
                                  size: 18,
                                ),
                                label: Text(
                                  'View Active QR Pass',
                                  style: GoogleFonts.inter(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              )
                            : !event.regConfig
                                ? ElevatedButton.icon(
                                    onPressed: null,
                                    style: ElevatedButton.styleFrom(
                                      disabledBackgroundColor: isDark
                                          ? const Color(0xFF1E293B)
                                          : const Color(0xFFF1F5F9),
                                      disabledForegroundColor:
                                          const Color(0xFF0284C7),
                                      padding: const EdgeInsets.symmetric(
                                        vertical: 14,
                                      ),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(14),
                                        side: BorderSide(
                                          color: const Color(0xFF0284C7)
                                              .withValues(alpha: 0.3),
                                        ),
                                      ),
                                    ),
                                    icon: const Icon(
                                      Icons.door_front_door_outlined,
                                      size: 18,
                                      color: Color(0xFF0284C7),
                                    ),
                                    label: Text(
                                      'Walk-in Entry • No Pass Needed',
                                      style: GoogleFonts.inter(
                                        fontSize: 12,
                                        fontWeight: FontWeight.w700,
                                        color: const Color(0xFF0284C7),
                                      ),
                                    ),
                                  )
                                : ElevatedButton.icon(
                                    onPressed: (!event.isRegistrationOpen ||
                                            _isRegistering)
                                        ? null
                                        : () => unawaited(_handleRegister()),
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: const Color(0xFF0369A1),
                                      foregroundColor: Colors.white,
                                      disabledBackgroundColor: isDark
                                          ? const Color(0xFF334155)
                                          : const Color(0xFFE2E8F0),
                                      disabledForegroundColor: Colors.grey,
                                      padding: const EdgeInsets.symmetric(
                                        vertical: 14,
                                      ),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(14),
                                      ),
                                    ),
                                    icon: _isRegistering
                                        ? const SizedBox(
                                            width: 16,
                                            height: 16,
                                            child: CircularProgressIndicator(
                                              strokeWidth: 2,
                                              color: Colors.white,
                                            ),
                                          )
                                        : Icon(
                                            _getCtaIcon(event),
                                            size: 18,
                                          ),
                                    label: Text(
                                      _getCtaLabel(event),
                                      style: GoogleFonts.inter(
                                        fontSize: 13,
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                  ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title, Color textColor) {
    return Text(
      title,
      style: GoogleFonts.outfit(
        fontSize: 15,
        fontWeight: FontWeight.w800,
        color: textColor,
        letterSpacing: -0.2,
      ),
    );
  }

  Widget _buildInfoRow(
    IconData icon,
    String label,
    String value,
    Color textPrimary,
    Color textSecondary,
  ) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 18, color: textSecondary),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: GoogleFonts.inter(
                  fontSize: 11,
                  color: textSecondary,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                value,
                style: GoogleFonts.inter(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: textPrimary,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildEligibilityChip(IconData icon, String text, bool isDark) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : const Color(0xFFF1F5F9),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: isDark
              ? const Color(0xFF283548)
              : const Color(0xFFE2E8F0),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: const Color(0xFF0284C7)),
          const SizedBox(width: 6),
          Text(
            text,
            style: GoogleFonts.inter(
              fontSize: 11,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCountdownBox({
    required String value,
    required String label,
    required bool isDark,
    required bool isUrgent,
    required Color textSecondary,
  }) {
    final highlightColor =
        isUrgent ? const Color(0xFFD97706) : const Color(0xFF0284C7);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: isDark
            ? const Color(0xFF1E293B)
            : (isUrgent
                ? const Color(0xFFFEF3C7).withValues(alpha: 0.5)
                : const Color(0xFFF1F5F9)),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: highlightColor.withValues(alpha: 0.25),
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            value,
            style: GoogleFonts.outfit(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: highlightColor,
              letterSpacing: -0.5,
            ),
          ),
          const SizedBox(height: 1),
          Text(
            label,
            style: GoogleFonts.inter(
              fontSize: 9,
              fontWeight: FontWeight.w600,
              letterSpacing: 0.6,
              color: textSecondary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCountdownDivider(Color textSecondary) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: Text(
        ':',
        style: GoogleFonts.outfit(
          fontSize: 16,
          fontWeight: FontWeight.w700,
          color: textSecondary.withValues(alpha: 0.5),
        ),
      ),
    );
  }

  Widget _buildRegistrationDeadlineSection({
    required BuildContext context,
    required StudentEvent event,
    required bool isDark,
    required Color textPrimary,
    required Color textSecondary,
    required Color border,
  }) {
    final now = DateTime.now();
    final deadline = event.regEnd!;
    final difference = deadline.difference(now);
    final isClosed = difference.isNegative;
    final isUpcoming = event.isRegistrationUpcoming;

    final stdDateTime = _formatDeadline(deadline);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(
              isClosed
                  ? Icons.lock_clock_outlined
                  : (isUpcoming
                      ? Icons.schedule_outlined
                      : Icons.timer_outlined),
              size: 18,
              color: isClosed
                  ? const Color(0xFFDC2626)
                  : (isUpcoming
                      ? const Color(0xFFD97706)
                      : const Color(0xFF0284C7)),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        'Registration Deadline',
                        style: GoogleFonts.inter(
                          fontSize: 11,
                          color: textSecondary,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 6,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: isClosed
                              ? const Color(0xFFDC2626).withValues(alpha: 0.1)
                              : (isUpcoming
                                  ? const Color(0xFFD97706)
                                      .withValues(alpha: 0.1)
                                  : const Color(0xFF16A34A)
                                      .withValues(alpha: 0.1)),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          isClosed
                              ? 'CLOSED'
                              : (isUpcoming ? 'OPENS SOON' : 'ACTIVE'),
                          style: GoogleFonts.inter(
                            fontSize: 9,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 0.5,
                            color: isClosed
                                ? const Color(0xFFDC2626)
                                : (isUpcoming
                                    ? const Color(0xFFD97706)
                                    : const Color(0xFF16A34A)),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 2),
                  Text(
                    isClosed
                        ? 'Registration closed on $stdDateTime'
                        : 'Closes on $stdDateTime',
                    style: GoogleFonts.inter(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: isClosed ? const Color(0xFFDC2626) : textPrimary,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        if (isClosed)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: isDark
                  ? const Color(0xFF1E293B)
                  : const Color(0xFFFEE2E2).withValues(alpha: 0.5),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: const Color(0xFFDC2626).withValues(alpha: 0.2),
              ),
            ),
            child: Row(
              children: [
                const Icon(
                  Icons.info_outline,
                  size: 14,
                  color: Color(0xFFDC2626),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Registrations for this event have concluded.',
                    style: GoogleFonts.inter(
                      fontSize: 11,
                      fontWeight: FontWeight.w500,
                      color: const Color(0xFFDC2626),
                    ),
                  ),
                ),
              ],
            ),
          )
        else if (isUpcoming) ...[
          Builder(
            builder: (context) {
              final startDiff = event.regStart!.difference(now);
              final days = startDiff.inDays;
              final hours = startDiff.inHours % 24;
              final minutes = startDiff.inMinutes % 60;
              final seconds = startDiff.inSeconds % 60;
              return Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 10,
                ),
                decoration: BoxDecoration(
                  color: isDark
                      ? const Color(0xFF1E293B)
                      : const Color(0xFFFEF3C7).withValues(alpha: 0.3),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: const Color(0xFFD97706).withValues(alpha: 0.25),
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(
                          Icons.hourglass_top_outlined,
                          size: 14,
                          color: Color(0xFFD97706),
                        ),
                        const SizedBox(width: 6),
                        Text(
                          'REGISTRATION OPENS IN',
                          style: GoogleFonts.inter(
                            fontSize: 10,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 0.5,
                            color: const Color(0xFFD97706),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        _buildCountdownBox(
                          value: days.toString().padLeft(2, '0'),
                          label: 'DAYS',
                          isDark: isDark,
                          isUrgent: true,
                          textSecondary: textSecondary,
                        ),
                        _buildCountdownDivider(textSecondary),
                        _buildCountdownBox(
                          value: hours.toString().padLeft(2, '0'),
                          label: 'HOURS',
                          isDark: isDark,
                          isUrgent: true,
                          textSecondary: textSecondary,
                        ),
                        _buildCountdownDivider(textSecondary),
                        _buildCountdownBox(
                          value: minutes.toString().padLeft(2, '0'),
                          label: 'MINS',
                          isDark: isDark,
                          isUrgent: true,
                          textSecondary: textSecondary,
                        ),
                        _buildCountdownDivider(textSecondary),
                        _buildCountdownBox(
                          value: seconds.toString().padLeft(2, '0'),
                          label: 'SECS',
                          isDark: isDark,
                          isUrgent: true,
                          textSecondary: textSecondary,
                        ),
                      ],
                    ),
                  ],
                ),
              );
            },
          ),
        ] else ...[
          Builder(
            builder: (context) {
              final days = difference.inDays;
              final hours = difference.inHours % 24;
              final minutes = difference.inMinutes % 60;
              final seconds = difference.inSeconds % 60;
              final isUrgent = difference.inHours < 24;
              final highlightColor = isUrgent
                  ? const Color(0xFFD97706)
                  : const Color(0xFF0284C7);

              return Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 10,
                ),
                decoration: BoxDecoration(
                  color: isDark
                      ? const Color(0xFF1E293B)
                      : (isUrgent
                          ? const Color(0xFFFEF3C7).withValues(alpha: 0.3)
                          : const Color(0xFF0284C7).withValues(alpha: 0.04)),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: highlightColor.withValues(alpha: 0.2),
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          isUrgent
                              ? Icons.bolt_outlined
                              : Icons.timelapse_outlined,
                          size: 14,
                          color: highlightColor,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          isUrgent
                              ? 'CLOSING SOON • TIME REMAINING'
                              : 'TIME REMAINING TO REGISTER',
                          style: GoogleFonts.inter(
                            fontSize: 10,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 0.5,
                            color: highlightColor,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        _buildCountdownBox(
                          value: days.toString().padLeft(2, '0'),
                          label: 'DAYS',
                          isDark: isDark,
                          isUrgent: isUrgent,
                          textSecondary: textSecondary,
                        ),
                        _buildCountdownDivider(textSecondary),
                        _buildCountdownBox(
                          value: hours.toString().padLeft(2, '0'),
                          label: 'HOURS',
                          isDark: isDark,
                          isUrgent: isUrgent,
                          textSecondary: textSecondary,
                        ),
                        _buildCountdownDivider(textSecondary),
                        _buildCountdownBox(
                          value: minutes.toString().padLeft(2, '0'),
                          label: 'MINS',
                          isDark: isDark,
                          isUrgent: isUrgent,
                          textSecondary: textSecondary,
                        ),
                        _buildCountdownDivider(textSecondary),
                        _buildCountdownBox(
                          value: seconds.toString().padLeft(2, '0'),
                          label: 'SECS',
                          isDark: isDark,
                          isUrgent: isUrgent,
                          textSecondary: textSecondary,
                        ),
                      ],
                    ),
                  ],
                ),
              );
            },
          ),
        ],
      ],
    );
  }

  Widget _buildEligibilitySection({
    required BuildContext context,
    required EventEligibility? eligibility,
    required bool isDark,
    required Color textPrimary,
    required Color textSecondary,
    required Color border,
  }) {
    final e = eligibility ?? const EventEligibility();
    final isAllSemesters = e.allowedSemesters.isEmpty;
    final isAllProgrammes = e.allowedProgrammes.isEmpty;

    final semesterText = isAllSemesters
        ? 'All Semesters'
        : 'Semesters: ${e.allowedSemesters.map((s) => 'S$s').join(', ')}';

    final programmeText = isAllProgrammes
        ? 'All Programmes'
        : 'Branches: ${e.allowedProgrammes.join(', ')}';

    final sexText = e.sexDisplay;

    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        _buildEligibilityChip(
          Icons.calendar_month_outlined,
          semesterText,
          isDark,
        ),
        _buildEligibilityChip(
          Icons.school_outlined,
          programmeText,
          isDark,
        ),
        _buildEligibilityChip(
          Icons.people_outline,
          sexText,
          isDark,
        ),
      ],
    );
  }

  Widget _buildCollaboratorCard({
    required EventCollaborator collab,
    required bool isDark,
    required Color textPrimary,
    required Color textSecondary,
    required Color border,
  }) {
    final hasLogo = collab.hasLogo;
    final hasTitle = collab.hasTitle;

    return Container(
      constraints: BoxConstraints(
        minWidth: hasLogo ? 150 : 100,
        maxWidth: 280,
      ),
      padding: EdgeInsets.symmetric(
        horizontal: 14,
        vertical: (hasTitle && hasLogo)
            ? 10
            : (hasLogo
                ? 8
                : (hasTitle ? 10 : 8)),
      ),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : const Color(0xFFFFFFFF),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: border),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Logo is only shown if non-empty
          if (hasLogo) ...[
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: isDark
                    ? const Color(0xFF0F172A)
                    : const Color(0xFFF1F5F9),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color: isDark
                      ? const Color(0xFF334155)
                      : const Color(0xFFE2E8F0),
                ),
              ),
              clipBehavior: Clip.antiAlias,
              child: Image.network(
                collab.logo!.trim(),
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) {
                  return _buildCollaboratorFallbackLogo(collab.name);
                },
              ),
            ),
            const SizedBox(width: 12),
          ],
          Flexible(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  collab.name,
                  style: GoogleFonts.outfit(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: textPrimary,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                // Title is only shown if non-empty
                if (hasTitle) ...[
                  const SizedBox(height: 2),
                  Text(
                    collab.title!.trim(),
                    style: GoogleFonts.inter(
                      fontSize: 10.5,
                      fontWeight: FontWeight.w500,
                      color: textSecondary,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCollaboratorFallbackLogo(String name) {
    final initials = name.trim().isNotEmpty
        ? name
            .trim()
            .split(RegExp(r'\s+'))
            .take(2)
            .map((word) => word.isNotEmpty ? word[0].toUpperCase() : '')
            .join()
        : 'CO';

    return Center(
      child: Text(
        initials,
        style: GoogleFonts.outfit(
          fontSize: 15,
          fontWeight: FontWeight.w700,
          color: const Color(0xFF0284C7),
        ),
      ),
    );
  }
}
