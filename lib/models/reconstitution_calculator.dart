import 'package:flutter/material.dart';

enum ReconstitutionOption {
  concentrated,
  average,
  diluted
}

class ReconstitutionCalculator {
  final double targetDose;
  final String targetDoseUnit;
  final double vialStrength;
  final String vialStrengthUnit;
  final double syringeSize;
  final double vialSize;
  final ReconstitutionOption option;

  ReconstitutionCalculator({
    required this.targetDose,
    required this.targetDoseUnit,
    required this.vialStrength,
    required this.vialStrengthUnit,
    required this.syringeSize,
    required this.vialSize,
    this.option = ReconstitutionOption.average,
  });

  /// Calculate the reconstitution volume based on the selected option
  double calculateReconstitutionVolume() {
    // Base calculation for average concentration
    double baseVolume = vialSize / 2;
    
    switch (option) {
      case ReconstitutionOption.concentrated:
        return baseVolume / 2; // More concentrated = less dilution
      case ReconstitutionOption.diluted:
        return baseVolume * 1.5; // More diluted = more reconstitution fluid
      case ReconstitutionOption.average:
        return baseVolume; // Standard concentration
    }
  }

  /// Calculate concentration after reconstitution (strength per mL)
  double calculateConcentration() {
    final reconVolume = calculateReconstitutionVolume();
    return vialStrength / reconVolume;
  }

  /// Calculate volume needed per dose
  double calculateVolumePerDose() {
    final concentration = calculateConcentration();
    return targetDose / concentration;
  }

  /// Calculate total number of doses possible
  int calculateTotalDoses() {
    final volumePerDose = calculateVolumePerDose();
    final totalVolume = calculateReconstitutionVolume();
    return (totalVolume / volumePerDose).floor();
  }

  /// Get syringe units based on volume
  double calculateSyringeUnits(double volume) {
    // Convert volume to units on syringe scale (0-100 IU)
    return (volume / syringeSize) * 100;
  }

  /// Format volume with appropriate precision
  String formatVolume(double volume) {
    return volume.toStringAsFixed(2);
  }

  /// Generate instructions for reconstitution
  String generateInstructions() {
    final reconVolume = calculateReconstitutionVolume();
    final doseVolume = calculateVolumePerDose();
    final totalDoses = calculateTotalDoses();
    final syringeUnits = calculateSyringeUnits(doseVolume);

    return '''
Reconstitute a $vialStrength $vialStrengthUnit vial with ${formatVolume(reconVolume)} mL of Bacteriostatic Water to deliver $targetDose $targetDoseUnit per dose using a $syringeSize mL syringe at ${syringeUnits.toStringAsFixed(1)} IU, providing a total of $totalDoses doses.
'''.trim();
  }
} 