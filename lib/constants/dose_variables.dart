// Dose Variables Table Implementation
class DoseVariables {
  // Variable Names
  static const String DOSE_NAME = 'doseName';
  static const String DOSE_TYPE = 'doseType';
  static const String DOSE = 'dose';

  // Field Types
  static const String TYPE_TEXT = 'Text';
  static const String TYPE_DROPDOWN = 'Dropdown';

  // Measurement Types
  static const String MEASURE_TABLETS = 'Tablets';
  static const String MEASURE_CAPSULES = 'Capsules';
  static const String MEASURE_STRENGTH = 'Strength';
  static const String MEASURE_VOLUME = 'Volume';
  static const String MEASURE_IU = 'IU';
  static const String MEASURE_SYRINGES = 'Syringes';

  // Variable Definitions Map
  static final Map<String, Map<String, dynamic>> variables = {
    'allTypes': {
      'doseName': {
        'variable': DOSE_NAME,
        'type': TYPE_TEXT,
        'behavior': 'Enter text e.g., Morning Dose',
        'notes': 'Identifies the dose'
      },
      'doseType': {
        'variable': DOSE_TYPE,
        'type': TYPE_DROPDOWN,
        'behavior': 'Choose measurement e.g., Tablets, Strength, Volume',
        'notes': 'Determines dose input type'
      },
      'dose': {
        'variable': DOSE,
        'type': TYPE_TEXT,
        'behavior': 'Enter number e.g., 2, 20, 0.25',
        'notes': 'Dose value in chosen unit; calculates equivalents'
      }
    },
    'tablet': {
      'doseName': {
        'variable': DOSE_NAME,
        'type': TYPE_TEXT,
        'behavior': 'Enter text e.g., Morning Dose',
        'notes': 'Identifies the dose'
      },
      'doseType': {
        'variable': DOSE_TYPE,
        'type': TYPE_DROPDOWN,
        'behavior': 'Choose Tablets or Strength',
        'notes': 'Options: Tablets (volume), Strength (strength)'
      },
      'dose': {
        'variable': DOSE,
        'type': TYPE_TEXT,
        'behavior': 'Enter number e.g., 2 (Tablets) or 20 (mg)',
        'notes': 'Calculates e.g., 2 Tablets = 20 mg using strength'
      }
    },
    'capsule': {
      'doseName': {
        'variable': DOSE_NAME,
        'type': TYPE_TEXT,
        'behavior': 'Enter text e.g., Morning Dose',
        'notes': 'Identifies the dose'
      },
      'doseType': {
        'variable': DOSE_TYPE,
        'type': TYPE_DROPDOWN,
        'behavior': 'Choose Capsules or Strength',
        'notes': 'Options: Capsules (volume), Strength (strength)'
      },
      'dose': {
        'variable': DOSE,
        'type': TYPE_TEXT,
        'behavior': 'Enter number e.g., 1 (Capsules) or 250 (mg)',
        'notes': 'Calculates e.g., 1 Capsule = 250 mg using strength'
      }
    },
    'liquidVial': {
      'doseName': {
        'variable': DOSE_NAME,
        'type': TYPE_TEXT,
        'behavior': 'Enter text e.g., Morning Dose',
        'notes': 'Identifies the dose'
      },
      'doseType': {
        'variable': DOSE_TYPE,
        'type': TYPE_DROPDOWN,
        'behavior': 'Choose Volume, Strength, IU',
        'notes': 'Options: Volume (volume), Strength (strength), IU'
      },
      'dose': {
        'variable': DOSE,
        'type': TYPE_TEXT,
        'behavior': 'Enter number e.g., 0.25 (mL), 250 (mcg), 25 (IU)',
        'notes': 'Calculates e.g., 0.25 mL = 250 mcg using strength'
      }
    },
    'reconstitutableVial': {
      'doseName': {
        'variable': DOSE_NAME,
        'type': TYPE_TEXT,
        'behavior': 'Enter text e.g., Morning Dose',
        'notes': 'Identifies the dose'
      },
      'doseType': {
        'variable': DOSE_TYPE,
        'type': TYPE_DROPDOWN,
        'behavior': 'Choose Volume, Strength, IU',
        'notes': 'Options: Volume (volume), Strength (strength), IU; requires reconVolume'
      },
      'dose': {
        'variable': DOSE,
        'type': TYPE_TEXT,
        'behavior': 'Enter number e.g., 10 (mL), 50 (mg), 25 (IU)',
        'notes': 'Calculates e.g., 10 mL = 50 mg using strength, post-reconstitution'
      }
    },
    'preFilledSyringe': {
      'doseName': {
        'variable': DOSE_NAME,
        'type': TYPE_TEXT,
        'behavior': 'Enter text e.g., Morning Dose',
        'notes': 'Identifies the dose'
      },
      'doseType': {
        'variable': DOSE_TYPE,
        'type': TYPE_DROPDOWN,
        'behavior': 'Choose Syringes, Volume, Strength',
        'notes': 'Options: Syringes (volume), Volume (volume), Strength (strength)'
      },
      'dose': {
        'variable': DOSE,
        'type': TYPE_TEXT,
        'behavior': 'Enter number e.g., 1 (Syringe), 0.5 (mL), 50 (mg)',
        'notes': 'Calculates e.g., 1 Syringe = 0.5 mL = 50 mg using strength'
      }
    }
  };
} 