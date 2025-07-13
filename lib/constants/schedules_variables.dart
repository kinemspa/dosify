// Schedules Variables Table Implementation
class SchedulesVariables {
  // Variable Names
  static const String SCHED_NAME = 'schedName';
  static const String SCHED_TYPE = 'schedType';
  static const String SCHED_TIMES = 'schedTimes';
  static const String SCHED_DETAILS = 'schedDetails';

  // Field Types
  static const String TYPE_TEXT = 'Text';
  static const String TYPE_DROPDOWN = 'Dropdown';
  static const String TYPE_TIME_PICKER = 'Time Picker';
  static const String TYPE_VARIES = 'Varies';

  // Schedule Types
  static const String MULTIPLE_TIMES_PER_DAY = 'Multiple Times Per Day';
  static const String DAILY = 'Daily';
  static const String CERTAIN_DAYS = 'Certain Days';
  static const String DAYS_ON_OFF = 'Days On/Off';
  static const String CERTAIN_WEEKS = 'Certain Weeks';
  static const String WEEKS_ON_OFF = 'Weeks On/Off';
  static const String CERTAIN_MONTHS = 'Certain Months';

  // Variable Definitions Map
  static final Map<String, Map<String, dynamic>> variables = {
    'scheduleName': {
      'variable': SCHED_NAME,
      'type': TYPE_TEXT,
      'behavior': 'Enter text e.g., Morning Schedule',
      'notes': 'Identifies the schedule, linked to doseName'
    },
    'scheduleType': {
      'variable': SCHED_TYPE,
      'type': TYPE_DROPDOWN,
      'behavior': 'Choose from Multiple Times Per Day, Daily, Certain Days, Days On/Off, Certain Weeks, Weeks On/Off, Certain Months',
      'notes': 'Determines schedule structure'
    },
    'scheduleTimes': {
      'variable': SCHED_TIMES,
      'type': TYPE_TIME_PICKER,
      'behavior': 'Select times e.g., 08:00, 14:00, 20:00',
      'notes': 'Customizable times for dose administration'
    },
    'scheduleDetails': {
      'variable': SCHED_DETAILS,
      'type': TYPE_VARIES,
      'behavior': 'Configure based on schedType e.g., days, weeks, months',
      'notes': 'Additional settings for schedule type'
    }
  };
} 