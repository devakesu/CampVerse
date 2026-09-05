import 'package:flutter/foundation.dart';

/// Single timed entry in an event agenda itinerary.
@immutable
class EventItineraryItem {
  /// Default constructor for itinerary item.
  const EventItineraryItem({
    required this.time,
    required this.activity,
  });

  /// Factory constructor parsing from JSON payload.
  factory EventItineraryItem.fromJson(Map<String, dynamic> json) {
    return EventItineraryItem(
      time: json['time'] as String? ?? '',
      activity: json['activity'] as String? ?? '',
    );
  }

  /// Scheduled time or time window (e.g. '10:00 - 12:00').
  final String time;

  /// Activity or session title.
  final String activity;
}

/// Pricing tier for ticketed events.
@immutable
class EventPricingTier {
  /// Default constructor for pricing tier.
  const EventPricingTier({
    required this.name,
    required this.priceCents,
  });

  /// Factory constructor parsing from JSON payload.
  factory EventPricingTier.fromJson(Map<String, dynamic> json) {
    return EventPricingTier(
      name: json['name'] as String? ?? 'General Pass',
      priceCents: json['price_cents'] as int? ?? 0,
    );
  }

  /// Tier display label (e.g. 'IEEE Member Pass').
  final String name;

  /// Price in cents / smallest denomination.
  final int priceCents;

  /// Formatted display price with currency.
  String formattedPrice(String currency) {
    if (priceCents == 0) {
      return 'Free';
    }
    final amount = (priceCents / 100).toStringAsFixed(0);
    return currency == 'INR' ? '₹$amount' : '$currency $amount';
  }
}

/// Academic and cohort eligibility rules for an event.
@immutable
class EventEligibility {
  /// Default constructor for event eligibility.
  const EventEligibility({
    this.allowedProgrammes = const [],
    this.allowedSemesters = const [],
    this.genderRestriction,
  });

  /// Factory constructor parsing from JSON payload.
  factory EventEligibility.fromJson(Map<String, dynamic> json) {
    final progs = <String>[];
    if (json['allowed_programmes'] is List) {
      for (final p in json['allowed_programmes'] as List) {
        if (p is String) {
          progs.add(p);
        }
      }
    }

    final sems = <int>[];
    if (json['allowed_semesters'] is List) {
      for (final s in json['allowed_semesters'] as List) {
        if (s is int) {
          sems.add(s);
        } else if (s is num) {
          sems.add(s.toInt());
        }
      }
    }

    return EventEligibility(
      allowedProgrammes: progs,
      allowedSemesters: sems,
      genderRestriction: json['gender_restriction'] as String?,
    );
  }

  /// List of allowed programme codes (e.g. ['CSE', 'ECE']).
  final List<String> allowedProgrammes;

  /// List of allowed semester numbers (e.g. [1, 2]).
  final List<int> allowedSemesters;

  /// Optional gender restriction string if applicable.
  final String? genderRestriction;

  /// Whether eligibility criteria is open to all students.
  bool get isOpenToAll =>
      allowedProgrammes.isEmpty &&
      allowedSemesters.isEmpty &&
      genderRestriction == null;

  /// Human-readable eligibility summary badge.
  String get summaryText {
    if (isOpenToAll) {
      return 'Open to All';
    }
    final parts = <String>[];
    if (allowedSemesters.isNotEmpty) {
      if (listEquals(allowedSemesters, [1, 2])) {
        parts.add('Freshers (S1-S2)');
      } else {
        parts.add('Sem ${allowedSemesters.join(', ')}');
      }
    }
    if (allowedProgrammes.isNotEmpty) {
      parts.add(allowedProgrammes.join('/'));
    }
    if (genderRestriction != null && genderRestriction!.isNotEmpty) {
      parts.add(genderRestriction!);
    }
    return parts.join(' • ');
  }
}

/// Coordinator or public contact for campus events.
@immutable
class EventContact {
  /// Default constructor for coordinator contact.
  const EventContact({
    required this.name,
    required this.role,
    required this.phone,
  });

  /// Factory constructor parsing from JSON payload.
  factory EventContact.fromJson(Map<String, dynamic> json) {
    return EventContact(
      name: json['name'] as String? ?? '',
      role: json['role'] as String? ?? 'Coordinator',
      phone: json['phone'] as String? ?? '',
    );
  }

  /// Coordinator full name.
  final String name;

  /// Role or designation (e.g. 'Lead Instructor', 'Student Chair').
  final String role;

