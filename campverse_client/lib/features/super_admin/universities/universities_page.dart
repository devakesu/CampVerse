import 'package:campverse/core/providers/super_admin_provider.dart';
import 'package:campverse/core/theme/app_colors.dart';
import 'package:campverse/features/super_admin/universities/add_university_page.dart';
import 'package:campverse/features/super_admin/universities/widgets/university_card.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Screen listing all registered universities with search and creation actions.
class UniversitiesPage extends ConsumerStatefulWidget {
  /// Default constructor for UniversitiesPage.
  const UniversitiesPage({super.key});

  @override
  ConsumerState<UniversitiesPage> createState() => _UniversitiesPageState();
}

class _UniversitiesPageState extends ConsumerState<UniversitiesPage> {
  final _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final universitiesAsync = ref.watch(universitiesProvider);

    return Scaffold(
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
                      'Affiliated Universities',
                      style:
                          Theme.of(context).textTheme.headlineSmall?.copyWith(
                                fontWeight: FontWeight.w800,
                              ),
                    ),
                    const SizedBox(height: 4),
                    const Text(
                      'Manage curriculum authorities and multi-campus schemes.',
                      style: TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
                ElevatedButton.icon(
                  onPressed: () {
                    Navigator.of(context).push(
                      MaterialPageRoute<void>(
                        builder: (context) => const AddUniversityPage(),
                      ),
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.roleSuperAdmin,
                    foregroundColor: Colors.white,
                  ),
                  icon: const Icon(Icons.add_rounded, size: 18),
                  label: const Text('Add University'),
                ),
              ],
            ),
            const SizedBox(height: 20),

            // Search Bar
            TextField(
              controller: _searchController,
              onChanged: (val) => setState(() => _searchQuery = val.trim()),
              decoration: InputDecoration(
                hintText: 'Search by university name, state, or slug...',
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

            // Universities List / State
            Expanded(
              child: universitiesAsync.when(
                data: (unis) {
                  final filtered = unis.where((u) {
                    if (_searchQuery.isEmpty) {
                      return true;
                    }
                    final query = _searchQuery.toLowerCase();
                    return u.name.toLowerCase().contains(query) ||
                        u.slug.toLowerCase().contains(query) ||
                        u.state.toLowerCase().contains(query);
                  }).toList();

                  if (filtered.isEmpty) {
                    return Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.school_outlined,
                            size: 48,
                            color: AppColors.textMuted.withValues(alpha: 0.5),
                          ),
                          const SizedBox(height: 12),
                          Text(
                            _searchQuery.isEmpty
                                ? 'No universities registered yet.'
                                : 'No matching universities found.',
                            style: const TextStyle(
                              color: AppColors.textSecondary,
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
                                        const AddUniversityPage(),
                                  ),
                                );
                              },
                              icon: const Icon(Icons.add_rounded),
                              label: const Text('Add First University'),
                            ),
                        ],
                      ),
                    );
                  }

                  return RefreshIndicator(
                    onRefresh: () =>
                        ref.read(universitiesProvider.notifier).refresh(),
                    child: ListView.builder(
                      itemCount: filtered.length,
                      itemBuilder: (context, index) {
                        return UniversityCard(university: filtered[index]);
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
                        'Failed to load universities: $err',
                        style: const TextStyle(color: AppColors.error),
                      ),
                      const SizedBox(height: 8),
                      ElevatedButton(
                        onPressed: () =>
                            ref.read(universitiesProvider.notifier).refresh(),
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
