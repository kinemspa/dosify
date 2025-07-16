import 'package:flutter/material.dart';
import 'dart:async';
import 'package:async/async.dart';
import '../../models/medication.dart';
import '../../models/injection_type.dart';
import '../../services/firebase_service.dart';
import '../../services/service_locator.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_decorations.dart';
import '../../theme/app_text_styles.dart';
import '../base_service_screen.dart';
import 'add_medication/add_medication_type_screen.dart';
import 'details/medication_detail_screen.dart';

class MedicationListScreen extends BaseServiceScreen {
  // Add a route name for navigation
  static const routeName = '/medication_list';
  
  const MedicationListScreen({super.key});

  @override
  State<MedicationListScreen> createState() => _MedicationListScreenState();
}

class _MedicationListScreenState extends BaseServiceScreenState<MedicationListScreen> {
  bool _isLoading = true;
  String? _errorMessage;
  StreamController<void> _refreshController = StreamController<void>.broadcast();

  @override
  void initState() {
    super.initState();
    _initializeFirebase();
  }
  
  @override
  void dispose() {
    _refreshController.close();
    super.dispose();
  }

  Future<void> _initializeFirebase() async {
    try {
      await firebaseService.initialize();
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
      _refreshController.add(null);
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
      _refreshController.add(null);
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
        // Use the new injectionType enum if available
        if (medication.injectionType != null) {
          switch (medication.injectionType!) {
            case InjectionType.liquidVial:
              icon = Icons.water_drop;
              color = Colors.blue;
              break;
            case InjectionType.powderVial:
              icon = Icons.science;
              color = Colors.purple;
              break;
            case InjectionType.prefilledSyringe:
              icon = Icons.vaccines;
              color = Colors.teal;
              break;
            case InjectionType.prefilledPen:
              icon = Icons.edit;
              color = Colors.green;
              break;
            case InjectionType.cartridge:
              icon = Icons.battery_std;
              color = Colors.amber;
              break;
            case InjectionType.ampule:
              icon = Icons.water_drop;
              color = Colors.cyan;
              break;
          }
        } 
        // Fallback to legacy fields if injectionType is not available
        else if (medication.isPreFilled == true) {
          if (medication.isPrefillPen == true) {
            icon = Icons.edit;  // Pen icon
            color = Colors.green;
          } else {
            icon = Icons.vaccines;  // Syringe icon
            color = Colors.teal;
          }
        } else if (medication.needsReconstitution == true) {
          icon = Icons.science;  // Lab/reconstitution icon
          color = Colors.purple;
        } else {
          icon = Icons.water_drop;  // Vial icon
          color = Colors.indigo;
        }
        break;
      case MedicationType.preFilledSyringe:
        icon = Icons.vaccines;
        color = Colors.teal;
        break;
      case MedicationType.vialPreMixed:
        icon = Icons.science;
        color = Colors.blue;
        break;
      case MedicationType.vialPowderedKnown:
        icon = Icons.science;
        color = Colors.purple;
        break;
      case MedicationType.vialPowderedRecon:
        icon = Icons.science;
        color = Colors.indigo;
        break;
      default:
        icon = Icons.medication;
        color = Colors.grey;
        break;
    }

    // Get medication type display text
    String typeText = _getMedicationTypeText(medication);

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
                      '${medication.strength} ${medication.strengthUnit} · $typeText',
                      style: TextStyle(
                        color: Theme.of(context).textTheme.bodyMedium?.color?.withOpacity(0.7),
                      ),
                    ),
                    if (medication.routeOfAdministration != null)
                      Text(
                        medication.routeOfAdministration!,
                        style: TextStyle(
                          fontSize: 12,
                          color: Theme.of(context).textTheme.bodyMedium?.color?.withOpacity(0.5),
                        ),
                      ),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    '${medication.currentInventory.toInt()}',  // Remove decimal places
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
  
  // Helper method to get medication type display text
  String _getMedicationTypeText(Medication medication) {
    switch (medication.type) {
      case MedicationType.tablet:
        return 'Tablet';
      case MedicationType.capsule:
        return 'Capsule';
      case MedicationType.injection:
        // Use the new injectionType enum if available
        if (medication.injectionType != null) {
          switch (medication.injectionType!) {
            case InjectionType.liquidVial:
              return 'Solution Vial';
            case InjectionType.powderVial:
              return 'Powdered Vial';
            case InjectionType.prefilledSyringe:
              return 'Prefilled Syringe';
            case InjectionType.prefilledPen:
              return 'Prefilled Pen';
            case InjectionType.cartridge:
              return 'Cartridge';
            case InjectionType.ampule:
              return 'Ampule';
          }
        } 
        // Fallback to legacy fields if injectionType is not available
        else if (medication.isPreFilled == true) {
          if (medication.isPrefillPen == true) {
            return 'Prefilled Pen';
          } else {
            return 'Prefilled Syringe';
          }
        } else if (medication.needsReconstitution == true) {
          return 'Reconstitution Vial';
        } else {
          return 'Vial';
        }
      case MedicationType.preFilledSyringe:
        return 'Prefilled Syringe';
      case MedicationType.vialPreMixed:
        return 'Pre-mixed Vial';
      case MedicationType.vialPowderedKnown:
        return 'Powdered Vial (Known)';
      case MedicationType.vialPowderedRecon:
        return 'Powdered Vial (Recon)';
      default:
        return 'Medication';
    }
  }

  @override
  Widget build(BuildContext context) {
    // Use ScaffoldMessengerState to control snackbars
    final scaffoldMessenger = ScaffoldMessenger.of(context);
    
    return Scaffold(
      body: Container(
        decoration: AppDecorations.screenBackground(context),
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
                    // Use a stream combiner to force refresh when needed
                    stream: StreamGroup.merge([
                      firebaseService.getMedications(),
                      // This stream will emit a value whenever we want to refresh
                      _refreshController.stream.asyncMap((_) => firebaseService.getMedications().first),
                    ]),
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
                                  color: Theme.of(context).brightness == Brightness.dark 
                                      ? Colors.white 
                                      : Theme.of(context).colorScheme.onSurface,
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

                      return RefreshIndicator(
                        onRefresh: () async {
                          _refreshController.add(null);
                        },
                        child: ListView.builder(
                          padding: const EdgeInsets.only(bottom: 80, left: 16, right: 16, top: 16),
                          itemCount: medications.length,
                          itemBuilder: (context, index) {
                            return _buildMedicationCard(medications[index]);
                          },
                        ),
                      );
                    },
                  ),
      ),
      floatingActionButton: FloatingActionButton(
        heroTag: 'addMedicationFab',
        onPressed: _navigateToAddMedication,
        child: const Icon(Icons.add),
      ),
    );
  }
} 