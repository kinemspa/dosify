import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:convert';

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

  /// Constructor for creating a new Medication instance
  Medication({
    required this.id,
    required this.name,
    required this.type,
    required this.strength,
    required this.strengthUnit,
    required this.tabletsInStock,
    required this.createdAt,
    required this.updatedAt,
    required this.userId,
  });

  /// Creates a copy of this Medication with the specified fields replaced with new values
  Medication copyWith({
    String? id,
    String? name,
    MedicationType? type,
    double? strength,
    String? strengthUnit,
    double? tabletsInStock,
    DateTime? createdAt,
    DateTime? updatedAt,
    String? userId,
  }) {
    return Medication(
      id: id ?? this.id,
      name: name ?? this.name,
      type: type ?? this.type,
      strength: strength ?? this.strength,
      strengthUnit: strengthUnit ?? this.strengthUnit,
      tabletsInStock: tabletsInStock ?? this.tabletsInStock,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      userId: userId ?? this.userId,
    );
  }

  /// Creates a Medication instance from a Firestore document
  factory Medication.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return Medication(
      id: doc.id,
      name: data['name'] as String,
      type: MedicationType.values.firstWhere(
        (e) => e.toString() == 'MedicationType.${data['type']}',
        orElse: () => MedicationType.tablet,
      ),
      strength: (data['strength'] as num).toDouble(),
      strengthUnit: data['strengthUnit'] as String,
      tabletsInStock: (data['tabletsInStock'] as num).toDouble(),
      createdAt: (data['createdAt'] as Timestamp).toDate(),
      updatedAt: (data['updatedAt'] as Timestamp).toDate(),
      userId: data['userId'] as String,
    );
  }

  /// Converts the Medication instance to a map for storing in Firestore
  Map<String, dynamic> toFirestore() {
    return {
      'name': name,
      'type': type.toString().split('.').last,
      'strength': strength,
      'strengthUnit': strengthUnit,
      'tabletsInStock': tabletsInStock,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
      'userId': userId,
    };
  }

  /// Converts the Medication instance to a JSON string for caching
  String toJson() {
    return jsonEncode({
      'id': id,
      'name': name,
      'type': type.toString().split('.').last,
      'strength': strength,
      'strengthUnit': strengthUnit,
      'tabletsInStock': tabletsInStock,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
      'userId': userId,
    });
  }

  /// Creates a Medication instance from a JSON string
  factory Medication.fromJson(String jsonString) {
    final data = jsonDecode(jsonString) as Map<String, dynamic>;
    return Medication(
      id: data['id'] as String,
      name: data['name'] as String,
      type: MedicationType.values.firstWhere(
        (e) => e.toString() == 'MedicationType.${data['type']}',
        orElse: () => MedicationType.tablet,
      ),
      strength: (data['strength'] as num).toDouble(),
      strengthUnit: data['strengthUnit'] as String,
      tabletsInStock: (data['tabletsInStock'] as num).toDouble(),
      createdAt: DateTime.parse(data['createdAt']),
      updatedAt: DateTime.parse(data['updatedAt']),
      userId: data['userId'] as String,
    );
  }
} 