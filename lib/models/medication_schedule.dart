import 'package:flutter/material.dart';
import 'dose.dart';
import 'notification_settings.dart';
import 'schedule.dart';

// Re-export the enums from schedule.dart for backward compatibility
export 'schedule.dart' show ScheduleFrequency, DoseStatus;

// MedicationSchedule is now just a specialized version of Schedule
// This class exists for backward compatibility
class MedicationSchedule extends Schedule {
  MedicationSchedule({
    required String id,
    required String medicationId,
    required String doseId,
    required String name,
    required ScheduleFrequency frequency,
    required DateTime startDate,
    DateTime? endDate,
    required List<TimeOfDay> times,
    List<int> daysOfWeek = const [],
    List<int> daysOfMonth = const [],
    int? daysOn,
    int? daysOff,
    int? weeksOn,
    int? weeksOff,
    required Map<DateTime, DoseStatus> doseStatuses,
    required NotificationSettings notificationSettings,
    String? notes,
    bool isActive = true,
    bool deductFromInventory = true,
  }) : super(
          id: id,
          doseId: doseId,
          medicationId: medicationId,
          name: name,
          frequency: frequency,
          startDate: startDate,
          endDate: endDate,
          times: times,
          daysOfWeek: daysOfWeek,
          daysOfMonth: daysOfMonth,
          daysOn: daysOn,
          daysOff: daysOff,
          weeksOn: weeksOn,
          weeksOff: weeksOff,
          doseStatuses: doseStatuses,
          notificationSettings: notificationSettings,
          notes: notes,
          isActive: isActive,
          deductFromInventory: deductFromInventory,
        );

  // Override copyWith to return MedicationSchedule for backward compatibility
  @override
  MedicationSchedule copyWith({
    String? id,
    String? medicationId,
    String? doseId,
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
    return MedicationSchedule(
      id: id ?? this.id,
      medicationId: medicationId ?? this.medicationId!,
      doseId: doseId ?? this.doseId,
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

  // Override markDoseStatus to return MedicationSchedule
  @override
  MedicationSchedule markDoseStatus(DateTime dateTime, DoseStatus status) {
    final newStatuses = Map<DateTime, DoseStatus>.from(doseStatuses);
    newStatuses[dateTime] = status;
    return copyWith(doseStatuses: newStatuses);
  }

  // Factory method to create from Map
  factory MedicationSchedule.fromMap(Map<String, dynamic> map) {
    // Use the Schedule.fromMap and convert to MedicationSchedule
    final schedule = Schedule.fromMap(map);
    
    return MedicationSchedule(
      id: schedule.id,
      medicationId: schedule.medicationId ?? '',  // Required for MedicationSchedule
      doseId: schedule.doseId,
      name: schedule.name,
      frequency: schedule.frequency,
      startDate: schedule.startDate,
      endDate: schedule.endDate,
      times: schedule.times,
      daysOfWeek: schedule.daysOfWeek,
      daysOfMonth: schedule.daysOfMonth,
      daysOn: schedule.daysOn,
      daysOff: schedule.daysOff,
      weeksOn: schedule.weeksOn,
      weeksOff: schedule.weeksOff,
      doseStatuses: schedule.doseStatuses,
      notificationSettings: schedule.notificationSettings,
      notes: schedule.notes,
      isActive: schedule.isActive,
      deductFromInventory: schedule.deductFromInventory,
    );
  }
} 