import 'dart:async';
import 'dart:math';

import 'package:campverse/core/models/app_role.dart';
import 'package:campverse/core/providers/super_admin_provider.dart';
import 'package:campverse/core/services/super_admin_service.dart';
import 'package:campverse/core/theme/app_colors.dart';
import 'package:campverse/core/widgets/university_picker_field.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Screen for registering a new college / institute campus tenant along with
/// its initial Principal and Office Administration accounts.
class AddInstitutePage extends ConsumerStatefulWidget {
  /// Default constructor for AddInstitutePage.
  const AddInstitutePage({super.key});

  @override
  ConsumerState<AddInstitutePage> createState() => _AddInstitutePageState();
}

class _AddInstitutePageState extends ConsumerState<AddInstitutePage> {
  final _formKey = GlobalKey<FormState>();

  // Institute Controllers
  final _nameController = TextEditingController();
  final _slugController = TextEditingController();
  final _domainController = TextEditingController();
  String? _selectedUniversityId;
  bool _isAutonomous = false;
  bool _isActive = true;
  bool _isSubmitting = false;

  // Principal Account Controllers
  final _principalNameController = TextEditingController();
  final _principalEmailController = TextEditingController();
  final _principalPasswordController = TextEditingController();
  final _principalPhoneController = TextEditingController();
  bool _obscurePrincipalPassword = true;

  // Office Admin Account Controllers
  final _officeAdminNameController = TextEditingController();
  final _officeAdminEmailController = TextEditingController();
  final _officeAdminPasswordController = TextEditingController();
  final _officeAdminPhoneController = TextEditingController();
  bool _obscureOfficeAdminPassword = true;

  @override
  void initState() {
    super.initState();
    // Pre-populate secure random initial passwords for convenience
    _principalPasswordController.text = _generateSecurePassword();
    _officeAdminPasswordController.text = _generateSecurePassword();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _slugController.dispose();
    _domainController.dispose();
    _principalNameController.dispose();
    _principalEmailController.dispose();
    _principalPasswordController.dispose();
    _principalPhoneController.dispose();
    _officeAdminNameController.dispose();
    _officeAdminEmailController.dispose();
    _officeAdminPasswordController.dispose();
    _officeAdminPhoneController.dispose();
    super.dispose();
  }

  /// Generate a random temporary password meeting institutional requirements.
  static String _generateSecurePassword() {
    const chars =
        'abcdefghjkmnpqrstuvwxyzABCDEFGHJKLMNPQRSTUVWXYZ23456789!@#%*';
    final random = Random.secure();
    return List.generate(10, (_) => chars[random.nextInt(chars.length)]).join();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() => _isSubmitting = true);

    final service = ref.read(superAdminServiceProvider);
    final result = await service.createInstituteWithAdmins(
      name: _nameController.text,
      slug: _slugController.text,
      principal: AdminUserCreationData(
        name: _principalNameController.text,
        email: _principalEmailController.text,
        password: _principalPasswordController.text,
        phone: _principalPhoneController.text.isNotEmpty
            ? _principalPhoneController.text
            : null,
      ),
      officeAdmin: AdminUserCreationData(
        name: _officeAdminNameController.text,
        email: _officeAdminEmailController.text,
        password: _officeAdminPasswordController.text,
        phone: _officeAdminPhoneController.text.isNotEmpty
            ? _officeAdminPhoneController.text
            : null,
      ),
      universityId: _selectedUniversityId,
      domain: _domainController.text.isNotEmpty ? _domainController.text : null,
      isAutonomous: _isAutonomous,
      isActive: _isActive,
    );

    setState(() => _isSubmitting = false);

    if (!mounted) {
      return;
    }

