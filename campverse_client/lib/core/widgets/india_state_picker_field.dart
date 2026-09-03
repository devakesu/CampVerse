import 'package:campverse/core/constants/india_states.dart';
import 'package:campverse/core/theme/app_colors.dart';
import 'package:flutter/material.dart';

/// A searchable form field for selecting an Indian State or Union Territory.
///
/// Tapping the field opens an adaptive searchable picker modal (dialog on
/// desktop/tablet, bottom sheet on mobile) containing all 28 States and
/// 8 Union Territories with instant search, category filters, and state codes.
class IndiaStatePickerFormField extends FormField<String> {
  /// Default constructor for [IndiaStatePickerFormField].
  IndiaStatePickerFormField({
    super.key,
    this.controller,
    String? initialValue,
    String labelText = 'State / Province *',
    String hintText = 'Select State or UT',
    super.validator,
    super.onSaved,
    ValueChanged<String>? onChanged,
    bool enabled = true,
    super.autovalidateMode = AutovalidateMode.onUserInteraction,
  }) : super(
          initialValue: controller != null ? controller.text : initialValue,
          builder: (state) {
            return _IndiaStatePickerFieldContent(
              state: state,
              controller: controller,
              labelText: labelText,
              hintText: hintText,
              enabled: enabled,
              onChanged: onChanged,
            );
          },
        );

  /// Optional text controller to synchronize with other form inputs.
  final TextEditingController? controller;
}

class _IndiaStatePickerFieldContent extends StatefulWidget {
  const _IndiaStatePickerFieldContent({
    required this.state,
    required this.labelText,
    required this.hintText,
    required this.enabled,
    this.controller,
    this.onChanged,
  });

  final FormFieldState<String> state;
  final TextEditingController? controller;
  final String labelText;
  final String hintText;
  final bool enabled;
  final ValueChanged<String>? onChanged;

  @override
  State<_IndiaStatePickerFieldContent> createState() =>
      _IndiaStatePickerFieldContentState();
}

