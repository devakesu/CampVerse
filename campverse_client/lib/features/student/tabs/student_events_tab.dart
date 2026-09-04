import 'package:campverse/core/theme/app_colors.dart';
import 'package:campverse/core/utils/responsive_layout.dart';
import 'package:campverse/features/student/models/student_event.dart';
import 'package:campverse/features/student/models/student_registration.dart';
import 'package:campverse/features/student/providers/student_providers.dart';
import 'package:campverse/features/student/widgets/event_card.dart';
import 'package:campverse/features/student/widgets/qr_pass_dialog.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Events tab coordinating campus discovery, tag filtering, and digital
/// QR passes.
class StudentEventsTab extends ConsumerStatefulWidget {
  /// Default constructor.
  const StudentEventsTab({
    this.initialSubTabIndex = 0,
    super.key,
  });

  /// Initial subtab index (0: Discover, 1: My Passes).
  final int initialSubTabIndex;

  @override
  ConsumerState<StudentEventsTab> createState() => _StudentEventsTabState();
}

class _StudentEventsTabState extends ConsumerState<StudentEventsTab>
    with SingleTickerProviderStateMixin {
  late TabController _tabCtrl;
  String _selectedCategory = 'All';
  String _searchQuery = '';

  static const List<String> _categories = [
    'All',
    'Tech',
    'Hackathon',
    'Cultural',
    'Sports',
    'Workshop',
  ];

  @override
  void initState() {
    super.initState();
    _tabCtrl = TabController(
      length: 2,
      vsync: this,
      initialIndex: widget.initialSubTabIndex,
    );
  }

  @override
  void dispose() {
    _tabCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDesktop = ResponsiveLayout.isDesktop(context);
    final eventsAsync = ref.watch(studentEventsProvider);
    final regsAsync = ref.watch(studentRegistrationsProvider);

    final allEvents = eventsAsync.value ?? const <StudentEvent>[];
    final allRegs = regsAsync.value ?? const <StudentRegistration>[];
    final activeRegsCount = allRegs.where((r) => r.isActive).length;

    // Filter events
    final filteredEvents = allEvents.where((e) {
      final matchesCat = _selectedCategory == 'All' ||
          e.tags.any(
            (t) => t.toLowerCase() == _selectedCategory.toLowerCase(),
          );
      final matchesSearch = _searchQuery.isEmpty ||
          e.title.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          e.venue.toLowerCase().contains(_searchQuery.toLowerCase());
      return matchesCat && matchesSearch;
    }).toList();

    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(60),
        child: Container(
          padding: EdgeInsets.symmetric(
            horizontal: isDesktop ? 32 : 16,
            vertical: 6,
          ),
          decoration: BoxDecoration(
            color: AppColors.surfaceOf(context),
            border: Border(
              bottom: BorderSide(
                color: AppColors.borderOf(context),
              ),
            ),
          ),
          child: TabBar(
            controller: _tabCtrl,
            isScrollable: true,
            tabAlignment: TabAlignment.start,
            labelColor: const Color(0xFF0369A1),
            unselectedLabelColor: AppColors.textSecondaryOf(context),
            indicatorColor: const Color(0xFF0369A1),
            indicatorWeight: 3,
            labelStyle: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w700,
            ),
            unselectedLabelStyle: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w500,
            ),
            tabs: [
              const Tab(
                icon: Icon(Icons.explore_outlined, size: 18),
                text: 'Discover Events',
              ),
              Tab(
                icon: const Icon(
                  Icons.confirmation_number_outlined,
                  size: 18,
                ),
                text: 'My Passes ($activeRegsCount)',
              ),
            ],
          ),
        ),
      ),
      body: TabBarView(
        controller: _tabCtrl,
        children: [
          _buildDiscoverView(context, filteredEvents),
          _buildMyPassesView(context, allRegs),
        ],
      ),
    );
  }

  // ── 1. Discover Events Subview ─────────────────────────────────────────────

  Widget _buildDiscoverView(
    BuildContext context,
    List<StudentEvent> events,
  ) {
    final isDesktop = ResponsiveLayout.isDesktop(context);

    return ListView(
      padding: EdgeInsets.symmetric(
        horizontal: isDesktop ? 32 : 18,
        vertical: 24,
      ),
      children: [
        // Search & Filter Row
        Row(
          children: [
            Expanded(
              child: TextField(
                onChanged: (v) => setState(() => _searchQuery = v),
                decoration: InputDecoration(
                  hintText: 'Search campus events, venues...',
                  prefixIcon: const Icon(Icons.search_rounded, size: 20),
                  filled: true,
                  fillColor: AppColors.surfaceOf(context),
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: BorderSide(color: AppColors.borderOf(context)),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: BorderSide(color: AppColors.borderOf(context)),
                  ),
                ),
              ),
            ),
          ],
        ),

        const SizedBox(height: 16),

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
                    fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                    color: isSelected
                        ? Colors.white
                        : AppColors.textPrimaryOf(context),
                  ),
                  backgroundColor: AppColors.surfaceOf(context),
                  selectedColor: const Color(0xFF0369A1),
                  showCheckmark: false,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
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

        const SizedBox(height: 24),

        // Events Grid / List
        if (events.isEmpty)
          Container(
            padding: const EdgeInsets.all(40),
            decoration: BoxDecoration(
              color: AppColors.surfaceOf(context),
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: AppColors.borderOf(context)),
            ),
            child: Center(
              child: Column(
                children: [
                  Icon(
                    Icons.event_busy_rounded,
                    size: 40,
                    color: AppColors.textSecondaryOf(context),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'No events found matching criteria',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textPrimaryOf(context),
                    ),
                  ),
                ],
              ),
            ),
          )
        else
          LayoutBuilder(
            builder: (context, constraints) {
              final isWide = constraints.maxWidth > 750;
              if (isWide) {
                return GridView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    crossAxisSpacing: 16,
                    mainAxisSpacing: 16,
                    childAspectRatio: 1.35,
                  ),
                  itemCount: events.length,
                  itemBuilder: (context, index) {
                    return EventCard(event: events[index]);
                  },
                );
              } else {
                return ListView.separated(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: events.length,
                  separatorBuilder: (context, _) => const SizedBox(height: 14),
                  itemBuilder: (context, index) {
                    return EventCard(event: events[index]);
                  },
                );
              }
            },
          ),
      ],
    );
  }

  // ── 2. My Passes & Registrations Subview ───────────────────────────────────

  Widget _buildMyPassesView(
    BuildContext context,
    List<StudentRegistration> regs,
  ) {
    final isDark = AppColors.isDark(context);
    final isDesktop = ResponsiveLayout.isDesktop(context);

    if (regs.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  color: const Color(0xFF0369A1).withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.confirmation_number_outlined,
                  size: 48,
                  color: Color(0xFF0284C7),
                ),
              ),
              const SizedBox(height: 18),
              Text(
                'No Event Passes Yet',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                  color: AppColors.textPrimaryOf(context),
                ),
              ),
              const SizedBox(height: 6),
              Text(
                'Browse upcoming campus hackathons and festivals to register '
                'and claim KTU activity points.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 13,
                  color: AppColors.textSecondaryOf(context),
                ),
              ),
              const SizedBox(height: 20),
              ElevatedButton.icon(
                onPressed: () => _tabCtrl.animateTo(0),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF0369A1),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                icon: const Icon(Icons.explore_rounded, size: 18),
                label: const Text('Discover Events'),
              ),
            ],
          ),
        ),
      );
    }

    return ListView.separated(
      padding: EdgeInsets.symmetric(
        horizontal: isDesktop ? 32 : 18,
        vertical: 24,
      ),
      itemCount: regs.length,
      separatorBuilder: (context, _) => const SizedBox(height: 14),
      itemBuilder: (context, index) {
        final reg = regs[index];
        final event = reg.event;

        return Card(
          elevation: 0,
          color: AppColors.surfaceOf(context),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
            side: BorderSide(
              color: reg.isActive
                  ? const Color(0xFF16A34A).withValues(alpha: 0.4)
                  : AppColors.borderOf(context),
              width: 1.3,
            ),
          ),
          child: InkWell(
            onTap: () => QrPassDialog.show(context, reg),
            borderRadius: BorderRadius.circular(20),
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Row(
                children: [
                  // QR Icon Box
                  Container(
                    width: 58,
                    height: 58,
                    decoration: BoxDecoration(
                      color: reg.isActive
                          ? const Color(0xFF16A34A).withValues(alpha: 0.12)
                          : isDark
                              ? const Color(0xFF1E293B)
                              : const Color(0xFFF1F5F9),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Icon(
                      Icons.qr_code_rounded,
                      color: reg.isActive
                          ? const Color(0xFF16A34A)
                          : Colors.grey,
                      size: 32,
                    ),
                  ),

                  const SizedBox(width: 16),

                  // Details
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color: reg.isActive
                                    ? const Color(0xFF16A34A)
                                        .withValues(alpha: 0.12)
                                    : AppColors.borderOf(context),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(
                                reg.status.toUpperCase(),
                                style: TextStyle(
                                  fontSize: 9,
                                  fontWeight: FontWeight.w800,
                                  color: reg.isActive
                                      ? const Color(0xFF16A34A)
                                      : Colors.grey,
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Text(
                              reg.qrPayload,
                              style: const TextStyle(
                                fontSize: 10,
                                fontFamily: 'monospace',
                                color: Colors.grey,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 6),
                        Text(
                          event?.title ?? 'Campus Entry Pass',
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w800,
                            color: AppColors.textPrimaryOf(context),
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 3),
                        Text(
                          event?.venue ?? 'Campus Hub',
                          style: TextStyle(
                            fontSize: 12,
                            color: AppColors.textSecondaryOf(context),
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(width: 12),

                  // View Pass Chevron Button
                  ElevatedButton(
                    onPressed: () => QrPassDialog.show(context, reg),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF0369A1),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 10,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    child: const Text(
                      'Pass',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
