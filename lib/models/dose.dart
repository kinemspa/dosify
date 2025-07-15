class Dose {
  final String id;
  final String medicationId;
  final double amount;
  final String unit; // e.g., mg, ml, tablets
  final String? name; // Name of the dose, can be auto-generated or user-defined
  final String? notes;
  final bool requiresCalculation;
  final String? calculationFormula; // Reference to calculation method if needed
  
  Dose({
    required this.id,
    required this.medicationId,
    required this.amount,
    required this.unit,
    this.name,
    this.notes,
    this.requiresCalculation = false,
    this.calculationFormula,
  });

  // Generate a default name based on amount and unit
  String getDisplayName() {
    return name ?? '$amount $unit';
  }

  // Calculate inventory reduction for this dose
  double calculateInventoryReduction(double medicationStrength) {
    // Basic calculation - can be extended based on medication type
    return amount / medicationStrength;
  }
} 