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

  /// Joined university name if fetched via relational query.
  final String? universityName;

  /// Creation timestamp.
  final DateTime? createdAt;

  /// Last modification timestamp.
  final DateTime? updatedAt;

  /// Convert to JSON payload for insertion.
  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'slug': slug,
      'is_autonomous': isAutonomous,
      'is_active': isActive,
      if (universityId != null && universityId!.isNotEmpty)
        'university_id': universityId,
      if (domain != null && domain!.isNotEmpty) 'domain': domain,
    };
  }
}
