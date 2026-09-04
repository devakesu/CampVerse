/// Visual identity & branding configuration for an institute campus.
class InstituteBranding {
  /// Default constructor for InstituteBranding.
  const InstituteBranding({
    this.logoUrl,
    this.bannerUrl,
    this.tagline,
    this.primaryColor,
    this.website,
    this.socialLinks = const {},
  });

  /// Parse from Supabase JSON map.
  factory InstituteBranding.fromJson(Map<String, dynamic>? json) {
    if (json == null) {
      return const InstituteBranding();
    }
    final links = <String, String>{};
    if (json['social_links'] is Map) {
      (json['social_links'] as Map).forEach((key, val) {
        if (key != null && val != null) {
          links[key.toString()] = val.toString();
        }
      });
    }
    return InstituteBranding(
      logoUrl: json['logo_url'] as String?,
      bannerUrl: json['banner_url'] as String?,
      tagline: json['tagline'] as String?,
      primaryColor: json['primary_color'] as String?,
      website: json['website'] as String?,
      socialLinks: links,
    );
  }

  /// Campus logo URL.
  final String? logoUrl;

  /// Campus cover banner image URL.
  final String? bannerUrl;

  /// Official institute motto or tagline.
  final String? tagline;

  /// Hex theme accent color (e.g. #1E3A8A).
  final String? primaryColor;

  /// Official website URL.
  final String? website;

  /// Social network links (key: network name, value: URL/handle).
  final Map<String, String> socialLinks;

  /// Serialize to JSON map.
  Map<String, dynamic> toJson() => {
        if (logoUrl != null) 'logo_url': logoUrl,
        if (bannerUrl != null) 'banner_url': bannerUrl,
        if (tagline != null) 'tagline': tagline,
        if (primaryColor != null) 'primary_color': primaryColor,
        if (website != null) 'website': website,
        'social_links': socialLinks,
      };

  /// Creates a copy with optional overrides.
  InstituteBranding copyWith({
    String? logoUrl,
    String? bannerUrl,
    String? tagline,
    String? primaryColor,
    String? website,
    Map<String, String>? socialLinks,
  }) {
    return InstituteBranding(
      logoUrl: logoUrl ?? this.logoUrl,
      bannerUrl: bannerUrl ?? this.bannerUrl,
      tagline: tagline ?? this.tagline,
      primaryColor: primaryColor ?? this.primaryColor,
      website: website ?? this.website,
      socialLinks: socialLinks ?? this.socialLinks,
    );
  }
}

/// Operational, location, and administrative settings for an institute.
class InstituteSettings {
  /// Default constructor for InstituteSettings.
  const InstituteSettings({
    this.contactEmail,
    this.contactPhone,
    this.address,
    this.city,
    this.state,
    this.pincode,
    this.establishedYear,
    this.campusType,
  });

  /// Parse from Supabase JSON map.
  factory InstituteSettings.fromJson(Map<String, dynamic>? json) {
    if (json == null) {
      return const InstituteSettings();
    }
    return InstituteSettings(
      contactEmail: json['contact_email'] as String?,
      contactPhone: json['contact_phone'] as String?,
      address: json['address'] as String?,
      city: json['city'] as String?,
      state: json['state'] as String?,
      pincode: json['pincode'] as String?,
      establishedYear: json['established_year'] as int?,
      campusType: json['campus_type'] as String?,
    );
  }

  /// Official contact / inquiry email.
  final String? contactEmail;

  /// Official campus telephone number.
  final String? contactPhone;

  /// Street address or campus location.
  final String? address;

  /// City name.
  final String? city;

  /// State or province.
  final String? state;

  /// Postal pin code.
  final String? pincode;

  /// Year of establishment.
  final int? establishedYear;

  /// Type of campus (e.g. Engineering, Polytechnic, Medical, Arts).
  final String? campusType;

  /// Serialize to JSON map.
  Map<String, dynamic> toJson() => {
        if (contactEmail != null) 'contact_email': contactEmail,
        if (contactPhone != null) 'contact_phone': contactPhone,
        if (address != null) 'address': address,
        if (city != null) 'city': city,
        if (state != null) 'state': state,
        if (pincode != null) 'pincode': pincode,
        if (establishedYear != null) 'established_year': establishedYear,
        if (campusType != null) 'campus_type': campusType,
      };

