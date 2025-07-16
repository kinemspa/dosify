import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:convert';
import 'injection_type.dart';

/// Enum representing different types of medications
enum MedicationType {
  /// Oral medication in tablet form
  tablet,
  
  /// Oral medication in capsule form
  capsule,
  
  /// Injectable medication
  injection,
  
  /// Pre-filled syringe
  preFilledSyringe,
  
  /// Pre-mixed vial
  vialPreMixed,
  
  /// Powdered vial with known concentration after reconstitution
  vialPowderedKnown,
  
  /// Powdered vial requiring reconstitution calculation
  vialPowderedRecon,
}

/// Extension to provide helper methods for MedicationType
extension MedicationTypeExtension on MedicationType {
  /// Returns a human-readable string representation of the medication type
  String get displayName {
    switch (this) {
      case MedicationType.tablet:
        return 'Tablet';
      case MedicationType.capsule:
        return 'Capsule';
      case MedicationType.injection:
        return 'Injection';
      case MedicationType.preFilledSyringe:
        return 'Pre-filled Syringe';
      case MedicationType.vialPreMixed:
        return 'Pre-mixed Vial';
      case MedicationType.vialPowderedKnown:
        return 'Powdered Vial (Known Concentration)';
      case MedicationType.vialPowderedRecon:
        return 'Powdered Vial (Needs Reconstitution)';
    }
  }

  /// Returns the appropriate icon for the medication type
  IconData get icon {
    switch (this) {
      case MedicationType.tablet:
        return Icons.local_pharmacy;
      case MedicationType.capsule:
        return Icons.medication;
      case MedicationType.injection:
        return Icons.vaccines;
      case MedicationType.preFilledSyringe:
        return Icons.vaccines;
      case MedicationType.vialPreMixed:
        return Icons.science;
      case MedicationType.vialPowderedKnown:
        return Icons.science;
      case MedicationType.vialPowderedRecon:
        return Icons.science;
    }
  }
}

/// Class representing a medication
class Medication {
  /// Unique identifier for the medication
  String id;
  
  /// Name of the medication
  String name;
  
  /// Type of medication (tablet, capsule, injection, etc.)
  MedicationType type;
  
  /// Specific injection type for injectable medications
  InjectionType? injectionType;
  
  /// Strength of the medication (e.g., 10 for 10mg)
  double strength;
  
  /// Unit of measurement for the strength (e.g., mg, mcg)
  String strengthUnit;
  
  /// Number of tablets/capsules/vials in stock
  double tabletsInStock;
  
  /// Date when the medication was created in the system
  DateTime createdAt;
  
  /// Date when the medication was last updated
  DateTime updatedAt;
  
  /// User ID of the person who owns this medication
  String userId;
  
  /// Route of administration for injectable medications
  String? routeOfAdministration;
  
  /// Legacy field: Whether this is a pre-filled medication
  bool? isPreFilled;
  
  /// Legacy field: Whether this is a pre-filled pen
  bool? isPrefillPen;
  
  /// Legacy field: Whether this medication needs reconstitution
  bool? needsReconstitution;
  
  /// Quantity unit (e.g., tablets, vials, etc.)
  String quantityUnit;
  
  /// Current inventory
  double currentInventory;
  
  /// Additional notes about the medication
  String? notes;
  
  /// Date when the inventory was last updated
  DateTime lastInventoryUpdate;
  
  /// Volume of diluent used for reconstitution
  double? reconstitutionVolume;
  
  /// Unit for reconstitution volume (usually mL)
  String? reconstitutionVolumeUnit;
  
  /// Concentration after reconstitution
  double? concentrationAfterReconstitution;
  
  /// Type of diluent used for reconstitution
  String? diluent;

  /// Constructor for creating a new Medication instance
  Medication({
    required this.id,
    required this.name,
    required this.type,
    this.injectionType,
    required this.strength,
    required this.strengthUnit,
    required this.tabletsInStock,
    DateTime? createdAt,
    DateTime? updatedAt,
    String? userId,
    this.routeOfAdministration,
    this.isPreFilled,
    this.isPrefillPen,
    this.needsReconstitution,
    String? quantityUnit,
    double? currentInventory,
    this.notes,
    DateTime? lastInventoryUpdate,
    this.reconstitutionVolume,
    this.reconstitutionVolumeUnit,
    this.concentrationAfterReconstitution,
    this.diluent,
  }) : quantityUnit = quantityUnit ?? 'tablets',
       currentInventory = currentInventory ?? tabletsInStock,
       createdAt = createdAt ?? DateTime.now(),
       updatedAt = updatedAt ?? DateTime.now(),
       userId = userId ?? '',
       lastInventoryUpdate = lastInventoryUpdate ?? DateTime.now();

