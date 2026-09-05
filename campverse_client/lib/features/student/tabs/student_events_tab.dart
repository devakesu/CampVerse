import 'dart:async';

import 'package:campverse/core/theme/app_colors.dart';
import 'package:campverse/core/utils/responsive_layout.dart';
import 'package:campverse/features/student/models/student_event.dart';
import 'package:campverse/features/student/models/student_registration.dart';
import 'package:campverse/features/student/providers/student_providers.dart';
import 'package:campverse/features/student/widgets/event_card.dart';
import 'package:campverse/features/student/widgets/qr_pass_dialog.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

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
  final TextEditingController _searchCtrl = TextEditingController();

  // Quick filter toggles
  bool _filterDutyLeaveOnly = false;
  bool _filterFreeOnly = false;
  bool _filterFeaturedOnly = false;
  bool _filterHighPointsOnly = false;

  static const List<String> _categories = [
    'All',
    'Tech',
    'Hackathon',
    'Workshop',
    'Cultural',
    'Sports',
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
    _searchCtrl.dispose();
    super.dispose();
  }

  String _formatDate(DateTime dt) {
    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
    ];
    return '${dt.day} ${months[dt.month - 1]} ${dt.year}';
  }

  String _formatTime(DateTime dt) {
    final hour = dt.hour > 12 ? dt.hour - 12 : (dt.hour == 0 ? 12 : dt.hour);
    final period = dt.hour >= 12 ? 'PM' : 'AM';
    final min = dt.minute.toString().padLeft(2, '0');
    return '$hour:$min $period';
  }

  @override
  Widget build(BuildContext context) {
    final isDesktop = ResponsiveLayout.isDesktop(context);
    final eventsAsync = ref.watch(studentEventsProvider);
    final regsAsync = ref.watch(studentRegistrationsProvider);

    final allEvents = eventsAsync.value ?? const <StudentEvent>[];
    final allRegs = regsAsync.value ?? const <StudentRegistration>[];
    final activeRegs = allRegs.where((r) => r.isActive).toList();
    final activeRegsCount = activeRegs.length;

    // Filter events based on search, category and toggles
    final filteredEvents = allEvents.where((e) {
      final matchesCat = _selectedCategory == 'All' ||
          e.tags.any(
            (t) => t.toLowerCase() == _selectedCategory.toLowerCase(),
          ) ||
          (e.primaryOrgCategory != null &&
              e.primaryOrgCategory!
                  .toLowerCase()
                  .contains(_selectedCategory.toLowerCase()));

      final query = _searchQuery.toLowerCase().trim();
      final matchesSearch = query.isEmpty ||
          e.title.toLowerCase().contains(query) ||
          e.venue.toLowerCase().contains(query) ||
          e.primaryOrgName.toLowerCase().contains(query) ||
          (e.shortDescription != null &&
              e.shortDescription!.toLowerCase().contains(query)) ||
          e.collaborators.any((c) => c.toLowerCase().contains(query));

      final matchesDutyLeave = !_filterDutyLeaveOnly || e.isDutyLeaveApproved;
      final matchesFree = !_filterFreeOnly || !e.isPaid;
      final matchesFeatured = !_filterFeaturedOnly || e.isFeatured;
      final matchesHighPoints =
          !_filterHighPointsOnly || e.ktuActivityPoints >= 15;

      return matchesCat &&
          matchesSearch &&
          matchesDutyLeave &&
          matchesFree &&
          matchesFeatured &&
          matchesHighPoints;
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
            labelStyle: GoogleFonts.inter(
              fontSize: 13,
              fontWeight: FontWeight.w700,
            ),
            unselectedLabelStyle: GoogleFonts.inter(
              fontSize: 13,
              fontWeight: FontWeight.w500,
            ),
            tabs: [
              Tab(
                icon: const Icon(Icons.explore_outlined, size: 18),
                text: 'Discover Events (${allEvents.length})',
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
          _buildDiscoverView(context, filteredEvents, allEvents, activeRegs),
          _buildMyPassesView(context, allRegs),
        ],
      ),
    );
  }

  // ── 1. Discover Events Subview ─────────────────────────────────────────────

  Widget _buildDiscoverView(
    BuildContext context,
    List<StudentEvent> filteredEvents,
    List<StudentEvent> allEvents,
    List<StudentRegistration> activeRegs,
  ) {
    final isDesktop = ResponsiveLayout.isDesktop(context);
    final textPrimary = AppColors.textPrimaryOf(context);
    final textSecondary = AppColors.textSecondaryOf(context);
    final border = AppColors.borderOf(context);
    final surface = AppColors.surfaceOf(context);

    // Calculate total KTU points across active passes
    final totalPoints = activeRegs.fold<int>(
      0,
      (sum, r) => sum + (r.event?.ktuActivityPoints ?? 0),
    );

    return ListView(
      padding: EdgeInsets.symmetric(
        horizontal: isDesktop ? 32 : 18,
        vertical: 24,
      ),
      children: [
        // Summary Stats Banner
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          decoration: BoxDecoration(
            color: surface,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: border),
          ),
          child: Row(
            children: [
              Expanded(
                child: _buildMetricItem(
                  context,
                  '${allEvents.length}',
                  'Upcoming Events',
                  Icons.event_note_rounded,
                  const Color(0xFF0369A1),
                ),
              ),
              Container(width: 1, height: 36, color: border),
              Expanded(
                child: _buildMetricItem(
                  context,
                  '${activeRegs.length}',
                  'Confirmed Passes',
                  Icons.confirmation_number_rounded,
                  const Color(0xFF16A34A),
                ),
              ),
              Container(width: 1, height: 36, color: border),
              Expanded(
                child: _buildMetricItem(
                  context,
                  '+$totalPoints',
                  'Earnable KTU Pts',
                  Icons.stars_rounded,
                  const Color(0xFF8B5CF6),
                ),
              ),
            ],
          ),
        ),

        const SizedBox(height: 20),

        // Search Box
        TextField(
          controller: _searchCtrl,
          onChanged: (v) => setState(() => _searchQuery = v),
          decoration: InputDecoration(
            hintText: 'Search campus events, clubs, venues, or topics...',
            hintStyle: GoogleFonts.inter(
              fontSize: 13,
              color: textSecondary,
            ),
            prefixIcon: const Icon(Icons.search_rounded, size: 20),
            suffixIcon: _searchQuery.isNotEmpty
                ? IconButton(
                    icon: const Icon(Icons.clear_rounded, size: 18),
                    onPressed: () {
                      _searchCtrl.clear();
                      setState(() => _searchQuery = '');
                    },
                  )
                : null,
            filled: true,
            fillColor: surface,
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 12,
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: BorderSide(color: border),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: BorderSide(color: border),
            ),
          ),
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
                  labelStyle: GoogleFonts.inter(
                    fontSize: 12,
                    fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                    color: isSelected ? Colors.white : textPrimary,
                  ),
                  backgroundColor: surface,
                  selectedColor: const Color(0xFF0369A1),
                  showCheckmark: false,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                    side: BorderSide(
                      color: isSelected ? const Color(0xFF0369A1) : border,
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

        const SizedBox(height: 10),

        // Quick Toggles (Duty Leave, Free, Featured, High Points)
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: [
              _buildToggleFilter(
                label: 'Duty Leave',
                icon: Icons.verified_user_outlined,
                isActive: _filterDutyLeaveOnly,
                onTap: () => setState(
                  () => _filterDutyLeaveOnly = !_filterDutyLeaveOnly,
                ),
              ),
              const SizedBox(width: 8),
              _buildToggleFilter(
                label: 'Free Entry',
                icon: Icons.payments_outlined,
                isActive: _filterFreeOnly,
                onTap: () => setState(() => _filterFreeOnly = !_filterFreeOnly),
              ),
              const SizedBox(width: 8),
              _buildToggleFilter(
                label: 'Featured',
                icon: Icons.bolt_rounded,
                isActive: _filterFeaturedOnly,
                onTap: () => setState(
                  () => _filterFeaturedOnly = !_filterFeaturedOnly,
                ),
              ),
              const SizedBox(width: 8),
              _buildToggleFilter(
                label: '≥15 KTU Pts',
                icon: Icons.stars_rounded,
                isActive: _filterHighPointsOnly,
                onTap: () => setState(
                  () => _filterHighPointsOnly = !_filterHighPointsOnly,
                ),
              ),
            ],
          ),
        ),

        const SizedBox(height: 24),

        // Events Listing
        if (filteredEvents.isEmpty)
          Container(
            padding: const EdgeInsets.all(40),
            decoration: BoxDecoration(
              color: surface,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: border),
            ),
            child: Center(
              child: Column(
                children: [
                  Icon(
                    Icons.event_busy_rounded,
                    size: 44,
                    color: textSecondary,
                  ),
                  const SizedBox(height: 14),
                  Text(
                    'No events found matching your criteria',
                    style: GoogleFonts.outfit(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: textPrimary,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Try changing your search terms or clearing '
                    'the active filters.',
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      color: textSecondary,
                    ),
                  ),
                  const SizedBox(height: 16),
                  OutlinedButton(
                    onPressed: () {
                      _searchCtrl.clear();
                      setState(() {
                        _searchQuery = '';
                        _selectedCategory = 'All';
                        _filterDutyLeaveOnly = false;
                        _filterFreeOnly = false;
                        _filterFeaturedOnly = false;
                        _filterHighPointsOnly = false;
                      });
                    },
                    child: const Text('Reset All Filters'),
                  ),
                ],
              ),
            ),
          )
        else
          LayoutBuilder(
            builder: (context, constraints) {
              final isWide = constraints.maxWidth >= 750;
              if (isWide) {
                // Responsive two-column staggered layout
                final leftColumn = <Widget>[];
                final rightColumn = <Widget>[];

                for (var i = 0; i < filteredEvents.length; i++) {
                  final card = Padding(
                    padding: const EdgeInsets.only(bottom: 16),
                    child: EventCard(event: filteredEvents[i]),
                  );
                  if (i.isEven) {
                    leftColumn.add(card);
                  } else {
                    rightColumn.add(card);
                  }
                }

                return Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Column(
                        children: leftColumn,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        children: rightColumn,
                      ),
                    ),
                  ],
                );
              } else {
                return ListView.separated(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: filteredEvents.length,
                  separatorBuilder: (context, _) => const SizedBox(height: 14),
                  itemBuilder: (context, index) {
                    return EventCard(event: filteredEvents[index]);
                  },
                );
              }
            },
          ),
      ],
    );
  }

  Widget _buildMetricItem(
    BuildContext context,
    String value,
    String label,
    IconData icon,
    Color color,
  ) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 16, color: color),
            const SizedBox(width: 6),
            Text(
              value,
              style: GoogleFonts.outfit(
                fontSize: 18,
                fontWeight: FontWeight.w800,
                color: AppColors.textPrimaryOf(context),
              ),
            ),
          ],
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: GoogleFonts.inter(
            fontSize: 10,
            fontWeight: FontWeight.w600,
            color: AppColors.textSecondaryOf(context),
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  Widget _buildToggleFilter({
    required String label,
    required IconData icon,
    required bool isActive,
    required VoidCallback onTap,
  }) {
    final isDark = AppColors.isDark(context);
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(
          color: isActive
              ? const Color(0xFF0369A1).withValues(alpha: 0.12)
              : (isDark ? const Color(0xFF1E293B) : const Color(0xFFF1F5F9)),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isActive
                ? const Color(0xFF0369A1)
                : AppColors.borderOf(context),
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 13,
              color: isActive
                  ? const Color(0xFF0369A1)
                  : AppColors.textSecondaryOf(context),
            ),
            const SizedBox(width: 5),
            Text(
              label,
              style: GoogleFonts.inter(
                fontSize: 11,
                fontWeight: isActive ? FontWeight.w700 : FontWeight.w500,
                color: isActive
                    ? const Color(0xFF0369A1)
                    : AppColors.textPrimaryOf(context),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── 2. My Passes & Registrations Subview ───────────────────────────────────

  Widget _buildMyPassesView(
    BuildContext context,
    List<StudentRegistration> regs,
  ) {
    final isDark = AppColors.isDark(context);
    final isDesktop = ResponsiveLayout.isDesktop(context);
    final surface = AppColors.surfaceOf(context);
    final textPrimary = AppColors.textPrimaryOf(context);
    final textSecondary = AppColors.textSecondaryOf(context);
    final border = AppColors.borderOf(context);

    if (regs.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(20),
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
                style: GoogleFonts.outfit(
                  fontSize: 20,
                  fontWeight: FontWeight.w800,
                  color: textPrimary,
                ),
              ),
              const SizedBox(height: 6),
              ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 380),
                child: Text(
                  'Browse upcoming campus hackathons, conclaves, and workshops '
                  'to claim verified entry passes and earn KTU activity '
                  'points.',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.inter(
                    fontSize: 13,
                    color: textSecondary,
                    height: 1.5,
                  ),
                ),
              ),
              const SizedBox(height: 22),
              ElevatedButton.icon(
                onPressed: () => _tabCtrl.animateTo(0),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF0369A1),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 12,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
                icon: const Icon(Icons.explore_rounded, size: 18),
                label: Text(
                  'Explore Campus Events',
                  style: GoogleFonts.inter(
                    fontWeight: FontWeight.w700,
                  ),
                ),
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
      separatorBuilder: (context, _) => const SizedBox(height: 16),
      itemBuilder: (context, index) {
        final reg = regs[index];
        final event = reg.event;
        final hasPoster =
            event?.posterUrl != null && event!.posterUrl!.isNotEmpty;

        return Card(
          elevation: 0,
          color: surface,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
            side: BorderSide(
              color: reg.isActive
                  ? const Color(0xFF16A34A).withValues(alpha: 0.45)
                  : border,
              width: reg.isActive ? 1.5 : 1.0,
            ),
          ),
          clipBehavior: Clip.antiAlias,
          child: InkWell(
            onTap: () => QrPassDialog.show(context, reg),
            borderRadius: BorderRadius.circular(20),
            child: Padding(
              padding: const EdgeInsets.all(18),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Pass QR Thumbnail or Poster Thumbnail
                  ClipRRect(
                    borderRadius: BorderRadius.circular(14),
                    child: hasPoster
                        ? Image.network(
                            event.posterUrl!,
                            width: 72,
                            height: 72,
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) =>
                                _buildQrIconBox(reg, isDark),
                          )
                        : _buildQrIconBox(reg, isDark),
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
                                vertical: 2.5,
                              ),
                              decoration: BoxDecoration(
                                color: reg.isActive
                                    ? const Color(0xFF16A34A)
                                        .withValues(alpha: 0.12)
                                    : border,
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(
                                reg.status.toUpperCase(),
                                style: GoogleFonts.inter(
                                  fontSize: 9,
                                  fontWeight: FontWeight.w800,
                                  letterSpacing: 0.6,
                                  color: reg.isActive
                                      ? const Color(0xFF16A34A)
                                      : Colors.grey,
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            InkWell(
                              onTap: () {
                                unawaited(
                                  Clipboard.setData(
                                    ClipboardData(text: reg.qrPayload),
                                  ),
                                );
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text('Token copied to clipboard'),
                                  ),
                                );
                              },
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(
                                    reg.qrPayload,
                                    style: const TextStyle(
                                      fontSize: 10,
                                      fontFamily: 'monospace',
                                      color: Colors.grey,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                  const SizedBox(width: 4),
                                  const Icon(
                                    Icons.copy_rounded,
                                    size: 11,
                                    color: Colors.grey,
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 6),
                        Text(
                          event?.title ?? 'Campus Entry Pass',
                          style: GoogleFonts.outfit(
                            fontSize: 15,
                            fontWeight: FontWeight.w800,
                            color: textPrimary,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            Icon(
                              Icons.location_on_outlined,
                              size: 13,
                              color: textSecondary,
                            ),
                            const SizedBox(width: 4),
                            Expanded(
                              child: Text(
                                event?.venue ?? 'Campus Venue',
                                style: GoogleFonts.inter(
                                  fontSize: 11,
                                  color: textSecondary,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                        if (event != null) ...[
                          const SizedBox(height: 2),
                          Row(
                            children: [
                              Icon(
                                Icons.schedule_rounded,
                                size: 13,
                                color: textSecondary,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                '${_formatDate(event.startTime)} • '
                                '${_formatTime(event.startTime)}',
                                style: GoogleFonts.inter(
                                  fontSize: 11,
                                  color: textSecondary,
                                ),
                              ),
                            ],
                          ),
                        ],
                        if (event != null &&
                            event.ktuActivityPoints > 0) ...[
                          const SizedBox(height: 6),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 6,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: const Color(0xFF8B5CF6)
                                  .withValues(alpha: 0.12),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              '+${event.ktuActivityPoints} KTU Points '
                              'on Gate Scan',
                              style: GoogleFonts.inter(
                                fontSize: 10,
                                fontWeight: FontWeight.w700,
                                color: const Color(0xFF8B5CF6),
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),

                  const SizedBox(width: 12),

                  // Open QR Pass Button
                  ElevatedButton.icon(
                    onPressed: () => QrPassDialog.show(context, reg),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF0369A1),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 10,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    icon: const Icon(Icons.qr_code_rounded, size: 16),
                    label: Text(
                      'Pass',
                      style: GoogleFonts.inter(
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

  Widget _buildQrIconBox(StudentRegistration reg, bool isDark) {
    return Container(
      width: 72,
      height: 72,
      decoration: BoxDecoration(
        color: reg.isActive
            ? const Color(0xFF16A34A).withValues(alpha: 0.12)
            : (isDark ? const Color(0xFF1E293B) : const Color(0xFFF1F5F9)),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Icon(
        Icons.qr_code_rounded,
        color: reg.isActive ? const Color(0xFF16A34A) : Colors.grey,
        size: 34,
      ),
    );
  }
}
