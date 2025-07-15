import 'package:flutter/material.dart';

enum RingType {
  none,
  short,
  medium,
  long,
  custom
}

enum VibrateType {
  none,
  gentle,
  normal,
  strong
}

class NotificationSettings {
  final String id;
  final RingType ringType;
  final VibrateType vibrateType;
  final int minutesBeforeDose; // How many minutes before the dose to send the notification
  final bool repeatedAlerts; // Whether to repeat the alert if not acknowledged
  final int repeatIntervalMinutes; // Minutes between repeated alerts
  final int maxRepeats; // Maximum number of repeats
  final int snoozeMinutes; // How many minutes to snooze when requested
  final bool showDoseDetails; // Whether to show dose details in the notification
  final Color notificationColor; // Color for the notification (if supported)
  final String? customSound; // Path to custom sound file

  const NotificationSettings({
    required this.id,
    this.ringType = RingType.medium,
    this.vibrateType = VibrateType.normal,
    this.minutesBeforeDose = 15,
    this.repeatedAlerts = false,
    this.repeatIntervalMinutes = 5,
    this.maxRepeats = 3,
    this.snoozeMinutes = 10,
    this.showDoseDetails = true,
    this.notificationColor = Colors.blue,
    this.customSound,
  });

  // Create a copy with modified fields
  NotificationSettings copyWith({
    String? id,
    RingType? ringType,
    VibrateType? vibrateType,
    int? minutesBeforeDose,
    bool? repeatedAlerts,
    int? repeatIntervalMinutes,
    int? maxRepeats,
    int? snoozeMinutes,
    bool? showDoseDetails,
    Color? notificationColor,
    String? customSound,
  }) {
    return NotificationSettings(
      id: id ?? this.id,
      ringType: ringType ?? this.ringType,
      vibrateType: vibrateType ?? this.vibrateType,
      minutesBeforeDose: minutesBeforeDose ?? this.minutesBeforeDose,
      repeatedAlerts: repeatedAlerts ?? this.repeatedAlerts,
      repeatIntervalMinutes: repeatIntervalMinutes ?? this.repeatIntervalMinutes,
      maxRepeats: maxRepeats ?? this.maxRepeats,
      snoozeMinutes: snoozeMinutes ?? this.snoozeMinutes,
      showDoseDetails: showDoseDetails ?? this.showDoseDetails,
      notificationColor: notificationColor ?? this.notificationColor,
      customSound: customSound ?? this.customSound,
    );
  }

  // Convert to Map for storage
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'ringType': ringType.index,
      'vibrateType': vibrateType.index,
      'minutesBeforeDose': minutesBeforeDose,
      'repeatedAlerts': repeatedAlerts,
      'repeatIntervalMinutes': repeatIntervalMinutes,
      'maxRepeats': maxRepeats,
      'snoozeMinutes': snoozeMinutes,
      'showDoseDetails': showDoseDetails,
      'notificationColor': notificationColor.value,
      'customSound': customSound,
    };
  }

  // Create from Map
  factory NotificationSettings.fromMap(Map<String, dynamic> map) {
    return NotificationSettings(
      id: map['id'],
      ringType: RingType.values[map['ringType']],
      vibrateType: VibrateType.values[map['vibrateType']],
      minutesBeforeDose: map['minutesBeforeDose'],
      repeatedAlerts: map['repeatedAlerts'],
      repeatIntervalMinutes: map['repeatIntervalMinutes'],
      maxRepeats: map['maxRepeats'],
      snoozeMinutes: map['snoozeMinutes'],
      showDoseDetails: map['showDoseDetails'],
      notificationColor: Color(map['notificationColor']),
      customSound: map['customSound'],
    );
  }
} 