  /// Creates a copy with optional overrides.
  InstituteSettings copyWith({
    String? contactEmail,
    String? contactPhone,
    String? address,
    String? city,
    String? state,
    String? pincode,
    int? establishedYear,
    String? campusType,
  }) {
    return InstituteSettings(
      contactEmail: contactEmail ?? this.contactEmail,
      contactPhone: contactPhone ?? this.contactPhone,
      address: address ?? this.address,
      city: city ?? this.city,
      state: state ?? this.state,
      pincode: pincode ?? this.pincode,
      establishedYear: establishedYear ?? this.establishedYear,
      campusType: campusType ?? this.campusType,
    );
  }
}

/// Institute entity representing an affiliated or autonomous college campus.
class Institute {
  /// Default constructor for Institute.
  const Institute({
    required this.id,
    required this.name,
    required this.slug,
    this.universityId,
    this.domain,
    this.isAutonomous = false,
    this.isActive = true,
    this.branding = const InstituteBranding(),
    this.settings = const InstituteSettings(),
    this.universityName,
    this.createdAt,
    this.updatedAt,
  });

  /// Parse from Supabase JSON map with optional joined university table.
  factory Institute.fromJson(Map<String, dynamic> json) {
    String? uniName;
    if (json['universities'] is Map<String, dynamic>) {
      uniName = (json['universities'] as Map<String, dynamic>)['name']
          as String?;
    }

    return Institute(
      id: json['id'] as String? ?? '',
      universityId: json['university_id'] as String?,
      name: json['name'] as String? ?? '',
      slug: json['slug'] as String? ?? '',
      domain: json['domain'] as String?,
      isAutonomous: json['is_autonomous'] as bool? ?? false,
      isActive: json['is_active'] as bool? ?? true,
      branding: InstituteBranding.fromJson(
        json['branding'] as Map<String, dynamic>?,
      ),
      settings: InstituteSettings.fromJson(
        json['settings'] as Map<String, dynamic>?,
      ),
      universityName: uniName,
      createdAt: json['created_at'] != null
          ? DateTime.tryParse(json['created_at'] as String)
          : null,
      updatedAt: json['updated_at'] != null
          ? DateTime.tryParse(json['updated_at'] as String)
          : null,
    );
  }

  /// Unique identifier (UUID).
  final String id;

  /// Affiliated university foreign key.
  final String? universityId;

  /// Full institute name (e.g. Govt. Model Engineering College).
  final String name;

  /// Institute short code / slug (e.g. MEC).
  final String slug;

  /// Institute official domain (e.g. mec.ac.in).
  final String? domain;

  /// Whether the institute defines its own autonomous curriculum.
  final bool isAutonomous;

  /// Whether the tenant is active and enabled for logins.
  final bool isActive;

  /// Visual branding attributes (logo, colors, taglines).
  final InstituteBranding branding;

  /// Administrative & contact settings.
  final InstituteSettings settings;

  /// Joined university name if fetched via relational query.
  final String? universityName;

  /// Creation timestamp.
  final DateTime? createdAt;

  /// Last modification timestamp.
  final DateTime? updatedAt;

  /// Convert to JSON payload for insertion/updates.
  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'slug': slug,
      'is_autonomous': isAutonomous,
      'is_active': isActive,
      'branding': branding.toJson(),
      'settings': settings.toJson(),
      if (universityId != null && universityId!.isNotEmpty)
        'university_id': universityId,
      if (domain != null && domain!.isNotEmpty) 'domain': domain,
    };
  }

  /// Creates a copy with optional overrides.
  Institute copyWith({
    String? id,
    String? universityId,
    String? name,
    String? slug,
    String? domain,
    bool? isAutonomous,
    bool? isActive,
    InstituteBranding? branding,
    InstituteSettings? settings,
    String? universityName,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Institute(
      id: id ?? this.id,
      universityId: universityId ?? this.universityId,
      name: name ?? this.name,
      slug: slug ?? this.slug,
      domain: domain ?? this.domain,
      isAutonomous: isAutonomous ?? this.isAutonomous,
      isActive: isActive ?? this.isActive,
      branding: branding ?? this.branding,
      settings: settings ?? this.settings,
      universityName: universityName ?? this.universityName,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
