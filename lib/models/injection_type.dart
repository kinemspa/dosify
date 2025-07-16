import 'package:flutter/material.dart';

/// Enum representing different types of injectable medications
enum InjectionType {
  /// Liquid medication in a vial
  liquidVial,
  
  /// Powdered medication in a vial that needs reconstitution
  powderVial,
  
  /// Pre-filled syringe with ready-to-use medication
  prefilledSyringe,
  
  /// Pre-filled pen device with ready-to-use medication
  prefilledPen,
  
  /// Cartridge for reusable pen devices
  cartridge,
  
  /// Single-use glass ampule
  ampule,
}

/// Extension to provide helper methods for InjectionType
extension InjectionTypeExtension on InjectionType {
  /// Returns a human-readable string representation of the injection type
  String get displayName {
    switch (this) {
      case InjectionType.liquidVial:
        return 'Solution Vial';
      case InjectionType.powderVial:
        return 'Powdered Vial';
      case InjectionType.prefilledSyringe:
        return 'Pre-filled Syringe';
      case InjectionType.prefilledPen:
        return 'Pre-filled Pen';
      case InjectionType.cartridge:
        return 'Cartridge';
      case InjectionType.ampule:
        return 'Ampule';
    }
  }
  
  /// Returns the appropriate icon for the injection type
  IconData get icon {
    switch (this) {
      case InjectionType.liquidVial:
        return Icons.water_drop;
      case InjectionType.powderVial:
        return Icons.science;
      case InjectionType.prefilledSyringe:
        return Icons.vaccines;
      case InjectionType.prefilledPen:
        return Icons.edit;
      case InjectionType.cartridge:
        return Icons.battery_std;
      case InjectionType.ampule:
        return Icons.water_drop;
    }
  }
  
  /// Returns the appropriate color for the injection type
  Color get color {
    switch (this) {
      case InjectionType.liquidVial:
        return Colors.blue;
      case InjectionType.powderVial:
        return Colors.purple;
      case InjectionType.prefilledSyringe:
        return Colors.teal;
      case InjectionType.prefilledPen:
        return Colors.green;
      case InjectionType.cartridge:
        return Colors.amber;
      case InjectionType.ampule:
        return Colors.cyan;
    }
  }
} 