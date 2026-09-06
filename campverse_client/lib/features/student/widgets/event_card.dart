import 'dart:async';

import 'package:campverse/core/theme/app_colors.dart';
import 'package:campverse/features/student/models/student_event.dart';
import 'package:campverse/features/student/models/student_registration.dart';
import 'package:campverse/features/student/providers/student_providers.dart';
import 'package:campverse/features/student/widgets/event_details_sheet.dart';
import 'package:campverse/features/student/widgets/qr_pass_dialog.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

/// Interactive event card with poster visual, incentives, and authentic pass
/// registration.
class EventCard extends ConsumerStatefulWidget {
  /// Default constructor.
  const EventCard({
    required this.event,
    this.onRegistered,
    super.key,
  });

  /// Event dataset.
  final StudentEvent event;

  /// Optional callback after registering.
  final VoidCallback? onRegistered;

  @override
  ConsumerState<EventCard> createState() => _EventCardState();
}

class _EventCardState extends ConsumerState<EventCard> {
  bool _isRegistering = false;

  void _showEventDetails(BuildContext context) {
    unawaited(
      EventDetailsSheet.show(
        context,
        widget.event,
        onRegistered: widget.onRegistered,
      ),
    );
  }

  void _openMyPass() {
    final allRegs = ref.read(studentRegistrationsProvider).value ?? const [];
    final matches = allRegs.where((r) => r.eventId == widget.event.id);
    final pass = matches.isNotEmpty
        ? matches.first
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
          content: Text('Could not complete registration. Try again.'),
          backgroundColor: Color(0xFFDC2626),
        ),
      );
    }
  }

  String _formatDate(DateTime dt) {
    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
    ];
    return '${dt.day} ${months[dt.month - 1]} ${dt.year}';
  }

  String _formatTime(DateTime dt) {
    final hour = dt.hour > 12 ? dt.hour - 12 : (dt.hour == 0 ? 12 : dt.hour);
    final period = dt.hour >= 12 ? 'PM' : 'AM';
    final min = dt.minute.toString().padLeft(2, '0');
    return '$hour:$min $period';
  }

  @override
  Widget build(BuildContext context) {
    final isDark = AppColors.isDark(context);
    final event = widget.event;
    final surface = AppColors.surfaceOf(context);
    final border = AppColors.borderOf(context);
    final textPrimary = AppColors.textPrimaryOf(context);
    final textSecondary = AppColors.textSecondaryOf(context);

    final hasPoster = event.posterUrl != null && event.posterUrl!.isNotEmpty;

    return Card(
      elevation: 0,
      color: surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: BorderSide(
          color: event.isFeatured
              ? const Color(0xFF0369A1).withValues(alpha: 0.6)
              : border,
          width: event.isFeatured ? 1.8 : 1.2,
        ),
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () => _showEventDetails(context),
        borderRadius: BorderRadius.circular(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            // Poster Image Visual Header
            if (hasPoster)
              SizedBox(
                height: 130,
                width: double.infinity,
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    Image.network(
                      event.posterUrl!,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) =>
                          ColoredBox(
                        color: isDark
                            ? const Color(0xFF1E293B)
                            : const Color(0xFFE2E8F0),
                        child: Icon(
                          Icons.event_seat_rounded,
                          size: 36,
                          color: textSecondary,
                        ),
                      ),
                    ),
                    // Gradient overlay protection
                    DecoratedBox(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            Colors.black.withValues(alpha: 0.2),
                            Colors.black.withValues(alpha: 0.65),
                          ],
                        ),
                      ),
                    ),
                    // Host Org and Category Badge
                    Positioned(
                      top: 10,
                      left: 10,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.black.withValues(alpha: 0.65),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: Colors.white.withValues(alpha: 0.2),
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            if (event.primaryOrgLogo != null &&
                                event.primaryOrgLogo!.isNotEmpty)
                              Padding(
                                padding: const EdgeInsets.only(right: 6),
                                child: CircleAvatar(
                                  radius: 7,
                                  backgroundImage:
                                      NetworkImage(event.primaryOrgLogo!),
                                ),
                              ),
                            Text(
                              event.primaryOrgName,
                              style: GoogleFonts.inter(
                                fontSize: 10,
                                fontWeight: FontWeight.w700,
                                color: Colors.white,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    // KTU Points Badge
                    if (event.ktuActivityPoints > 0)
                      Positioned(
                        top: 10,
                        right: 10,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: const Color(0xFF8B5CF6),
                            borderRadius: BorderRadius.circular(8),
                            boxShadow: [
                              BoxShadow(
                                color: const Color(0xFF8B5CF6)
                                    .withValues(alpha: 0.4),
                                blurRadius: 6,
                              ),
                            ],
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(
                                Icons.stars_rounded,
                                size: 12,
                                color: Colors.white,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                '+${event.ktuActivityPoints} KTU',
                                style: GoogleFonts.inter(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w800,
                                  color: Colors.white,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    // Bottom title row inside poster if dark
                    Positioned(
                      bottom: 8,
                      left: 12,
                      right: 12,
                      child: Row(
                        children: [
                          if (event.isFeatured)
                            Container(
                              margin: const EdgeInsets.only(right: 8),
                              padding: const EdgeInsets.symmetric(
                                horizontal: 6,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color: const Color(0xFF0284C7),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(
                                'FEATURED',
                                style: GoogleFonts.inter(
                                  fontSize: 9,
                                  fontWeight: FontWeight.w800,
                                  color: Colors.white,
                                  letterSpacing: 0.5,
                                ),
                              ),
                            ),
                          if (event.primaryOrgCategory != null)
                            Text(
                              event.primaryOrgCategory!,
                              style: GoogleFonts.inter(
                                fontSize: 10,
                                fontWeight: FontWeight.w600,
                                color: Colors.white70,
                              ),
                            ),
                        ],
                      ),
                    ),
                  ],
                ),
              )
            else
              // Fallback top row if no poster
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Flexible(
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(0xFF0369A1)
                              .withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          event.primaryOrgName,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: GoogleFonts.inter(
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            color: const Color(0xFF0284C7),
                          ),
                        ),
                      ),
                    ),
                    if (event.ktuActivityPoints > 0)
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color:
                              const Color(0xFF8B5CF6).withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(
                              Icons.stars_rounded,
                              size: 13,
                              color: Color(0xFF8B5CF6),
                            ),
                            const SizedBox(width: 4),
                            Text(
                              '+${event.ktuActivityPoints} KTU Pts',
                              style: GoogleFonts.inter(
                                fontSize: 10,
                                fontWeight: FontWeight.w800,
                                color: const Color(0xFF8B5CF6),
                              ),
                            ),
                          ],
                        ),
                      ),
                  ],
                ),
              ),

            // Card Body Content
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Title
                  Text(
                    event.title,
                    style: GoogleFonts.outfit(
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                      color: textPrimary,
                      letterSpacing: -0.2,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),

                  // Short Description
                  if (event.shortDescription != null &&
                      event.shortDescription!.isNotEmpty) ...[
                    const SizedBox(height: 6),
                    Text(
                      event.shortDescription!,
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        color: textSecondary,
                        height: 1.4,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],

                  const SizedBox(height: 10),

                  // Venue & Date/Time
                  Row(
                    children: [
                      Icon(
                        Icons.schedule_rounded,
                        size: 14,
                        color: textSecondary,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        '${_formatDate(event.startTime)} • '
                        '${_formatTime(event.startTime)}',
                        style: GoogleFonts.inter(
                          fontSize: 11,
                          color: textSecondary,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Icon(
                        Icons.place_outlined,
                        size: 14,
                        color: textSecondary,
                      ),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          event.venue,
                          style: GoogleFonts.inter(
                            fontSize: 11,
                            color: textSecondary,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 10),

                  // Badges: Duty Leave, Eligibility, Collaborators
                  Wrap(
                    spacing: 6,
                    runSpacing: 4,
                    children: [
                      if (event.isDutyLeaveApproved)
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 7,
                            vertical: 2.5,
                          ),
                          decoration: BoxDecoration(
                            color: const Color(0xFF16A34A)
                                .withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(
                                Icons.verified_user_outlined,
                                size: 11,
                                color: Color(0xFF16A34A),
                              ),
                              const SizedBox(width: 4),
                              Text(
                                'Duty Leave',
                                style: GoogleFonts.inter(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w700,
                                  color: const Color(0xFF16A34A),
                                ),
                              ),
                            ],
                          ),
                        ),
                      if (event.eligibility != null &&
                          !event.eligibility!.isOpenToAll)
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 7,
                            vertical: 2.5,
                          ),
                          decoration: BoxDecoration(
                            color: isDark
                                ? const Color(0xFF1E293B)
                                : const Color(0xFFF1F5F9),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            event.eligibility!.summaryText,
                            style: GoogleFonts.inter(
                              fontSize: 10,
                              fontWeight: FontWeight.w600,
                              color: textSecondary,
                            ),
                          ),
                        ),
                      if (event.collaborators.isNotEmpty)
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 7,
                            vertical: 2.5,
                          ),
                          decoration: BoxDecoration(
                            color: isDark
                                ? const Color(0xFF1E293B)
                                : const Color(0xFFF1F5F9),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            '+${event.collaborators.length} Co-hosts',
                            style: GoogleFonts.inter(
                              fontSize: 10,
                              fontWeight: FontWeight.w600,
                              color: textSecondary,
                            ),
                          ),
                        ),
                    ],
                  ),

                  const SizedBox(height: 14),

                  // Bottom Price & Registration CTA Row
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            event.formattedPrice,
                            style: GoogleFonts.inter(
                              fontSize: 13,
                              fontWeight: FontWeight.w800,
                              color: event.isPaid
                                  ? textPrimary
                                  : const Color(0xFF16A34A),
                            ),
                          ),
                          if (event.regEnd != null)
                            Text(
                              event.isRegistrationOpen
                                  ? 'Reg open'
                                  : 'Reg closed',
                              style: GoogleFonts.inter(
                                fontSize: 10,
                                color: event.isRegistrationOpen
                                    ? const Color(0xFF0284C7)
                                    : const Color(0xFFDC2626),
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                        ],
                      ),
                      if (event.isRegisteredByMe)
                        OutlinedButton.icon(
                          onPressed: _openMyPass,
                          style: OutlinedButton.styleFrom(
                            foregroundColor: const Color(0xFF16A34A),
                            side: const BorderSide(color: Color(0xFF16A34A)),
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 8,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                          icon: const Icon(Icons.qr_code_rounded, size: 16),
                          label: Text(
                            'View QR Pass',
                            style: GoogleFonts.inter(
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        )
                      else
                        ElevatedButton.icon(
                          onPressed:
                              (!event.isRegistrationOpen || _isRegistering)
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
                              horizontal: 14,
                              vertical: 8,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                          icon: _isRegistering
                              ? const SizedBox(
                                  width: 14,
                                  height: 14,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: Colors.white,
                                  ),
                                )
                              : Icon(
                                  event.isRegistrationOpen
                                      ? Icons.confirmation_number_outlined
                                      : Icons.lock_clock_outlined,
                                  size: 16,
                                ),
                          label: Text(
                            _isRegistering
                                ? 'Registering...'
                                : (event.isRegistrationOpen
                                    ? 'Register'
                                    : 'Closed'),
                            style: GoogleFonts.inter(
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
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
    );
  }
}
