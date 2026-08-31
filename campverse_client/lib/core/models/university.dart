/// University entity representing a state or national affiliating university.
class University {
  /// Default constructor for University.
  const University({
    required this.id,
    required this.name,
    required this.slug,
    required this.state,
    this.website,
    this.createdAt,
    this.updatedAt,
  });

  /// Parse from Supabase JSON map.
  factory University.fromJson(Map<String, dynamic> json) {
    return University(
      id: json['id'] as String? ?? '',
      name: json['name'] as String? ?? '',
      slug: json['slug'] as String? ?? '',
      state: json['state'] as String? ?? '',
      website: json['website'] as String?,
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

  /// Full university title (e.g. APJ Abdul Kalam Technological University).
  final String name;

  /// Short unique identifier slug (e.g. KTU).
  final String slug;

  /// State / province jurisdiction (e.g. Kerala).
  final String state;

  /// Official website URL.
  final String? website;

  /// Record creation timestamp.
  final DateTime? createdAt;

  /// Record last updated timestamp.
  final DateTime? updatedAt;

  /// Convert to JSON payload for insertion.
  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'slug': slug,
      'state': state,
      if (website != null && website!.isNotEmpty) 'website': website,
    };
  }
}
