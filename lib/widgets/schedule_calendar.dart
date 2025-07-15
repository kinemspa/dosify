import 'package:flutter/material.dart';
import '../models/schedule.dart';
import '../theme/app_colors.dart';

class ScheduleCalendar extends StatefulWidget {
  final List<Schedule> schedules;
  final DateTime initialDate;
  final Function(DateTime)? onDaySelected;

  const ScheduleCalendar({
    super.key,
    required this.schedules,
    this.initialDate = const DateTime(0),
    this.onDaySelected,
  });

  @override
  State<ScheduleCalendar> createState() => _ScheduleCalendarState();
}

class _ScheduleCalendarState extends State<ScheduleCalendar> {
  late DateTime _selectedMonth;
  late DateTime _selectedDay;

  @override
  void initState() {
    super.initState();
    _selectedMonth = widget.initialDate != const DateTime(0) 
        ? DateTime(widget.initialDate.year, widget.initialDate.month, 1)
        : DateTime(DateTime.now().year, DateTime.now().month, 1);
    _selectedDay = widget.initialDate != const DateTime(0)
        ? widget.initialDate
        : DateTime.now();
  }

  void _previousMonth() {
    setState(() {
      _selectedMonth = DateTime(
        _selectedMonth.year,
        _selectedMonth.month - 1,
        1,
      );
    });
  }

  void _nextMonth() {
    setState(() {
      _selectedMonth = DateTime(
        _selectedMonth.year,
        _selectedMonth.month + 1,
        1,
      );
    });
  }

  void _selectDay(DateTime day) {
    setState(() {
      _selectedDay = day;
    });
    if (widget.onDaySelected != null) {
      widget.onDaySelected!(day);
    }
  }

  // Get the first day of the week (Monday in most countries)
  int _getFirstDayOfWeekOffset() {
    // 0 = Monday, 6 = Sunday in DateTime.weekday
    final firstDayOfMonth = DateTime(_selectedMonth.year, _selectedMonth.month, 1);
    // Convert to 0-indexed where 0 is Monday
    return (firstDayOfMonth.weekday - 1) % 7;
  }

  // Get the number of days in the selected month
  int _getDaysInMonth() {
    return DateTime(
      _selectedMonth.year,
      _selectedMonth.month + 1,
      0,
    ).day;
  }

  // Check if a day has any scheduled doses
  bool _hasDoseScheduled(DateTime date) {
    for (var schedule in widget.schedules) {
      if (schedule.hasDoseScheduled(date)) {
        return true;
      }
    }
    return false;
  }

  // Get the status of a scheduled dose for a specific day
  DoseStatus? _getDoseStatus(DateTime date) {
    for (var schedule in widget.schedules) {
      if (schedule.hasDoseScheduled(date)) {
        // Check if there's a status for this date
        final dateOnly = DateTime(date.year, date.month, date.day);
        for (var entry in schedule.doseStatuses.entries) {
          final entryDateOnly = DateTime(
            entry.key.year,
            entry.key.month,
            entry.key.day,
          );
          if (entryDateOnly == dateOnly) {
            return entry.value;
          }
        }
        // If no status found, it's pending
        return DoseStatus.pending;
      }
    }
    return null;
  }

