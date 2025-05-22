// lib/widgets/components/modern_selection_widgets.dart
import 'package:flutter/material.dart';
import '../../theme/app_theme.dart';

// Modern selection bottom sheet widget
class ModernSelectionBottomSheet extends StatefulWidget {
  final String title;
  final List<String> options;
  final String? selectedValue;
  final IconData icon;
  final Function(String) onSelected;

  const ModernSelectionBottomSheet({
    Key? key,
    required this.title,
    required this.options,
    this.selectedValue,
    required this.icon,
    required this.onSelected,
  }) : super(key: key);

  @override
  _ModernSelectionBottomSheetState createState() => _ModernSelectionBottomSheetState();
}

class _ModernSelectionBottomSheetState extends State<ModernSelectionBottomSheet> {
  String? _tempSelectedValue;

  @override
  void initState() {
    super.initState();
    _tempSelectedValue = widget.selectedValue;
  }

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return Container(
      decoration: BoxDecoration(
        color: isDarkMode ? AppColors.darkCard : Colors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Handle bar
          Container(
            margin: const EdgeInsets.only(top: 12),
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: isDarkMode ? AppColors.darkDivider : Colors.grey.shade300,
              borderRadius: BorderRadius.circular(2),
            ),
          ),

          // Header
          Container(
            padding: const EdgeInsets.all(24),
            child: Row(
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: AppColors.primary.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Icon(
                    widget.icon,
                    color: AppColors.primary,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.title,
                        style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          color: isDarkMode ? AppColors.darkTextPrimary : AppColors.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Choose one option',
                        style: TextStyle(
                          fontSize: 14,
                          color: isDarkMode ? AppColors.darkTextSecondary : AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: Icon(
                    Icons.close,
                    color: isDarkMode ? AppColors.darkTextSecondary : AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),

          // Options list
          Flexible(
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              shrinkWrap: true,
              itemCount: widget.options.length,
              itemBuilder: (context, index) {
                final option = widget.options[index];
                final isSelected = _tempSelectedValue == option;

                return Container(
                  margin: const EdgeInsets.only(bottom: 8),
                  child: Material(
                    color: Colors.transparent,
                    child: InkWell(
                      onTap: () {
                        setState(() {
                          _tempSelectedValue = option;
                        });

                        // Add a small delay for visual feedback
                        Future.delayed(const Duration(milliseconds: 150), () {
                          widget.onSelected(option);
                          Navigator.pop(context);
                        });
                      },
                      borderRadius: BorderRadius.circular(16),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                        decoration: BoxDecoration(
                          color: isSelected
                              ? AppColors.primary.withOpacity(0.1)
                              : (isDarkMode ? AppColors.darkElevated : Colors.grey.shade50),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: isSelected
                                ? AppColors.primary
                                : (isDarkMode ? AppColors.darkDivider : Colors.grey.shade200),
                            width: isSelected ? 2 : 1,
                          ),
                        ),
                        child: Row(
                          children: [
                            Expanded(
                              child: Text(
                                option,
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                                  color: isSelected
                                      ? AppColors.primary
                                      : (isDarkMode ? AppColors.darkTextPrimary : AppColors.textPrimary),
                                ),
                              ),
                            ),
                            if (isSelected)
                              Container(
                                width: 24,
                                height: 24,
                                decoration: BoxDecoration(
                                  color: AppColors.primary,
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(
                                  Icons.check,
                                  color: Colors.white,
                                  size: 16,
                                ),
                              ),
                          ],
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),

          // Bottom padding
          SizedBox(height: MediaQuery.of(context).padding.bottom + 16),
        ],
      ),
    );
  }
}

// Modern selection field that triggers the bottom sheet
class ModernSelectionField extends StatelessWidget {
  final String label;
  final String hint;
  final String? value;
  final IconData icon;
  final List<String> options;
  final Function(String) onChanged;
  final bool isDarkMode;

  const ModernSelectionField({
    Key? key,
    required this.label,
    required this.hint,
    this.value,
    required this.icon,
    required this.options,
    required this.onChanged,
    required this.isDarkMode,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: isDarkMode ? AppColors.darkTextPrimary : AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: 8),

        Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: () {
              showModalBottomSheet(
                context: context,
                isScrollControlled: true,
                backgroundColor: Colors.transparent,
                builder: (context) => DraggableScrollableSheet(
                  initialChildSize: 0.6,
                  maxChildSize: 0.9,
                  minChildSize: 0.4,
                  builder: (context, scrollController) => ModernSelectionBottomSheet(
                    title: label,
                    options: options,
                    selectedValue: value,
                    icon: icon,
                    onSelected: onChanged,
                  ),
                ),
              );
            },
            borderRadius: BorderRadius.circular(16),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              decoration: BoxDecoration(
                color: isDarkMode ? AppColors.darkCard : Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: isDarkMode ? AppColors.darkDivider : AppColors.divider,
                ),
              ),
              child: Row(
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: AppColors.primary.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      icon,
                      color: AppColors.primary,
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          value?.isNotEmpty == true ? value! : hint,
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: value?.isNotEmpty == true ? FontWeight.w600 : FontWeight.w400,
                            color: value?.isNotEmpty == true
                                ? (isDarkMode ? AppColors.darkTextPrimary : AppColors.textPrimary)
                                : (isDarkMode ? AppColors.darkTextTertiary : AppColors.textTertiary),
                          ),
                        ),
                        if (value?.isNotEmpty == true) ...[
                          const SizedBox(height: 2),
                          Text(
                            label,
                            style: TextStyle(
                              fontSize: 12,
                              color: isDarkMode ? AppColors.darkTextSecondary : AppColors.textSecondary,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                  Container(
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                      color: (isDarkMode ? AppColors.darkElevated : Colors.grey.shade100),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(
                      Icons.keyboard_arrow_down,
                      color: isDarkMode ? AppColors.darkTextSecondary : AppColors.textSecondary,
                      size: 20,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}

// Multi-selection widget for languages
class ModernMultiSelectionField extends StatelessWidget {
  final String label;
  final String hint;
  final List<String> selectedValues;
  final IconData icon;
  final List<String> options;
  final Function(List<String>) onChanged;
  final bool isDarkMode;
  final int? maxSelections;

  const ModernMultiSelectionField({
    Key? key,
    required this.label,
    required this.hint,
    required this.selectedValues,
    required this.icon,
    required this.options,
    required this.onChanged,
    required this.isDarkMode,
    this.maxSelections,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: isDarkMode ? AppColors.darkTextPrimary : AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: 8),

        Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: () {
              showModalBottomSheet(
                context: context,
                isScrollControlled: true,
                backgroundColor: Colors.transparent,
                builder: (context) => DraggableScrollableSheet(
                  initialChildSize: 0.7,
                  maxChildSize: 0.9,
                  minChildSize: 0.5,
                  builder: (context, scrollController) => ModernMultiSelectionBottomSheet(
                    title: label,
                    options: options,
                    selectedValues: selectedValues,
                    icon: icon,
                    onChanged: onChanged,
                    maxSelections: maxSelections,
                  ),
                ),
              );
            },
            borderRadius: BorderRadius.circular(16),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              decoration: BoxDecoration(
                color: isDarkMode ? AppColors.darkCard : Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: isDarkMode ? AppColors.darkDivider : AppColors.divider,
                ),
              ),
              child: Row(
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: AppColors.primary.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      icon,
                      color: AppColors.primary,
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          selectedValues.isNotEmpty
                              ? selectedValues.length == 1
                              ? selectedValues.first
                              : '${selectedValues.length} selected'
                              : hint,
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: selectedValues.isNotEmpty ? FontWeight.w600 : FontWeight.w400,
                            color: selectedValues.isNotEmpty
                                ? (isDarkMode ? AppColors.darkTextPrimary : AppColors.textPrimary)
                                : (isDarkMode ? AppColors.darkTextTertiary : AppColors.textTertiary),
                          ),
                        ),
                        if (selectedValues.isNotEmpty) ...[
                          const SizedBox(height: 2),
                          Text(
                            label,
                            style: TextStyle(
                              fontSize: 12,
                              color: isDarkMode ? AppColors.darkTextSecondary : AppColors.textSecondary,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                  Container(
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                      color: (isDarkMode ? AppColors.darkElevated : Colors.grey.shade100),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(
                      Icons.keyboard_arrow_down,
                      color: isDarkMode ? AppColors.darkTextSecondary : AppColors.textSecondary,
                      size: 20,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}

// Multi-selection bottom sheet
class ModernMultiSelectionBottomSheet extends StatefulWidget {
  final String title;
  final List<String> options;
  final List<String> selectedValues;
  final IconData icon;
  final Function(List<String>) onChanged;
  final int? maxSelections;

  const ModernMultiSelectionBottomSheet({
    Key? key,
    required this.title,
    required this.options,
    required this.selectedValues,
    required this.icon,
    required this.onChanged,
    this.maxSelections,
  }) : super(key: key);

  @override
  _ModernMultiSelectionBottomSheetState createState() => _ModernMultiSelectionBottomSheetState();
}

class _ModernMultiSelectionBottomSheetState extends State<ModernMultiSelectionBottomSheet> {
  late List<String> _tempSelectedValues;

  @override
  void initState() {
    super.initState();
    _tempSelectedValues = List.from(widget.selectedValues);
  }

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return Container(
      decoration: BoxDecoration(
        color: isDarkMode ? AppColors.darkCard : Colors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Handle bar
          Container(
            margin: const EdgeInsets.only(top: 12),
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: isDarkMode ? AppColors.darkDivider : Colors.grey.shade300,
              borderRadius: BorderRadius.circular(2),
            ),
          ),

          // Header
          Container(
            padding: const EdgeInsets.all(24),
            child: Row(
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: AppColors.primary.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Icon(
                    widget.icon,
                    color: AppColors.primary,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.title,
                        style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          color: isDarkMode ? AppColors.darkTextPrimary : AppColors.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        widget.maxSelections != null
                            ? 'Select up to ${widget.maxSelections} options'
                            : 'Select multiple options',
                        style: TextStyle(
                          fontSize: 14,
                          color: isDarkMode ? AppColors.darkTextSecondary : AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: Icon(
                    Icons.close,
                    color: isDarkMode ? AppColors.darkTextSecondary : AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),

          // Options list
          Flexible(
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              shrinkWrap: true,
              itemCount: widget.options.length,
              itemBuilder: (context, index) {
                final option = widget.options[index];
                final isSelected = _tempSelectedValues.contains(option);
                final canSelect = widget.maxSelections == null ||
                    _tempSelectedValues.length < widget.maxSelections! ||
                    isSelected;

                return Container(
                  margin: const EdgeInsets.only(bottom: 8),
                  child: Material(
                    color: Colors.transparent,
                    child: InkWell(
                      onTap: canSelect ? () {
                        setState(() {
                          if (isSelected) {
                            _tempSelectedValues.remove(option);
                          } else {
                            _tempSelectedValues.add(option);
                          }
                        });
                      } : null,
                      borderRadius: BorderRadius.circular(16),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                        decoration: BoxDecoration(
                          color: isSelected
                              ? AppColors.primary.withOpacity(0.1)
                              : (isDarkMode ? AppColors.darkElevated : Colors.grey.shade50),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: isSelected
                                ? AppColors.primary
                                : (isDarkMode ? AppColors.darkDivider : Colors.grey.shade200),
                            width: isSelected ? 2 : 1,
                          ),
                        ),
                        child: Row(
                          children: [
                            Expanded(
                              child: Text(
                                option,
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                                  color: !canSelect
                                      ? (isDarkMode ? AppColors.darkTextTertiary : Colors.grey.shade400)
                                      : isSelected
                                      ? AppColors.primary
                                      : (isDarkMode ? AppColors.darkTextPrimary : AppColors.textPrimary),
                                ),
                              ),
                            ),
                            Container(
                              width: 24,
                              height: 24,
                              decoration: BoxDecoration(
                                color: isSelected ? AppColors.primary : Colors.transparent,
                                shape: BoxShape.circle,
                                border: !isSelected ? Border.all(
                                  color: isDarkMode ? AppColors.darkDivider : Colors.grey.shade300,
                                  width: 2,
                                ) : null,
                              ),
                              child: isSelected ? const Icon(
                                Icons.check,
                                color: Colors.white,
                                size: 16,
                              ) : null,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),

          // Done button
          Container(
            padding: const EdgeInsets.all(24),
            child: SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  widget.onChanged(_tempSelectedValues);
                  Navigator.pop(context);
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  elevation: 0,
                ),
                child: Text(
                  'Done (${_tempSelectedValues.length} selected)',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ),

          // Bottom padding
          SizedBox(height: MediaQuery.of(context).padding.bottom),
        ],
      ),
    );
  }
}