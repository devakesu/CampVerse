import 'package:campverse/core/models/app_role.dart';
import 'package:campverse/core/models/institute.dart';
import 'package:campverse/core/providers/campus_admin_provider.dart';
import 'package:campverse/core/theme/app_colors.dart';
import 'package:campverse/core/widgets/india_state_picker_field.dart';
import 'package:campverse/core/widgets/university_picker_field.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Full institute management screen featuring General Information &
/// Campus Branding editors for Office Admin and Principal.
class InstituteManagementPage extends ConsumerStatefulWidget {
  /// Default constructor for InstituteManagementPage.
  const InstituteManagementPage({
    required this.role,
    super.key,
  });

  /// The active administrative role.
  final AppRole role;

  @override
  ConsumerState<InstituteManagementPage> createState() =>
      _InstituteManagementPageState();
}

class _InstituteManagementPageState
    extends ConsumerState<InstituteManagementPage>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;
  final _infoFormKey = GlobalKey<FormState>();
  final _brandingFormKey = GlobalKey<FormState>();

  // General Info Controllers
  final _nameController = TextEditingController();
  final _slugController = TextEditingController();
  final _domainController = TextEditingController();
  final _addressController = TextEditingController();
  final _cityController = TextEditingController();
  final _stateController = TextEditingController();
  final _pincodeController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _establishedYearController = TextEditingController();

  String? _selectedUniversityId;
  String? _selectedCampusType;
  bool _isAutonomous = false;

  // Branding Controllers
  final _logoUrlController = TextEditingController();
  final _bannerUrlController = TextEditingController();
  final _taglineController = TextEditingController();
  final _websiteController = TextEditingController();
  final _linkedinController = TextEditingController();
  final _twitterController = TextEditingController();
  final _instagramController = TextEditingController();
  final _youtubeController = TextEditingController();
  String _selectedPrimaryColor = '#1E3A8A';

  bool _isSavingInfo = false;
  bool _isSavingBranding = false;
  String? _lastLoadedInstituteId;

  static const List<String> _campusTypes = [
    'Engineering & Technology',
    'Arts, Science & Commerce',
    'Medical & Healthcare',
    'Polytechnic & Vocational',
    'Management & Business Studies',
    'Autonomous University Campus',
  ];

  static const List<String> _brandColors = [
    '#1E3A8A', // Oxford Navy
    '#334155', // Mineral Slate
    '#1D4ED8', // Royal Cobalt
    '#065F46', // Evergreen Pine
    '#9F1239', // Velvet Crimson
    '#0369A1', // Caspian Cerulean
    '#D97706', // Amber Ochre
    '#581C87', // Amethyst Purple
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);

    // Live preview listener on branding fields
    _logoUrlController.addListener(_onBrandingFieldChanged);
    _bannerUrlController.addListener(_onBrandingFieldChanged);
    _taglineController.addListener(_onBrandingFieldChanged);
    _websiteController.addListener(_onBrandingFieldChanged);
  }

  void _onBrandingFieldChanged() {
    if (mounted) {
      setState(() {});
    }
  }

  @override
  void dispose() {
    _logoUrlController.removeListener(_onBrandingFieldChanged);
    _bannerUrlController.removeListener(_onBrandingFieldChanged);
    _taglineController.removeListener(_onBrandingFieldChanged);
    _websiteController.removeListener(_onBrandingFieldChanged);

    _tabController.dispose();
    _nameController.dispose();
    _slugController.dispose();
    _domainController.dispose();
    _addressController.dispose();
    _cityController.dispose();
    _stateController.dispose();
    _pincodeController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _establishedYearController.dispose();

    _logoUrlController.dispose();
    _bannerUrlController.dispose();
    _taglineController.dispose();
    _websiteController.dispose();
    _linkedinController.dispose();
    _twitterController.dispose();
    _instagramController.dispose();
    _youtubeController.dispose();
    super.dispose();
  }

  void _populateFromInstitute(Institute institute) {
    if (_lastLoadedInstituteId == institute.id) {
      return;
    }
    _lastLoadedInstituteId = institute.id;

    _nameController.text = institute.name;
    _slugController.text = institute.slug;
    _domainController.text = institute.domain ?? '';
    _selectedUniversityId = institute.universityId;
    _isAutonomous = institute.isAutonomous;

    final settings = institute.settings;
    _addressController.text = settings.address ?? '';
    _cityController.text = settings.city ?? '';
    _stateController.text = settings.state ?? '';
    _pincodeController.text = settings.pincode ?? '';
    _emailController.text = settings.contactEmail ?? '';
    _phoneController.text = settings.contactPhone ?? '';
    _establishedYearController.text =
        settings.establishedYear != null ? '${settings.establishedYear}' : '';
    _selectedCampusType = settings.campusType;

    final branding = institute.branding;
    _logoUrlController.text = branding.logoUrl ?? '';
    _bannerUrlController.text = branding.bannerUrl ?? '';
    _taglineController.text = branding.tagline ?? '';
    _websiteController.text = branding.website ?? '';
    _selectedPrimaryColor = branding.primaryColor ?? '#1E3A8A';

    final links = branding.socialLinks;
    _linkedinController.text = links['linkedin'] ?? '';
    _twitterController.text = links['twitter'] ?? '';
    _instagramController.text = links['instagram'] ?? '';
    _youtubeController.text = links['youtube'] ?? '';
  }

  Future<void> _saveInstituteInfo(String instituteId) async {
    if (!_infoFormKey.currentState!.validate()) {
      return;
    }
    setState(() => _isSavingInfo = true);

    try {
      int? year;
      if (_establishedYearController.text.trim().isNotEmpty) {
        year = int.tryParse(_establishedYearController.text.trim());
      }

      final settings = InstituteSettings(
        contactEmail: _emailController.text.trim().isNotEmpty
            ? _emailController.text.trim()
            : null,
        contactPhone: _phoneController.text.trim().isNotEmpty
            ? _phoneController.text.trim()
            : null,
        address: _addressController.text.trim().isNotEmpty
            ? _addressController.text.trim()
            : null,
        city: _cityController.text.trim().isNotEmpty
            ? _cityController.text.trim()
            : null,
        state: _stateController.text.trim().isNotEmpty
            ? _stateController.text.trim()
            : null,
        pincode: _pincodeController.text.trim().isNotEmpty
            ? _pincodeController.text.trim()
            : null,
        establishedYear: year,
        campusType: _selectedCampusType,
      );

      final service = ref.read(campusAdminServiceProvider);
      final res = await service.updateInstituteInfo(
        instituteId: instituteId,
        name: _nameController.text.trim(),
        slug: _slugController.text.trim().toUpperCase(),
        domain: _domainController.text.trim(),
        universityId: _selectedUniversityId,
        isAutonomous: _isAutonomous,
        settings: settings,
      );

      if (res.success && res.data != null) {
        ref.read(currentInstituteProvider.notifier).updateLocal(res.data!);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              backgroundColor: Color(0xFF059669),
              content: Text('Institute information updated successfully.'),
            ),
          );
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              backgroundColor: const Color(0xFFDC2626),
              content: Text(res.error ?? 'Failed to update institute.'),
            ),
          );
        }
      }
    } finally {
      if (mounted) {
        setState(() => _isSavingInfo = false);
      }
    }
  }

  Future<void> _saveCampusBranding(String instituteId) async {
    if (!_brandingFormKey.currentState!.validate()) {
      return;
    }
    setState(() => _isSavingBranding = true);

    try {
      final links = <String, String>{};
      if (_linkedinController.text.trim().isNotEmpty) {
        links['linkedin'] = _linkedinController.text.trim();
      }
      if (_twitterController.text.trim().isNotEmpty) {
        links['twitter'] = _twitterController.text.trim();
      }
      if (_instagramController.text.trim().isNotEmpty) {
        links['instagram'] = _instagramController.text.trim();
      }
      if (_youtubeController.text.trim().isNotEmpty) {
        links['youtube'] = _youtubeController.text.trim();
      }

      final branding = InstituteBranding(
        logoUrl: _logoUrlController.text.trim().isNotEmpty
            ? _logoUrlController.text.trim()
            : null,
        bannerUrl: _bannerUrlController.text.trim().isNotEmpty
            ? _bannerUrlController.text.trim()
            : null,
        tagline: _taglineController.text.trim().isNotEmpty
            ? _taglineController.text.trim()
            : null,
        primaryColor: _selectedPrimaryColor,
        website: _websiteController.text.trim().isNotEmpty
            ? _websiteController.text.trim()
            : null,
        socialLinks: links,
      );

      final service = ref.read(campusAdminServiceProvider);
      final res = await service.updateInstituteBranding(
        instituteId: instituteId,
        branding: branding,
      );

      if (res.success && res.data != null) {
        ref.read(currentInstituteProvider.notifier).updateLocal(res.data!);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              backgroundColor: Color(0xFF059669),
              content: Text('Campus branding updated successfully.'),
            ),
          );
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              backgroundColor: const Color(0xFFDC2626),
              content: Text(res.error ?? 'Failed to update branding.'),
            ),
          );
        }
      }
    } finally {
      if (mounted) {
        setState(() => _isSavingBranding = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final instituteAsync = ref.watch(currentInstituteProvider);
    final universitiesAsync = ref.watch(campusUniversitiesProvider);
    final isDark = AppColors.isDark(context);
    final roleColor = AppColors.roleColorOf(context, widget.role);

    return instituteAsync.when(
      data: (institute) {
        if (institute == null) {
          return const Scaffold(
            body: Center(child: Text('No institute record assigned.')),
          );
        }

        _populateFromInstitute(institute);

        return Scaffold(
          backgroundColor: AppColors.backgroundOf(context),
          appBar: AppBar(
            backgroundColor: AppColors.surfaceOf(context),
            elevation: 0,
            scrolledUnderElevation: 0,
            title: Text(
              'Institute Management Console',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w800,
                color: AppColors.textPrimaryOf(context),
              ),
            ),
            bottom: TabBar(
              controller: _tabController,
              indicatorColor: roleColor,
              labelColor: roleColor,
              unselectedLabelColor: AppColors.textSecondaryOf(context),
              labelStyle: const TextStyle(
                fontWeight: FontWeight.w700,
                fontSize: 14,
              ),
              tabs: const [
                Tab(
                  icon: Icon(Icons.info_outline_rounded, size: 18),
                  text: 'Campus Profile & Information',
                ),
                Tab(
                  icon: Icon(Icons.palette_outlined, size: 18),
                  text: 'Branding & Visual Identity',
                ),
              ],
            ),
          ),
          body: TabBarView(
            controller: _tabController,
            children: [
              // Tab 1: Campus Information
              SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: _buildInfoTab(
                  context,
                  institute,
                  universitiesAsync.value ?? [],
                  roleColor,
                  isDark,
                ),
              ),

              // Tab 2: Branding & Identity
              SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: _buildBrandingTab(
                  context,
                  institute,
                  roleColor,
                  isDark,
                ),
              ),
            ],
          ),
        );
      },
      loading: () => const Scaffold(
        body: Center(child: CircularProgressIndicator.adaptive()),
      ),
      error: (err, _) => Scaffold(
        body: Center(child: Text('Failed to load institute: $err')),
      ),
    );
  }

  // ── Tab 1: Campus Information Form ─────────────────────────────────────────

  Widget _buildInfoTab(
    BuildContext context,
    Institute institute,
    List<dynamic> universities,
    Color roleColor,
    bool isDark,
  ) {
    return Form(
      key: _infoFormKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Role Authority Banner
          _buildRoleAuthorityBadge(context, roleColor, isDark),
          const SizedBox(height: 20),

          // Core Identity Card
          _buildSectionCard(
            context,
            title: 'Core Campus Identity',
            subtitle: 'Official name, unique institutional code, and domain.',
            icon: Icons.domain_rounded,
            color: roleColor,
            children: [
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(
                  labelText: 'Institute Full Name *',
                  hintText: 'e.g. Govt. Model Engineering College',
                  prefixIcon: Icon(Icons.school_rounded),
                ),
                validator: (val) {
                  if (val == null || val.trim().isEmpty) {
                    return 'Institute name is required.';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _slugController,
                      decoration: const InputDecoration(
                        labelText: 'Institute Code / Slug *',
                        hintText: 'e.g. MEC',
                        prefixIcon: Icon(Icons.tag_rounded),
                      ),
                      textCapitalization: TextCapitalization.characters,
                      validator: (val) {
                        if (val == null || val.trim().isEmpty) {
                          return 'Slug is required.';
                        }
                        return null;
                      },
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    flex: 2,
                    child: TextFormField(
                      controller: _domainController,
                      decoration: const InputDecoration(
                        labelText: 'Official Domain',
                        hintText: 'e.g. mec.ac.in',
                        prefixIcon: Icon(Icons.language_rounded),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              if (universities.isNotEmpty)
                UniversityPickerFormField(
                  universities: universities.cast(),
                  initialValue: _selectedUniversityId,
                  onChanged: (uni) {
                    setState(() => _selectedUniversityId = uni?.id);
                  },
                ),
              const SizedBox(height: 16),

              // Autonomous Toggle
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: AppColors.surfaceElevatedOf(context),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.surfaceBorderOf(context)),
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: _isAutonomous
                            ? const Color(0xFF059669).withValues(alpha: 0.15)
                            : Colors.grey.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(
                        _isAutonomous
                            ? Icons.stars_rounded
                            : Icons.account_balance_outlined,
                        color: _isAutonomous
                            ? const Color(0xFF059669)
                            : AppColors.textSecondaryOf(context),
                        size: 24,
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            _isAutonomous
                                ? 'Autonomous Curriculum Enabled'
                                : 'University Affiliated Syllabus',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                              color: AppColors.textPrimaryOf(context),
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            _isAutonomous
                                ? 'Institute designs autonomous schemes, '
                                  'syllabi, and credit systems.'
                                : 'Campus follows standardized curriculum '
                                  'from affiliated university.',
                            style: TextStyle(
                              fontSize: 12,
                              color: AppColors.textSecondaryOf(context),
                            ),
                          ),
                        ],
                      ),
                    ),
                    Switch.adaptive(
                      value: _isAutonomous,
                      activeTrackColor: const Color(0xFF059669),
                      onChanged: (val) {
                        setState(() => _isAutonomous = val);
                      },
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),

          // Location & Contact Card
          _buildSectionCard(
            context,
            title: 'Location & Operational Contact',
            subtitle: 'Campus postal address and public inquiry channels.',
            icon: Icons.place_rounded,
            color: const Color(0xFF059669),
            children: [
              TextFormField(
                controller: _addressController,
                decoration: const InputDecoration(
                  labelText: 'Campus Street Address',
                  hintText: 'e.g. Thrikkakara, Kochi',
                  prefixIcon: Icon(Icons.location_city_rounded),
                ),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _cityController,
                      decoration: const InputDecoration(
                        labelText: 'City',
                        hintText: 'e.g. Kochi',
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: IndiaStatePickerFormField(
                      controller: _stateController,
                      initialValue: _stateController.text,
                      labelText: 'State / Province',
                      onChanged: (val) => setState(() {}),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: TextFormField(
                      controller: _pincodeController,
                      decoration: const InputDecoration(
                        labelText: 'Postal Pincode',
                        hintText: 'e.g. 682021',
                      ),
                      keyboardType: TextInputType.number,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _emailController,
                      decoration: const InputDecoration(
                        labelText: 'Official Inquiry Email',
                        hintText: 'e.g. office@mec.ac.in',
                        prefixIcon: Icon(Icons.email_outlined),
                      ),
                      keyboardType: TextInputType.emailAddress,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: TextFormField(
                      controller: _phoneController,
                      decoration: const InputDecoration(
                        labelText: 'Official Campus Telephone',
                        hintText: 'e.g. +91 484 2575370',
                        prefixIcon: Icon(Icons.phone_outlined),
                      ),
                      keyboardType: TextInputType.phone,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _establishedYearController,
                      decoration: const InputDecoration(
                        labelText: 'Year Established',
                        hintText: 'e.g. 1989',
                        prefixIcon: Icon(Icons.calendar_today_rounded),
                      ),
                      keyboardType: TextInputType.number,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: DropdownButtonFormField<String>(
                      initialValue: _selectedCampusType,
                      isExpanded: true,
                      decoration: const InputDecoration(
                        labelText: 'Campus Discipline',
                        prefixIcon: Icon(Icons.category_rounded),
                      ),
                      items: _campusTypes.map((type) {
                        return DropdownMenuItem(
                          value: type,
                          child: Text(
                            type,
                            overflow: TextOverflow.ellipsis,
                          ),
                        );
                      }).toList(),
                      onChanged: (val) =>
                          setState(() => _selectedCampusType = val),
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 24),

          // Save Info Button
          ElevatedButton.icon(
            style: ElevatedButton.styleFrom(
              backgroundColor: roleColor,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            icon: _isSavingInfo
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  )
                : const Icon(Icons.save_rounded),
            label: Text(
              _isSavingInfo
                  ? 'Saving Information...'
                  : 'Save Institute Information',
              style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
            ),
            onPressed: _isSavingInfo
                ? null
                : () => _saveInstituteInfo(institute.id),
          ),
        ],
      ),
    );
  }

  // ── Tab 2: Branding & Identity Form ────────────────────────────────────────

  Widget _buildBrandingTab(
    BuildContext context,
    Institute institute,
    Color roleColor,
    bool isDark,
  ) {
    return Form(
      key: _brandingFormKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Live Brand Card Preview (Widescreen)
          _buildLiveBrandPreviewCard(context, institute, isDark),
          const SizedBox(height: 24),

          // Visual Assets Card
          _buildSectionCard(
            context,
            title: 'Visual Assets & Imagery',
            subtitle: 'Campus logo and cover banner URLs.',
            icon: Icons.image_rounded,
            color: roleColor,
            children: [
              TextFormField(
                controller: _logoUrlController,
                decoration: const InputDecoration(
                  labelText: 'Campus Logo URL',
                  hintText: 'https://example.com/logo.png',
                  prefixIcon: Icon(Icons.photo_rounded),
                ),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _bannerUrlController,
                decoration: const InputDecoration(
                  labelText: 'Campus Cover Banner URL',
                  hintText: 'https://example.com/campus-cover.jpg',
                  prefixIcon: Icon(Icons.panorama_rounded),
                ),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _taglineController,
                decoration: const InputDecoration(
                  labelText: 'Official Motto / Tagline',
                  hintText: 'e.g. Moulding Engineers with Distinction',
                  prefixIcon: Icon(Icons.format_quote_rounded),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),

          // Color Palette Card
          _buildSectionCard(
            context,
            title: 'Campus Theme & Accent Color',
            subtitle: 'Select or input the primary brand color for the portal.',
            icon: Icons.color_lens_rounded,
            color: const Color(0xFF1D4ED8),
            children: [
              Wrap(
                spacing: 12,
                runSpacing: 12,
                children: _brandColors.map((colorHex) {
                  final isSelected = _selectedPrimaryColor.toUpperCase() ==
                      colorHex.toUpperCase();
                  final hex = colorHex.replaceAll('#', '');
                  final color = Color(int.parse('FF$hex', radix: 16));
                  return InkWell(
                    onTap: () {
                      setState(() => _selectedPrimaryColor = colorHex);
                    },
                    borderRadius: BorderRadius.circular(10),
                    child: Container(
                      width: 42,
                      height: 42,
                      decoration: BoxDecoration(
                        color: color,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                          color: isSelected ? Colors.white : Colors.transparent,
                          width: 2.5,
                        ),
                        boxShadow: isSelected
                            ? [
                                BoxShadow(
                                  color: color.withValues(alpha: 0.5),
                                  blurRadius: 8,
                                  offset: const Offset(0, 2),
                                ),
                              ]
                            : null,
                      ),
                      child: isSelected
                          ? const Icon(
                              Icons.check_rounded,
                              color: Colors.white,
                              size: 20,
                            )
                          : null,
                    ),
                  );
                }).toList(),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: _parseHexColor(_selectedPrimaryColor),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: AppColors.surfaceBorderOf(context),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    'Active Brand Accent: $_selectedPrimaryColor',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textPrimaryOf(context),
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 20),

          // Digital Presence & Social Links
          _buildSectionCard(
            context,
            title: 'Web Presence & Official Channels',
            subtitle: 'Campus website and social networking channels.',
            icon: Icons.public_rounded,
            color: const Color(0xFF0369A1),
            children: [
              TextFormField(
                controller: _websiteController,
                decoration: const InputDecoration(
                  labelText: 'Official Website URL',
                  hintText: 'https://mec.ac.in',
                  prefixIcon: Icon(Icons.link_rounded),
                ),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _linkedinController,
                      decoration: const InputDecoration(
                        labelText: 'LinkedIn URL',
                        hintText: 'https://linkedin.com/school/mec',
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: TextFormField(
                      controller: _twitterController,
                      decoration: const InputDecoration(
                        labelText: 'Twitter / X URL',
                        hintText: 'https://x.com/mec_kochi',
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _instagramController,
                      decoration: const InputDecoration(
                        labelText: 'Instagram URL',
                        hintText: 'https://instagram.com/mec_kochi',
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: TextFormField(
                      controller: _youtubeController,
                      decoration: const InputDecoration(
                        labelText: 'YouTube Channel URL',
                        hintText: 'https://youtube.com/@mec',
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 24),

          // Save Branding Button
          ElevatedButton.icon(
            style: ElevatedButton.styleFrom(
              backgroundColor: roleColor,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            icon: _isSavingBranding
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  )
                : const Icon(Icons.palette_rounded),
            label: Text(
              _isSavingBranding ? 'Saving Branding...' : 'Save Campus Branding',
              style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
            ),
            onPressed: _isSavingBranding
                ? null
                : () => _saveCampusBranding(institute.id),
          ),
        ],
      ),
    );
  }

  // ── Helper Widgets ─────────────────────────────────────────────────────────

  Widget _buildRoleAuthorityBadge(
    BuildContext context,
    Color roleColor,
    bool isDark,
  ) {
    final isPrincipal = widget.role == AppRole.principal;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: roleColor.withValues(alpha: isDark ? 0.2 : 0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: roleColor.withValues(alpha: isDark ? 0.4 : 0.25),
        ),
      ),
      child: Row(
        children: [
          Icon(
            isPrincipal
                ? Icons.verified_user_rounded
                : Icons.admin_panel_settings_outlined,
            color: roleColor,
            size: 22,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  isPrincipal
                      ? 'Principal Executive Governance'
                      : 'Office Administration Workspace',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w800,
                    color: roleColor,
                  ),
                ),
                Text(
                  isPrincipal
                      ? 'Holding statutory authority for campus accreditation, '
                        'autonomous syllabus declarations, and institutional '
                        'seal.'
                      : 'Managing campus operations, registrar records, '
                        'admissions, and facilities data.',
                  style: TextStyle(
                    fontSize: 11,
                    color: AppColors.textSecondaryOf(context),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLiveBrandPreviewCard(
    BuildContext context,
    Institute institute,
    bool isDark,
  ) {
    final logoUrl = _logoUrlController.text.trim();
    final bannerUrl = _bannerUrlController.text.trim();
    final tagline = _taglineController.text.trim();
    final accentColor = _parseHexColor(_selectedPrimaryColor);

    return Container(
      decoration: BoxDecoration(
        color: AppColors.surfaceOf(context),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.surfaceBorderOf(context)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.3 : 0.06),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Banner Area
          Container(
            height: 120,
            width: double.infinity,
            decoration: BoxDecoration(
              color: accentColor.withValues(alpha: 0.15),
              image: bannerUrl.isNotEmpty
                  ? DecorationImage(
                      image: NetworkImage(bannerUrl),
                      fit: BoxFit.cover,
                      onError: (exception, stackTrace) {},
                    )
                  : null,
            ),
            child: Stack(
              children: [
                Positioned(
                  top: 12,
                  right: 12,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.7),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Text(
                      'Live Portal Preview',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Content Area with Overlapping Logo
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Transform.translate(
                  offset: const Offset(0, -28),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Container(
                        width: 68,
                        height: 68,
                        decoration: BoxDecoration(
                          color: AppColors.surfaceOf(context),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: AppColors.surfaceBorderOf(context),
                            width: 3,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.15),
                              blurRadius: 8,
                            ),
                          ],
                        ),
                        clipBehavior: Clip.antiAlias,
                        child: logoUrl.isNotEmpty
                            ? Image.network(
                                logoUrl,
                                fit: BoxFit.cover,
                                errorBuilder: (context, error, stackTrace) =>
                                    _buildMonogramLogo(
                                  institute.slug,
                                  accentColor,
                                ),
                              )
                            : _buildMonogramLogo(institute.slug, accentColor),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              institute.name,
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w800,
                                color: AppColors.textPrimaryOf(context),
                              ),
                            ),
                            if (tagline.isNotEmpty)
                              Text(
                                '“$tagline”',
                                style: TextStyle(
                                  fontSize: 12,
                                  fontStyle: FontStyle.italic,
                                  color: AppColors.textSecondaryOf(context),
                                ),
                              ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 3,
                      ),
                      decoration: BoxDecoration(
                        color: accentColor.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        institute.slug,
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w800,
                          color: accentColor,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    if (institute.domain != null)
                      Text(
                        institute.domain!,
                        style: TextStyle(
                          fontSize: 12,
                          color: AppColors.textSecondaryOf(context),
                        ),
                      ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMonogramLogo(String slug, Color accentColor) {
    return Container(
      color: accentColor.withValues(alpha: 0.15),
      alignment: Alignment.center,
      child: Text(
        slug.isNotEmpty ? slug.substring(0, slug.length.clamp(1, 3)) : 'CV',
        style: TextStyle(
          fontSize: 20,
          fontWeight: FontWeight.w800,
          color: accentColor,
        ),
      ),
    );
  }

  Widget _buildSectionCard(
    BuildContext context, {
    required String title,
    required String subtitle,
    required IconData icon,
    required Color color,
    required List<Widget> children,
  }) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.surfaceOf(context),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.surfaceBorderOf(context)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, color: color, size: 20),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textPrimaryOf(context),
                      ),
                    ),
                    Text(
                      subtitle,
                      style: TextStyle(
                        fontSize: 12,
                        color: AppColors.textSecondaryOf(context),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          ...children,
        ],
      ),
    );
  }

  Color _parseHexColor(String hexStr) {
    try {
      final hex = hexStr.replaceAll('#', '');
      return Color(int.parse('FF$hex', radix: 16));
    } on Exception catch (_) {
      return const Color(0xFF1E3A8A);
    }
  }
}
