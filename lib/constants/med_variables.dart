// Med Variables Table Implementation
class MedVariables {
  // Medication Type Constants
  static const String TABLET = 'Tablet';
  static const String CAPSULE = 'Capsule';
  static const String LIQUID_VIAL = 'Liquid Vial';
  static const String RECONSTITUTABLE_VIAL = 'Reconstitutable Vial';
  static const String PREFILLED_SYRINGE = 'Pre-filled Syringe';

  // Variable Names
  static const String MED_TYPE = 'medType';
  static const String STR_VAL = 'strVal';
  static const String STR_UNIT = 'strUnit';
  static const String STRENGTH = 'strength';
  static const String VOL_VAL = 'volVal';
  static const String VOL_UNIT = 'volUnit';
  static const String VOLUME = 'volume';
  static const String RECON_VOLUME = 'reconVolume';

  // Default Units
  static const String DEFAULT_TABLET_UNIT = 'mg';
  static const String DEFAULT_CAPSULE_UNIT = 'mg';
  static const String DEFAULT_LIQUID_UNIT = 'mg/mL';
  static const String DEFAULT_RECON_UNIT = 'mg/mL';
  static const String DEFAULT_PREFILLED_UNIT = 'mg/mL';
  static const String DEFAULT_VOLUME_UNIT = 'mL';

  // Field Types
  static const String TYPE_DROPDOWN = 'Dropdown';
  static const String TYPE_TEXT = 'Text';
  static const String TYPE_FIXED = 'Fixed';
  static const String TYPE_TEXT_DROPDOWN = 'Text+Dropdown';

