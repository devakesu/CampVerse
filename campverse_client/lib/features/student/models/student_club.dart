import 'package:flutter/foundation.dart';

/// Represents a campus student club or student union organization.
@immutable
class StudentClub {
  /// Default constructor for StudentClub.
  const StudentClub({
    required this.id,
    required this.name,
    required this.slug,
    required this.orgType,
    required this.category,
    this.logoPath,
    this.leadName = 'Club Secretary',
    this.memberCount = 42,
    this.description = 'Active student community organizing campus events.',
    this.myMembershipRole,
    this.isActive = true,
  });

  /// Factory constructor parsing from Supabase joined query.
  factory StudentClub.fromJson(
    Map<String, dynamic> json, {
    String? userRole,
  }) {
    return StudentClub(
      id: json['id'] as String? ?? '',
      name: json['name'] as String? ?? 'Campus Tech Club',
      slug: json['slug'] as String? ?? 'tech-club',
      orgType: json['org_type'] as String? ?? 'club',
      category: json['org_category'] as String? ?? 'Technical',
      logoPath: json['logo_path'] as String?,
      leadName: json['lead_name'] as String? ?? 'Club Chair',
      memberCount: json['member_count'] as int? ?? 50,
      description: (json['description'] as String?) ??
          'Promoting student learning, hackathons, and creative projects.',
      myMembershipRole: userRole,
      isActive: json['is_active'] as bool? ?? true,
    );
  }

  /// Organization ID.
  final String id;

  /// Name of the club or union.
  final String name;

  /// URL/slug identifier.
  final String slug;

  /// Type: 'club' or 'student_union'.
  final String orgType;

  /// Category: 'Technical', 'Cultural', 'Sports', 'Social', etc.
  final String category;

  /// Club logo image asset or URL.
  final String? logoPath;

  /// Primary lead or chair name.
  final String leadName;

  /// Total registered member count.
  final int memberCount;

  /// Organization description.
  final String description;

  /// The current student's role in this club ('lead', 'core_member',
  /// 'volunteer', 'member', or null if not joined).
  final String? myMembershipRole;

  /// Whether the organization is active.
  final bool isActive;

  /// Whether the student is an active member of this organization.
  bool get isMember => myMembershipRole != null;

  /// Whether this is the campus Student Union body.
  bool get isStudentUnion => orgType == 'student_union';
}
