import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../models/medication.dart';
import '../../../models/injection_type.dart';
import '../../../models/dose.dart';
import '../../../services/firebase_service.dart';
import '../../../services/service_locator.dart';
import '../../../theme/app_colors.dart';
import '../../../theme/app_decorations.dart';
import '../../../widgets/number_input_field.dart';
import '../../../widgets/confirmation_dialog.dart';
import '../../../widgets/refill_dialog.dart';
import '../../../widgets/help_card.dart';
import '../../../widgets/upcoming_doses_widget.dart';
import '../../base_service_screen.dart';
import '../doses/add_dose_screen.dart';
import '../schedules/add_schedule_screen.dart';
import '../tools/reconstitution_calculator_screen.dart';

class MedicationDetailScreen extends BaseServiceScreen {
  final Medication medication;

  const MedicationDetailScreen({
    super.key,
    required this.medication,
  });

  @override
  State<MedicationDetailScreen> createState() => _MedicationDetailScreenState();
}

class _MedicationDetailScreenState extends BaseServiceScreenState<MedicationDetailScreen> {
  late Medication _medication;
  bool _isLoading = false;
  bool _isLoadingDoses = true;
  final TextEditingController _inventoryController = TextEditingController();
  List<Dose> _doses = [];

  @override
  void initState() {
    super.initState();
    _medication = widget.medication;
    _inventoryController.text = _medication.currentInventory.toString();
    _loadDoses();
  }

  Future<void> _loadDoses() async {
    setState(() {
      _isLoadingDoses = true;
    });
    
    try {
      final doses = await firebaseService.getDosesForMedication(_medication.id);
      setState(() {
        _doses = doses;
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error loading doses: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      setState(() {
        _isLoadingDoses = false;
      });
    }
  }

  @override
  void dispose() {
    _inventoryController.dispose();
    super.dispose();
  }

  Future<void> _showRefillDialog() async {
    final result = await RefillDialog.show(
      context: context,
      medicationName: _medication.name,
      currentInventory: _medication.currentInventory.toInt(),
      quantityUnit: _medication.quantityUnit,
    );

    if (result == true) {
      final refillAmount = int.tryParse(RefillDialog.getRefillAmount()) ?? 0;
      if (refillAmount <= 0) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Please enter a valid refill amount'),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }

      setState(() => _isLoading = true);

      try {
        final newInventory = _medication.currentInventory + refillAmount;
        await firebaseService.updateMedicationInventory(
          _medication.id,
          newInventory,
        );

        setState(() {
          _medication = _medication.copyWithNewInventory(newInventory);
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Added $refillAmount ${_medication.quantityUnit} to inventory'),
            backgroundColor: Colors.green,
          ),
        );
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error updating inventory: $e'),
            backgroundColor: Colors.red,
          ),
        );
      } finally {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _navigateToAddDose() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => AddDoseScreen(
          medicationId: _medication.id,
          medicationName: _medication.name,
        ),
      ),
    );

    if (result == true) {
      _loadDoses(); // Reload doses if a dose was added
    }
  }

