import 'package:flutter/foundation.dart';

/// Represents a campus event discoverable by students.
@immutable
class StudentEvent {
  /// Default constructor for StudentEvent.
  const StudentEvent({
    required this.id,
    required this.title,
    required this.venue,
    required this.startTime,
    required this.endTime,
    this.primaryOrgId = '',
    this.primaryOrgName = 'Campus Club',
    this.primaryOrgLogo,
    this.posterUrl,
    this.maxCapacity,
    this.tags = const [],
    this.isFeatured = false,
    this.ktuActivityPoints = 0,
    this.isCertificateProvided = true,
    this.isDutyLeaveApproved = false,
    this.isPaid = false,
    this.priceCents = 0,
    this.currency = 'INR',
    this.description = 'Join us for an exciting campus event!',
    this.isRegisteredByMe = false,
  });

  /// Factory constructor parsing from Supabase joined query.
  factory StudentEvent.fromJson(
    Map<String, dynamic> json, {
    bool isRegistered = false,
  }) {
    final org = json['organizations'] as Map<String, dynamic>?;
    final incentives = json['incentives'] as Map<String, dynamic>?;
    final pricing = json['pricing'] as Map<String, dynamic>?;

    final tagsList = <String>[];
    if (json['tags'] is List) {
      for (final t in json['tags'] as List) {
        if (t is String) {
          tagsList.add(t);
        }
      }
    }

    final startParsed =
        DateTime.tryParse(json['start_time']?.toString() ?? '') ??
            DateTime.now().add(const Duration(days: 2));
    final endParsed = DateTime.tryParse(json['end_time']?.toString() ?? '') ??
        startParsed.add(const Duration(hours: 3));

    return StudentEvent(
      id: json['id'] as String? ?? '',
      title: json['title'] as String? ?? 'Campus Hackathon 2026',
      venue: json['venue'] as String? ?? 'Auditorium / Campus Hub',
      startTime: startParsed,
      endTime: endParsed,
      primaryOrgId: json['primary_org_id'] as String? ?? '',
      primaryOrgName: org?['name'] as String? ?? 'IEEE Student Branch',
      primaryOrgLogo: org?['logo_path'] as String?,
      posterUrl: json['poster_url'] as String?,
      maxCapacity: json['max_capacity'] as int?,
      tags: tagsList.isNotEmpty ? tagsList : const ['Tech', 'Hackathon'],
      isFeatured: json['is_featured'] as bool? ?? false,
      ktuActivityPoints: incentives?['ktu_activity_points'] as int? ?? 15,
      isCertificateProvided:
          incentives?['certificate_provided'] as bool? ?? true,
      isDutyLeaveApproved: incentives?['duty_leave_approved'] as bool? ?? true,
      isPaid: pricing?['is_paid'] as bool? ?? false,
      priceCents: pricing?['base_price_cents'] as int? ?? 0,
      currency: pricing?['currency'] as String? ?? 'INR',
      description: (json['description'] as String?) ??
          'Experience interactive workshops, project showcases, and keynote '
              'sessions with industry leaders.',
      isRegisteredByMe: isRegistered,
    );
  }

  /// Event identifier.
  final String id;

  /// Event title.
  final String title;

  /// Event venue location.
  final String venue;

  /// Scheduled start time.
  final DateTime startTime;

  /// Scheduled end time.
  final DateTime endTime;

  /// Primary host organization ID.
  final String primaryOrgId;

  /// Primary host organization name.
  final String primaryOrgName;

  /// Primary host organization logo URL or path.
  final String? primaryOrgLogo;

  /// Event poster image URL.
  final String? posterUrl;

  /// Maximum allowed attendees.
  final int? maxCapacity;

  /// Classification tags (e.g. 'Tech', 'Cultural', 'Sports').
  final List<String> tags;

  /// Whether the event is featured on the dashboard hero.
  final bool isFeatured;

  /// KTU activity points credited for participation.
  final int ktuActivityPoints;

  /// Whether a digital verified certificate is awarded.
  final bool isCertificateProvided;

  /// Whether institutional duty leave is officially sanctioned.
  final bool isDutyLeaveApproved;

  /// Whether entry requires ticket purchase.
  final bool isPaid;

  /// Ticket price in cents / smallest denomination.
  final int priceCents;

  /// Currency ISO code.
  final String currency;

  /// Full event description.
  final String description;

  /// Whether current student has an active confirmed registration.
  final bool isRegisteredByMe;

  /// Creates a copy with optional overrides.
  StudentEvent copyWith({
    bool? isRegisteredByMe,
  }) {
    return StudentEvent(
      id: id,
      title: title,
      venue: venue,
      startTime: startTime,
      endTime: endTime,
      primaryOrgId: primaryOrgId,
      primaryOrgName: primaryOrgName,
      primaryOrgLogo: primaryOrgLogo,
      posterUrl: posterUrl,
      maxCapacity: maxCapacity,
      tags: tags,
      isFeatured: isFeatured,
      ktuActivityPoints: ktuActivityPoints,
      isCertificateProvided: isCertificateProvided,
      isDutyLeaveApproved: isDutyLeaveApproved,
      isPaid: isPaid,
      priceCents: priceCents,
      currency: currency,
      description: description,
      isRegisteredByMe: isRegisteredByMe ?? this.isRegisteredByMe,
    );
  }
}
