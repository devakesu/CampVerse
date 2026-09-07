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
    this.allowedSex = const [],
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

    final sexList = <String>[];
    final rawSex = json['allowed_sex'] ??
        json['sex_restriction'] ??
        json['gender_restriction'];

    if (rawSex is List) {
      for (final s in rawSex) {
        final code = s?.toString().trim().toUpperCase();
        if (code != null && code.isNotEmpty) {
          sexList.add(code);
        }
      }
    } else if (rawSex is String && rawSex.trim().isNotEmpty) {
      final upper = rawSex.trim().toUpperCase();
      if (upper == 'F' ||
          upper.startsWith('FEMALE') ||
          upper.contains('WOMEN')) {
        sexList.add('F');
      } else if (upper == 'M' ||
          upper.startsWith('MALE') ||
          upper.contains('MEN')) {
        sexList.add('M');
      } else if (upper == 'T' || upper.contains('TRANS')) {
        sexList.add('T');
      } else if (upper != 'ALL' && upper != 'NONE' && upper != 'NULL') {
        sexList.add(upper);
      }
    }

    return EventEligibility(
      allowedProgrammes: progs,
      allowedSemesters: sems,
      allowedSex: List.unmodifiable(sexList),
      genderRestriction: sexList.isNotEmpty ? sexList.join(', ') : null,
    );
  }

  /// List of allowed programme codes (e.g. ['CSE', 'ECE']).
  final List<String> allowedProgrammes;

  /// List of allowed semester numbers (e.g. [1, 2]).
  final List<int> allowedSemesters;

  /// Allowed sex codes (e.g. ['M'], ['F'], ['T']).
  /// An empty list indicates open to all.
  final List<String> allowedSex;

  /// Legacy field for backward compatibility.
  final String? genderRestriction;

  /// Helper to convert single sex code to friendly name.
  static String formatSexCode(String code) {
    switch (code.toUpperCase()) {
      case 'F':
        return 'Female';
      case 'M':
        return 'Male';
      case 'T':
        return 'Transgender';
      case 'O':
        return 'Other';
      default:
        return code;
    }
  }

  /// Whether eligibility criteria is open to all students.
  bool get isOpenToAll =>
      allowedProgrammes.isEmpty && allowedSemesters.isEmpty && isAllSex;

  /// Whether no sex/gender restriction is imposed.
  bool get isAllSex =>
      allowedSex.isEmpty ||
      (allowedSex.contains('M') &&
          allowedSex.contains('F') &&
          allowedSex.contains('T'));

  /// Backward-compatible alias for [isAllSex].
  bool get isAllGenders => isAllSex;

  /// Checks if a student with the given sex code is allowed.
  bool isAllowedForSex(String? studentSex) {
    if (isAllSex || studentSex == null || studentSex.trim().isEmpty) {
      return true;
    }
    return allowedSex.contains(studentSex.trim().toUpperCase());
  }

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
    if (!isAllSex && allowedSex.isNotEmpty) {
      if (allowedSex.length == 1) {
        parts.add('${formatSexCode(allowedSex.first)} Only');
      } else {
        parts.add(allowedSex.map(formatSexCode).join(' / '));
      }
    }
    return parts.join(' • ');
  }

  /// Display string for allowed semesters.
  String get semesterDisplay => allowedSemesters.isNotEmpty
      ? 'Semesters: ${allowedSemesters.map((s) => 'S$s').join(', ')}'
      : 'Semesters: All Semesters';

  /// Display string for allowed programmes.
  String get programmeDisplay => allowedProgrammes.isNotEmpty
      ? 'Branches: ${allowedProgrammes.join(', ')}'
      : 'Branches: All Programmes';

  /// Display string for sex / gender restriction.
  String get sexDisplay {
    if (isAllSex) {
      return 'Sex: Open to All';
    }
    if (allowedSex.length == 1) {
      return 'Sex: ${formatSexCode(allowedSex.first)} Only';
    }
    return 'Sex: ${allowedSex.map(formatSexCode).join(' & ')}';
  }

  /// Backward-compatible alias for [sexDisplay].
  String get genderDisplay => sexDisplay;

  /// Whether all semesters are eligible.
  bool get isAllSemesters => allowedSemesters.isEmpty;

  /// Whether all academic programmes are eligible.
  bool get isAllProgrammes => allowedProgrammes.isEmpty;
}

/// Coordinator or public contact for campus events.
@immutable
class EventContact {
  /// Default constructor for coordinator contact.
  const EventContact({
    required this.name,
    required this.role,
    required this.phone,
    this.email,
  });

  /// Factory constructor parsing from JSON payload.
  factory EventContact.fromJson(Map<String, dynamic> json) {
    return EventContact(
      name: json['name'] as String? ?? '',
      role: json['role'] as String? ?? 'Coordinator',
      phone: json['phone'] as String? ?? '',
      email: json['email'] as String?,
    );
  }

  /// Coordinator full name.
  final String name;

  /// Role or designation (e.g. 'Lead Instructor', 'Student Chair').
  final String role;

  /// Contact phone number with dial prefix.
  final String phone;

  /// Optional contact email address.
  final String? email;
}

/// Co-organizer or partner organization for an event.
@immutable
class EventCollaborator {
  /// Default constructor for co-organizer.
  const EventCollaborator({
    required this.name,
    this.logo,
    this.title,
  });

