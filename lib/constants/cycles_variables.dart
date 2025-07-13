// Cycles Variables Table Implementation
class CyclesVariables {
  // Variable Names
  static const String CYCLE_NAME = 'cycleName';
  static const String CYCLE_TYPE = 'cycleType';
  static const String CYCLE_END = 'cycleEnd';
  static const String CYCLE_PATTERN = 'cyclePattern';
  static const String CYCLE_REPEAT = 'cycleRepeat';

  // Field Types
  static const String TYPE_TEXT = 'Text';
  static const String TYPE_DROPDOWN = 'Dropdown';
  static const String TYPE_DATE_PICKER = 'Date Picker';
  static const String TYPE_VARIES = 'Varies';
  static const String TYPE_CHECKBOX = 'Checkbox';

  // Cycle Types
  static const String NEVER_ENDING = 'Never Ending';
  static const String END_ON_DATE = 'End on Date';
  static const String DAYS_ON_OFF = 'Days On/Off';
  static const String WEEKS_ON_OFF = 'Weeks On/Off';
  static const String MONTHS_ON_OFF = 'Months On/Off';

  // Variable Definitions Map
  static final Map<String, Map<String, dynamic>> variables = {
    'cycleName': {
      'variable': CYCLE_NAME,
      'type': TYPE_TEXT,
      'behavior': 'Enter text e.g., Treatment Cycle 1',
      'notes': 'Identifies the cycle, linked to doseName'
    },
    'cycleType': {
      'variable': CYCLE_TYPE,
      'type': TYPE_DROPDOWN,
      'behavior': 'Choose from Never Ending, End on Date, Days On/Off, Weeks On/Off, Months On/Off',
      'notes': 'Determines cycle duration and structure'
    },
    'cycleEnd': {
      'variable': CYCLE_END,
      'type': TYPE_DATE_PICKER,
      'behavior': 'Select date e.g., 2025-12-31',
      'notes': 'Only for End on Specific Date'
    },
    'cyclePattern': {
      'variable': CYCLE_PATTERN,
      'type': TYPE_VARIES,
      'behavior': 'Define dose-switching or breaks e.g., Dose 1: 2 weeks, Dose 2: 2 weeks, Break: 1 week',
      'notes': 'Configures dose sequence and breaks'
    },
    'cycleRepeat': {
      'variable': CYCLE_REPEAT,
      'type': TYPE_CHECKBOX,
      'behavior': 'Enable/disable repetition',
      'notes': 'True for on/off patterns or dose-switching'
    }
  };
} 