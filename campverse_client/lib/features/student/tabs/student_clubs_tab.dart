import 'package:campverse/core/theme/app_colors.dart';
import 'package:campverse/core/utils/responsive_layout.dart';
import 'package:campverse/features/student/models/student_club.dart';
import 'package:campverse/features/student/providers/student_providers.dart';
import 'package:campverse/features/student/widgets/club_card.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Clubs & Student Union tab offering campus life and leadership exploration.
class StudentClubsTab extends ConsumerStatefulWidget {
  /// Default constructor.
  const StudentClubsTab({super.key});

  @override
  ConsumerState<StudentClubsTab> createState() => _StudentClubsTabState();
}

class _StudentClubsTabState extends ConsumerState<StudentClubsTab> {
  String _selectedCategory = 'All';

  static const List<String> _categories = [
    'All',
    'Technical',
    'Cultural',
    'Sports',
    'Governance',
  ];

  @override
  Widget build(BuildContext context) {
    final isDark = AppColors.isDark(context);
    final isDesktop = ResponsiveLayout.isDesktop(context);
    final clubsAsync = ref.watch(studentClubsProvider);

    final allClubs = clubsAsync.valueOrNull ?? const <StudentClub>[];
    final studentUnion = allClubs.firstWhere(
      (c) => c.isStudentUnion,
      orElse: () => const StudentClub(
        id: 'csu',
        name: 'College Student Union (CSU)',
        slug: 'student-union',
        orgType: 'student_union',
        category: 'Governance',
        leadName: 'Gokul Mohan (Chairman)',
        description:
            'Democratically elected governing body advocating for '
            'student rights, academic quality, campus festivals, and '
            'community welfare.',
      ),
    );

    final regularClubs = allClubs.where((c) => !c.isStudentUnion).toList();
    final filteredClubs = regularClubs.where((c) {
      if (_selectedCategory == 'All') {
        return true;
      }
      return c.category.toLowerCase() == _selectedCategory.toLowerCase();
    }).toList();

    return RefreshIndicator(
      onRefresh: () async {
        ref.invalidate(studentClubsProvider);
      },
      child: ListView(
        padding: EdgeInsets.symmetric(
          horizontal: isDesktop ? 32 : 18,
          vertical: 24,
        ),
        children: [
          // ── Student Union Spotlight Banner ─────────────────────────────────
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: isDark
                    ? [
                        const Color(0xFF1E1B18),
                        const Color(0xFF9A3412).withValues(alpha: 0.25),
                      ]
                    : [
                        const Color(0xFF9A3412),
                        const Color(0xFFC2410C),
                      ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(22),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF9A3412).withValues(alpha: 0.2),
                  blurRadius: 18,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.account_balance_rounded,
                              size: 13,
                              color: Colors.white,
                            ),
                            SizedBox(width: 6),
                            Text(
                              'STUDENT GOVERNANCE BODY',
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.w800,
                                letterSpacing: 0.8,
                                color: Colors.white,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        studentUnion.name,
                        style: TextStyle(
                          fontSize: isDesktop ? 22 : 18,
                          fontWeight: FontWeight.w800,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        studentUnion.description,
                        style: const TextStyle(
                          fontSize: 12,
                          height: 1.4,
                          color: Colors.white70,
                        ),
                      ),
                      const SizedBox(height: 14),
                      Row(
                        children: [
                          const Icon(
                            Icons.badge_outlined,
                            size: 15,
                            color: Colors.white,
                          ),
                          const SizedBox(width: 6),
                          Text(
                            studentUnion.leadName,
                            style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                              color: Colors.white,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                if (isDesktop) ...[
                  const SizedBox(width: 20),
                  Container(
                    width: 72,
                    height: 72,
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.15),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.how_to_vote_rounded,
                      color: Colors.white,
                      size: 36,
                    ),
                  ),
                ],
              ],
            ),
          ),

          const SizedBox(height: 28),

          // ── Clubs Category Header ──────────────────────────────────────────
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Sanctioned Campus Clubs',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                  color: AppColors.textPrimaryOf(context),
                ),
              ),
              Text(
                '${filteredClubs.length} Clubs',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textSecondaryOf(context),
                ),
              ),
            ],
          ),

          const SizedBox(height: 14),

          // Category Filter Chips
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: _categories.map((cat) {
                final isSelected = _selectedCategory == cat;
                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: FilterChip(
                    selected: isSelected,
                    label: Text(cat),
                    labelStyle: TextStyle(
                      fontSize: 12,
                      fontWeight:
                          isSelected ? FontWeight.w700 : FontWeight.w500,
                      color: isSelected
                          ? Colors.white
                          : AppColors.textPrimaryOf(context),
                    ),
                    backgroundColor: AppColors.surfaceOf(context),
                    selectedColor: const Color(0xFF0369A1),
                    showCheckmark: false,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 6,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                      side: BorderSide(
                        color: isSelected
                            ? const Color(0xFF0369A1)
                            : AppColors.borderOf(context),
                      ),
                    ),
                    onSelected: (val) {
                      if (val) {
                        setState(() => _selectedCategory = cat);
                      }
                    },
                  ),
                );
              }).toList(),
            ),
          ),

          const SizedBox(height: 20),

          // Clubs Grid / List
          LayoutBuilder(
            builder: (context, constraints) {
              final isWide = constraints.maxWidth > 700;
              if (isWide) {
                return GridView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    crossAxisSpacing: 16,
                    mainAxisSpacing: 16,
                    childAspectRatio: 1.6,
                  ),
                  itemCount: filteredClubs.length,
                  itemBuilder: (context, index) {
                    return ClubCard(club: filteredClubs[index]);
                  },
                );
              } else {
                return ListView.separated(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: filteredClubs.length,
                  separatorBuilder: (context, _) => const SizedBox(height: 14),
                  itemBuilder: (context, index) {
                    return ClubCard(club: filteredClubs[index]);
                  },
                );
              }
            },
          ),
        ],
      ),
    );
  }
}
