enum ScheduleFrequency {
  once,
  daily,
  weekly,
  monthly,
  custom
}

class Schedule {
  final String id;
  final String doseId;
  final ScheduleFrequency frequency;
  final DateTime startDate;
  final DateTime? endDate;
  final List<DateTime> scheduledTimes;
  final Map<DateTime, bool> completedDoses; // DateTime to completion status
  
  Schedule({
    required this.id,
    required this.doseId,
    required this.frequency,
    required this.startDate,
    this.endDate,
    required this.scheduledTimes,
    required this.completedDoses,
  });

  // Mark a dose as taken and return the new inventory reduction
  bool markDoseTaken(DateTime time, double inventoryReduction) {
    if (scheduledTimes.contains(time) && !completedDoses[time]!) {
      completedDoses[time] = true;
      return true;
    }
    return false;
  }

  // Check if a specific time has a scheduled dose
  bool hasDoseScheduled(DateTime time) {
    return scheduledTimes.contains(time);
  }

  // Get all upcoming doses
  List<DateTime> getUpcomingDoses() {
    final now = DateTime.now();
    return scheduledTimes
        .where((time) => time.isAfter(now) && !completedDoses[time]!)
        .toList();
  }
} 