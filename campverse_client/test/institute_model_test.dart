import 'package:campverse/core/models/institute.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Institute Model Tests', () {
    test(
      'Serializes and deserializes Institute with Branding and Settings',
      () {
      final json = {
        'id': 'inst-123',
        'university_id': 'uni-456',
        'name': 'Govt. Model Engineering College',
        'slug': 'MEC',
        'domain': 'mec.ac.in',
        'is_autonomous': true,
        'is_active': true,
        'branding': {
          'logo_url': 'https://mec.ac.in/logo.png',
          'banner_url': 'https://mec.ac.in/banner.jpg',
          'tagline': 'Excellence in Engineering',
          'primary_color': '#1E3A8A',
          'website': 'https://mec.ac.in',
          'social_links': {
            'linkedin': 'https://linkedin.com/school/mec',
            'twitter': 'https://x.com/mec',
          },
        },
        'settings': {
          'contact_email': 'principal@mec.ac.in',
          'contact_phone': '+91 484 2575370',
          'address': 'Thrikkakara',
          'city': 'Kochi',
          'state': 'Kerala',
          'pincode': '682021',
          'established_year': 1989,
          'campus_type': 'Engineering & Technology',
        },
        'universities': {
          'name': 'APJ Abdul Kalam Technological University',
        },
      };

      final institute = Institute.fromJson(json);

      expect(institute.id, 'inst-123');
      expect(institute.name, 'Govt. Model Engineering College');
      expect(institute.slug, 'MEC');
      expect(institute.domain, 'mec.ac.in');
      expect(institute.isAutonomous, isTrue);
      expect(institute.universityName,
          'APJ Abdul Kalam Technological University');

      // Branding checks
      expect(institute.branding.logoUrl, 'https://mec.ac.in/logo.png');
      expect(institute.branding.tagline, 'Excellence in Engineering');
      expect(institute.branding.primaryColor, '#1E3A8A');
      expect(institute.branding.socialLinks['linkedin'],
          'https://linkedin.com/school/mec');

      // Settings checks
      expect(institute.settings.contactEmail, 'principal@mec.ac.in');
      expect(institute.settings.city, 'Kochi');
      expect(institute.settings.state, 'Kerala');
      expect(institute.settings.establishedYear, 1989);

      // Serialization roundtrip
      final serialized = institute.toJson();
      expect(serialized['name'], 'Govt. Model Engineering College');
      expect(serialized['slug'], 'MEC');
      expect(serialized['is_autonomous'], isTrue);
      expect((serialized['branding'] as Map)['primary_color'], '#1E3A8A');
      expect((serialized['settings'] as Map)['city'], 'Kochi');
    });

    test('Handles null and empty branding/settings gracefully', () {
      final json = {
        'id': 'inst-999',
        'name': 'Simple College',
        'slug': 'SC',
      };

      final institute = Institute.fromJson(json);

      expect(institute.branding.logoUrl, isNull);
      expect(institute.branding.tagline, isNull);
      expect(institute.branding.socialLinks, isEmpty);
      expect(institute.settings.address, isNull);
      expect(institute.isAutonomous, isFalse);
    });

    test('copyWith works correctly', () {
      const institute = Institute(
        id: 'inst-1',
        name: 'Original Name',
        slug: 'ORIG',
      );

      final updated = institute.copyWith(
        name: 'Updated Name',
        isAutonomous: true,
        branding: const InstituteBranding(tagline: 'New Tagline'),
      );

      expect(updated.id, 'inst-1');
      expect(updated.name, 'Updated Name');
      expect(updated.slug, 'ORIG');
      expect(updated.isAutonomous, isTrue);
      expect(updated.branding.tagline, 'New Tagline');
    });
  });
}
