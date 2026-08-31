import 'package:campverse/core/providers/super_admin_provider.dart';
import 'package:campverse/core/theme/app_colors.dart';
import 'package:campverse/features/super_admin/institutes/add_institute_page.dart';
import 'package:campverse/features/super_admin/institutes/widgets/institute_card.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Screen listing all college campus tenants with filtering and actions.
class InstitutesPage extends ConsumerStatefulWidget {
  /// Default constructor for InstitutesPage.
  const InstitutesPage({super.key});

  @override
  ConsumerState<InstitutesPage> createState() => _InstitutesPageState();
}

class _InstitutesPageState extends ConsumerState<InstitutesPage> {
  final _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final institutesAsync = ref.watch(institutesProvider);

    return Scaffold(
      backgroundColor: AppColors.backgroundOf(context),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Header Action Bar
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Institute Campuses',
                      style:
                          Theme.of(context).textTheme.headlineSmall?.copyWith(
                                fontWeight: FontWeight.w800,
                                color: AppColors.textPrimaryOf(context),
                              ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Manage institutional tenants, domain routing, '
                      'and status.',
                      style: TextStyle(
                        color: AppColors.textSecondaryOf(context),
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
                ElevatedButton.icon(
                  onPressed: () {
                    Navigator.of(context).push(
                      MaterialPageRoute<void>(
                        builder: (context) => const AddInstitutePage(),
                      ),
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.rolePrincipal,
                    foregroundColor: Colors.white,
                  ),
                  icon: const Icon(Icons.add_rounded, size: 18),
                  label: const Text('Add Institute'),
                ),
              ],
            ),
            const SizedBox(height: 20),

            // Search Bar
            TextField(
              controller: _searchController,
              onChanged: (val) => setState(() => _searchQuery = val.trim()),
              style: TextStyle(color: AppColors.textPrimaryOf(context)),
              decoration: InputDecoration(
                hintText: 'Search by institute name, slug, or domain...',
                prefixIcon: const Icon(Icons.search_rounded),
                suffixIcon: _searchQuery.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear_rounded),
                        onPressed: () {
                          _searchController.clear();
                          setState(() => _searchQuery = '');
                        },
                      )
                    : null,
              ),
            ),
            const SizedBox(height: 16),

            // Institutes List / State
            Expanded(
              child: institutesAsync.when(
                data: (insts) {
                  final filtered = insts.where((inst) {
                    if (_searchQuery.isEmpty) {
                      return true;
                    }
                    final query = _searchQuery.toLowerCase();
                    return inst.name.toLowerCase().contains(query) ||
                        inst.slug.toLowerCase().contains(query) ||
                        (inst.domain?.toLowerCase().contains(query) ?? false);
                  }).toList();

                  if (filtered.isEmpty) {
                    return Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.domain_disabled_rounded,
                            size: 48,
                            color: AppColors.textMutedOf(context)
                                .withValues(alpha: 0.5),
                          ),
                          const SizedBox(height: 12),
                          Text(
                            _searchQuery.isEmpty
                                ? 'No institutes registered yet.'
                                : 'No matching institutes found.',
                            style: TextStyle(
                              color: AppColors.textSecondaryOf(context),
                              fontSize: 15,
                            ),
                          ),
                          const SizedBox(height: 8),
                          if (_searchQuery.isEmpty)
                            TextButton.icon(
                              onPressed: () {
                                Navigator.of(context).push(
                                  MaterialPageRoute<void>(
                                    builder: (context) =>
                                        const AddInstitutePage(),
                                  ),
                                );
                              },
                              icon: const Icon(Icons.add_rounded),
                              label: const Text('Onboard First Institute'),
                            ),
                        ],
                      ),
                    );
                  }

                  return RefreshIndicator(
                    onRefresh: () =>
                        ref.read(institutesProvider.notifier).refresh(),
                    child: ListView.builder(
                      itemCount: filtered.length,
                      itemBuilder: (context, index) {
                        return InstituteCard(institute: filtered[index]);
                      },
                    ),
                  );
                },
                loading: () => const Center(
                  child: CircularProgressIndicator(),
                ),
                error: (err, _) => Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(
                        Icons.error_outline_rounded,
                        color: AppColors.error,
                        size: 40,
                      ),
                      const SizedBox(height: 12),
                      Text(
                        'Failed to load institutes: $err',
                        style: const TextStyle(color: AppColors.error),
                      ),
                      const SizedBox(height: 8),
                      ElevatedButton(
                        onPressed: () =>
                            ref.read(institutesProvider.notifier).refresh(),
                        child: const Text('Retry'),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