  /// Contact phone number with dial prefix.
  final String phone;
}

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
    this.primaryOrgCategory,
    this.primaryOrgSlug,
    this.primaryOrgType,
    this.posterUrl,
    this.maxCapacity,
    this.tags = const [],
    this.isFeatured = false,
    this.shortDescription,
    this.description,
    this.regEnd,
    this.regConfig = true,
    this.visibility = 'institute',
    this.status = 'published',
    this.collaborators = const [],
    this.itinerary = const [],
    this.pricingTiers = const [],
    this.isPaid = false,
    this.priceCents = 0,
    this.currency = 'INR',
    this.ktuActivityPoints = 0,
    this.isCertificateProvided = true,
    this.isDutyLeaveApproved = false,
    this.eligibility,
    this.contacts = const [],
    this.links = const {},
    this.mediaUrls = const [],
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
    final eligibilityMap = json['eligibility'] as Map<String, dynamic>?;

    final tagsList = <String>[];
    if (json['tags'] is List) {
      for (final t in json['tags'] as List) {
        if (t is String && t.isNotEmpty) {
          tagsList.add(t);
        }
      }
    }

    final collaboratorsList = <String>[];
    if (json['collaborators'] is List) {
      for (final c in json['collaborators'] as List) {
        if (c is String && c.isNotEmpty) {
          collaboratorsList.add(c);
        }
      }
    }

    final itineraryList = <EventItineraryItem>[];
    if (json['itinerary'] is List) {
      for (final item in json['itinerary'] as List) {
        if (item is Map<String, dynamic>) {
          itineraryList.add(EventItineraryItem.fromJson(item));
        }
      }
    }

    final pricingTiersList = <EventPricingTier>[];
    if (pricing?['tiers'] is List) {
      for (final tier in pricing!['tiers'] as List) {
        if (tier is Map<String, dynamic>) {
          pricingTiersList.add(EventPricingTier.fromJson(tier));
        }
      }
    }

    final contactsList = <EventContact>[];
    if (json['contacts'] is List) {
      for (final c in json['contacts'] as List) {
        if (c is Map<String, dynamic>) {
          contactsList.add(EventContact.fromJson(c));
        }
      }
    }

    final linksMap = <String, String>{};
    if (json['links'] is Map) {
      for (final entry in (json['links'] as Map).entries) {
        if (entry.key is String &&
            entry.value is String &&
            (entry.value as String).isNotEmpty) {
          linksMap[entry.key as String] = entry.value as String;
        }
      }
    }

    final mediaList = <String>[];
    if (json['media_urls'] is List) {
      for (final m in json['media_urls'] as List) {
        if (m is String && m.isNotEmpty) {
          mediaList.add(m);
        }
      }
    }

    final startParsed =
        DateTime.tryParse(json['start_time']?.toString() ?? '') ??
            DateTime.now().add(const Duration(days: 2));
    final endParsed = DateTime.tryParse(json['end_time']?.toString() ?? '') ??
        startParsed.add(const Duration(hours: 3));
    final regEndParsed =
        DateTime.tryParse(json['reg_end']?.toString() ?? '');

    return StudentEvent(
      id: json['id'] as String? ?? '',
      title: json['title'] as String? ?? 'Campus Event',
      venue: json['venue'] as String? ?? 'Campus Venue',
      startTime: startParsed,
      endTime: endParsed,
      primaryOrgId: json['primary_org_id'] as String? ?? '',
      primaryOrgName: org?['name'] as String? ?? 'Campus Club',
      primaryOrgLogo: org?['logo_path'] as String?,
      primaryOrgCategory: org?['org_category'] as String?,
      primaryOrgSlug: org?['slug'] as String?,
      primaryOrgType: org?['org_type'] as String?,
      posterUrl: json['poster_url'] as String?,
      maxCapacity: json['max_capacity'] as int?,
      tags: tagsList,
      isFeatured: json['is_featured'] as bool? ?? false,
      shortDescription: json['short_description'] as String?,
      description: json['description'] as String?,
      regEnd: regEndParsed,
      regConfig: json['reg_config'] as bool? ?? true,
      visibility: json['visibility'] as String? ?? 'institute',
      status: json['status'] as String? ?? 'published',
      collaborators: collaboratorsList,
      itinerary: itineraryList,
      pricingTiers: pricingTiersList,
      isPaid: pricing?['is_paid'] as bool? ?? false,
      priceCents: pricing?['base_price_cents'] as int? ?? 0,
      currency: pricing?['currency'] as String? ?? 'INR',
      ktuActivityPoints: incentives?['ktu_activity_points'] as int? ?? 0,
      isCertificateProvided:
          incentives?['certificate_provided'] as bool? ?? true,
      isDutyLeaveApproved:
          incentives?['duty_leave_approved'] as bool? ?? false,
      eligibility: eligibilityMap != null
          ? EventEligibility.fromJson(eligibilityMap)
          : null,
      contacts: contactsList,
      links: linksMap,
      mediaUrls: mediaList,
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

  /// Primary host organization category (e.g. 'Technical', 'Cultural').
  final String? primaryOrgCategory;

  /// Primary host organization slug.
  final String? primaryOrgSlug;

  /// Primary host organization type (e.g. 'club', 'student_union').
  final String? primaryOrgType;

  /// Event poster image URL.
  final String? posterUrl;

  /// Maximum allowed attendees.
  final int? maxCapacity;

  /// Classification tags (e.g. 'Tech', 'Cultural', 'Sports').
  final List<String> tags;

  /// Whether the event is featured on the dashboard hero.
  final bool isFeatured;

  /// Concise 1-sentence summary shown on listing cards.
  final String? shortDescription;

  /// Comprehensive description shown on detailed sheets.
  final String? description;

  /// Registration deadline timestamp.
  final DateTime? regEnd;

  /// Whether registration is configured and active.
  final bool regConfig;

  /// Event visibility scope ('public', 'institute', 'club', 'custom').
  final String visibility;

  /// Event status ('draft', 'published', 'cancelled', 'completed').
  final String status;

  /// Co-organizing clubs or partner institutes.
  final List<String> collaborators;

  /// Structured agenda/timeline items.
  final List<EventItineraryItem> itinerary;

  /// Available ticket pricing tiers.
  final List<EventPricingTier> pricingTiers;

  /// Whether entry requires ticket purchase.
  final bool isPaid;

  /// Ticket base price in cents / smallest denomination.
  final int priceCents;

  /// Currency ISO code.
  final String currency;

  /// KTU activity points credited for participation.
  final int ktuActivityPoints;

  /// Whether a digital verified certificate is awarded.
  final bool isCertificateProvided;

  /// Whether institutional duty leave is officially sanctioned.
  final bool isDutyLeaveApproved;

  /// Academic cohort and department eligibility criteria.
  final EventEligibility? eligibility;

  /// Public coordinator contact list.
  final List<EventContact> contacts;

  /// Social, website, discord, brochure, and rulebook links.
  final Map<String, String> links;

  /// Media gallery images.
  final List<String> mediaUrls;

  /// Whether current student has an active confirmed registration.
  final bool isRegisteredByMe;

  // ── Helper Getters ─────────────────────────────────────────────────────────

  /// Whether registrations are currently accepted.
  bool get isRegistrationOpen {
    if (!regConfig || status != 'published') {
      return false;
    }
    if (regEnd == null) {
      return true;
    }
    return DateTime.now().isBefore(regEnd!);
  }

  /// Whether the registration deadline has elapsed.
  bool get isRegistrationClosed => !isRegistrationOpen;

  /// Formatted price tag string (e.g. 'Free Entry' or '₹150' or 'From ₹199').
  String get formattedPrice {
    if (!isPaid || priceCents == 0) {
      return 'Free Entry';
    }
    if (pricingTiers.length > 1) {
      final minCents = pricingTiers
          .map((t) => t.priceCents)
          .reduce((a, b) => a < b ? a : b);
      final minAmount = (minCents / 100).toStringAsFixed(0);
      return currency == 'INR'
          ? 'From ₹$minAmount'
          : 'From $currency $minAmount';
    }
    final amount = (priceCents / 100).toStringAsFixed(0);
    return currency == 'INR' ? '₹$amount' : '$currency $amount';
  }

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
      primaryOrgCategory: primaryOrgCategory,
      primaryOrgSlug: primaryOrgSlug,
      primaryOrgType: primaryOrgType,
      posterUrl: posterUrl,
      maxCapacity: maxCapacity,
      tags: tags,
      isFeatured: isFeatured,
      shortDescription: shortDescription,
      description: description,
      regEnd: regEnd,
      regConfig: regConfig,
      visibility: visibility,
      status: status,
      collaborators: collaborators,
      itinerary: itinerary,
      pricingTiers: pricingTiers,
      isPaid: isPaid,
      priceCents: priceCents,
      currency: currency,
      ktuActivityPoints: ktuActivityPoints,
      isCertificateProvided: isCertificateProvided,
      isDutyLeaveApproved: isDutyLeaveApproved,
      eligibility: eligibility,
      contacts: contacts,
      links: links,
      mediaUrls: mediaUrls,
      isRegisteredByMe: isRegisteredByMe ?? this.isRegisteredByMe,
    );
  }
}
