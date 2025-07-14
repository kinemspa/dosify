import 'package:flutter/material.dart';
import '../../models/medication.dart';
import '../../services/firebase_service.dart';
import 'reconstitution_calculator_screen.dart';

class MedicationDetailsScreen extends StatefulWidget {
  final Medication medication;

  const MedicationDetailsScreen({
    super.key,
    required this.medication,
  });

  @override
  State<MedicationDetailsScreen> createState() => _MedicationDetailsScreenState();
}

class _MedicationDetailsScreenState extends State<MedicationDetailsScreen> {
  late Medication _medication;
  final FirebaseService _firebaseService = FirebaseService();

  @override
  void initState() {
    super.initState();
    _medication = widget.medication;
  }

  Future<void> _saveReconstitutionSettings(double volume, String unit) async {
    final updatedMedication = Medication(
      id: _medication.id,
      name: _medication.name,
      type: _medication.type,
      strength: _medication.strength,
      strengthUnit: _medication.strengthUnit,
      quantity: _medication.quantity,
      quantityUnit: _medication.quantityUnit,
      currentInventory: _medication.currentInventory,
      reconstitutionVolume: volume,
      reconstitutionVolumeUnit: unit,
      concentrationAfterReconstitution: _medication.strength / volume,
    );

    await _firebaseService.addMedication(updatedMedication);
    setState(() {
      _medication = updatedMedication;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_medication.name),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Medication details card
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Medication Details',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    const SizedBox(height: 16),
                    _buildDetailRow('Type', _medication.type.toString().split('.').last),
                    _buildDetailRow('Strength', '${_medication.strength} ${_medication.strengthUnit}'),
                    _buildDetailRow('Quantity', '${_medication.quantity} ${_medication.quantityUnit}'),
                    _buildDetailRow('Current Inventory', _medication.currentInventory.toString()),
                    if (_medication.reconstitutionVolume != null) ...[
                      const Divider(),
                      Text(
                        'Reconstitution Settings',
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      const SizedBox(height: 8),
                      _buildDetailRow(
                        'Volume',
                        '${_medication.reconstitutionVolume} ${_medication.reconstitutionVolumeUnit}',
                      ),
                      _buildDetailRow(
                        'Concentration',
                        '${_medication.concentrationAfterReconstitution?.toStringAsFixed(2)} ${_medication.strengthUnit}/mL',
                      ),
                    ],
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Reconstitution calculator button for appropriate medication types
            if (_medication.type == MedicationType.vialPowderedRecon ||
                _medication.type == MedicationType.vialPowderedKnown)
              ElevatedButton.icon(
                onPressed: () async {
                  final result = await Navigator.push<Map<String, dynamic>>(
                    context,
                    MaterialPageRoute(
                      builder: (context) => ReconstitutionCalculatorScreen(
                        initialVialStrength: _medication.strength,
                        initialVialStrengthUnit: _medication.strengthUnit,
                        initialVialSize: _medication.quantity,
                      ),
                    ),
                  );

                  if (result != null) {
                    await _saveReconstitutionSettings(
                      result['volume'] as double,
                      result['unit'] as String,
                    );
                  }
                },
                icon: const Icon(Icons.calculate),
                label: Text(
                  _medication.reconstitutionVolume == null
                      ? 'Calculate Reconstitution'
                      : 'Recalculate Reconstitution',
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: const TextStyle(
              fontWeight: FontWeight.w500,
              color: Colors.grey,
            ),
          ),
          Text(value),
        ],
      ),
    );
  }
} 