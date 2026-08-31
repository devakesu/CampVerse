import 'package:campverse/core/providers/super_admin_provider.dart';
import 'package:campverse/core/theme/app_colors.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Screen for registering a new college / institute campus tenant.
class AddInstitutePage extends ConsumerStatefulWidget {
  /// Default constructor for AddInstitutePage.
  const AddInstitutePage({super.key});

  @override
  ConsumerState<AddInstitutePage> createState() => _AddInstitutePageState();
}

class _AddInstitutePageState extends ConsumerState<AddInstitutePage> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _slugController = TextEditingController();
  final _domainController = TextEditingController();
  String? _selectedUniversityId;
  bool _isAutonomous = false;
  bool _isActive = true;
  bool _isSubmitting = false;

  @override
  void dispose() {
    _nameController.dispose();
    _slugController.dispose();
    _domainController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() => _isSubmitting = true);

    final service = ref.read(superAdminServiceProvider);
    final result = await service.createInstitute(
      name: _nameController.text,
      slug: _slugController.text,
      universityId: _selectedUniversityId,
      domain: _domainController.text.isNotEmpty ? _domainController.text : null,
      isAutonomous: _isAutonomous,
      isActive: _isActive,
    );

    setState(() => _isSubmitting = false);

    if (!mounted) {
      return;
    }

    if (result.success) {
      await ref.read(institutesProvider.notifier).refresh();
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Institute registered successfully!'),
          backgroundColor: AppColors.success,
        ),
      );
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

  @override
  Widget build(BuildContext context) {
    final universitiesAsync = ref.watch(universitiesProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Add Institute Campus'),
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 640),
            child: Container(
              padding: const EdgeInsets.all(28),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: AppColors.surfaceBorder),
              ),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const Text(
                      'Institute Tenant Details',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 6),
                    const Text(
                      'Onboard a college campus tenant. Each institute has '
                      'its own isolated database partition and portal.',
                      style: TextStyle(
                        fontSize: 13,
                        color: AppColors.textSecondary,
                      ),
                    ),
                    const SizedBox(height: 24),
                    TextFormField(
                      controller: _nameController,
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

                    // University Selector Dropdown
                    universitiesAsync.when(
                      data: (unis) {
                        return DropdownButtonFormField<String>(
                          initialValue: _selectedUniversityId,
                          decoration: const InputDecoration(
                            labelText: 'Affiliated University',
                            prefixIcon: Icon(Icons.account_balance_outlined),
                          ),
                          hint: const Text('Select affiliating university'),
                          items: unis.map((u) {
                            return DropdownMenuItem<String>(
                              value: u.id,
                              child: Text('${u.name} (${u.slug})'),
                            );
                          }).toList(),
                          onChanged: (val) =>
                              setState(() => _selectedUniversityId = val),
                        );
                      },
                      loading: () => const LinearProgressIndicator(),
                      error: (_, _) => const SizedBox.shrink(),
                    ),
                    const SizedBox(height: 20),

                    // Autonomous Toggle Switch
                    SwitchListTile(
                      contentPadding: EdgeInsets.zero,
                      title: const Text(
                        'Autonomous Syllabus Structure',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      subtitle: const Text(
                        'Enables custom course codes and curriculum schemes '
                        'independent of university guidelines.',
                        style: TextStyle(
                          fontSize: 12,
                          color: AppColors.textSecondary,
                        ),
                      ),
                      value: _isAutonomous,
                      activeThumbColor: AppColors.accent,
                      onChanged: (val) => setState(() => _isAutonomous = val),
                    ),
                    const Divider(color: AppColors.surfaceBorder),

                    // Active Tenant Switch
                    SwitchListTile(
                      contentPadding: EdgeInsets.zero,
                      title: const Text(
                        'Tenant Active Status',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      subtitle: const Text(
                        'Allow students and staff from this campus to sign in.',
                        style: TextStyle(
                          fontSize: 12,
                          color: AppColors.textSecondary,
                        ),
                      ),
                      value: _isActive,
                      activeThumbColor: AppColors.success,
                      onChanged: (val) => setState(() => _isActive = val),
                    ),
                    const SizedBox(height: 28),

                    ElevatedButton(
                      onPressed: _isSubmitting ? null : _submit,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.rolePrincipal,
                        foregroundColor: Colors.white,
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
                              children: [
                                Icon(Icons.check_circle_outline_rounded),
                                SizedBox(width: 8),
                                Text('Create Institute Tenant'),
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
}