    if (result.success && result.data != null) {
      await ref.read(institutesProvider.notifier).refresh();
      if (!mounted) {
        return;
      }
      await _showSuccessDialog(result.data!);
      if (!mounted) {
        return;
      }
      Navigator.of(context).pop();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(result.error ?? 'Failed to register institute.'),
          backgroundColor: AppColors.error,
        ),
      );
    }
  }

  Future<void> _showSuccessDialog(CreateInstituteResult data) async {
    final isDark = AppColors.isDark(context);
    final principalColor = AppColors.roleColorOf(context, AppRole.principal);
    final officeAdminColor =
        AppColors.roleColorOf(context, AppRole.officeAdmin);

    await showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          backgroundColor: AppColors.surfaceOf(ctx),
          title: Row(
            children: [
              const Icon(
                Icons.check_circle_rounded,
                color: AppColors.success,
                size: 28,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  'Campus Tenant Registered',
                  style: TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 18,
                    color: AppColors.textPrimaryOf(ctx),
                  ),
                ),
              ),
            ],
          ),
          content: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 480),
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    'Institute "${data.institute.name}" '
                    '(${data.institute.slug}) has been successfully '
                    'initialized. Save the administrator credentials below '
                    'and securely share them with leadership:',
                    style: TextStyle(
                      fontSize: 13,
                      color: AppColors.textSecondaryOf(ctx),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Principal Credentials Card
                  _buildCredentialBox(
                    ctx: ctx,
                    roleTitle: 'Principal Executive Account',
                    roleColor: principalColor,
                    roleIcon: Icons.account_balance_rounded,
                    name: data.principal.name,
                    email: data.principal.email,
                    password: _principalPasswordController.text,
                    isDark: isDark,
                  ),
                  const SizedBox(height: 12),

                  // Office Admin Credentials Card
                  _buildCredentialBox(
                    ctx: ctx,
                    roleTitle: 'Office Administrator Account',
                    roleColor: officeAdminColor,
                    roleIcon: Icons.badge_rounded,
                    name: data.officeAdmin.name,
                    email: data.officeAdmin.email,
                    password: _officeAdminPasswordController.text,
                    isDark: isDark,
                  ),
                ],
              ),
            ),
          ),
          actions: [
            FilledButton(
              onPressed: () => Navigator.of(ctx).pop(),
              style: FilledButton.styleFrom(
                backgroundColor: AppColors.accent,
                foregroundColor: Colors.white,
              ),
              child: const Text('Done & Return to Institutes'),
            ),
          ],
        );
      },
    );
  }

  Widget _buildCredentialBox({
    required BuildContext ctx,
    required String roleTitle,
    required Color roleColor,
    required IconData roleIcon,
    required String name,
    required String email,
    required String password,
    required bool isDark,
  }) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: roleColor.withValues(alpha: isDark ? 0.12 : 0.06),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: roleColor.withValues(alpha: isDark ? 0.35 : 0.2),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(roleIcon, size: 16, color: roleColor),
              const SizedBox(width: 6),
              Text(
                roleTitle,
                style: TextStyle(
                  fontWeight: FontWeight.w700,
                  fontSize: 13,
                  color: roleColor,
                ),
              ),
              const Spacer(),
              IconButton(
                icon: const Icon(Icons.copy_rounded, size: 16),
                tooltip: 'Copy login details',
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
                onPressed: () {
                  final text =
                      '$roleTitle\nName: $name\n'
                      'Email: $email\nPassword: $password';
                  unawaited(Clipboard.setData(ClipboardData(text: text)));
                  ScaffoldMessenger.of(ctx).showSnackBar(
                    SnackBar(
                      content: Text('Copied $roleTitle credentials!'),
                      duration: const Duration(seconds: 2),
                    ),
                  );
                },
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            'Name: $name',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimaryOf(ctx),
            ),
          ),
          Text(
            'Email: $email',
            style: TextStyle(
              fontSize: 12,
              color: AppColors.textPrimaryOf(ctx),
            ),
          ),
          Text(
            'Initial Password: $password',
            style: TextStyle(
              fontSize: 12,
              fontFamily: 'monospace',
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimaryOf(ctx),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final universitiesAsync = ref.watch(universitiesProvider);
    final isDark = AppColors.isDark(context);
    final principalColor = AppColors.roleColorOf(context, AppRole.principal);
    final officeAdminColor =
        AppColors.roleColorOf(context, AppRole.officeAdmin);

    return Scaffold(
      backgroundColor: AppColors.backgroundOf(context),
      appBar: AppBar(
        title: Text(
          'Add Institute Campus',
          style: TextStyle(
            fontWeight: FontWeight.w700,
            color: AppColors.textPrimaryOf(context),
          ),
        ),
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 680),
            child: Container(
              padding: const EdgeInsets.all(28),
              decoration: BoxDecoration(
                color: AppColors.surfaceOf(context),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: AppColors.borderOf(context)),
                boxShadow: [
                  BoxShadow(
                    color: isDark
                        ? Colors.black.withValues(alpha: 0.2)
                        : Colors.black.withValues(alpha: 0.04),
                    blurRadius: 16,
                    offset: const Offset(0, 6),
                  ),
                ],
              ),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // ── 1. Institute Tenant Section ──────────────────────────
                    Text(
                      'Institute Tenant Details',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textPrimaryOf(context),
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'Onboard a college campus tenant. Each institute has '
                      'its own isolated database partition and portal.',
                      style: TextStyle(
                        fontSize: 13,
                        color: AppColors.textSecondaryOf(context),
                      ),
                    ),
                    const SizedBox(height: 24),
                    TextFormField(
                      controller: _nameController,
                      style: TextStyle(color: AppColors.textPrimaryOf(context)),
                      decoration: const InputDecoration(
                        labelText: 'Institute Name *',
                        hintText: 'e.g. Govt. Model Engineering College',
                        prefixIcon: Icon(Icons.domain_outlined),
                      ),
                      validator: (val) {
                        if (val == null || val.trim().isEmpty) {
                          return 'Please enter institute name';
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
                            textCapitalization: TextCapitalization.characters,
                            style: TextStyle(
                              color: AppColors.textPrimaryOf(context),
                            ),
                            decoration: const InputDecoration(
                              labelText: 'Slug / Code *',
                              hintText: 'e.g. MEC',
                              prefixIcon: Icon(Icons.short_text_rounded),
                            ),
                            validator: (val) {
                              if (val == null || val.trim().isEmpty) {
                                return 'Slug required';
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
                            keyboardType: TextInputType.url,
                            style: TextStyle(
                              color: AppColors.textPrimaryOf(context),
                            ),
                            decoration: const InputDecoration(
                              labelText: 'Campus Domain',
                              hintText: 'e.g. mec.ac.in',
                              prefixIcon: Icon(Icons.public_rounded),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),

                    // Affiliating University Selector (Search & State Filter)
                    universitiesAsync.when(
                      data: (unis) {
                        return UniversityPickerFormField(
                          universities: unis,
                          initialValue: _selectedUniversityId,
                          onChanged: (u) =>
                              setState(() => _selectedUniversityId = u?.id),
                        );
                      },
                      loading: () => const LinearProgressIndicator(),
                      error: (_, _) => const SizedBox.shrink(),
                    ),
                    const SizedBox(height: 20),

                    // Autonomous Toggle Switch
                    Material(
                      type: MaterialType.transparency,
                      child: SwitchListTile(
                        contentPadding: EdgeInsets.zero,
                        title: Text(
                          'Autonomous Syllabus Structure',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: AppColors.textPrimaryOf(context),
                          ),
                        ),
                        subtitle: Text(
                          'Enables custom course codes and curriculum schemes '
                          'independent of university guidelines.',
                          style: TextStyle(
                            fontSize: 12,
                            color: AppColors.textSecondaryOf(context),
                          ),
                        ),
                        value: _isAutonomous,
                        activeThumbColor: AppColors.accent,
                        onChanged: (val) => setState(() => _isAutonomous = val),
                      ),
                    ),
                    Divider(color: AppColors.borderOf(context)),

                    // Active Tenant Switch
                    Material(
                      type: MaterialType.transparency,
                      child: SwitchListTile(
                        contentPadding: EdgeInsets.zero,
                        title: Text(
                          'Tenant Active Status',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: AppColors.textPrimaryOf(context),
                          ),
                        ),
                        subtitle: Text(
                          'Allow students and staff from this campus '
                          'to sign in.',
                          style: TextStyle(
                            fontSize: 12,
                            color: AppColors.textSecondaryOf(context),
                          ),
                        ),
                        value: _isActive,
                        activeThumbColor: AppColors.success,
                        onChanged: (val) => setState(() => _isActive = val),
                      ),
                    ),
                    const SizedBox(height: 28),

                    // ── 2. Principal Account Section ─────────────────────────
                    _buildSectionHeader(
                      context: context,
                      title: 'Principal Executive Account',
                      subtitle:
                          'Campus head administrator account with executive '
                          'access.',
                      icon: Icons.account_balance_rounded,
                      themeColor: principalColor,
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: TextFormField(
                            controller: _principalNameController,
                            style: TextStyle(
                              color: AppColors.textPrimaryOf(context),
                            ),
                            decoration: const InputDecoration(
                              labelText: 'Principal Full Name *',
                              hintText: 'e.g. Dr. Jacob Thomas',
                              prefixIcon: Icon(Icons.person_outline_rounded),
                            ),
                            validator: (val) {
                              if (val == null || val.trim().isEmpty) {
                                return 'Enter Principal name';
                              }
                              return null;
                            },
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: TextFormField(
                            controller: _principalPhoneController,
                            keyboardType: TextInputType.phone,
                            style: TextStyle(
                              color: AppColors.textPrimaryOf(context),
                            ),
                            decoration: const InputDecoration(
                              labelText: 'Contact Phone',
                              hintText: 'e.g. +91 98765 43210',
                              prefixIcon: Icon(Icons.phone_outlined),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),
                    Row(
                      children: [
                        Expanded(
                          child: TextFormField(
                            controller: _principalEmailController,
                            keyboardType: TextInputType.emailAddress,
                            style: TextStyle(
                              color: AppColors.textPrimaryOf(context),
                            ),
                            decoration: const InputDecoration(
                              labelText: 'Principal Login Email *',
                              hintText: 'e.g. principal@mec.ac.in',
                              prefixIcon: Icon(Icons.alternate_email_rounded),
                            ),
                            validator: (val) {
                              if (val == null || val.trim().isEmpty) {
                                return 'Enter Principal email';
                              }
                              if (!val.contains('@') || !val.contains('.')) {
                                return 'Enter valid email address';
                              }
                              return null;
                            },
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: TextFormField(
                            controller: _principalPasswordController,
                            obscureText: _obscurePrincipalPassword,
                            style: TextStyle(
                              color: AppColors.textPrimaryOf(context),
                            ),
                            decoration: InputDecoration(
                              labelText: 'Initial Password *',
                              prefixIcon:
                                  const Icon(Icons.lock_outline_rounded),
                              suffixIcon: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  IconButton(
                                    icon: Icon(
                                      _obscurePrincipalPassword
                                          ? Icons.visibility_off_outlined
                                          : Icons.visibility_outlined,
                                      size: 18,
                                    ),
                                    onPressed: () => setState(
                                      () => _obscurePrincipalPassword =
                                          !_obscurePrincipalPassword,
                                    ),
                                  ),
                                  IconButton(
                                    icon: const Icon(
                                      Icons.refresh_rounded,
                                      size: 18,
                                    ),
                                    tooltip: 'Regenerate secure password',
                                    onPressed: () => setState(
                                      () => _principalPasswordController.text =
                                          _generateSecurePassword(),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            validator: (val) {
                              if (val == null || val.length < 6) {
                                return 'Password must be >= 6 chars';
                              }
                              return null;
                            },
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 28),

                    // ── 3. Office Admin Account Section ──────────────────────
                    _buildSectionHeader(
                      context: context,
                      title: 'Office Administrator Account',
                      subtitle:
                          'Institutional office management account for '
                          'admissions, academics, and staff.',
                      icon: Icons.badge_rounded,
                      themeColor: officeAdminColor,
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: TextFormField(
                            controller: _officeAdminNameController,
                            style: TextStyle(
                              color: AppColors.textPrimaryOf(context),
                            ),
                            decoration: const InputDecoration(
                              labelText: 'Office Admin Full Name *',
                              hintText: 'e.g. Suresh Kumar',
                              prefixIcon: Icon(Icons.person_outline_rounded),
                            ),
                            validator: (val) {
                              if (val == null || val.trim().isEmpty) {
                                return 'Enter Office Admin name';
                              }
                              return null;
                            },
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: TextFormField(
                            controller: _officeAdminPhoneController,
                            keyboardType: TextInputType.phone,
                            style: TextStyle(
                              color: AppColors.textPrimaryOf(context),
                            ),
                            decoration: const InputDecoration(
                              labelText: 'Contact Phone',
                              hintText: 'e.g. +91 98765 43211',
                              prefixIcon: Icon(Icons.phone_outlined),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),
                    Row(
                      children: [
                        Expanded(
                          child: TextFormField(
                            controller: _officeAdminEmailController,
                            keyboardType: TextInputType.emailAddress,
                            style: TextStyle(
                              color: AppColors.textPrimaryOf(context),
                            ),
                            decoration: const InputDecoration(
                              labelText: 'Office Admin Login Email *',
                              hintText: 'e.g. office@mec.ac.in',
                              prefixIcon: Icon(Icons.alternate_email_rounded),
                            ),
                            validator: (val) {
                              if (val == null || val.trim().isEmpty) {
                                return 'Enter Office Admin email';
                              }
                              if (!val.contains('@') || !val.contains('.')) {
                                return 'Enter valid email address';
                              }
                              if (val.trim().toLowerCase() ==
                                  _principalEmailController.text
                                      .trim()
                                      .toLowerCase()) {
                                return 'Must differ from Principal email';
                              }
                              return null;
                            },
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: TextFormField(
                            controller: _officeAdminPasswordController,
                            obscureText: _obscureOfficeAdminPassword,
                            style: TextStyle(
                              color: AppColors.textPrimaryOf(context),
                            ),
                            decoration: InputDecoration(
                              labelText: 'Initial Password *',
                              prefixIcon:
                                  const Icon(Icons.lock_outline_rounded),
                              suffixIcon: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  IconButton(
                                    icon: Icon(
                                      _obscureOfficeAdminPassword
                                          ? Icons.visibility_off_outlined
                                          : Icons.visibility_outlined,
                                      size: 18,
                                    ),
                                    onPressed: () => setState(
                                      () => _obscureOfficeAdminPassword =
                                          !_obscureOfficeAdminPassword,
                                    ),
                                  ),
                                  IconButton(
                                    icon: const Icon(
                                      Icons.refresh_rounded,
                                      size: 18,
                                    ),
                                    tooltip: 'Regenerate secure password',
                                    onPressed: () => setState(
                                      () =>
                                          _officeAdminPasswordController.text =
                                              _generateSecurePassword(),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            validator: (val) {
                              if (val == null || val.length < 6) {
                                return 'Password must be >= 6 chars';
                              }
                              return null;
                            },
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 32),

                    ElevatedButton(
                      onPressed: _isSubmitting ? null : _submit,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.rolePrincipal,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                      ),
                      child: _isSubmitting
                          ? const SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : const Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(Icons.check_circle_outline_rounded),
                                SizedBox(width: 8),
                                Flexible(
                                  child: Text(
                                    'Register Institute & Onboard Administrators',
                                    overflow: TextOverflow.ellipsis,
                                    style:
                                        TextStyle(fontWeight: FontWeight.w600),
                                  ),
                                ),
                              ],
                            ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSectionHeader({
    required BuildContext context,
    required String title,
    required String subtitle,
    required IconData icon,
    required Color themeColor,
  }) {
    final isDark = AppColors.isDark(context);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: themeColor.withValues(alpha: isDark ? 0.15 : 0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: themeColor.withValues(alpha: isDark ? 0.3 : 0.15),
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: themeColor.withValues(alpha: isDark ? 0.3 : 0.2),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, size: 18, color: themeColor),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: themeColor,
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
    );
  }
}