class _IndiaStatePickerFieldContentState
    extends State<_IndiaStatePickerFieldContent> {
  @override
  void initState() {
    super.initState();
    widget.controller?.addListener(_handleControllerChanged);
  }

  @override
  void dispose() {
    widget.controller?.removeListener(_handleControllerChanged);
    super.dispose();
  }

  void _handleControllerChanged() {
    if (widget.controller != null &&
        widget.controller!.text != widget.state.value) {
      widget.state.didChange(widget.controller!.text);
    }
  }

  Future<void> _openPicker() async {
    if (!widget.enabled) {
      return;
    }

    final selected = await IndiaStatePickerModal.show(
      context,
      initialSelectedState: widget.state.value,
    );

    if (selected != null) {
      widget.controller?.text = selected;
      widget.state.didChange(selected);
      widget.onChanged?.call(selected);
    }
  }

  void _clearValue() {
    widget.controller?.clear();
    widget.state.didChange('');
    widget.onChanged?.call('');
  }

  @override
  Widget build(BuildContext context) {
    final hasValue = widget.state.value != null &&
        widget.state.value!.trim().isNotEmpty;
    final displayValue = widget.state.value ?? '';

    // Find state model if match exists for code badge
    IndianStateOrUT? matchedModel;
    for (final item in kIndiaStatesAndUTs) {
      if (item.name.toLowerCase() == displayValue.toLowerCase()) {
        matchedModel = item;
        break;
      }
    }

    return InkWell(
      onTap: widget.enabled ? _openPicker : null,
      borderRadius: BorderRadius.circular(12),
      child: InputDecorator(
        decoration: InputDecoration(
          labelText: widget.labelText,
          hintText: widget.hintText,
          prefixIcon: const Icon(Icons.map_outlined),
          errorText: widget.state.errorText,
          suffixIcon: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (hasValue && widget.enabled)
                IconButton(
                  icon: const Icon(Icons.clear_rounded, size: 18),
                  tooltip: 'Clear selection',
                  onPressed: _clearValue,
                ),
              const Padding(
                padding: EdgeInsets.only(right: 12),
                child: Icon(Icons.arrow_drop_down_rounded, size: 24),
              ),
            ],
          ),
        ),
        isEmpty: !hasValue,
        child: hasValue
            ? Row(
                children: [
                  Expanded(
                    child: Text(
                      displayValue,
                      style: TextStyle(
                        fontSize: 15,
                        color: AppColors.textPrimaryOf(context),
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  if (matchedModel != null) ...[
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 6,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: matchedModel.isUnionTerritory
                            ? Colors.teal.withValues(alpha: 0.15)
                            : AppColors.primaryOf(context)
                                .withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        matchedModel.code,
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: matchedModel.isUnionTerritory
                              ? Colors.teal
                              : AppColors.primaryOf(context),
                        ),
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

/// Adaptive modal for searching and selecting Indian States and UTs.
class IndiaStatePickerModal extends StatefulWidget {
  /// Default constructor for [IndiaStatePickerModal].
  const IndiaStatePickerModal({
    this.initialSelectedState,
    super.key,
  });

  /// The currently selected state name, if any.
  final String? initialSelectedState;

  /// Shows the picker adaptively (dialog on wide screens, bottom sheet on
  /// mobile).
  static Future<String?> show(
    BuildContext context, {
    String? initialSelectedState,
  }) {
    final isWide = MediaQuery.of(context).size.width > 600;

    if (isWide) {
      return showDialog<String>(
        context: context,
        builder: (context) => Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          clipBehavior: Clip.antiAlias,
          child: ConstrainedBox(
            constraints: const BoxConstraints(
              maxWidth: 500,
              maxHeight: 640,
            ),
            child: IndiaStatePickerModal(
              initialSelectedState: initialSelectedState,
            ),
          ),
        ),
      );
    }

    return showModalBottomSheet<String>(
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
              child: IndiaStatePickerModal(
                initialSelectedState: initialSelectedState,
              ),
            ),
          );
        },
      ),
    );
  }

  @override
  State<IndiaStatePickerModal> createState() => _IndiaStatePickerModalState();
}

class _IndiaStatePickerModalState extends State<IndiaStatePickerModal> {
  final _searchController = TextEditingController();
  IndiaStateCategory _selectedCategory = IndiaStateCategory.all;
  String _searchQuery = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final filtered = filterIndiaStates(
      query: _searchQuery,
      category: _selectedCategory,
    );

    final isDark = AppColors.isDark(context);

    // Counts for tabs
    final allCount = filterIndiaStates(
      query: _searchQuery,
    ).length;
    final statesCount = filterIndiaStates(
      query: _searchQuery,
      category: IndiaStateCategory.states,
    ).length;
    final utCount = filterIndiaStates(
      query: _searchQuery,
      category: IndiaStateCategory.unionTerritories,
    ).length;

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Top Header
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
                  Icons.travel_explore_rounded,
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
                      'Select State / UT',
                      style: TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textPrimaryOf(context),
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'India • 28 States & 8 Union Territories',
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
          padding: const EdgeInsets.fromLTRB(16, 14, 16, 10),
          child: TextField(
            controller: _searchController,
            autofocus: true,
            style: TextStyle(color: AppColors.textPrimaryOf(context)),
            decoration: InputDecoration(
              hintText: 'Search state, UT, or code (e.g. Kerala, KL)...',
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
                Navigator.of(context).pop(filtered.first.name);
              }
            },
          ),
        ),

        // Filter Category Chips
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          child: Row(
            children: [
              _buildCategoryChip(
                label: 'All ($allCount)',
                category: IndiaStateCategory.all,
              ),
              const SizedBox(width: 8),
              _buildCategoryChip(
                label: 'States ($statesCount)',
                category: IndiaStateCategory.states,
              ),
              const SizedBox(width: 8),
              _buildCategoryChip(
                label: 'UTs ($utCount)',
                category: IndiaStateCategory.unionTerritories,
              ),
            ],
          ),
        ),

        const SizedBox(height: 8),

        // Search Results List
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
                    final isSelected = widget.initialSelectedState != null &&
                        widget.initialSelectedState!.toLowerCase() ==
                            item.name.toLowerCase();

                    return _buildStateTile(
                      context: context,
                      item: item,
                      isSelected: isSelected,
                      isDark: isDark,
                    );
                  },
                ),
        ),
      ],
    );
  }

  Widget _buildCategoryChip({
    required String label,
    required IndiaStateCategory category,
  }) {
    final isSelected = _selectedCategory == category;
    final primaryColor = AppColors.primaryOf(context);

    return InkWell(
      onTap: () => setState(() => _selectedCategory = category),
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
            color: isSelected
                ? primaryColor
                : AppColors.borderOf(context),
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

  Widget _buildStateTile({
    required BuildContext context,
    required IndianStateOrUT item,
    required bool isSelected,
    required bool isDark,
  }) {
    final primaryColor = AppColors.primaryOf(context);

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
          width: 38,
          height: 38,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: item.isUnionTerritory
                ? Colors.teal.withValues(alpha: isDark ? 0.25 : 0.12)
                : primaryColor.withValues(alpha: isDark ? 0.25 : 0.12),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Text(
            item.code,
            style: TextStyle(
              fontWeight: FontWeight.w800,
              fontSize: 13,
              color: item.isUnionTerritory ? Colors.teal : primaryColor,
            ),
          ),
        ),
        title: Text(
          item.name,
          style: TextStyle(
            fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
            fontSize: 14,
            color: isSelected
                ? primaryColor
                : AppColors.textPrimaryOf(context),
          ),
        ),
        subtitle: Text(
          item.categoryLabel,
          style: TextStyle(
            fontSize: 12,
            color: AppColors.textSecondaryOf(context),
          ),
        ),
        trailing: isSelected
            ? Icon(
                Icons.check_circle_rounded,
                color: primaryColor,
                size: 20,
              )
            : null,
        onTap: () => Navigator.of(context).pop(item.name),
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
              Icons.search_off_rounded,
              size: 44,
              color: AppColors.textMutedOf(context),
            ),
            const SizedBox(height: 12),
            Text(
              'No matching State or UT found',
              style: TextStyle(
                fontWeight: FontWeight.w600,
                fontSize: 15,
                color: AppColors.textPrimaryOf(context),
              ),
            ),
            const SizedBox(height: 6),
            Text(
              'No Indian administrative division matched "$_searchQuery"',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 13,
                color: AppColors.textSecondaryOf(context),
              ),
            ),
            if (_searchQuery.trim().isNotEmpty) ...[
              const SizedBox(height: 16),
              OutlinedButton.icon(
                onPressed: () =>
                    Navigator.of(context).pop(_searchQuery.trim()),
                icon: const Icon(Icons.add_location_alt_outlined, size: 18),
                label: Text('Use "${_searchQuery.trim()}" as custom state'),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
