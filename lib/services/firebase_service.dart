import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/medication.dart';
import '../models/dose.dart';
import '../models/schedule.dart';
import 'encryption_service.dart';

class FirebaseService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final EncryptionService _encryptionService = EncryptionService();

  // Initialize
  Future<void> initialize() async {
    await _encryptionService.initialize();
  }

  // Medications
  Future<void> addMedication(Medication medication) async {
    final userId = _auth.currentUser?.uid;
    if (userId == null) throw Exception('User not authenticated');

    final encryptedData = _encryptionService.encryptMedicationData({
      'name': medication.name,
      'strength': medication.strength,
      'type': medication.type.toString(),
      'quantity': medication.quantity,
      'strengthUnit': medication.strengthUnit,
      'quantityUnit': medication.quantityUnit,
      'currentInventory': medication.currentInventory,
    });

    await _firestore
        .collection('users')
        .doc(userId)
        .collection('medications')
        .doc(medication.id)
        .set(encryptedData);
  }

  // Get user's medications
  Stream<List<Medication>> getMedications() {
    final userId = _auth.currentUser?.uid;
    if (userId == null) throw Exception('User not authenticated');

    return _firestore
        .collection('users')
        .doc(userId)
        .collection('medications')
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) {
        final decryptedData = _encryptionService.decryptMedicationData(doc.data());
        // Convert decrypted data back to Medication object
        return Medication(
          id: doc.id,
          name: decryptedData['name'],
          type: MedicationType.values.firstWhere(
              (e) => e.toString() == decryptedData['type']),
          strength: decryptedData['strength'],
          strengthUnit: decryptedData['strengthUnit'],
          quantity: decryptedData['quantity'],
          quantityUnit: decryptedData['quantityUnit'],
          currentInventory: decryptedData['currentInventory'],
        );
      }).toList();
    });
  }

  // Doses
  Future<void> addDose(Dose dose) async {
    final userId = _auth.currentUser?.uid;
    if (userId == null) throw Exception('User not authenticated');

    final encryptedData = {
      'medicationId': dose.medicationId,
      'amount': _encryptionService.encryptData(dose.amount.toString()),
      'unit': _encryptionService.encryptData(dose.unit),
      'notes': dose.notes != null ? _encryptionService.encryptData(dose.notes!) : null,
    };

    await _firestore
        .collection('users')
        .doc(userId)
        .collection('doses')
        .doc(dose.id)
        .set(encryptedData);
  }

  // Schedules
  Future<void> addSchedule(Schedule schedule) async {
    final userId = _auth.currentUser?.uid;
    if (userId == null) throw Exception('User not authenticated');

    final encryptedData = {
      'doseId': schedule.doseId,
      'frequency': schedule.frequency.toString(),
      'startDate': schedule.startDate.toIso8601String(),
      'endDate': schedule.endDate?.toIso8601String(),
      'scheduledTimes': schedule.scheduledTimes
          .map((time) => time.toIso8601String())
          .toList(),
      'completedDoses': Map.fromEntries(
        schedule.completedDoses.entries.map(
          (e) => MapEntry(e.key.toIso8601String(), e.value),
        ),
      ),
    };

    await _firestore
        .collection('users')
        .doc(userId)
        .collection('schedules')
        .doc(schedule.id)
        .set(encryptedData);
  }

  // Update inventory
  Future<void> updateMedicationInventory(String medicationId, double newInventory) async {
    final userId = _auth.currentUser?.uid;
    if (userId == null) throw Exception('User not authenticated');

    await _firestore
        .collection('users')
        .doc(userId)
        .collection('medications')
        .doc(medicationId)
        .update({
      'currentInventory': _encryptionService.encryptData(newInventory.toString()),
      'lastInventoryUpdate': DateTime.now().toIso8601String(),
    });
  }
} 