import 'package:cloud_firestore/cloud_firestore.dart';

enum DoseStatus {
  scheduled,
  taken,
  missed,
  skipped,
}

class Dose {
  final String id;
  final String medicationId;
  final double amount;
  final String unit; // e.g., mg, ml, tablets
  final String? name; // Name of the dose, can be auto-generated or user-defined
  final String? notes;
  final bool requiresCalculation;
  final String? calculationFormula; // Reference to calculation method if needed
  final DateTime scheduledTime;
  final DateTime? actualTime;
  final DoseStatus status;
  final DateTime? createdAt;
  
  Dose({
    required this.id,
    required this.medicationId,
    required this.amount,
    required this.unit,
    this.name,
    this.notes,
    this.requiresCalculation = false,
    this.calculationFormula,
    required this.scheduledTime,
    this.actualTime,
    this.status = DoseStatus.scheduled,
    this.createdAt,
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

  /// Creates a Dose instance from Firestore data
  static Dose fromFirestore(Map<String, dynamic> data) {
    // Parse status
    final statusString = data['status'] as String?;
    DoseStatus status = DoseStatus.scheduled;
    if (statusString != null) {
      try {
        status = DoseStatus.values.firstWhere(
          (e) => e.toString().split('.').last == statusString,
        );
      } catch (e) {
        // Fallback to default if not found
        print('Error parsing dose status: $statusString');
      }
    }

    return Dose(
      id: data['id'] as String,
      medicationId: data['medicationId'] as String,
      amount: (data['amount'] as num).toDouble(),
      unit: data['unit'] as String,
      name: data['name'] as String?,
      notes: data['notes'] as String?,
      requiresCalculation: data['requiresCalculation'] as bool? ?? false,
      calculationFormula: data['calculationFormula'] as String?,
      scheduledTime: data['scheduledTime'] is Timestamp
          ? (data['scheduledTime'] as Timestamp).toDate()
          : DateTime.parse(data['scheduledTime'] as String),
      actualTime: data['actualTime'] != null
          ? (data['actualTime'] is Timestamp
              ? (data['actualTime'] as Timestamp).toDate()
              : DateTime.parse(data['actualTime'] as String))
          : null,
      status: status,
      createdAt: data['createdAt'] != null
          ? (data['createdAt'] is Timestamp
              ? (data['createdAt'] as Timestamp).toDate()
              : DateTime.parse(data['createdAt'] as String))
          : null,
    );
  }

  /// Converts the Dose instance to a map for storing in Firestore
  Map<String, dynamic> toFirestore() {
    return {
      'medicationId': medicationId,
      'amount': amount,
      'unit': unit,
      'name': name,
      'notes': notes,
      'requiresCalculation': requiresCalculation,
      'calculationFormula': calculationFormula,
      'scheduledTime': Timestamp.fromDate(scheduledTime),
      'actualTime': actualTime != null ? Timestamp.fromDate(actualTime!) : null,
      'status': status.toString().split('.').last,
      'createdAt': createdAt != null ? Timestamp.fromDate(createdAt!) : Timestamp.fromDate(DateTime.now()),
    };
  }
} 