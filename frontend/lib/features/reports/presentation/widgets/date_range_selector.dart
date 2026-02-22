import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../../core/theme/app_colors.dart';

/// Preset date-range options.
enum DateRangePreset {
  thisWeek('This Week'),
  thisMonth('This Month'),
  thisQuarter('This Quarter'),
  thisYear('This Year'),
  custom('Custom');

  final String label;
  const DateRangePreset(this.label);
}

/// A compact date-range selector with preset chips and a custom range picker.
class DateRangeSelector extends StatefulWidget {
  final DateTimeRange initialRange;
  final ValueChanged<DateTimeRange> onChanged;

  const DateRangeSelector({
    super.key,
    required this.initialRange,
    required this.onChanged,
  });

  @override
  State<DateRangeSelector> createState() => _DateRangeSelectorState();
}

class _DateRangeSelectorState extends State<DateRangeSelector> {
  late DateTimeRange _selected;
  DateRangePreset _activePreset = DateRangePreset.thisMonth;

  @override
  void initState() {
    super.initState();
    _selected = widget.initialRange;
  }

  // ── Preset calculation ──────────────────────────────────────────────
  DateTimeRange _rangeForPreset(DateRangePreset preset) {
    final now = DateTime.now();
    switch (preset) {
      case DateRangePreset.thisWeek:
        final start = now.subtract(Duration(days: now.weekday - 1));
        return DateTimeRange(
          start: DateTime(start.year, start.month, start.day),
          end: DateTime(now.year, now.month, now.day, 23, 59, 59),
        );
      case DateRangePreset.thisMonth:
        return DateTimeRange(
          start: DateTime(now.year, now.month, 1),
          end: DateTime(now.year, now.month + 1, 0),
        );
      case DateRangePreset.thisQuarter:
        final qStart = ((now.month - 1) ~/ 3) * 3 + 1;
        return DateTimeRange(
          start: DateTime(now.year, qStart, 1),
          end: DateTime(now.year, qStart + 3, 0),
        );
      case DateRangePreset.thisYear:
        return DateTimeRange(
          start: DateTime(now.year, 1, 1),
          end: DateTime(now.year, 12, 31),
        );
      case DateRangePreset.custom:
        return _selected;
    }
  }

  void _selectPreset(DateRangePreset preset) {
    if (preset == DateRangePreset.custom) {
      _openCustomPicker();
      return;
    }
    final range = _rangeForPreset(preset);
    setState(() {
      _activePreset = preset;
      _selected = range;
    });
    widget.onChanged(range);
  }

  Future<void> _openCustomPicker() async {
    final picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2020),
      lastDate: DateTime.now().add(const Duration(days: 1)),
      initialDateRange: _selected,
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: Theme.of(context).colorScheme.copyWith(
              primary: AppColors.primary,
              onPrimary: Colors.white,
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null) {
      setState(() {
        _activePreset = DateRangePreset.custom;
        _selected = picked;
      });
      widget.onChanged(picked);
    }
  }

  @override
  Widget build(BuildContext context) {
    final fmt = DateFormat('MMM dd');
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // ── Preset Chips ────────────────────────────────────────────
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: DateRangePreset.values.map((preset) {
              final isActive = _activePreset == preset;
              return Padding(
                padding: const EdgeInsets.only(right: 8),
                child: ChoiceChip(
                  label: Text(preset.label),
                  selected: isActive,
                  selectedColor: AppColors.primary.withOpacity(0.15),
                  labelStyle: TextStyle(
                    color: isActive
                        ? AppColors.primary
                        : AppColors.textSecondary,
                    fontWeight: isActive ? FontWeight.w600 : FontWeight.w400,
                    fontSize: 13,
                  ),
                  onSelected: (_) => _selectPreset(preset),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                    side: BorderSide(
                      color: isActive ? AppColors.primary : AppColors.border,
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
        ),
        const SizedBox(height: 8),

        // ── Selected Range Indicator ────────────────────────────────
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: AppColors.primary.withOpacity(0.06),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.calendar_today_rounded,
                size: 16,
                color: AppColors.primary,
              ),
              const SizedBox(width: 8),
              Text(
                '${fmt.format(_selected.start)} – ${fmt.format(_selected.end)}',
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                  color: AppColors.primary,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
