import 'package:flutter/material.dart';
import 'notification_settings.dart';

enum ScheduleFrequency {
  once,
  daily,
  certainDays,
  daysOnOff,
  weekly,
  certainWeeks,
  weeksOnOff,
  monthly,
  certainMonths,
  custom
}

enum DoseStatus {
  pending,
  taken,
  missed,
  skipped,
  postponed
}

class Schedule {
  final String id;
  final String doseId;
  final String? medicationId; // Optional: only needed for medication schedules
  final String name;
  final ScheduleFrequency frequency;
  final DateTime startDate;
  final DateTime? endDate;
  final List<TimeOfDay> times; // Times of day for the dose
  final List<int> daysOfWeek; // For weekly schedules (1-7, where 1 is Monday)
  final List<int> daysOfMonth; // For monthly schedules (1-31)
  final int? daysOn; // For days on/off pattern
  final int? daysOff; // For days on/off pattern
  final int? weeksOn; // For weeks on/off pattern
  final int? weeksOff; // For weeks on/off pattern
  final Map<DateTime, DoseStatus> doseStatuses; // Track status of each dose
  final NotificationSettings notificationSettings;
  final String? notes;
  final bool isActive;
  final bool deductFromInventory; // Whether to deduct from medication inventory when taken

  Schedule({
    required this.id,
    required this.doseId,
    this.medicationId, // Optional for backward compatibility
    required this.name,
    required this.frequency,
    required this.startDate,
    this.endDate,
    required this.times,
    this.daysOfWeek = const [],
    this.daysOfMonth = const [],
    this.daysOn,
    this.daysOff,
    this.weeksOn,
    this.weeksOff,
    required this.doseStatuses,
    required this.notificationSettings,
    this.notes,
    this.isActive = true,
    this.deductFromInventory = true, // Default to true for medication schedules
  });

  // Create a copy with modified fields
  Schedule copyWith({
    String? id,
    String? doseId,
    String? medicationId,
    String? name,
    ScheduleFrequency? frequency,
    DateTime? startDate,
    DateTime? endDate,
    List<TimeOfDay>? times,
    List<int>? daysOfWeek,
    List<int>? daysOfMonth,
    int? daysOn,
    int? daysOff,
    int? weeksOn,
    int? weeksOff,
    Map<DateTime, DoseStatus>? doseStatuses,
    NotificationSettings? notificationSettings,
    String? notes,
    bool? isActive,
    bool? deductFromInventory,
  }) {
    return Schedule(
      id: id ?? this.id,
      doseId: doseId ?? this.doseId,
      medicationId: medicationId ?? this.medicationId,
      name: name ?? this.name,
      frequency: frequency ?? this.frequency,
      startDate: startDate ?? this.startDate,
      endDate: endDate ?? this.endDate,
      times: times ?? this.times,
      daysOfWeek: daysOfWeek ?? this.daysOfWeek,
      daysOfMonth: daysOfMonth ?? this.daysOfMonth,
      daysOn: daysOn ?? this.daysOn,
      daysOff: daysOff ?? this.daysOff,
      weeksOn: weeksOn ?? this.weeksOn,
      weeksOff: weeksOff ?? this.weeksOff,
      doseStatuses: doseStatuses ?? this.doseStatuses,
      notificationSettings: notificationSettings ?? this.notificationSettings,
      notes: notes ?? this.notes,
      isActive: isActive ?? this.isActive,
      deductFromInventory: deductFromInventory ?? this.deductFromInventory,
    );
  }

  // Mark a dose as taken
  Schedule markDoseStatus(DateTime dateTime, DoseStatus status) {
    final newStatuses = Map<DateTime, DoseStatus>.from(doseStatuses);
    newStatuses[dateTime] = status;
    return copyWith(doseStatuses: newStatuses);
  }

  // Check if a specific date has a scheduled dose
  bool hasDoseScheduled(DateTime date) {
    final dateOnly = DateTime(date.year, date.month, date.day);
    
    // Check if date is within schedule range
    if (startDate.isAfter(dateOnly) || 
        (endDate != null && endDate!.isBefore(dateOnly))) {
      return false;
    }

    switch (frequency) {
      case ScheduleFrequency.once:
        return dateOnly.isAtSameMomentAs(DateTime(
          startDate.year, startDate.month, startDate.day));
      
      case ScheduleFrequency.daily:
        return true;
      
      case ScheduleFrequency.certainDays:
        // Check if the day of week is in the list (1-7, where 1 is Monday)
        return daysOfWeek.contains(date.weekday);
      
      case ScheduleFrequency.daysOnOff:
        if (daysOn == null || daysOff == null) return false;
        
        // Calculate days since start
        final difference = dateOnly.difference(startDate).inDays;
        final cycleLength = daysOn! + daysOff!;
        final dayInCycle = difference % cycleLength;
        
        // Check if it's in the "on" period
        return dayInCycle < daysOn!;
      
      case ScheduleFrequency.weekly:
        // Check if it's the same day of week as start date
        return date.weekday == startDate.weekday;
      
      case ScheduleFrequency.certainWeeks:
        // Not implemented yet
        return false;
      
      case ScheduleFrequency.weeksOnOff:
        if (weeksOn == null || weeksOff == null) return false;
        
        // Calculate weeks since start
        final difference = dateOnly.difference(startDate).inDays ~/ 7;
        final cycleLength = weeksOn! + weeksOff!;
        final weekInCycle = difference % cycleLength;
        
        // Check if it's in the "on" period
        return weekInCycle < weeksOn!;
      
      case ScheduleFrequency.monthly:
        // Check if it's the same day of month as start date
        return date.day == startDate.day;
      
      case ScheduleFrequency.certainMonths:
        // Not implemented yet
        return false;
      
      case ScheduleFrequency.custom:
        // For custom schedules, check the doseStatuses map
        return doseStatuses.containsKey(dateOnly);
      
      default:
        return false;
    }
  }