  /// Creates a copy of this Medication with the specified fields replaced with new values
  Medication copyWith({
    String? id,
    String? name,
    MedicationType? type,
    InjectionType? injectionType,
    double? strength,
    String? strengthUnit,
    double? tabletsInStock,
    DateTime? createdAt,
    DateTime? updatedAt,
    String? userId,
    String? routeOfAdministration,
    bool? isPreFilled,
    bool? isPrefillPen,
    bool? needsReconstitution,
    String? quantityUnit,
    double? currentInventory,
    String? notes,
    DateTime? lastInventoryUpdate,
    double? reconstitutionVolume,
    String? reconstitutionVolumeUnit,
    double? concentrationAfterReconstitution,
    String? diluent,
  }) {
    return Medication(
      id: id ?? this.id,
      name: name ?? this.name,
      type: type ?? this.type,
      injectionType: injectionType ?? this.injectionType,
      strength: strength ?? this.strength,
      strengthUnit: strengthUnit ?? this.strengthUnit,
      tabletsInStock: tabletsInStock ?? this.tabletsInStock,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      userId: userId ?? this.userId,
      routeOfAdministration: routeOfAdministration ?? this.routeOfAdministration,
      isPreFilled: isPreFilled ?? this.isPreFilled,
      isPrefillPen: isPrefillPen ?? this.isPrefillPen,
      needsReconstitution: needsReconstitution ?? this.needsReconstitution,
      quantityUnit: quantityUnit ?? this.quantityUnit,
      currentInventory: currentInventory ?? this.currentInventory,
      notes: notes ?? this.notes,
      lastInventoryUpdate: lastInventoryUpdate ?? this.lastInventoryUpdate,
      reconstitutionVolume: reconstitutionVolume ?? this.reconstitutionVolume,
      reconstitutionVolumeUnit: reconstitutionVolumeUnit ?? this.reconstitutionVolumeUnit,
      concentrationAfterReconstitution: concentrationAfterReconstitution ?? this.concentrationAfterReconstitution,
      diluent: diluent ?? this.diluent,
    );
  }
  
  /// Creates a copy of this Medication with updated inventory
  Medication copyWithNewInventory(double newInventory) {
    return copyWith(
      currentInventory: newInventory,
      lastInventoryUpdate: DateTime.now(),
    );
  }

  /// Creates a Medication instance from a Firestore document
  factory Medication.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    
    // Parse medication type
    final medicationType = MedicationType.values.firstWhere(
      (e) => e.toString() == 'MedicationType.${data['type']}',
      orElse: () => MedicationType.tablet,
    );
    
    // Parse injection type if available
    InjectionType? injectionType;
    if (data['injectionType'] != null) {
      try {
        injectionType = InjectionType.values.firstWhere(
          (e) => e.toString() == 'InjectionType.${data['injectionType']}',
        );
      } catch (e) {
        // Fallback to default if not found
        print('Error parsing injection type: ${data['injectionType']}');
      }
    }
    
