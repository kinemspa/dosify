class Dose {
  final String id;
  final String medicationId;
  final double amount;
  final String unit; // e.g., mg, ml, tablets
  final String? notes;
  final bool requiresCalculation;
  final String? calculationFormula; // Reference to calculation method if needed
  
  Dose({
    required this.id,
    required this.medicationId,
    required this.amount,
    required this.unit,
    this.notes,
    this.requiresCalculation = false,
    this.calculationFormula,
  });

  // Calculate inventory reduction for this dose
  double calculateInventoryReduction(double medicationStrength) {
    // Basic calculation - can be extended based on medication type
    return amount / medicationStrength;
  }
} 