  // Get all scheduled doses for a specific date
  List<DateTime> getDosesForDate(DateTime date) {
    if (!hasDoseScheduled(date)) {
      return [];
    }
    
    final List<DateTime> doses = [];
    final dateOnly = DateTime(date.year, date.month, date.day);
    
    // Add each scheduled time for this date
    for (var time in times) {
      final doseDateTime = DateTime(
        dateOnly.year,
        dateOnly.month,
        dateOnly.day,
        time.hour,
        time.minute,
      );
      doses.add(doseDateTime);
    }
    
    return doses;
  }

  // Get all upcoming doses within a date range
  List<DateTime> getUpcomingDoses({
    required DateTime from,
    required DateTime to,
  }) {
    final List<DateTime> upcomingDoses = [];
    
    // Iterate through each day in the range
    for (var date = from;
        date.isBefore(to.add(const Duration(days: 1)));
        date = date.add(const Duration(days: 1))) {
      
      upcomingDoses.addAll(getDosesForDate(date));
    }
    
    // Filter out doses that are in the past
    final now = DateTime.now();
    return upcomingDoses.where((dose) => dose.isAfter(now)).toList();
  }

  // Convert to Map for storage
  Map<String, dynamic> toMap() {
    // Convert TimeOfDay to minutes since midnight for storage
    final List<int> timesList = times.map((time) => 
        time.hour * 60 + time.minute).toList();
    
    // Convert DateTime keys to ISO strings for storage
    final Map<String, int> statusMap = {};
    doseStatuses.forEach((key, value) {
      statusMap[key.toIso8601String()] = value.index;
    });
    
    final map = {
      'id': id,
      'doseId': doseId,
      'name': name,
      'frequency': frequency.index,
      'startDate': startDate.toIso8601String(),
      'endDate': endDate?.toIso8601String(),
      'times': timesList,
      'daysOfWeek': daysOfWeek,
      'daysOfMonth': daysOfMonth,
      'daysOn': daysOn,
      'daysOff': daysOff,
      'weeksOn': weeksOn,
      'weeksOff': weeksOff,
      'doseStatuses': statusMap,
      'notificationSettings': notificationSettings.toMap(),
      'notes': notes,
      'isActive': isActive,
      'deductFromInventory': deductFromInventory,
    };
    
    // Only add medicationId if it exists
    if (medicationId != null) {
      map['medicationId'] = medicationId;
    }
    
    return map;
  }

  // Create from Map
  factory Schedule.fromMap(Map<String, dynamic> map) {
    // Convert minutes since midnight to TimeOfDay
    final List<TimeOfDay> timesList = (map['times'] as List<dynamic>).map((minutes) => 
        TimeOfDay(hour: minutes ~/ 60, minute: minutes % 60)).toList();
    
    // Convert ISO string keys to DateTime and int values to DoseStatus
    final Map<DateTime, DoseStatus> statusMap = {};
    final Map<String, dynamic> rawStatusMap = map['doseStatuses'] as Map<String, dynamic>;
    rawStatusMap.forEach((key, value) {
      statusMap[DateTime.parse(key)] = DoseStatus.values[value as int];
    });
    
    return Schedule(
      id: map['id'] as String,
      doseId: map['doseId'] as String,
      medicationId: map['medicationId'] as String?, // Optional
      name: map['name'] as String,
      frequency: ScheduleFrequency.values[map['frequency'] as int],
      startDate: DateTime.parse(map['startDate'] as String),
      endDate: map['endDate'] != null ? DateTime.parse(map['endDate'] as String) : null,
      times: timesList,
      daysOfWeek: List<int>.from(map['daysOfWeek'] ?? []),
      daysOfMonth: List<int>.from(map['daysOfMonth'] ?? []),
      daysOn: map['daysOn'] as int?,
      daysOff: map['daysOff'] as int?,
      weeksOn: map['weeksOn'] as int?,
      weeksOff: map['weeksOff'] as int?,
      doseStatuses: statusMap,
      notificationSettings: NotificationSettings.fromMap(
          map['notificationSettings'] as Map<String, dynamic>),
      notes: map['notes'] as String?,
      isActive: map['isActive'] as bool? ?? true,
      deductFromInventory: map['deductFromInventory'] as bool? ?? true,
    );
  }
  
  // Factory method to create from MedicationSchedule (for migration)
  factory Schedule.fromMedicationSchedule(dynamic medicationSchedule) {
    return Schedule(
      id: medicationSchedule.id,
      doseId: medicationSchedule.doseId,
      medicationId: medicationSchedule.medicationId,
      name: medicationSchedule.name,
      frequency: medicationSchedule.frequency,
      startDate: medicationSchedule.startDate,
      endDate: medicationSchedule.endDate,
      times: medicationSchedule.times,
      daysOfWeek: medicationSchedule.daysOfWeek,
      daysOfMonth: medicationSchedule.daysOfMonth,
      daysOn: medicationSchedule.daysOn,
      daysOff: medicationSchedule.daysOff,
      weeksOn: medicationSchedule.weeksOn,
      weeksOff: medicationSchedule.weeksOff,
      doseStatuses: medicationSchedule.doseStatuses,
      notificationSettings: medicationSchedule.notificationSettings,
      notes: medicationSchedule.notes,
      isActive: medicationSchedule.isActive,
      deductFromInventory: medicationSchedule.deductFromInventory,
    );
  }
} 