  Future<void> _navigateToEditDose(Dose dose) async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => AddDoseScreen(
          medicationId: _medication.id,
          medicationName: _medication.name,
          existingDose: dose,
        ),
      ),
    );

    if (result == true) {
      _loadDoses(); // Reload doses if a dose was updated
    }
  }

  Future<void> _navigateToReconstitutionCalculator() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ReconstitutionCalculatorScreen(
          initialVialStrength: _medication.strength,
          initialVialStrengthUnit: _medication.strengthUnit,
          initialVialSize: _medication.tabletsInStock,
        ),
      ),
    );

    if (result == true) {
      _loadDoses(); // Reload doses to update reconstitution status if needed
    }
  }

  Future<void> _navigateToSchedule(Dose dose) async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => AddScheduleScreen(
          doseId: dose.id,
          doseName: dose.name ?? '${dose.amount} ${dose.unit}',
        ),
      ),
    );

    if (result == true) {
      // Reload doses if a schedule was added
      _loadDoses();
    }
  }

  Future<void> _showDeleteConfirmation(BuildContext context) async {
    final result = await ConfirmationDialog.show(
      context: context,
      title: 'Delete Medication',
      message: 'Are you sure you want to delete ${_medication.name}?',
      confirmText: 'DELETE',
    );

    if (result == true) {
      setState(() => _isLoading = true);

      try {
        await firebaseService.deleteMedication(_medication.id);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Medication deleted successfully'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.pop(context, true); // Return true to indicate deletion
      } catch (e) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error deleting medication: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  // Add a new method that doesn't take a BuildContext parameter
  void _showDeleteConfirmationDialog() {
    _showDeleteConfirmation(context);
  }

  void _showDoseSelectionDialog() {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Select Dose to Schedule'),
          content: SizedBox(
            width: double.maxFinite,
            child: ListView.builder(
              shrinkWrap: true,
              itemCount: _doses.length,
              itemBuilder: (context, index) {
                final dose = _doses[index];
                final displayName = dose.name ?? '${dose.amount} ${dose.unit}';
                
                return ListTile(
                  leading: const Icon(Icons.medication_liquid),
                  title: Text(displayName),
                  onTap: () {
                    Navigator.of(context).pop();
                    _navigateToSchedule(dose);
                  },
                );
              },
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('CANCEL'),
            ),
          ],
        );
      },
    );
  }

  IconData _getMedicationIcon() {
    switch (_medication.type) {
      case MedicationType.tablet:
        return Icons.local_pharmacy;
      case MedicationType.capsule:
        return Icons.medication;
      case MedicationType.injection:
        // Use the new injectionType enum if available
        if (_medication.injectionType != null) {
          switch (_medication.injectionType!) {
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
        // Fallback to legacy fields if injectionType is not available
        else if (_medication.isPreFilled == true) {
          if (_medication.isPrefillPen == true) {
            return Icons.edit;  // Pen icon
          } else {
            return Icons.vaccines;  // Syringe icon
          }
        } else if (_medication.needsReconstitution == true) {
          return Icons.science;
        } else {
          return Icons.water_drop;
        }
      case MedicationType.preFilledSyringe:
        return Icons.vaccines;
      case MedicationType.vialPreMixed:
        return Icons.science;
      case MedicationType.vialPowderedKnown:
        return Icons.science;
      case MedicationType.vialPowderedRecon:
        return Icons.science;
      default:
        return Icons.medication;
    }
  }

  Color _getMedicationColor() {
    switch (_medication.type) {
      case MedicationType.tablet:
        return Colors.blue;
      case MedicationType.capsule:
        return Colors.orange;
      case MedicationType.injection:
        // Use the new injectionType enum if available
        if (_medication.injectionType != null) {
          switch (_medication.injectionType!) {
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
        // Fallback to legacy fields if injectionType is not available
        else if (_medication.isPreFilled == true) {
          if (_medication.isPrefillPen == true) {
            return Colors.green;
          } else {
            return Colors.teal;
          }
        } else if (_medication.needsReconstitution == true) {
          return Colors.purple;
        } else {
          return Colors.indigo;
        }
      case MedicationType.preFilledSyringe:
        return Colors.teal;
      case MedicationType.vialPreMixed:
        return Colors.blue;
      case MedicationType.vialPowderedKnown:
        return Colors.purple;
      case MedicationType.vialPowderedRecon:
        return Colors.deepPurple;
      default:
        return Colors.grey;
    }
  }

  String _getMedicationTypeName() {
    switch (_medication.type) {
      case MedicationType.tablet:
        return 'Tablet';
      case MedicationType.capsule:
        return 'Capsule';
      case MedicationType.injection:
        // Use the new injectionType enum if available
        if (_medication.injectionType != null) {
          switch (_medication.injectionType!) {
            case InjectionType.liquidVial:
              return 'Solution Vial';
            case InjectionType.powderVial:
              return 'Powdered Vial (Needs Reconstitution)';
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
        // Fallback to legacy fields if injectionType is not available
        else if (_medication.isPreFilled == true) {
          if (_medication.isPrefillPen == true) {
            return 'Pre-filled Pen';
          } else {
            return 'Pre-filled Syringe';
          }
        } else if (_medication.needsReconstitution == true) {
          return 'Powdered Vial (Needs Reconstitution)';
        } else {
          return 'Injection Vial';
        }
      case MedicationType.preFilledSyringe:
        return 'Pre-filled Syringe';
      case MedicationType.vialPreMixed:
        return 'Pre-mixed Vial';
      case MedicationType.vialPowderedKnown:
        return 'Powdered Vial (Known Concentration)';
      case MedicationType.vialPowderedRecon:
        return 'Powdered Vial (Recon)';
      default:
        return 'Medication';
    }
  }

  // Get icon for medication type
  IconData _getIconForMedicationType(MedicationType type) {
    switch (type) {
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
      default:
        return Icons.medication;
    }
  }
  
  // Get string representation of medication type
  String _getMedicationTypeString(MedicationType type) {
    switch (type) {
      case MedicationType.tablet:
        return 'Tablet';
      case MedicationType.capsule:
        return 'Capsule';
      case MedicationType.injection:
        if (_medication.injectionType == InjectionType.prefilledSyringe) {
          return 'Pre-filled Syringe';
        } else if (_medication.injectionType == InjectionType.prefilledPen) {
          return 'Pre-filled Pen';
        } else if (_medication.injectionType == InjectionType.powderVial) {
          return 'Powder Vial';
        } else if (_medication.injectionType == InjectionType.liquidVial) {
          return 'Liquid Vial';
        } else if (_medication.injectionType == InjectionType.cartridge) {
          return 'Cartridge';
        } else if (_medication.injectionType == InjectionType.ampule) {
          return 'Ampule';
        } else {
          return 'Injection';
        }
      case MedicationType.preFilledSyringe:
        return 'Pre-filled Syringe';
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
  
  // Build a detail row with label and value
  Widget _buildDetailRow(String label, String value, {Widget? trailing}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Row(
        children: [
          SizedBox(
            width: 100,
            child: Text(
              label,
              style: const TextStyle(
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          Expanded(
            child: Text(value),
          ),
          if (trailing != null) trailing,
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final bool isDarkMode = Theme.of(context).brightness == Brightness.dark;
    
    // Determine color based on medication type
    Color color;
    switch (_medication.type) {
      case MedicationType.tablet:
        color = Colors.blue;
        break;
      case MedicationType.capsule:
        color = Colors.orange;
        break;
      case MedicationType.injection:
        color = Colors.teal;
        break;
      case MedicationType.preFilledSyringe:
        color = Colors.teal;
        break;
      case MedicationType.vialPreMixed:
        color = Colors.blue;
        break;
      case MedicationType.vialPowderedKnown:
        color = Colors.purple;
        break;
      case MedicationType.vialPowderedRecon:
        color = Colors.deepPurple;
        break;
    }
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('Medication Details'),
        actions: [
          IconButton(
            icon: const Icon(Icons.delete),
            onPressed: () => _showDeleteConfirmation(context),
          ),
        ],
      ),
      body: Container(
        decoration: AppDecorations.screenBackground(context),
        height: double.infinity,
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Medication Card with Inventory Management
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Medication Name and Type
                        Row(
                          children: [
                            Icon(
                              _getIconForMedicationType(_medication.type),
                              color: color,
                              size: 24,
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    _medication.name,
                                    style: const TextStyle(
                                      fontSize: 20,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  Text(
                                    _getMedicationTypeString(_medication.type),
                                    style: TextStyle(
                                      fontSize: 14,
                                      color: isDarkMode ? Colors.white70 : Colors.black54,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        
                        const SizedBox(height: 16),
                        const Divider(),
                        const SizedBox(height: 16),
                        
                        // Medication Details
                        _buildDetailRow(
                          'Strength',
                          '${_medication.strength} ${_medication.strengthUnit} per ${_medication.quantityUnit}',
                        ),
                        
                        const SizedBox(height: 8),
                        
                        // Inventory
                        _buildDetailRow(
                          'Current Inventory',
                          '${_medication.currentInventory} ${_medication.quantityUnit}',
                          trailing: ElevatedButton.icon(
                            onPressed: _showRefillDialog,
                            icon: const Icon(Icons.add),
                            label: const Text('REFILL'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: color,
                            ),
                          ),
                        ),
                        
                        const SizedBox(height: 16),
                        
                        // Action Buttons
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                          children: [
                            if (_medication.type == MedicationType.injection && 
                                (_medication.injectionType == InjectionType.powderVial ||
                                (_medication.needsReconstitution ?? false) ||
                                (_medication.injectionType == InjectionType.powderVial)))
                              ElevatedButton.icon(
                                onPressed: _navigateToReconstitutionCalculator,
                                icon: const Icon(Icons.calculate),
                                label: const Text('CALCULATOR'),
                                style: ElevatedButton.styleFrom(
                                  padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 16),
                                  backgroundColor: Colors.teal,
                                ),
                              ),
                            ElevatedButton.icon(
                              onPressed: () {
                                if (_doses.isEmpty) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Text('Please add a dose first before scheduling'),
                                      backgroundColor: Colors.orange,
                                    ),
                                  );
                                } else {
                                  // Show dose selection dialog if there are multiple doses
                                  if (_doses.length > 1) {
                                    _showDoseSelectionDialog();
                                  } else {
                                    // If there's only one dose, use it directly
                                    _navigateToSchedule(_doses[0]);
                                  }
                                }
                              },
                              icon: const Icon(Icons.calendar_today),
                              label: const Text('SCHEDULE'),
                              style: ElevatedButton.styleFrom(
                                padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 16),
                                backgroundColor: Colors.purple,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 24),

                // Help Card for medication management - now collapsible
                PersistentHelpCard(
                  title: 'Managing Your Medication',
                  content: 'This screen helps you track and manage your medication:',
                  icon: Icons.medical_services_outlined,
                  steps: [
                    'Use the Refill button to update your inventory',
                    'Add doses to track your medication schedule',
                    'For injectable medications, use the reconstitution calculator',
                    'Monitor your remaining supply with the inventory tracker',
                  ],
                  storageKey: 'medication_detail_help_dismissed_${_medication.id}',
                  initiallyExpanded: true,
                ),
                
                const SizedBox(height: 16),
                
                // Upcoming Doses Section
                Card(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Upcoming Doses Header
                      Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Row(
                          children: [
                            Icon(
                              Icons.schedule,
                              color: color,
                              size: 24,
                            ),
                            const SizedBox(width: 8),
                            const Text(
                              'Upcoming Doses',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                      
                      // Divider between header and content
                      const Divider(height: 1),
                      
                      // Upcoming Doses Content
                      SizedBox(
                        height: 300, // Fixed height for the upcoming doses list
                        child: UpcomingDosesWidget(
                          medicationId: _medication.id,
                          daysToShow: 14, // Show doses for next 2 weeks
                          emptyMessage: 'No upcoming doses scheduled for this medication',
                        ),
                      ),
                    ],
                  ),
                ),
                
                const SizedBox(height: 16),
                
                // Doses Section
                Card(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Doses Header with Add Button
                      Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Row(
                              children: [
                                Icon(
                                  Icons.medication_liquid,
                                  color: color,
                                  size: 24,
                                ),
                                const SizedBox(width: 8),
                                const Text(
                                  'Doses',
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                            ElevatedButton.icon(
                              onPressed: _navigateToAddDose,
                              icon: const Icon(Icons.add),
                              label: const Text('ADD DOSE'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: color,
                              ),
                            ),
                          ],
                        ),
                      ),
                      
                      // Divider between header and content
                      const Divider(height: 1),
                      
                      // Doses Content
                      if (_isLoadingDoses)
                        const Padding(
                          padding: EdgeInsets.all(24.0),
                          child: Center(
                            child: CircularProgressIndicator(),
                          ),
                        )
                      else if (_doses.isEmpty)
                        const Padding(
                          padding: EdgeInsets.all(24.0),
                          child: Center(
                            child: Text(
                              'No doses added yet',
                              style: TextStyle(
                                fontSize: 16,
                                fontStyle: FontStyle.italic,
                                color: Colors.grey,
                              ),
                            ),
                          ),
                        )
                      else
                        ListView.separated(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          itemCount: _doses.length,
                          separatorBuilder: (context, index) => const Divider(height: 1),
                          itemBuilder: (context, index) {
                            return _buildDoseListItem(_doses[index]);
                          },
                        ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildDoseListItem(Dose dose) {
    // Get the display name for the dose
    String displayName = dose.name ?? '${dose.amount} ${dose.unit}';
    
    // Ensure dose amount is valid and displayed properly
    String doseAmountDisplay;
    try {
      // Format the dose amount to remove trailing zeros
      double displayAmount = dose.amount;
      
      // Format the display string
      if (displayAmount == displayAmount.toInt()) {
        doseAmountDisplay = "${displayAmount.toInt()} ${dose.unit}";
      } else {
        // Remove trailing zeros
        String amountStr = displayAmount.toString().replaceAll(RegExp(r'\.0+$'), '');
        amountStr = amountStr.replaceAll(RegExp(r'(\.\d*?)0+$'), r'$1');
        doseAmountDisplay = "$amountStr ${dose.unit}";
      }
    } catch (e) {
      // Fallback if there's an issue with the dose amount
      doseAmountDisplay = "${dose.unit} dose";
    }

    return ListTile(
      title: Text(
        displayName,
        style: const TextStyle(
          fontWeight: FontWeight.bold,
        ),
      ),
      subtitle: Text(doseAmountDisplay),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          IconButton(
            icon: const Icon(Icons.calendar_month),
            tooltip: 'Schedule',
            onPressed: () => _navigateToSchedule(dose),
          ),
          IconButton(
            icon: const Icon(Icons.edit),
            tooltip: 'Edit',
            onPressed: () => _navigateToEditDose(dose),
          ),
        ],
      ),
      onTap: () => _navigateToEditDose(dose),
    );
  }
} 