  // Variable Definitions Map
  static final Map<String, Map<String, dynamic>> variables = {
    'allTypes': {
      'medicationType': {
        'variable': MED_TYPE,
        'type': TYPE_DROPDOWN,
        'behavior': 'Select from Tablet, Capsule, Liquid Vial, Reconstitutable Vial, Pre-filled Syringe',
        'notes': 'Sets strForm, strength, volume'
      }
    },
    TABLET: {
      'strengthValue': {
        'variable': STR_VAL,
        'type': TYPE_TEXT,
        'behavior': 'Enter number e.g., 500',
        'notes': 'Strength per tablet'
      },
      'strengthUnit': {
        'variable': STR_UNIT,
        'type': TYPE_DROPDOWN,
        'behavior': 'Choose from units e.g., mg',
        'notes': 'Default: mg'
      },
      'strength': {
        'variable': STRENGTH,
        'type': TYPE_TEXT_DROPDOWN,
        'behavior': 'Combines strVal and strUnit e.g., 500 mg',
        'notes': 'Collective variable for strVal/strUnit'
      },
      'volumeValue': {
        'variable': VOL_VAL,
        'type': TYPE_TEXT,
        'behavior': 'Enter number e.g., 2',
        'notes': 'Number of tablets'
      },
      'volumeUnit': {
        'variable': VOL_UNIT,
        'type': TYPE_FIXED,
        'behavior': 'Set to Tablet',
        'notes': 'Not changeable'
      },
      'volume': {
        'variable': VOLUME,
        'type': TYPE_TEXT,
        'behavior': 'Combines volVal and volUnit e.g., 2 Tablet',
        'notes': 'Collective variable for volVal/volUnit'
      }
    },
    CAPSULE: {
      'strengthValue': {
        'variable': STR_VAL,
        'type': TYPE_TEXT,
        'behavior': 'Enter number e.g., 250',
        'notes': 'Strength per capsule'
      },
      'strengthUnit': {
        'variable': STR_UNIT,
        'type': TYPE_DROPDOWN,
        'behavior': 'Choose from units e.g., mg',
        'notes': 'Default: mg'
      },
      'strength': {
        'variable': STRENGTH,
        'type': TYPE_TEXT_DROPDOWN,
        'behavior': 'Combines strVal and strUnit e.g., 250 mg',
        'notes': 'Collective variable for strVal/strUnit'
      },
      'volumeValue': {
        'variable': VOL_VAL,
        'type': TYPE_TEXT,
        'behavior': 'Enter number e.g., 1',
        'notes': 'Number of capsules'
      },
      'volumeUnit': {
        'variable': VOL_UNIT,
        'type': TYPE_FIXED,
        'behavior': 'Set to Capsule',
        'notes': 'Not changeable'
      },
      'volume': {
        'variable': VOLUME,
        'type': TYPE_TEXT,
        'behavior': 'Combines volVal and volUnit e.g., 1 Capsule',
        'notes': 'Collective variable for volVal/volUnit'
      }
    },
    LIQUID_VIAL: {
      'strengthValue': {
        'variable': STR_VAL,
        'type': TYPE_TEXT,
        'behavior': 'Enter number e.g., 100',
        'notes': 'Strength per mL'
      },
      'strengthUnit': {
        'variable': STR_UNIT,
        'type': TYPE_DROPDOWN,
        'behavior': 'Choose from units e.g., mg/mL',
        'notes': 'Default: mg/mL'
      },
      'strength': {
        'variable': STRENGTH,
        'type': TYPE_TEXT_DROPDOWN,
        'behavior': 'Combines strVal and strUnit e.g., 100 mg/mL',
        'notes': 'Collective variable for strVal/strUnit'
      },
      'volumeValue': {
        'variable': VOL_VAL,
        'type': TYPE_TEXT,
        'behavior': 'Enter number e.g., 5.5',
        'notes': 'Volume used from vial'
      },
      'volumeUnit': {
        'variable': VOL_UNIT,
        'type': TYPE_DROPDOWN,
        'behavior': 'Choose from units e.g., mL',
        'notes': 'Default: mL'
      },
      'volume': {
        'variable': VOLUME,
        'type': TYPE_TEXT_DROPDOWN,
        'behavior': 'Combines volVal and volUnit e.g., 5.5 mL',
        'notes': 'Collective variable for volVal/volUnit'
      }
    },
    RECONSTITUTABLE_VIAL: {
      'strengthValue': {
        'variable': STR_VAL,
        'type': TYPE_TEXT,
        'behavior': 'Enter number e.g., 50',
        'notes': 'Strength after mixing'
      },
      'strengthUnit': {
        'variable': STR_UNIT,
        'type': TYPE_DROPDOWN,
        'behavior': 'Choose from units e.g., mg/mL',
        'notes': 'Default: mg/mL'
      },
      'strength': {
        'variable': STRENGTH,
        'type': TYPE_TEXT_DROPDOWN,
        'behavior': 'Combines strVal and strUnit e.g., 50 mg/mL',
        'notes': 'Collective variable for strVal/strUnit'
      },
      'volumeValue': {
        'variable': VOL_VAL,
        'type': TYPE_TEXT,
        'behavior': 'Set by reconVolume e.g., 10',
        'notes': 'Total volume after mixing, not user-entered'
      },
      'volumeUnit': {
        'variable': VOL_UNIT,
        'type': TYPE_DROPDOWN,
        'behavior': 'Set to mL post-reconstitution',
        'notes': 'Default: mL, not user-selectable until mixing'
      },
      'volume': {
        'variable': VOLUME,
        'type': TYPE_TEXT_DROPDOWN,
        'behavior': 'Combines volVal and volUnit e.g., 10 mL',
        'notes': 'Set by reconVolume, collective for volVal/volUnit'
      },
      'reconstitutionVolume': {
        'variable': RECON_VOLUME,
        'type': TYPE_TEXT,
        'behavior': 'Set by calculator e.g., 10',
        'notes': 'Diluent volume added, determines volume'
      }
    },
    PREFILLED_SYRINGE: {
      'strengthValue': {
        'variable': STR_VAL,
        'type': TYPE_TEXT,
        'behavior': 'Enter number e.g., 100',
        'notes': 'Strength per mL'
      },
      'strengthUnit': {
        'variable': STR_UNIT,
        'type': TYPE_DROPDOWN,
        'behavior': 'Choose from units e.g., mg/mL',
        'notes': 'Default: mg/mL'
      },
      'strength': {
        'variable': STRENGTH,
        'type': TYPE_TEXT_DROPDOWN,
        'behavior': 'Combines strVal and strUnit e.g., 100 mg/mL',
        'notes': 'Collective variable for strVal/strUnit'
      },
      'volumeValue': {
        'variable': VOL_VAL,
        'type': TYPE_TEXT,
        'behavior': 'Enter number e.g., 0.5',
        'notes': 'Volume per syringe'
      },
      'volumeUnit': {
        'variable': VOL_UNIT,
        'type': TYPE_DROPDOWN,
        'behavior': 'Choose from units e.g., mL',
        'notes': 'Default: mL'
      },
      'volume': {
        'variable': VOLUME,
        'type': TYPE_TEXT_DROPDOWN,
        'behavior': 'Combines volVal and volUnit e.g., 0.5 mL',
        'notes': 'Collective variable for volVal/volUnit'
      }
    }
  };

  // Helper method to get a variable value
  static dynamic getValue(String variableName) {
    return variables[variableName]?['value'];
  }

  // Helper method to get a variable's unit
  static String? getUnit(String variableName) {
    return variables[variableName]?['unit'];
  }
} 