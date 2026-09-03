import 'package:campverse/core/models/university.dart';
import 'package:campverse/core/theme/app_colors.dart';
import 'package:flutter/material.dart';

/// A searchable form field for selecting an affiliating university,
/// filterable by jurisdiction state.
///
/// Tapping the field opens an adaptive picker modal (dialog on desktop/tablet,
/// bottom sheet on mobile) featuring real-time search by name, slug/code, or
/// jurisdiction state, along with interactive state filter chips.
class UniversityPickerFormField extends FormField<String> {
  /// Default constructor for [UniversityPickerFormField].
  UniversityPickerFormField({
    required List<University> universities,
    super.key,
    super.initialValue,
    String labelText = 'Affiliated University',
    String hintText = 'Select affiliating university',
    String? initialFilterState,
    ValueChanged<University?>? onChanged,
    super.validator,
    super.onSaved,
    bool enabled = true,
    super.autovalidateMode = AutovalidateMode.onUserInteraction,
  }) : super(
          builder: (state) {
            return _UniversityPickerFieldContent(
              state: state,
              universities: universities,
              labelText: labelText,
              hintText: hintText,
              initialFilterState: initialFilterState,
              enabled: enabled,
              onChanged: onChanged,
            );
          },
        );
}

class _UniversityPickerFieldContent extends StatefulWidget {
  const _UniversityPickerFieldContent({
    required this.state,
    required this.universities,
    required this.labelText,
    required this.hintText,
    required this.enabled,
    this.initialFilterState,
    this.onChanged,
  });

  final FormFieldState<String> state;
  final List<University> universities;
  final String labelText;
  final String hintText;
  final String? initialFilterState;
  final bool enabled;
  final ValueChanged<University?>? onChanged;

  @override
  State<_UniversityPickerFieldContent> createState() =>
      _UniversityPickerFieldContentState();
}

class _UniversityPickerFieldContentState
    extends State<_UniversityPickerFieldContent> {
  Future<void> _openPicker() async {
    if (!widget.enabled) {
      return;
    }

    final selected = await UniversityPickerModal.show(
      context,
      universities: widget.universities,
      initialSelectedUniversityId: widget.state.value,
      initialFilterState: widget.initialFilterState,
    );

    if (selected != null) {
      widget.state.didChange(selected.id);
      widget.onChanged?.call(selected);
    }
  }

  void _clearValue() {
    widget.state.didChange(null);
    widget.onChanged?.call(null);
  }

  @override
  Widget build(BuildContext context) {
    final selectedId = widget.state.value;
    final hasValue = selectedId != null && selectedId.trim().isNotEmpty;

    University? selectedUniversity;
    if (hasValue) {
      for (final u in widget.universities) {
        if (u.id == selectedId) {
          selectedUniversity = u;
          break;
        }
      }
    }

    final isDark = AppColors.isDark(context);
    final primaryColor = AppColors.primaryOf(context);

    return InkWell(
      onTap: widget.enabled ? _openPicker : null,
      borderRadius: BorderRadius.circular(12),
      child: InputDecorator(
        decoration: InputDecoration(
          labelText: widget.labelText,
          hintText: widget.hintText,
          prefixIcon: const Icon(Icons.account_balance_outlined),
          errorText: widget.state.errorText,
          suffixIcon: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (hasValue && widget.enabled)
                IconButton(
                  icon: const Icon(Icons.clear_rounded, size: 18),
                  tooltip: 'Clear university selection',
                  onPressed: _clearValue,
                ),
              const Padding(
                padding: EdgeInsets.only(right: 12),
                child: Icon(Icons.arrow_drop_down_rounded, size: 24),
              ),
            ],
          ),
        ),
        isEmpty: !hasValue || selectedUniversity == null,
        child: hasValue && selectedUniversity != null
            ? Row(
                children: [
                  Expanded(
                    child: Text(
                      selectedUniversity.name,
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w500,
                        color: AppColors.textPrimaryOf(context),
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const SizedBox(width: 8),
                  // Slug Badge
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 6,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: primaryColor.withValues(
                        alpha: isDark ? 0.25 : 0.12,
                      ),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      selectedUniversity.slug,
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: primaryColor,
                      ),
                    ),
                  ),
                  if (selectedUniversity.state.isNotEmpty) ...[
                    const SizedBox(width: 6),
                    // State Badge
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 6,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.teal.withValues(
                          alpha: isDark ? 0.25 : 0.12,
                        ),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(
                            Icons.location_on_outlined,
                            size: 11,
                            color: Colors.teal,
                          ),
                          const SizedBox(width: 2),
                          Text(
                            selectedUniversity.state,
                            style: const TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: Colors.teal,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ],
              )
            : null,
      ),
    );
  }
}

