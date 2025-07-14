enum MedicationType {
  tablet,
  capsule,
  injection // Merged all injection types (vials and pre-filled syringes)
}

class Medication {
  final String id;
  final String name;
  final MedicationType type;
  final double strength;
  final String strengthUnit; // e.g., mg, mcg, IU
  final double quantity;
  final String quantityUnit; // e.g., tablets, vials, syringes
  final double currentInventory;
  DateTime? lastInventoryUpdate;
  
  // Additional fields based on type
  // For injection medications
  final double? reconstitutionVolume;
  final String? reconstitutionVolumeUnit;
  final double? concentrationAfterReconstitution;
  
  // Injection-specific fields
  final bool? needsReconstitution; // True for powdered vials
  final bool? isPreFilled; // True for pre-filled syringes
  
  Medication({
    required this.id,
    required this.name,
    required this.type,
    required this.strength,
    required this.strengthUnit,
    required this.quantity,
    required this.quantityUnit,
    required this.currentInventory,
    this.lastInventoryUpdate,
    this.reconstitutionVolume,
    this.reconstitutionVolumeUnit,
    this.concentrationAfterReconstitution,
    this.needsReconstitution,
    this.isPreFilled,
  });

  // Create a copy of this medication with updated inventory
  Medication copyWithNewInventory(double newInventory) {
    return Medication(
      id: id,
      name: name,
      type: type,
      strength: strength,
      strengthUnit: strengthUnit,
      quantity: quantity,
      quantityUnit: quantityUnit,
      currentInventory: newInventory,
      lastInventoryUpdate: DateTime.now(),
      reconstitutionVolume: reconstitutionVolume,
      reconstitutionVolumeUnit: reconstitutionVolumeUnit,
      concentrationAfterReconstitution: concentrationAfterReconstitution,
      needsReconstitution: needsReconstitution,
      isPreFilled: isPreFilled,
    );
  }
} 