  // Get color for a day based on dose status
  Color _getDayColor(DateTime date, bool isDarkMode) {
    final status = _getDoseStatus(date);
    if (status == null) {
      return Colors.transparent;
    }
    
    switch (status) {
      case DoseStatus.taken:
        return Colors.green.withOpacity(0.7);
      case DoseStatus.missed:
        return Colors.red.withOpacity(0.7);
      case DoseStatus.skipped:
        return Colors.orange.withOpacity(0.7);
      case DoseStatus.postponed:
        return Colors.blue.withOpacity(0.7);
      case DoseStatus.pending:
        return isDarkMode ? Colors.white30 : Colors.black12;
      default:
        return Colors.transparent;
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final textColor = isDarkMode ? AppColors.darkTextPrimary : AppColors.lightTextPrimary;
    final backgroundColor = isDarkMode ? AppColors.darkCardBackground : AppColors.lightCardBackground;
    
    // Get calendar data
    final daysInMonth = _getDaysInMonth();
    final firstDayOffset = _getFirstDayOfWeekOffset();
    
    return Container(
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Month navigation
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 12.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                IconButton(
                  icon: const Icon(Icons.chevron_left),
                  onPressed: _previousMonth,
                ),
                Text(
                  '${_getMonthName(_selectedMonth.month)} ${_selectedMonth.year}',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                    color: textColor,
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.chevron_right),
                  onPressed: _nextMonth,
                ),
              ],
            ),
          ),
          
          // Weekday headers
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: _getWeekdayLabels().map((day) => 
                Expanded(
                  child: Text(
                    day,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: textColor.withOpacity(0.7),
                    ),
                  ),
                )
              ).toList(),
            ),
          ),
          
          const SizedBox(height: 8),
          
          // Calendar grid
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 7,
              childAspectRatio: 1,
            ),
            itemCount: firstDayOffset + daysInMonth,
            itemBuilder: (context, index) {
              // Empty cells for days before the 1st
              if (index < firstDayOffset) {
                return const SizedBox.shrink();
              }
              
              // Day cells
              final day = index - firstDayOffset + 1;
              final date = DateTime(_selectedMonth.year, _selectedMonth.month, day);
              final isToday = _isToday(date);
              final isSelected = _isSameDay(date, _selectedDay);
              final hasDose = _hasDoseScheduled(date);
              final dayColor = _getDayColor(date, isDarkMode);
              
              return GestureDetector(
                onTap: () => _selectDay(date),
                child: Container(
                  margin: const EdgeInsets.all(2),
                  decoration: BoxDecoration(
                    color: dayColor,
                    border: isSelected 
                        ? Border.all(
                            color: Theme.of(context).colorScheme.primary,
                            width: 2,
                          )
                        : null,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Stack(
                    children: [
                      // Day number
                      Center(
                        child: Text(
                          day.toString(),
                          style: TextStyle(
                            fontWeight: isToday ? FontWeight.bold : FontWeight.normal,
                            color: isToday 
                                ? Theme.of(context).colorScheme.primary
                                : textColor,
                          ),
                        ),
                      ),
                      
                      // Indicator for scheduled doses
                      if (hasDose)
                        Positioned(
                          top: 2,
                          right: 2,
                          child: Container(
                            width: 8,
                            height: 8,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: _getDoseIndicatorColor(date, isDarkMode),
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              );
            },
          ),
          
          const SizedBox(height: 8),
          
          // Legend
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _buildLegendItem('Pending', Colors.grey, isDarkMode),
                _buildLegendItem('Taken', Colors.green, isDarkMode),
                _buildLegendItem('Missed', Colors.red, isDarkMode),
                _buildLegendItem('Skipped', Colors.orange, isDarkMode),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLegendItem(String label, Color color, bool isDarkMode) {
    return Row(
      children: [
        Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(
            color: color.withOpacity(0.7),
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(width: 4),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: isDarkMode ? Colors.white70 : Colors.black87,
          ),
        ),
      ],
    );
  }

  Color _getDoseIndicatorColor(DateTime date, bool isDarkMode) {
    final status = _getDoseStatus(date);
    switch (status) {
      case DoseStatus.taken:
        return Colors.green;
      case DoseStatus.missed:
        return Colors.red;
      case DoseStatus.skipped:
        return Colors.orange;
      case DoseStatus.postponed:
        return Colors.blue;
      case DoseStatus.pending:
      default:
        return isDarkMode ? Colors.white : Colors.black;
    }
  }

  bool _isToday(DateTime date) {
    final now = DateTime.now();
    return date.year == now.year && date.month == now.month && date.day == now.day;
  }

  bool _isSameDay(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }

  String _getMonthName(int month) {
    const months = [
      'January', 'February', 'March', 'April', 'May', 'June',
      'July', 'August', 'September', 'October', 'November', 'December'
    ];
    return months[month - 1];
  }

  List<String> _getWeekdayLabels() {
    return ['M', 'T', 'W', 'T', 'F', 'S', 'S'];
  }
} 