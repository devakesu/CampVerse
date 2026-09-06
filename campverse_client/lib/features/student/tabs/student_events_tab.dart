import 'dart:async';

import 'package:campverse/core/theme/app_colors.dart';
import 'package:campverse/core/utils/responsive_layout.dart';
import 'package:campverse/core/widgets/error_state_card.dart';
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

/// Filter options for time status of events.
enum EventStatusFilter {
  /// Show all events without time filtering.
  all,

  /// Events actively in progress right now.
  happeningNow,

  /// Events scheduled to take place today.
  scheduledToday,

  /// Events scheduled for the future.
  upcoming,
}

/// Represents a campus event category with icon and distinct color accent.
class EventCategoryItem {
  /// Creates an event category definition.
  const EventCategoryItem({
    required this.id,
    required this.label,
    required this.icon,
    required this.color,
  });

  /// Unique category identifier matching event tags or org categories.
  final String id;

  /// Display label.
  final String label;

  /// Vector icon.
  final IconData icon;

  /// Brand/accent color.
  final Color color;
}

class _StudentEventsTabState extends ConsumerState<StudentEventsTab>
    with SingleTickerProviderStateMixin {
  late TabController _tabCtrl;
  String _selectedCategory = 'All';
  String _searchQuery = '';
  final TextEditingController _searchCtrl = TextEditingController();
  final FocusNode _searchFocus = FocusNode();
  bool _isSearchFocused = false;
  final OverlayPortalController _searchDropdownCtrl = OverlayPortalController();
  final LayerLink _searchLayerLink = LayerLink();
  double _searchBarWidth = 400;
  EventStatusFilter _statusFilter = EventStatusFilter.all;

  // Quick filter toggles
  bool _filterDutyLeaveOnly = false;
  bool _filterFreeOnly = false;

  static const List<EventCategoryItem> _categories = [
    EventCategoryItem(
      id: 'All',
      label: 'All',
      icon: Icons.grid_view_rounded,
      color: Color(0xFF0284C7),
    ),
    EventCategoryItem(
      id: 'Tech',
      label: 'Tech',
      icon: Icons.terminal_rounded,
      color: Color(0xFF6366F1),
    ),
    EventCategoryItem(
      id: 'Hackathon',
      label: 'Hackathon',
      icon: Icons.bolt_rounded,
      color: Color(0xFFF59E0B),
    ),
    EventCategoryItem(
      id: 'Workshop',
      label: 'Workshop',
      icon: Icons.lightbulb_outline_rounded,
      color: Color(0xFF10B981),
    ),
    EventCategoryItem(
      id: 'Cultural',
      label: 'Cultural',
      icon: Icons.palette_outlined,
      color: Color(0xFFEC4899),
    ),
    EventCategoryItem(
      id: 'Sports',
      label: 'Sports',
      icon: Icons.sports_basketball_outlined,
      color: Color(0xFFF97316),
    ),
  ];

  @override
  void initState() {
    super.initState();
    _tabCtrl = TabController(
      length: 2,
      vsync: this,
      initialIndex: widget.initialSubTabIndex,
    );
    _tabCtrl.addListener(() {
      if (mounted) {
        setState(() {});
      }
    });
    _searchFocus.addListener(() {
      if (mounted) {
        setState(() {
          _isSearchFocused = _searchFocus.hasFocus;
        });
      }
    });
  }

  @override
  void dispose() {
    _tabCtrl.dispose();
    _searchCtrl.dispose();
    _searchFocus.dispose();
    super.dispose();
  }

  List<String> _getMatchingEvents(String query, List<StudentEvent> events) {
    if (query.isEmpty) {
      return const [];
    }
    return events
        .where((e) => e.title.toLowerCase().contains(query))
        .map((e) => e.title)
        .toSet()
        .take(4)
        .toList();
  }

  List<String> _getMatchingOrganisations(
    String query,
    List<StudentEvent> events,
  ) {
    if (query.isEmpty) {
      return const [];
    }
    final orgs = <String>{};
    for (final e in events) {
      if (e.primaryOrgName.toLowerCase().contains(query)) {
        orgs.add(e.primaryOrgName);
      }
      for (final col in e.collaborators) {
        if (col.toLowerCase().contains(query)) {
          orgs.add(col);
        }
      }
    }
    return orgs.take(4).toList();
  }

  List<String> _getMatchingVenues(String query, List<StudentEvent> events) {
    if (query.isEmpty) {
      return const [];
    }
    final venues = <String>{};
    for (final e in events) {
      if (e.venue.isNotEmpty && e.venue.toLowerCase().contains(query)) {
        venues.add(e.venue);
      }
    }
    return venues.take(4).toList();
  }

  bool _hasAnyMatches(String query, List<StudentEvent> events) {
    return _getMatchingEvents(query, events).isNotEmpty ||
        _getMatchingOrganisations(query, events).isNotEmpty ||
        _getMatchingVenues(query, events).isNotEmpty;
  }

  void _selectSearchSuggestion(String itemText) {
    _searchCtrl.text = itemText;
    _searchCtrl.selection = TextSelection.fromPosition(
      TextPosition(offset: itemText.length),
    );
    setState(() {
      _searchQuery = itemText;
      _selectedCategory = 'All';
      _statusFilter = EventStatusFilter.all;
    });
    if (_searchDropdownCtrl.isShowing) {
      _searchDropdownCtrl.hide();
    }
    _searchFocus.unfocus();
  }

  bool _isHappeningNow(StudentEvent e, DateTime now) {
    return !now.isBefore(e.startTime) && !now.isAfter(e.endTime);
  }

  bool _isScheduledToday(StudentEvent e, DateTime now) {
    final startOfToday = DateTime(now.year, now.month, now.day);
    final endOfToday = DateTime(now.year, now.month, now.day, 23, 59, 59, 999);
    final startsToday = e.startTime.year == now.year &&
        e.startTime.month == now.month &&
        e.startTime.day == now.day;
    final spansToday =
        e.startTime.isBefore(endOfToday) && e.endTime.isAfter(startOfToday);
    return startsToday || spansToday;
  }

  bool _isUpcoming(StudentEvent e, DateTime now) {
    return e.startTime.isAfter(now);
  }

  bool _matchesNonStatusFilters(StudentEvent e) {
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
        (e.description != null &&
            e.description!.toLowerCase().contains(query)) ||
        e.tags.any((t) => t.toLowerCase().contains(query)) ||
        e.collaborators.any((c) => c.toLowerCase().contains(query));

    final matchesDutyLeave = !_filterDutyLeaveOnly || e.isDutyLeaveApproved;
    final matchesFree = !_filterFreeOnly || !e.isPaid;

    return matchesCat && matchesSearch && matchesDutyLeave && matchesFree;
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

    final allEvents = eventsAsync.valueOrNull ?? const <StudentEvent>[];
    final allRegs = regsAsync.valueOrNull ?? const <StudentRegistration>[];
    final activeRegs = allRegs.where((r) => r.isActive).toList();
    final now = DateTime.now();

    // Filter events based on active search, category, and quick toggles
    // (excluding status)
    final baseFilteredEvents =
        allEvents.where(_matchesNonStatusFilters).toList();

    // Apply status filter on top of base filters for the event listing
    final filteredEvents = baseFilteredEvents.where((e) {
      return switch (_statusFilter) {
        EventStatusFilter.all => true,
        EventStatusFilter.happeningNow => _isHappeningNow(e, now),
        EventStatusFilter.scheduledToday => _isScheduledToday(e, now),
        EventStatusFilter.upcoming => _isUpcoming(e, now),
      };
    }).toList();

    return CallbackShortcuts(
      bindings: {
        const SingleActivator(LogicalKeyboardKey.keyK, control: true):
            _searchFocus.requestFocus,
        const SingleActivator(LogicalKeyboardKey.keyK, meta: true):
            _searchFocus.requestFocus,
      },
      child: Focus(
        child: Scaffold(
          backgroundColor: Colors.transparent,
          appBar: PreferredSize(
            preferredSize: const Size.fromHeight(68),
            child: Container(
              padding: EdgeInsets.symmetric(
                horizontal: isDesktop ? 32 : 12,
                vertical: 8,
              ),
              decoration: BoxDecoration(
                color: AppColors.surfaceOf(context),
                border: Border(
                  bottom: BorderSide(
                    color: AppColors.borderOf(context),
                  ),
                ),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: _buildTopTabBox(
                      context,
                      index: 0,
                      label: 'Discover Events',
                      icon: Icons.explore_rounded,
                      activeColor: const Color(0xFF0284C7),
                      isCompact: !isDesktop,
                    ),
                  ),
                  SizedBox(width: isDesktop ? 12 : 8),
                  Expanded(
                    child: _buildTopTabBox(
                      context,
                      index: 1,
                      label: 'My Passes',
                      icon: Icons.confirmation_number_rounded,
                      activeColor: const Color(0xFF16A34A),
                      isCompact: !isDesktop,
                    ),
                  ),
                ],
              ),
            ),
          ),
          body: TabBarView(
            controller: _tabCtrl,
            children: [
              _buildDiscoverView(
                context,
                filteredEvents: filteredEvents,
                baseFilteredEvents: baseFilteredEvents,
                allEvents: allEvents,
                activeRegs: activeRegs,
                eventsAsync: eventsAsync,
                now: now,
              ),
              _buildMyPassesView(context, allRegs, regsAsync),
            ],
          ),
        ),
      ),
    );
  }

  // ── 1. Discover Events Subview ─────────────────────────────────────────────

  Widget _buildDiscoverView(
    BuildContext context, {
    required List<StudentEvent> filteredEvents,
    required List<StudentEvent> baseFilteredEvents,
    required List<StudentEvent> allEvents,
    required List<StudentRegistration> activeRegs,
    required AsyncValue<List<StudentEvent>> eventsAsync,
    required DateTime now,
  }) {
    if (eventsAsync.isLoading && !eventsAsync.hasValue) {
      return const Center(child: CircularProgressIndicator());
    }

    if (eventsAsync.hasError && !eventsAsync.hasValue) {
      return ErrorStateCard(
        title: 'Unable to Load Campus Events',
        message: eventsAsync.error?.toString() ??
            'Could not retrieve campus events from the server.',
        onRetry: () =>
            ref.read(studentEventsProvider.notifier).loadEvents(),
      );
    }

    final isDesktop = ResponsiveLayout.isDesktop(context);
    final textPrimary = AppColors.textPrimaryOf(context);
    final textSecondary = AppColors.textSecondaryOf(context);
    final border = AppColors.borderOf(context);
    final surface = AppColors.surfaceOf(context);

    // Counts update automatically based on search, category, and quick
    // filter chips
    final happeningNowCount =
        baseFilteredEvents.where((e) => _isHappeningNow(e, now)).length;
    final scheduledTodayCount =
        baseFilteredEvents.where((e) => _isScheduledToday(e, now)).length;
    final upcomingCount =
        baseFilteredEvents.where((e) => _isUpcoming(e, now)).length;

    return ListView(
      padding: EdgeInsets.symmetric(
        horizontal: isDesktop ? 32 : 14,
        vertical: 20,
      ),
      children: [
        if (eventsAsync.hasError) ...[
          InlineErrorBanner(
            message: eventsAsync.error?.toString() ??
                'Failed to refresh latest events.',
            onRetry: () =>
                ref.read(studentEventsProvider.notifier).loadEvents(),
            margin: const EdgeInsets.only(bottom: 16),
          ),
        ],

        // Status Metric Cards (Happening Now, Scheduled Today, Upcoming)
        LayoutBuilder(
          builder: (context, constraints) {
            final isCompact = constraints.maxWidth < 560;
            return Row(
              children: [
                Expanded(
                  child: _buildStatusMetricCard(
                    context,
                    title: 'Happening Now',
                    count: happeningNowCount,
                    subtitle: 'Live on campus',
                    icon: Icons.sensors_rounded,
                    accentColor: const Color(0xFF10B981),
                    isSelected:
                        _statusFilter == EventStatusFilter.happeningNow,
                    isCompact: isCompact,
                    onTap: () {
                      setState(() {
                        _statusFilter =
                            _statusFilter == EventStatusFilter.happeningNow
                                ? EventStatusFilter.all
                                : EventStatusFilter.happeningNow;
                      });
                    },
                  ),
                ),
                SizedBox(width: isCompact ? 8 : 14),
                Expanded(
                  child: _buildStatusMetricCard(
                    context,
                    title: 'Scheduled Today',
                    count: scheduledTodayCount,
                    subtitle: "Today's timeline",
                    icon: Icons.today_rounded,
                    accentColor: const Color(0xFF0284C7),
                    isSelected:
                        _statusFilter == EventStatusFilter.scheduledToday,
                    isCompact: isCompact,
                    onTap: () {
                      setState(() {
                        _statusFilter =
                            _statusFilter == EventStatusFilter.scheduledToday
                                ? EventStatusFilter.all
                                : EventStatusFilter.scheduledToday;
                      });
                    },
                  ),
                ),
                SizedBox(width: isCompact ? 8 : 14),
                Expanded(
                  child: _buildStatusMetricCard(
                    context,
                    title: 'Upcoming',
                    count: upcomingCount,
                    subtitle: 'Future schedule',
                    icon: Icons.rocket_launch_rounded,
                    accentColor: const Color(0xFF8B5CF6),
                    isSelected: _statusFilter == EventStatusFilter.upcoming,
                    isCompact: isCompact,
                    onTap: () {
                      setState(() {
                        _statusFilter =
                            _statusFilter == EventStatusFilter.upcoming
                                ? EventStatusFilter.all
                                : EventStatusFilter.upcoming;
                      });
                    },
                  ),
                ),
              ],
            );
          },
        ),

        const SizedBox(height: 20),

        // Modern Search Bar with Grouped Autocomplete Dropdown
        TapRegion(
          groupId: 'search_region',
          onTapOutside: (_) {
            if (_searchDropdownCtrl.isShowing) {
              _searchDropdownCtrl.hide();
            }
            if (_searchFocus.hasFocus) {
              _searchFocus.unfocus();
            }
          },
          child: LayoutBuilder(
            builder: (context, constraints) {
              _searchBarWidth = constraints.maxWidth;
              return CompositedTransformTarget(
                link: _searchLayerLink,
                child: OverlayPortal(
                  controller: _searchDropdownCtrl,
                  overlayChildBuilder: (context) {
                    final query = _searchQuery.trim().toLowerCase();
                    final matchingEvents =
                        _getMatchingEvents(query, allEvents);
                    final matchingOrgs =
                        _getMatchingOrganisations(query, allEvents);
                    final matchingVenues =
                        _getMatchingVenues(query, allEvents);

                    return CompositedTransformFollower(
                      link: _searchLayerLink,
                      targetAnchor: Alignment.bottomLeft,
                      offset: const Offset(0, 6),
                      child: Align(
                        alignment: Alignment.topLeft,
                        child: SizedBox(
                          width: _searchBarWidth,
                          child: _buildSearchDropdown(
                            context,
                            matchingEvents: matchingEvents,
                            matchingOrgs: matchingOrgs,
                            matchingVenues: matchingVenues,
                          ),
                        ),
                      ),
                    );
                  },
                  child: _buildModernSearchBar(context, allEvents),
                ),
              );
            },
          ),
        ),

        const SizedBox(height: 14),

        // Category Selector & Quick Filters (Duty Leave & Free Entry)
        LayoutBuilder(
          builder: (context, constraints) {
            final isWide = constraints.maxWidth >= 760;

            final desktopCategoriesWidget = SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              physics: const BouncingScrollPhysics(),
              clipBehavior: Clip.none,
              child: Row(
                children: _categories.map((cat) {
                  return Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: _buildCategoryItem(
                      context,
                      item: cat,
                      isSelected: _selectedCategory == cat.id,
                      onTap: () => setState(() => _selectedCategory = cat.id),
                    ),
                  );
                }).toList(),
              ),
            );

            final badgesWidget = Row(
              mainAxisSize: MainAxisSize.min,
              mainAxisAlignment: isWide
                  ? MainAxisAlignment.start
                  : MainAxisAlignment.center,
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
                  onTap: () => setState(
                    () => _filterFreeOnly = !_filterFreeOnly,
                  ),
                ),
              ],
            );

            if (isWide) {
              return Row(
                children: [
                  Expanded(child: desktopCategoriesWidget),
                  const SizedBox(width: 14),
                  badgesWidget,
                ],
              );
            }

            // Mobile / Small displays: Non-scrolling category picker + centered badges
            return Column(
              children: [
                _buildMobileCategorySelector(context),
                const SizedBox(height: 10),
                Center(child: badgesWidget),
              ],
            );
          },
        ),

        const SizedBox(height: 20),

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
                        _statusFilter = EventStatusFilter.all;
                        _filterDutyLeaveOnly = false;
                        _filterFreeOnly = false;
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

  Widget _buildTopTabBox(
    BuildContext context, {
    required int index,
    required String label,
    required IconData icon,
    required Color activeColor,
    bool isCompact = false,
  }) {
    final isSelected = _tabCtrl.index == index;
    final isDark = AppColors.isDark(context);
    final border = AppColors.borderOf(context);
    final textSecondary = AppColors.textSecondaryOf(context);

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () {
          _tabCtrl.animateTo(index);
          setState(() {});
        },
        borderRadius: BorderRadius.circular(14),
        hoverColor: activeColor.withValues(alpha: 0.06),
        splashColor: activeColor.withValues(alpha: 0.12),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeInOut,
          padding: EdgeInsets.symmetric(
            horizontal: isCompact ? 8 : 14,
            vertical: 10,
          ),
          decoration: BoxDecoration(
            color: isSelected
                ? (isDark
                    ? activeColor.withValues(alpha: 0.16)
                    : activeColor.withValues(alpha: 0.08))
                : (isDark ? const Color(0xFF1E293B) : const Color(0xFFF8FAFC)),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: isSelected ? activeColor : border,
              width: isSelected ? 1.5 : 1.0,
            ),
            boxShadow: isSelected
                ? [
                    BoxShadow(
                      color: activeColor.withValues(alpha: 0.12),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ]
                : null,
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: EdgeInsets.all(isCompact ? 4 : 5),
                decoration: BoxDecoration(
                  color: isSelected
                      ? activeColor.withValues(alpha: 0.18)
                      : Colors.transparent,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  icon,
                  size: isCompact ? 16 : 18,
                  color: isSelected ? activeColor : textSecondary,
                ),
              ),
              SizedBox(width: isCompact ? 6 : 8),
              Flexible(
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Text(
                    label,
                    maxLines: 1,
                    style: GoogleFonts.outfit(
                      fontSize: isCompact ? 13 : 14,
                      fontWeight:
                          isSelected ? FontWeight.w700 : FontWeight.w600,
                      color: isSelected
                          ? (isDark ? Colors.white : activeColor)
                          : textSecondary,
                      letterSpacing: -0.3,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatusMetricCard(
    BuildContext context, {
    required String title,
    required int count,
    required String subtitle,
    required IconData icon,
    required Color accentColor,
    required bool isSelected,
    required VoidCallback onTap,
    bool isCompact = false,
  }) {
    final isDark = AppColors.isDark(context);
    final border = AppColors.borderOf(context);
    final textSecondary = AppColors.textSecondaryOf(context);
    final textPrimary = AppColors.textPrimaryOf(context);

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(18),
        hoverColor: accentColor.withValues(alpha: 0.06),
        splashColor: accentColor.withValues(alpha: 0.12),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 240),
          curve: Curves.easeOutCubic,
          transform: isSelected
              ? Matrix4.translationValues(0, -3, 0)
              : Matrix4.identity(),
          padding: EdgeInsets.symmetric(
            horizontal: isCompact ? 8 : 14,
            vertical: isCompact ? 10 : 14,
          ),
          decoration: BoxDecoration(
            color: isSelected ? null : AppColors.surfaceOf(context),
            gradient: isSelected
                ? LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: isDark
                        ? [
                            accentColor.withValues(alpha: 0.28),
                            accentColor.withValues(alpha: 0.12),
                          ]
                        : [
                            accentColor.withValues(alpha: 0.18),
                            accentColor.withValues(alpha: 0.05),
                          ],
                  )
                : null,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(
              color: isSelected
                  ? accentColor
                  : (isDark ? border : const Color(0xFFE2E8F0)),
              width: isSelected ? 2.0 : 1.0,
            ),
            boxShadow: [
              BoxShadow(
                color: isSelected
                    ? accentColor.withValues(alpha: isDark ? 0.42 : 0.28)
                    : (isDark
                        ? Colors.black.withValues(alpha: 0.2)
                        : const Color(0xFF0F172A).withValues(alpha: 0.04)),
                blurRadius: isSelected ? 16 : 6,
                spreadRadius: isSelected ? 1 : 0,
                offset: Offset(0, isSelected ? 6 : 3),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    padding: EdgeInsets.all(isCompact ? 5 : 7),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? accentColor
                          : accentColor.withValues(alpha: 0.14),
                      borderRadius: BorderRadius.circular(10),
                      boxShadow: isSelected
                          ? [
                              BoxShadow(
                                color: accentColor.withValues(alpha: 0.45),
                                blurRadius: 6,
                                offset: const Offset(0, 2),
                              ),
                            ]
                          : null,
                    ),
                    child: Icon(
                      icon,
                      size: isCompact ? 16 : 18,
                      color: isSelected ? Colors.white : accentColor,
                    ),
                  ),
                  if (isSelected)
                    Container(
                      padding: const EdgeInsets.all(3),
                      decoration: BoxDecoration(
                        color: accentColor.withValues(
                          alpha: isDark ? 0.3 : 0.15,
                        ),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        Icons.close_rounded,
                        size: isCompact ? 11 : 13,
                        color: accentColor,
                      ),
                    ),
                ],
              ),
              SizedBox(height: isCompact ? 8 : 10),
              FittedBox(
                fit: BoxFit.scaleDown,
                alignment: Alignment.centerLeft,
                child: Text(
                  '$count',
                  style: GoogleFonts.outfit(
                    fontSize: isCompact ? 22 : 26,
                    fontWeight: FontWeight.w800,
                    color: isSelected ? accentColor : textPrimary,
                    letterSpacing: -0.5,
                  ),
                ),
              ),
              const SizedBox(height: 2),
              SizedBox(
                height: isCompact ? 28 : 20,
                child: Align(
                  alignment: Alignment.topLeft,
                  child: Text(
                    title,
                    maxLines: 2,
                    softWrap: true,
                    style: GoogleFonts.inter(
                      fontSize: isCompact ? 11 : 12.5,
                      fontWeight:
                          isSelected ? FontWeight.w800 : FontWeight.w700,
                      height: 1.15,
                      color: isSelected ? accentColor : textPrimary,
                    ),
                  ),
                ),
              ),
              if (!isCompact) ...[
                const SizedBox(height: 2),
                Text(
                  isSelected ? 'Tap to clear filter' : subtitle,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.inter(
                    fontSize: 10,
                    fontWeight:
                        isSelected ? FontWeight.w600 : FontWeight.w500,
                    color: isSelected
                        ? accentColor.withValues(alpha: 0.9)
                        : textSecondary,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildModernSearchBar(
    BuildContext context,
    List<StudentEvent> allEvents,
  ) {
    final isDark = AppColors.isDark(context);
    final border = AppColors.borderOf(context);
    final surface = AppColors.surfaceOf(context);
    final textSecondary = AppColors.textSecondaryOf(context);
    final textPrimary = AppColors.textPrimaryOf(context);
    final isDesktop = ResponsiveLayout.isDesktop(context);

    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      height: 52,
      padding: const EdgeInsets.symmetric(horizontal: 10),
      decoration: BoxDecoration(
        color: surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: _isSearchFocused
              ? const Color(0xFF0284C7)
              : (isDark ? border : const Color(0xFFE2E8F0)),
          width: _isSearchFocused ? 1.5 : 1.0,
        ),
        boxShadow: [
          BoxShadow(
            color: _isSearchFocused
                ? const Color(0xFF0284C7).withValues(alpha: 0.18)
                : (isDark
                    ? Colors.black.withValues(alpha: 0.2)
                    : const Color(0xFF0F172A).withValues(alpha: 0.05)),
            blurRadius: _isSearchFocused ? 14 : 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF0284C7), Color(0xFF0369A1)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(11),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF0284C7).withValues(alpha: 0.35),
                  blurRadius: 6,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: const Icon(
              Icons.search_rounded,
              size: 19,
              color: Colors.white,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: TextField(
              controller: _searchCtrl,
              focusNode: _searchFocus,
              onTap: () {
                final query = _searchCtrl.text.trim().toLowerCase();
                if (query.isNotEmpty && _hasAnyMatches(query, allEvents)) {
                  if (!_searchDropdownCtrl.isShowing) {
                    _searchDropdownCtrl.show();
                  }
                }
              },
              onChanged: (v) {
                setState(() => _searchQuery = v);
                final query = v.trim().toLowerCase();
                if (query.isNotEmpty && _hasAnyMatches(query, allEvents)) {
                  if (!_searchDropdownCtrl.isShowing) {
                    _searchDropdownCtrl.show();
                  }
                } else {
                  if (_searchDropdownCtrl.isShowing) {
                    _searchDropdownCtrl.hide();
                  }
                }
              },
              onSubmitted: (_) {
                if (_searchDropdownCtrl.isShowing) {
                  _searchDropdownCtrl.hide();
                }
                _searchFocus.unfocus();
              },
              textAlignVertical: TextAlignVertical.center,
              style: GoogleFonts.inter(
                fontSize: 13.5,
                height: 1.2,
                fontWeight: FontWeight.w500,
                color: textPrimary,
              ),
              decoration: InputDecoration(
                isDense: true,
                hintText: isDesktop
                    ? 'Search campus events, clubs, venues, or topics...'
                    : 'Search events, clubs, venues...',
                hintStyle: GoogleFonts.inter(
                  fontSize: 13,
                  height: 1.2,
                  color: textSecondary,
                  fontWeight: FontWeight.w400,
                ),
                filled: false,
                border: InputBorder.none,
                enabledBorder: InputBorder.none,
                focusedBorder: InputBorder.none,
                contentPadding: const EdgeInsets.symmetric(vertical: 10),
              ),
            ),
          ),
          if (_searchQuery.isNotEmpty)
            Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: () {
                  _searchCtrl.clear();
                  _searchDropdownCtrl.hide();
                  setState(() => _searchQuery = '');
                },
                borderRadius: BorderRadius.circular(20),
                child: Padding(
                  padding: const EdgeInsets.all(6),
                  child: Icon(
                    Icons.cancel_rounded,
                    size: 18,
                    color: textSecondary,
                  ),
                ),
              ),
            )
          else if (isDesktop)
            Container(
              padding: const EdgeInsets.symmetric(
                horizontal: 8,
                vertical: 4,
              ),
              decoration: BoxDecoration(
                color: isDark
                    ? const Color(0xFF334155)
                    : const Color(0xFFF1F5F9),
                borderRadius: BorderRadius.circular(6),
                border: Border.all(
                  color: border,
                ),
              ),
              child: Text(
                'Ctrl+K',
                style: GoogleFonts.inter(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: textSecondary,
                ),
              ),
            )
          else
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: isDark
                    ? const Color(0xFF1E293B)
                    : const Color(0xFFF1F5F9),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                Icons.tune_rounded,
                size: 16,
                color: textSecondary,
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildSearchDropdown(
    BuildContext context, {
    required List<String> matchingEvents,
    required List<String> matchingOrgs,
    required List<String> matchingVenues,
  }) {
    final isDark = AppColors.isDark(context);
    final border = AppColors.borderOf(context);
    final surface = isDark ? const Color(0xFF1E293B) : Colors.white;

    final hasAny = matchingEvents.isNotEmpty ||
        matchingOrgs.isNotEmpty ||
        matchingVenues.isNotEmpty;

    if (!hasAny) {
      return const SizedBox.shrink();
    }

    final groups = <Widget>[];

    if (matchingEvents.isNotEmpty) {
      groups.add(
        _buildSearchDropdownGroup(
          context,
          title: 'EVENTS',
          icon: Icons.calendar_month_rounded,
          color: const Color(0xFF0284C7),
          items: matchingEvents,
          itemIcon: Icons.event_rounded,
        ),
      );
    }

    if (matchingOrgs.isNotEmpty) {
      if (groups.isNotEmpty) {
        groups.add(
          Divider(
            height: 1,
            thickness: 1,
            color: border.withValues(alpha: 0.6),
          ),
        );
      }
      groups.add(
        _buildSearchDropdownGroup(
          context,
          title: 'ORGANISATIONS',
          icon: Icons.groups_rounded,
          color: const Color(0xFF6366F1),
          items: matchingOrgs,
          itemIcon: Icons.corporate_fare_rounded,
        ),
      );
    }

    if (matchingVenues.isNotEmpty) {
      if (groups.isNotEmpty) {
        groups.add(
          Divider(
            height: 1,
            thickness: 1,
            color: border.withValues(alpha: 0.6),
          ),
        );
      }
      groups.add(
        _buildSearchDropdownGroup(
          context,
          title: 'VENUES',
          icon: Icons.place_rounded,
          color: const Color(0xFF10B981),
          items: matchingVenues,
          itemIcon: Icons.location_on_outlined,
        ),
      );
    }

    return TapRegion(
      groupId: 'search_region',
      child: Material(
        color: surface,
        elevation: 10,
        shadowColor: Colors.black.withValues(alpha: isDark ? 0.4 : 0.12),
        borderRadius: BorderRadius.circular(16),
        clipBehavior: Clip.antiAlias,
        child: Container(
          constraints: const BoxConstraints(maxHeight: 360),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
              width: 1.2,
            ),
          ),
          child: SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: groups,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSearchDropdownGroup(
    BuildContext context, {
    required String title,
    required IconData icon,
    required Color color,
    required List<String> items,
    required IconData itemIcon,
  }) {
    final textPrimary = AppColors.textPrimaryOf(context);
    final textSecondary = AppColors.textSecondaryOf(context);

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(14, 10, 14, 4),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.14),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Icon(icon, size: 12, color: color),
              ),
              const SizedBox(width: 8),
              Text(
                title,
                style: GoogleFonts.inter(
                  fontSize: 10.5,
                  fontWeight: FontWeight.w700,
                  color: color,
                  letterSpacing: 0.6,
                ),
              ),
              const SizedBox(width: 6),
              Text(
                '(${items.length})',
                style: GoogleFonts.inter(
                  fontSize: 10,
                  fontWeight: FontWeight.w600,
                  color: textSecondary,
                ),
              ),
            ],
          ),
        ),
        ...items.map((itemText) {
          return Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: () => _selectSearchSuggestion(itemText),
              hoverColor: color.withValues(alpha: 0.08),
              splashColor: color.withValues(alpha: 0.14),
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 9,
                ),
                child: Row(
                  children: [
                    Icon(
                      itemIcon,
                      size: 15,
                      color: textSecondary,
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        itemText,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: GoogleFonts.inter(
                          fontSize: 12.5,
                          fontWeight: FontWeight.w500,
                          color: textPrimary,
                        ),
                      ),
                    ),
                    Icon(
                      Icons.north_west_rounded,
                      size: 13,
                      color: textSecondary.withValues(alpha: 0.4),
                    ),
                  ],
                ),
              ),
            ),
          );
        }),
        const SizedBox(height: 4),
      ],
    );
  }

  Widget _buildCategoryItem(
    BuildContext context, {
    required EventCategoryItem item,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    final isDark = AppColors.isDark(context);
    final border = AppColors.borderOf(context);
    final surface = AppColors.surfaceOf(context);
    final textPrimary = AppColors.textPrimaryOf(context);

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        hoverColor: item.color.withValues(alpha: 0.08),
        splashColor: item.color.withValues(alpha: 0.16),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOutCubic,
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
          decoration: BoxDecoration(
            color: isSelected
                ? item.color
                : (isDark ? surface : const Color(0xFFF8FAFC)),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: isSelected
                  ? item.color
                  : (isDark ? border : const Color(0xFFE2E8F0)),
              width: isSelected ? 1.5 : 1.0,
            ),
            boxShadow: isSelected
                ? [
                    BoxShadow(
                      color: item.color.withValues(alpha: 0.32),
                      blurRadius: 10,
                      offset: const Offset(0, 3),
                    ),
                  ]
                : null,
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 24,
                height: 24,
                decoration: BoxDecoration(
                  color: isSelected
                      ? Colors.white.withValues(alpha: 0.24)
                      : item.color.withValues(alpha: 0.12),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  item.icon,
                  size: 13.5,
                  color: isSelected ? Colors.white : item.color,
                ),
              ),
              const SizedBox(width: 8),
              Text(
                item.label,
                style: GoogleFonts.inter(
                  fontSize: 12.5,
                  fontWeight: isSelected ? FontWeight.w700 : FontWeight.w600,
                  color: isSelected
                      ? Colors.white
                      : (isDark ? textPrimary : const Color(0xFF334155)),
                  letterSpacing: -0.2,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMobileCategorySelector(BuildContext context) {
    final isDark = AppColors.isDark(context);
    final border = AppColors.borderOf(context);
    final surface = AppColors.surfaceOf(context);
    final textPrimary = AppColors.textPrimaryOf(context);
    final textSecondary = AppColors.textSecondaryOf(context);

    final selectedCat = _categories.firstWhere(
      (c) => c.id == _selectedCategory,
      orElse: () => _categories.first,
    );
    final isFiltered = _selectedCategory != 'All';

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () => _showCategoryPickerSheet(context),
        borderRadius: BorderRadius.circular(16),
        hoverColor: selectedCat.color.withValues(alpha: 0.05),
        splashColor: selectedCat.color.withValues(alpha: 0.12),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          decoration: BoxDecoration(
            color: isFiltered
                ? selectedCat.color.withValues(alpha: isDark ? 0.18 : 0.08)
                : surface,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: isFiltered
                  ? selectedCat.color
                  : (isDark ? border : const Color(0xFFE2E8F0)),
              width: isFiltered ? 1.5 : 1.0,
            ),
            boxShadow: [
              BoxShadow(
                color: isFiltered
                    ? selectedCat.color.withValues(alpha: 0.18)
                    : (isDark
                        ? Colors.black.withValues(alpha: 0.2)
                        : const Color(0xFF0F172A).withValues(alpha: 0.04)),
                blurRadius: isFiltered ? 10 : 6,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Row(
            children: [
              Container(
                width: 30,
                height: 30,
                decoration: BoxDecoration(
                  color: selectedCat.color.withValues(alpha: 0.14),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  selectedCat.icon,
                  size: 16,
                  color: selectedCat.color,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'CATEGORY',
                      style: GoogleFonts.inter(
                        fontSize: 9.5,
                        fontWeight: FontWeight.w700,
                        color: textSecondary,
                        letterSpacing: 0.5,
                      ),
                    ),
                    Text(
                      selectedCat.label == 'All'
                          ? 'All Categories'
                          : selectedCat.label,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.inter(
                        fontSize: 13.5,
                        fontWeight: FontWeight.w700,
                        color: isFiltered ? selectedCat.color : textPrimary,
                      ),
                    ),
                  ],
                ),
              ),
              if (isFiltered) ...[
                InkWell(
                  onTap: () => setState(() => _selectedCategory = 'All'),
                  borderRadius: BorderRadius.circular(12),
                  child: Padding(
                    padding: const EdgeInsets.all(4),
                    child: Icon(
                      Icons.cancel_rounded,
                      size: 18,
                      color: selectedCat.color,
                    ),
                  ),
                ),
                const SizedBox(width: 6),
              ],
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: isDark
                      ? const Color(0xFF334155)
                      : const Color(0xFFF1F5F9),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: isDark
                        ? const Color(0xFF475569)
                        : const Color(0xFFE2E8F0),
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'Change',
                      style: GoogleFonts.inter(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: textSecondary,
                      ),
                    ),
                    const SizedBox(width: 3),
                    Icon(
                      Icons.keyboard_arrow_down_rounded,
                      size: 14,
                      color: textSecondary,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showCategoryPickerSheet(BuildContext context) {
    final isDark = AppColors.isDark(context);
    final border = AppColors.borderOf(context);
    final textPrimary = AppColors.textPrimaryOf(context);
    final textSecondary = AppColors.textSecondaryOf(context);

    unawaited(
      showModalBottomSheet<void>(
        context: context,
        backgroundColor: isDark ? const Color(0xFF0F172A) : Colors.white,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        isScrollControlled: true,
        builder: (ctx) {
          return SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Container(
                      width: 38,
                      height: 4,
                      decoration: BoxDecoration(
                        color: isDark
                            ? const Color(0xFF334155)
                            : const Color(0xFFCBD5E1),
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Event Categories',
                              style: GoogleFonts.outfit(
                                fontSize: 18,
                                fontWeight: FontWeight.w700,
                                color: textPrimary,
                              ),
                            ),
                            Text(
                              'Filter campus events by category',
                              style: GoogleFonts.inter(
                                fontSize: 12,
                                color: textSecondary,
                              ),
                            ),
                          ],
                        ),
                      ),
                      if (_selectedCategory != 'All')
                        TextButton(
                          onPressed: () {
                            setState(() => _selectedCategory = 'All');
                            Navigator.pop(ctx);
                          },
                          child: Text(
                            'Reset',
                            style: GoogleFonts.inter(
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                              color: const Color(0xFF0284C7),
                            ),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  GridView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      mainAxisSpacing: 10,
                      crossAxisSpacing: 10,
                      childAspectRatio: 2.5,
                    ),
                    itemCount: _categories.length,
                    itemBuilder: (ctx, index) {
                      final cat = _categories[index];
                      final isSelected = _selectedCategory == cat.id;

                      return Material(
                        color: Colors.transparent,
                        child: InkWell(
                          onTap: () {
                            setState(() => _selectedCategory = cat.id);
                            Navigator.pop(ctx);
                          },
                          borderRadius: BorderRadius.circular(16),
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 180),
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 8,
                            ),
                            decoration: BoxDecoration(
                              color: isSelected
                                  ? cat.color
                                      .withValues(alpha: isDark ? 0.2 : 0.12)
                                  : (isDark
                                      ? const Color(0xFF1E293B)
                                      : const Color(0xFFF8FAFC)),
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(
                                color: isSelected
                                    ? cat.color
                                    : (isDark
                                        ? border
                                        : const Color(0xFFE2E8F0)),
                                width: isSelected ? 1.75 : 1.0,
                              ),
                            ),
                            child: Row(
                              children: [
                                Container(
                                  width: 32,
                                  height: 32,
                                  decoration: BoxDecoration(
                                    color: isSelected
                                        ? cat.color
                                        : cat.color.withValues(alpha: 0.12),
                                    shape: BoxShape.circle,
                                  ),
                                  child: Icon(
                                    cat.icon,
                                    size: 16,
                                    color: isSelected
                                        ? Colors.white
                                        : cat.color,
                                  ),
                                ),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: Text(
                                    cat.label,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: GoogleFonts.inter(
                                      fontSize: 13,
                                      fontWeight: isSelected
                                          ? FontWeight.w700
                                          : FontWeight.w600,
                                      color: isSelected
                                          ? cat.color
                                          : textPrimary,
                                    ),
                                  ),
                                ),
                                if (isSelected)
                                  Icon(
                                    Icons.check_circle_rounded,
                                    size: 16,
                                    color: cat.color,
                                  ),
                              ],
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildToggleFilter({
    required String label,
    required IconData icon,
    required bool isActive,
    required VoidCallback onTap,
  }) {
    final isDark = AppColors.isDark(context);
    final border = AppColors.borderOf(context);
    final textPrimary = AppColors.textPrimaryOf(context);
    final textSecondary = AppColors.textSecondaryOf(context);

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        hoverColor: const Color(0xFF0284C7).withValues(alpha: 0.06),
        splashColor: const Color(0xFF0284C7).withValues(alpha: 0.12),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          curve: Curves.easeInOut,
          padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 7),
          decoration: BoxDecoration(
            color: isActive
                ? const Color(0xFF0284C7).withValues(alpha: 0.12)
                : (isDark ? const Color(0xFF1E293B) : const Color(0xFFF8FAFC)),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: isActive
                  ? const Color(0xFF0284C7)
                  : (isDark ? border : const Color(0xFFE2E8F0)),
              width: isActive ? 1.4 : 1.0,
            ),
            boxShadow: isActive
                ? [
                    BoxShadow(
                      color: const Color(0xFF0284C7).withValues(alpha: 0.16),
                      blurRadius: 6,
                      offset: const Offset(0, 2),
                    ),
                  ]
                : null,
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                icon,
                size: 14,
                color: isActive
                    ? const Color(0xFF0284C7)
                    : textSecondary,
              ),
              const SizedBox(width: 6),
              Text(
                label,
                style: GoogleFonts.inter(
                  fontSize: 12,
                  fontWeight: isActive ? FontWeight.w700 : FontWeight.w500,
                  color: isActive
                      ? const Color(0xFF0284C7)
                      : textPrimary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ── 2. My Passes & Registrations Subview ───────────────────────────────────

  Widget _buildMyPassesView(
    BuildContext context,
    List<StudentRegistration> regs,
    AsyncValue<List<StudentRegistration>> regsAsync,
  ) {
    if (regsAsync.isLoading && !regsAsync.hasValue) {
      return const Center(child: CircularProgressIndicator());
    }

    if (regsAsync.hasError && !regsAsync.hasValue) {
      return ErrorStateCard(
        title: 'Unable to Load Event Passes',
        message: regsAsync.error?.toString() ??
            'Could not retrieve your digital event passes. Please try again.',
        onRetry: () =>
            ref.read(studentRegistrationsProvider.notifier).loadRegistrations(),
      );
    }

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

    final hasError = regsAsync.hasError;
    final totalCount = regs.length + (hasError ? 1 : 0);

    return ListView.separated(
      padding: EdgeInsets.symmetric(
        horizontal: isDesktop ? 32 : 18,
        vertical: 24,
      ),
      itemCount: totalCount,
      separatorBuilder: (context, _) => const SizedBox(height: 16),
      itemBuilder: (context, index) {
        if (hasError && index == 0) {
          return InlineErrorBanner(
            message: regsAsync.error?.toString() ??
                'Failed to refresh entry passes.',
            onRetry: () => ref
                .read(studentRegistrationsProvider.notifier)
                .loadRegistrations(),
          );
        }
        final reg = regs[hasError ? index - 1 : index];
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
