import 'package:flutter/material.dart';
import '../../models/medication.dart';
import '../../services/firebase_service.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_decorations.dart';
import 'add_medication_type_screen.dart';
import 'medication_detail_screen.dart';

class MedicationListScreen extends StatefulWidget {
  const MedicationListScreen({super.key});

  @override
  State<MedicationListScreen> createState() => _MedicationListScreenState();
}

class _MedicationListScreenState extends State<MedicationListScreen> {
  final FirebaseService _firebaseService = FirebaseService();
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _initializeFirebase();
  }

  Future<void> _initializeFirebase() async {
    try {
      await _firebaseService.initialize();
      setState(() {
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
        _errorMessage = 'Failed to initialize: $e';
      });
    }
  }

  void _navigateToAddMedication() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const AddMedicationTypeScreen()),
    );

    if (result == true) {
      // If a medication was added, refresh the list
      setState(() {});
    }
  }

  void _navigateToMedicationDetail(Medication medication) async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => MedicationDetailScreen(medication: medication),
      ),
    );

    // If a medication was deleted or updated, refresh the list
    if (result == true) {
      setState(() {});
    }
  }

  Widget _buildMedicationCard(Medication medication) {
    IconData icon;
    Color color;

    switch (medication.type) {
      case MedicationType.tablet:
        icon = Icons.local_pharmacy;
        color = Colors.blue;
        break;
      case MedicationType.capsule:
        icon = Icons.medication;
        color = Colors.orange;
        break;
      case MedicationType.injection:
        // Check if it's a pre-filled syringe or vial
        if (medication.isPreFilled == true) {
          icon = Icons.vaccines;
          color = Colors.green;
        } else if (medication.needsReconstitution == true) {
          icon = Icons.science;
          color = Colors.teal;
        } else {
          icon = Icons.water_drop;
          color = Colors.purple;
        }
        break;
    }

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: InkWell(
        onTap: () => _navigateToMedicationDetail(medication),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  icon,
                  color: color,
                  size: 32,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      medication.name,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${medication.strength} ${medication.strengthUnit}',
                      style: TextStyle(
                        color: Theme.of(context).textTheme.bodyMedium?.color?.withOpacity(0.7),
                      ),
                    ),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    '${medication.currentInventory}',
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    medication.quantityUnit,
                    style: TextStyle(
                      color: Theme.of(context).textTheme.bodyMedium?.color?.withOpacity(0.7),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('My Medications'),
      ),
      body: Container(
        decoration: AppDecorations.gradientBackground,
        child: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : _errorMessage != null
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(
                          Icons.error_outline,
                          color: Colors.red,
                          size: 48,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          _errorMessage!,
                          style: const TextStyle(color: Colors.red),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 16),
                        ElevatedButton(
                          onPressed: _initializeFirebase,
                          child: const Text('Retry'),
                        ),
                      ],
                    ),
                  )
                : StreamBuilder<List<Medication>>(
                    stream: _firebaseService.getMedications(),
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return const Center(child: CircularProgressIndicator());
                      }

                      if (snapshot.hasError) {
                        return Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(
                                Icons.error_outline,
                                color: Colors.red,
                                size: 48,
                              ),
                              const SizedBox(height: 16),
                              Text(
                                'Error: ${snapshot.error}',
                                style: const TextStyle(color: Colors.red),
                                textAlign: TextAlign.center,
                              ),
                              const SizedBox(height: 16),
                              ElevatedButton(
                                onPressed: _initializeFirebase,
                                child: const Text('Retry'),
                              ),
                            ],
                          ),
                        );
                      }

                      final medications = snapshot.data ?? [];

                      if (medications.isEmpty) {
                        return Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.medication_outlined,
                                size: 72,
                                color: Colors.grey[400],
                              ),
                              const SizedBox(height: 16),
                              Text(
                                'No medications added yet',
                                style: TextStyle(
                                  fontSize: 18,
                                  color: Colors.white,
                                ),
                              ),
                              const SizedBox(height: 16),
                              ElevatedButton.icon(
                                onPressed: _navigateToAddMedication,
                                icon: const Icon(Icons.add),
                                label: const Text('Add Medication'),
                              ),
                            ],
                          ),
                        );
                      }

                      return ListView.builder(
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        itemCount: medications.length,
                        itemBuilder: (context, index) {
                          return _buildMedicationCard(medications[index]);
                        },
                      );
                    },
                  ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _navigateToAddMedication,
        child: const Icon(Icons.add),
      ),
    );
  }
} 