/// Adaptive modal for searching and filtering universities by state.
class UniversityPickerModal extends StatefulWidget {
  /// Default constructor for [UniversityPickerModal].
  const UniversityPickerModal({
    required this.universities,
    this.initialSelectedUniversityId,
    this.initialFilterState,
    super.key,
  });

  /// All registered universities available for selection.
  final List<University> universities;

  /// ID of the currently selected university, if any.
  final String? initialSelectedUniversityId;

  /// Optional initial state to pre-filter by.
  final String? initialFilterState;

  /// Shows the picker adaptively (dialog on wide screens, bottom sheet on
  /// mobile).
  static Future<University?> show(
    BuildContext context, {
    required List<University> universities,
    String? initialSelectedUniversityId,
    String? initialFilterState,
  }) {
    final isWide = MediaQuery.of(context).size.width > 600;

    if (isWide) {
      return showDialog<University>(
        context: context,
        builder: (context) => Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          clipBehavior: Clip.antiAlias,
          child: ConstrainedBox(
            constraints: const BoxConstraints(
              maxWidth: 580,
              maxHeight: 680,
            ),
            child: UniversityPickerModal(
              universities: universities,
              initialSelectedUniversityId: initialSelectedUniversityId,
              initialFilterState: initialFilterState,
            ),
          ),
        ),
      );
    }

    return showModalBottomSheet<University>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.85,
        minChildSize: 0.5,
        maxChildSize: 0.95,
        builder: (context, scrollController) {
          return ClipRRect(
            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
            child: Material(
              color: AppColors.surfaceOf(context),
              child: UniversityPickerModal(
                universities: universities,
                initialSelectedUniversityId: initialSelectedUniversityId,
                initialFilterState: initialFilterState,
              ),
            ),
          );
        },
      ),
    );
  }

  @override
  State<UniversityPickerModal> createState() => _UniversityPickerModalState();
}

class _UniversityPickerModalState extends State<UniversityPickerModal> {
  final _searchController = TextEditingController();
  String _searchQuery = '';
  String? _selectedState;