    return Medication(
      id: doc.id,
      name: data['name'] as String,
      type: medicationType,
      injectionType: injectionType,
      strength: (data['strength'] as num).toDouble(),
      strengthUnit: data['strengthUnit'] as String,
      tabletsInStock: (data['tabletsInStock'] as num).toDouble(),
      createdAt: (data['createdAt'] as Timestamp).toDate(),
      updatedAt: (data['updatedAt'] as Timestamp).toDate(),
      userId: data['userId'] as String,
      routeOfAdministration: data['routeOfAdministration'] as String?,
      isPreFilled: data['isPreFilled'] as bool?,
      isPrefillPen: data['isPrefillPen'] as bool?,
      needsReconstitution: data['needsReconstitution'] as bool?,
      quantityUnit: data['quantityUnit'] as String? ?? 'tablets',
      currentInventory: data['currentInventory'] != null 
          ? (data['currentInventory'] as num).toDouble() 
          : (data['tabletsInStock'] as num).toDouble(),
      notes: data['notes'] as String?,
      lastInventoryUpdate: data['lastInventoryUpdate'] != null
          ? (data['lastInventoryUpdate'] as Timestamp).toDate()
          : DateTime.now(),
      reconstitutionVolume: data['reconstitutionVolume'] != null
          ? (data['reconstitutionVolume'] as num).toDouble()
          : null,
      reconstitutionVolumeUnit: data['reconstitutionVolumeUnit'] as String?,
      concentrationAfterReconstitution: data['concentrationAfterReconstitution'] != null
          ? (data['concentrationAfterReconstitution'] as num).toDouble()
          : null,
      diluent: data['diluent'] as String?,
    );
  }

  /// Converts the Medication instance to a map for storing in Firestore
  Map<String, dynamic> toFirestore() {
    final map = {
      'name': name,
      'type': type.toString().split('.').last,
      'strength': strength,
      'strengthUnit': strengthUnit,
      'tabletsInStock': tabletsInStock,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
      'userId': userId,
      'quantityUnit': quantityUnit,
      'currentInventory': currentInventory,
      'lastInventoryUpdate': Timestamp.fromDate(lastInventoryUpdate),
    };
    
    // Add optional fields if they exist
    if (injectionType != null) {
      map['injectionType'] = injectionType.toString().split('.').last;
    }
    if (routeOfAdministration != null) {
      map['routeOfAdministration'] = routeOfAdministration as Object;
    }
    if (isPreFilled != null) {
      map['isPreFilled'] = isPreFilled as Object;
    }
    if (isPrefillPen != null) {
      map['isPrefillPen'] = isPrefillPen as Object;
    }
    if (needsReconstitution != null) {
      map['needsReconstitution'] = needsReconstitution as Object;
    }
    if (notes != null) {
      map['notes'] = notes as Object;
    }
    if (reconstitutionVolume != null) {
      map['reconstitutionVolume'] = reconstitutionVolume as Object;
    }
    if (reconstitutionVolumeUnit != null) {
      map['reconstitutionVolumeUnit'] = reconstitutionVolumeUnit as Object;
    }
    if (concentrationAfterReconstitution != null) {
      map['concentrationAfterReconstitution'] = concentrationAfterReconstitution as Object;
    }
    if (diluent != null) {
      map['diluent'] = diluent as Object;
    }
    
    return map;
  }

  /// Converts the Medication instance to a JSON string for caching
  String toJson() {
    final map = {
      'id': id,
      'name': name,
      'type': type.toString().split('.').last,
      'strength': strength,
      'strengthUnit': strengthUnit,
      'tabletsInStock': tabletsInStock,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
      'userId': userId,
      'quantityUnit': quantityUnit,
      'currentInventory': currentInventory,
      'lastInventoryUpdate': lastInventoryUpdate.toIso8601String(),
    };
    
    // Add optional fields if they exist
    if (injectionType != null) {
      map['injectionType'] = injectionType.toString().split('.').last;
    }
    if (routeOfAdministration != null) {
      map['routeOfAdministration'] = routeOfAdministration as Object;
    }
    if (isPreFilled != null) {
      map['isPreFilled'] = isPreFilled as Object;
    }
    if (isPrefillPen != null) {
      map['isPrefillPen'] = isPrefillPen as Object;
    }
    if (needsReconstitution != null) {
      map['needsReconstitution'] = needsReconstitution as Object;
    }
    if (notes != null) {
      map['notes'] = notes as Object;
    }
    if (reconstitutionVolume != null) {
      map['reconstitutionVolume'] = reconstitutionVolume as Object;
    }
    if (reconstitutionVolumeUnit != null) {
      map['reconstitutionVolumeUnit'] = reconstitutionVolumeUnit as Object;
    }
    if (concentrationAfterReconstitution != null) {
      map['concentrationAfterReconstitution'] = concentrationAfterReconstitution as Object;
    }
    if (diluent != null) {
      map['diluent'] = diluent as Object;
    }
    
    return jsonEncode(map);
  }

  /// Creates a Medication instance from a JSON string
  factory Medication.fromJson(String jsonString) {
    final data = jsonDecode(jsonString) as Map<String, dynamic>;
    
    // Parse medication type
    final medicationType = MedicationType.values.firstWhere(
      (e) => e.toString() == 'MedicationType.${data['type']}',
      orElse: () => MedicationType.tablet,
    );
    
    // Parse injection type if available
    InjectionType? injectionType;
    if (data['injectionType'] != null) {
      try {
        injectionType = InjectionType.values.firstWhere(
          (e) => e.toString() == 'InjectionType.${data['injectionType']}',
        );
      } catch (e) {
        // Fallback to default if not found
        print('Error parsing injection type: ${data['injectionType']}');
      }
    }
    
    return Medication(
      id: data['id'] as String,
      name: data['name'] as String,
      type: medicationType,
      injectionType: injectionType,
      strength: (data['strength'] as num).toDouble(),
      strengthUnit: data['strengthUnit'] as String,
      tabletsInStock: (data['tabletsInStock'] as num).toDouble(),
      createdAt: DateTime.parse(data['createdAt']),
      updatedAt: DateTime.parse(data['updatedAt']),
      userId: data['userId'] as String,
      routeOfAdministration: data['routeOfAdministration'] as String?,
      isPreFilled: data['isPreFilled'] as bool?,
      isPrefillPen: data['isPrefillPen'] as bool?,
      needsReconstitution: data['needsReconstitution'] as bool?,
      quantityUnit: data['quantityUnit'] as String? ?? 'tablets',
      currentInventory: data['currentInventory'] != null 
          ? (data['currentInventory'] as num).toDouble() 
          : (data['tabletsInStock'] as num).toDouble(),
      notes: data['notes'] as String?,
      lastInventoryUpdate: data['lastInventoryUpdate'] != null
          ? DateTime.parse(data['lastInventoryUpdate'])
          : DateTime.now(),
      reconstitutionVolume: data['reconstitutionVolume'] != null
          ? (data['reconstitutionVolume'] as num).toDouble()
          : null,
      reconstitutionVolumeUnit: data['reconstitutionVolumeUnit'] as String?,
      concentrationAfterReconstitution: data['concentrationAfterReconstitution'] != null
          ? (data['concentrationAfterReconstitution'] as num).toDouble()
          : null,
      diluent: data['diluent'] as String?,
    );
  }

  /// Creates a Medication instance from Firestore data (Map format)
  /// Used by the refactored Firebase service
  static Medication fromFirestoreData(Map<String, dynamic> data) {
    // Parse medication type
    final medicationType = MedicationType.values.firstWhere(
      (e) => e.toString().split('.').last == data['type'],
      orElse: () => MedicationType.tablet,
    );
    
    // Parse injection type if available
    InjectionType? injectionType;
    if (data['injectionType'] != null) {
      try {
        injectionType = InjectionType.values.firstWhere(
          (e) => e.toString().split('.').last == data['injectionType'],
        );
      } catch (e) {
        // Fallback to default if not found
        print('Error parsing injection type: ${data['injectionType']}');
      }
    }
    
    return Medication(
      id: data['id'] as String,
      name: data['name'] as String,
      type: medicationType,
      injectionType: injectionType,
      strength: (data['strength'] as num).toDouble(),
      strengthUnit: data['strengthUnit'] as String,
      tabletsInStock: data['tabletsInStock'] != null 
          ? (data['tabletsInStock'] as num).toDouble()
          : (data['currentInventory'] as num).toDouble(),
      createdAt: data['createdAt'] is String 
          ? DateTime.parse(data['createdAt'])
          : (data['createdAt'] as Timestamp).toDate(),
      updatedAt: data['updatedAt'] is String
          ? DateTime.parse(data['updatedAt'])
          : (data['updatedAt'] as Timestamp).toDate(),
      userId: data['userId'] as String,
      routeOfAdministration: data['routeOfAdministration'] as String?,
      isPreFilled: data['isPreFilled'] as bool?,
      isPrefillPen: data['isPrefillPen'] as bool?,
      needsReconstitution: data['needsReconstitution'] as bool?,
      quantityUnit: data['quantityUnit'] as String? ?? 'tablets',
      currentInventory: data['currentInventory'] != null 
          ? (data['currentInventory'] as num).toDouble() 
          : (data['tabletsInStock'] as num?)?.toDouble() ?? 0.0,
      notes: data['notes'] as String?,
      lastInventoryUpdate: data['lastInventoryUpdate'] != null
          ? (data['lastInventoryUpdate'] is String
              ? DateTime.parse(data['lastInventoryUpdate'])
              : (data['lastInventoryUpdate'] as Timestamp).toDate())
          : DateTime.now(),
      reconstitutionVolume: data['reconstitutionVolume'] != null
          ? (data['reconstitutionVolume'] as num).toDouble()
          : null,
      reconstitutionVolumeUnit: data['reconstitutionVolumeUnit'] as String?,
      concentrationAfterReconstitution: data['concentrationAfterReconstitution'] != null
          ? (data['concentrationAfterReconstitution'] as num).toDouble()
          : null,
      diluent: data['diluent'] as String?,
    );
  }
} 