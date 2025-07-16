import 'package:flutter/material.dart';
import '../../../models/medication.dart';
import '../../../models/dose.dart';
import '../../../services/firebase_service.dart';
import '../../../services/service_locator.dart';
import '../doses/add_dose_screen.dart';
import '../schedules/view_schedules_screen.dart';
// import 'reconstitution_calculator_screen.dart'; // File missing, commented out

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
  late final FirebaseService _firebaseService;
  bool _isLoading = true;
  List<Dose> _doses = [];

  @override
  void initState() {
    super.initState();
    _medication = widget.medication;
    _firebaseService = ServiceLocator.get<FirebaseService>();
    _loadDoses();
  }

  Future<void> _loadDoses() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final doses = await _firebaseService.getDosesForMedication(_medication.id);
      
      if (mounted) {
        setState(() {
          _doses = doses;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error loading doses: $e'),
            backgroundColor: Colors.red,
          ),
        );
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _navigateToAddDoseScreen({Dose? existingDose}) async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => AddDoseScreen(
          medicationId: _medication.id,
          medicationName: _medication.name,
          existingDose: existingDose,
        ),
      ),
    );

    if (result == true) {
      // Dose was added/edited, reload doses
      await _loadDoses();
    }
  }

  Future<void> _navigateToViewSchedulesScreen(Dose dose) async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ViewSchedulesScreen(
          medication: _medication,
          dose: dose,
        ),
      ),
    );
  }

  Future<void> _saveReconstitutionSettings(double volume, String unit) async {
    final updatedMedication = Medication(
      id: _medication.id,
      name: _medication.name,
      type: _medication.type,
      strength: _medication.strength,
      strengthUnit: _medication.strengthUnit,
      tabletsInStock: _medication.currentInventory,
      quantityUnit: _medication.quantityUnit,
      currentInventory: _medication.currentInventory,
      reconstitutionVolume: volume,
      reconstitutionVolumeUnit: unit,
      concentrationAfterReconstitution: _medication.strength / volume,
      needsReconstitution: _medication.needsReconstitution,
      isPreFilled: _medication.isPreFilled,
      isPrefillPen: _medication.isPrefillPen,
      injectionType: _medication.injectionType,
      routeOfAdministration: _medication.routeOfAdministration,
      diluent: _medication.diluent,
      notes: _medication.notes,
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
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _loadDoses,
              child: SingleChildScrollView(
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
                            _buildDetailRow('Quantity', '${_medication.currentInventory} ${_medication.quantityUnit}'),
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
                    const SizedBox(height: 24),

                    // Doses section
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Doses',
                          style: Theme.of(context).textTheme.titleLarge,
                        ),
                        ElevatedButton.icon(
                          onPressed: () => _navigateToAddDoseScreen(),
                          icon: const Icon(Icons.add),
                          label: const Text('Add Dose'),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    
                    if (_doses.isEmpty)
                      const Card(
                        child: Padding(
                          padding: EdgeInsets.all(16),
                          child: Center(
                            child: Text(
                              'No doses added yet. Add a dose to create schedules.',
                              textAlign: TextAlign.center,
                            ),
                          ),
                        ),
                      )
                    else
                      ListView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: _doses.length,
                        itemBuilder: (context, index) {
                          final dose = _doses[index];
                          return Card(
                            margin: const EdgeInsets.only(bottom: 16),
                            child: Padding(
                              padding: const EdgeInsets.all(16),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      Expanded(
                                        child: Text(
                                          dose.getDisplayName(),
                                          style: const TextStyle(
                                            fontWeight: FontWeight.bold,
                                            fontSize: 18,
                                          ),
                                        ),
                                      ),
                                      IconButton(
                                        icon: const Icon(Icons.edit),
                                        onPressed: () => _navigateToAddDoseScreen(existingDose: dose),
                                      ),
                                    ],
                                  ),
                                  if (dose.notes != null) ...[
                                    const SizedBox(height: 8),
                                    Text(
                                      dose.notes!,
                                      style: const TextStyle(
                                        fontStyle: FontStyle.italic,
                                        color: Colors.grey,
                                      ),
                                    ),
                                  ],
                                  const SizedBox(height: 16),
                                  ElevatedButton.icon(
                                    onPressed: () => _navigateToViewSchedulesScreen(dose),
                                    icon: const Icon(Icons.schedule),
                                    label: const Text('Manage Schedules'),
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),

                    // Reconstitution calculator button for appropriate medication types
                    if (_medication.type == MedicationType.injection && _medication.needsReconstitution == true) ...[
                      const SizedBox(height: 24),
                      ElevatedButton.icon(
                        onPressed: () async {
                          final result = await Navigator.push<Map<String, dynamic>>(
                            context,
                            MaterialPageRoute(
                              builder: (context) => Scaffold(
                                appBar: AppBar(title: const Text('Calculator')),
                                body: const Center(child: Text('Calculator not implemented')),
                              ), // ReconstitutionCalculatorScreen removed
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
                  ],
                ),
              ),
            ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _navigateToAddDoseScreen(),
        child: const Icon(Icons.add),
        tooltip: 'Add Dose',
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