  @override
  void initState() {
    super.initState();
    if (widget.initialFilterState != null &&
        widget.initialFilterState!.trim().isNotEmpty) {
      _selectedState = widget.initialFilterState!.trim();
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  List<String> _extractStates() {
    final stateSet = <String>{};
    for (final u in widget.universities) {
      final s = u.state.trim();
      if (s.isNotEmpty) {
        stateSet.add(s);
      }
    }
    final list = stateSet.toList()..sort((a, b) => a.compareTo(b));
    return list;
  }

  List<University> _getFilteredUniversities() {
    final cleanQuery = _searchQuery.trim().toLowerCase();

    return widget.universities.where((u) {
      // 1. Filter by State
      if (_selectedState != null && _selectedState!.isNotEmpty) {
        if (u.state.trim().toLowerCase() != _selectedState!.toLowerCase()) {
          return false;
        }
      }

      // 2. Search query filter
      if (cleanQuery.isEmpty) {
        return true;
      }

      final nameMatches = u.name.toLowerCase().contains(cleanQuery);
      final slugMatches = u.slug.toLowerCase().contains(cleanQuery);
      final stateMatches = u.state.toLowerCase().contains(cleanQuery);

      return nameMatches || slugMatches || stateMatches;
    }).toList();
  }

  int _countForState(String stateName) {
    return widget.universities.where((u) {
      return u.state.trim().toLowerCase() == stateName.toLowerCase();
    }).length;
  }

  @override
  Widget build(BuildContext context) {
    final filtered = _getFilteredUniversities();
    final uniqueStates = _extractStates();
    final isDark = AppColors.isDark(context);
    final primaryColor = AppColors.primaryOf(context);

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Modal Header
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 18, 16, 12),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppColors.roleSuperAdmin.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(
                  Icons.account_balance_outlined,
                  color: AppColors.roleSuperAdmin,
                  size: 22,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Select Affiliating University',
                      style: TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textPrimaryOf(context),
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Search by name or code • Filter by state jurisdiction',
                      style: TextStyle(
                        fontSize: 12,
                        color: AppColors.textSecondaryOf(context),
                      ),
                    ),
                  ],
                ),
              ),
              IconButton(
                icon: const Icon(Icons.close_rounded),
                tooltip: 'Close',
                onPressed: () => Navigator.of(context).pop(),
              ),
            ],
          ),
        ),

        const Divider(height: 1),

        // Search Input Bar
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
          child: TextField(
            controller: _searchController,
            autofocus: true,
            style: TextStyle(color: AppColors.textPrimaryOf(context)),
            decoration: InputDecoration(
              hintText: 'Search by university name, code (e.g. KTU)...',
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
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 12,
              ),
            ),
            onChanged: (val) => setState(() => _searchQuery = val),
            onSubmitted: (_) {
              if (filtered.isNotEmpty) {
                Navigator.of(context).pop(filtered.first);
              }
            },
          ),
        ),

        // State Filter Bar
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(
                    Icons.filter_list_rounded,
                    size: 15,
                    color: AppColors.textSecondaryOf(context),
                  ),
                  const SizedBox(width: 6),
                  Text(
                    'Filter by State:',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textSecondaryOf(context),
                    ),
                  ),
                  if (_selectedState != null) ...[
                    const Spacer(),
                    InkWell(
                      onTap: () => setState(() => _selectedState = null),
                      borderRadius: BorderRadius.circular(4),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 4,
                          vertical: 2,
                        ),
                        child: Text(
                          'Clear State Filter',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: primaryColor,
                          ),
                        ),
                      ),
                    ),
                  ],
                ],
              ),
              const SizedBox(height: 8),
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    _buildStateChip(
                      label: 'All States (${widget.universities.length})',
                      isSelected: _selectedState == null,
                      onTap: () => setState(() => _selectedState = null),
                    ),
                    for (final state in uniqueStates) ...[
                      const SizedBox(width: 8),
                      _buildStateChip(
                        label: '$state (${_countForState(state)})',
                        isSelected: _selectedState?.toLowerCase() ==
                            state.toLowerCase(),
                        onTap: () {
                          setState(() {
                            if (_selectedState?.toLowerCase() ==
                                state.toLowerCase()) {
                              _selectedState = null;
                            } else {
                              _selectedState = state;
                            }
                          });
                        },
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),

        const SizedBox(height: 6),

        // Result Count Header
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 4),
          child: Text(
            'Showing ${filtered.length} of '
            '${widget.universities.length} universities',
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w500,
              color: AppColors.textMutedOf(context),
            ),
          ),
        ),

        // University Results List
        Expanded(
          child: filtered.isEmpty
              ? _buildEmptyState(context, isDark)
              : ListView.separated(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 8,
                  ),
                  itemCount: filtered.length,
                  separatorBuilder: (_, _) => const SizedBox(height: 4),
                  itemBuilder: (context, index) {
                    final item = filtered[index];
                    final isSelected =
                        widget.initialSelectedUniversityId != null &&
                            widget.initialSelectedUniversityId == item.id;

                    return _buildUniversityTile(
                      context: context,
                      item: item,
                      isSelected: isSelected,
                      isDark: isDark,
                      primaryColor: primaryColor,
                    );
                  },
                ),
        ),
      ],
    );
  }

  Widget _buildStateChip({
    required String label,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    final primaryColor = AppColors.primaryOf(context);

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected
              ? primaryColor
              : AppColors.surfaceElevatedOf(context),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? primaryColor : AppColors.borderOf(context),
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
            color: isSelected
                ? Colors.white
                : AppColors.textSecondaryOf(context),
          ),
        ),
      ),
    );
  }

  Widget _buildUniversityTile({
    required BuildContext context,
    required University item,
    required bool isSelected,
    required bool isDark,
    required Color primaryColor,
  }) {
    return Material(
      color: isSelected
          ? primaryColor.withValues(alpha: isDark ? 0.2 : 0.1)
          : Colors.transparent,
      borderRadius: BorderRadius.circular(12),
      child: ListTile(
        dense: true,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        leading: Container(
          width: 40,
          height: 40,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: primaryColor.withValues(alpha: isDark ? 0.25 : 0.12),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Text(
            item.slug.isNotEmpty
                ? (item.slug.length > 4 ? item.slug.substring(0, 4) : item.slug)
                : 'UNI',
            style: TextStyle(
              fontWeight: FontWeight.w800,
              fontSize: 12,
              color: primaryColor,
            ),
          ),
        ),
        title: Text(
          item.name,
          style: TextStyle(
            fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
            fontSize: 14,
            color: isSelected ? primaryColor : AppColors.textPrimaryOf(context),
          ),
        ),
        subtitle: Padding(
          padding: const EdgeInsets.only(top: 4),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 6,
                  vertical: 1.5,
                ),
                decoration: BoxDecoration(
                  color: AppColors.surfaceElevatedOf(context),
                  borderRadius: BorderRadius.circular(4),
                  border: Border.all(color: AppColors.borderOf(context)),
                ),
                child: Text(
                  item.slug,
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textSecondaryOf(context),
                  ),
                ),
              ),
              if (item.state.isNotEmpty) ...[
                const SizedBox(width: 6),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 6,
                    vertical: 1.5,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.teal.withValues(alpha: isDark ? 0.25 : 0.12),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        Icons.location_on_outlined,
                        size: 11,
                        color: Colors.teal,
                      ),
                      const SizedBox(width: 2),
                      Text(
                        item.state,
                        style: const TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: Colors.teal,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
        ),
        trailing: isSelected
            ? Icon(
                Icons.check_circle_rounded,
                color: primaryColor,
                size: 20,
              )
            : null,
        onTap: () => Navigator.of(context).pop(item),
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context, bool isDark) {
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.school_outlined,
              size: 44,
              color: AppColors.textMutedOf(context),
            ),
            const SizedBox(height: 12),
            Text(
              'No matching universities found',
              style: TextStyle(
                fontWeight: FontWeight.w600,
                fontSize: 15,
                color: AppColors.textPrimaryOf(context),
              ),
            ),
            const SizedBox(height: 6),
            Text(
              _selectedState != null
                  ? 'No universities match the current search within '
                      '$_selectedState.'
                  : 'No registered university matched "$_searchQuery".',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 13,
                color: AppColors.textSecondaryOf(context),
              ),
            ),
            const SizedBox(height: 16),
            OutlinedButton.icon(
              onPressed: () {
                _searchController.clear();
                setState(() {
                  _searchQuery = '';
                  _selectedState = null;
                });
              },
              icon: const Icon(Icons.restart_alt_rounded, size: 18),
              label: const Text('Reset filters'),
            ),
          ],
        ),
      ),
    );
  }
}