  /// Factory constructor parsing from mixed dynamic value or map.
  factory EventCollaborator.fromEntry(String name, dynamic value) {
    String? logoUrl;
    String? titleText;

    if (value is Map) {
      logoUrl = value['logo']?.toString();
      titleText = value['title']?.toString();
    } else if (value is List && value.isNotEmpty) {
      final first = value.first;
      if (first is Map) {
        logoUrl = first['logo']?.toString();
        titleText = first['title']?.toString();
      } else if (first is String && first.isNotEmpty) {
        logoUrl = first;
      }
    } else if (value is String && value.isNotEmpty) {
      logoUrl = value;
    }

    final cleanedLogo = (logoUrl != null && logoUrl.trim().isNotEmpty)
        ? logoUrl.trim()
        : null;
    final cleanedTitle = (titleText != null && titleText.trim().isNotEmpty)
        ? titleText.trim()
        : null;

    return EventCollaborator(
      name: name,
      logo: cleanedLogo,
      title: cleanedTitle,
    );
  }

  /// Name of the co-organizing body or partner institute.
  final String name;

  /// Optional logo image URL of the collaborator.
  final String? logo;

  /// Optional partner role or designation (e.g. 'Technical Partner',
  /// 'Knowledge Partner').
  final String? title;

  /// Whether a valid non-empty logo URL is provided.
  bool get hasLogo => logo != null && logo!.trim().isNotEmpty;

  /// Whether a valid non-empty title or role is provided.
  bool get hasTitle => title != null && title!.trim().isNotEmpty;

  @override
  String toString() => name;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is EventCollaborator &&
          runtimeType == other.runtimeType &&
          name == other.name &&
          logo == other.logo &&
          title == other.title;

  @override
  int get hashCode => Object.hash(name, logo, title);
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
    this.regStart,
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

    final collaboratorsList = <EventCollaborator>[];
    final rawCollaborators = json['collaborators'];
    if (rawCollaborators is Map) {
      for (final entry in rawCollaborators.entries) {
        final name = entry.key?.toString().trim() ?? '';
        if (name.isNotEmpty) {
          collaboratorsList.add(
            EventCollaborator.fromEntry(name, entry.value),
          );
        }
      }
    } else if (rawCollaborators is List) {
      for (final item in rawCollaborators) {
        if (item is String && item.trim().isNotEmpty) {
          collaboratorsList.add(EventCollaborator(name: item.trim()));
        } else if (item is Map) {
          final name =
              (item['name'] ?? item['organization'])?.toString().trim() ?? '';
          if (name.isNotEmpty) {
            final logo = item['logo']?.toString();
            final title = item['title']?.toString();
            collaboratorsList.add(EventCollaborator(
              name: name,
              logo: logo != null && logo.trim().isNotEmpty
                  ? logo.trim()
                  : null,
              title: title != null && title.trim().isNotEmpty
                  ? title.trim()
                  : null,
            ));
          }
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
    final regStartParsed = DateTime.tryParse(
      (json['reg_start'] ?? json['reg_start_time'])?.toString() ?? '',
    );
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
      regStart: regStartParsed,
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

  /// Registration opening timestamp.
  final DateTime? regStart;

  /// Registration deadline timestamp.
  final DateTime? regEnd;

  /// Whether registration is configured and active.
  final bool regConfig;

  /// Event visibility scope ('public', 'institute', 'club', 'custom').
  final String visibility;

  /// Event status ('draft', 'published', 'cancelled', 'completed').
  final String status;

  /// Co-organizing clubs or partner institutes.
  final List<EventCollaborator> collaborators;

  /// List of collaborator names for quick text matching and filters.
  List<String> get collaboratorNames =>
      collaborators.map((c) => c.name).toList();

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

  /// Whether the event has been officially cancelled.
  bool get isCancelled => status.toLowerCase() == 'cancelled';

  /// Whether the event has already concluded.
  bool get isCompleted => status.toLowerCase() == 'completed';

  /// Whether the event has any academic or attendance incentives.
  bool get hasIncentives =>
      ktuActivityPoints > 0 || isDutyLeaveApproved || isCertificateProvided;

  /// Whether registration has not yet opened.
  bool get isRegistrationUpcoming {
    if (!regConfig || status != 'published') {
      return false;
    }
    if (regStart == null) {
      return false;
    }
    return DateTime.now().isBefore(regStart!);
  }

  /// Whether registrations are currently accepted.
  bool get isRegistrationOpen {
    if (!regConfig || status != 'published') {
      return false;
    }
    final now = DateTime.now();
    if (regStart != null && now.isBefore(regStart!)) {
      return false;
    }
    if (regEnd == null) {
      return true;
    }
    return now.isBefore(regEnd!);
  }

  /// Whether the registration deadline has elapsed.
  bool get isRegistrationClosed {
    if (!regConfig || status != 'published') {
      return true;
    }
    if (regEnd != null && DateTime.now().isAfter(regEnd!)) {
      return true;
    }
    return false;
  }

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
    DateTime? regStart,
    DateTime? regEnd,
    List<EventCollaborator>? collaborators,
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
      regStart: regStart ?? this.regStart,
      regEnd: regEnd ?? this.regEnd,
      regConfig: regConfig,
      visibility: visibility,
      status: status,
      collaborators: collaborators ?? this.collaborators,
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
