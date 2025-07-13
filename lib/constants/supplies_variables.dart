// Supplies Variables Table Implementation
class SuppliesVariables {
  // Variable Names
  static const String SUPPLY_NAME = 'supplyName';
  static const String SUPPLY_UNIT_QTY = 'supplyUnitQty';
  static const String SUPPLY_UNIT_VOL_QTY = 'supplyUnitVolQty';

  // Field Types
  static const String TYPE_TEXT = 'Text';

  // Variable Definitions Map
  static final Map<String, Map<String, dynamic>> variables = {
    'supplyName': {
      'variable': SUPPLY_NAME,
      'type': TYPE_TEXT,
      'behavior': 'Enter text e.g., 1 mL Syringe, Bacteriostatic Water',
      'notes': 'Identifies the supply, linked to doseName'
    },
    'supplyUnitQuantity': {
      'variable': SUPPLY_UNIT_QTY,
      'type': TYPE_TEXT,
      'behavior': 'Enter number e.g., 50, 5',
      'notes': 'Number of supply units (e.g., syringes, vials)'
    },
    'supplyUnitVolumeQuantity': {
      'variable': SUPPLY_UNIT_VOL_QTY,
      'type': TYPE_TEXT,
      'behavior': 'Enter number e.g., 1, 30',
      'notes': 'Volume per unit (e.g., 1 mL/syringe, 30 mL/vial)'
    }
  };
} 