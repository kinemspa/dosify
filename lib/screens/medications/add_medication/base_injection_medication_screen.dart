import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';
import '../../../models/medication.dart';
import '../../../services/firebase_service.dart';
import '../../../services/service_locator.dart';
import '../../../theme/app_decorations.dart';
import '../../../widgets/number_input_field.dart';
import '../../../widgets/input_field_row.dart';
import '../../../widgets/medication_confirmation_dialog.dart';
import '../../base_service_screen.dart';

/// Base abstract class for all injection medication screens
abstract class BaseInjectionMedicationScreen extends BaseServiceScreen {
  const BaseInjectionMedicationScreen({super.key});
}

/// Base state class for injection medication screens
abstract class BaseInjectionMedicationScreenState<T extends BaseInjectionMedicationScreen> extends BaseServiceScreenState<T> {
  // Common form controllers
  final formKey = GlobalKey<FormState>();
  final nameController = TextEditingController();
  final strengthController = TextEditingController();
  final quantityController = TextEditingController();
  final inventoryController = TextEditingController();
  
  // Common properties
  String strengthUnit = 'mg';
  String quantityUnit = 'mL';
  bool isLoading = false;
  
  // Injection type that this screen handles
  InjectionType get injectionType;
  
  // Display name for this injection type
  String get injectionTypeName;
  
  // Icon for this injection type
  IconData get injectionTypeIcon;
  
  // Color for this injection type
  Color get injectionTypeColor;
  
  // Route of administration
  String? routeOfAdministration;
  
  // Routes of administration options
  final List<String> routesOfAdministration = [
    'Subcutaneous (SC)',
    'Intramuscular (IM)',
    'Intravenous (IV)',
    'Intradermal (ID)',
    'Intra-articular',
    'Intrathecal',
    'Multiple routes'
  ];

  @override
  void dispose() {
    nameController.dispose();
    strengthController.dispose();
    quantityController.dispose();
    inventoryController.dispose();
    super.dispose();
  }
  
  // Common save medication method
  Future<void> saveMedication() async {
    if (!formKey.currentState!.validate()) {
      return;
    }
    
    // Validate any additional fields specific to this injection type
    if (!validateSpecificFields()) {
      return;
    }

    setState(() {
      isLoading = true;
    });

    try {
      // Generate a unique ID
      final uuid = const Uuid().v4();
      
      // Parse strength value
      final double strength = double.parse(strengthController.text);
      
      // Parse quantity value
      final double quantity = double.parse(quantityController.text);
      
      // Parse inventory value
      final double inventory = double.parse(inventoryController.text);
      
      // Create medication object with common fields
      final medication = createMedicationObject(
        uuid: uuid,
        strength: strength,
        quantity: quantity,
        inventory: inventory,
      );
      
      // Save to Firebase
      await firebaseService.addMedication(medication);
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Medication saved successfully'),
            backgroundColor: Colors.green,
          ),
        );
        
        // Navigate back with success result
        Navigator.pop(context, true);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error saving medication: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          isLoading = false;
        });
      }
    }
  }
  
  // Method to create the medication object - to be implemented by subclasses
  Medication createMedicationObject({
    required String uuid,
    required double strength,
    required double quantity,
    required double inventory,
  });
  
  // Method to validate fields specific to this injection type
  bool validateSpecificFields() {
    return true; // Default implementation
  }
  
  // Common method to show confirmation dialog
  Future<void> showConfirmationDialog() async {
    // Parse values
    final name = nameController.text;
    final strength = double.tryParse(strengthController.text) ?? 0;
    final inventory = double.tryParse(inventoryController.text) ?? 0;

    // Calculate total medicine
    final double totalMedicine = strength * inventory;
    
    // Format total medicine string with appropriate units
    String totalMedicineStr;
    if (strengthUnit == 'mcg' && totalMedicine >= 1000) {
      // Convert to mg if possible and show both
      final double mgValue = totalMedicine / 1000;
      totalMedicineStr = '${totalMedicine.toInt()} mcg (${mgValue.toStringAsFixed(mgValue.truncateToDouble() == mgValue ? 0 : 2)} mg)';
    } else if (strengthUnit == 'mg' && totalMedicine >= 1000) {
      // Convert to g if possible and show both
      final double gValue = totalMedicine / 1000;
      totalMedicineStr = '${totalMedicine.toInt()} mg (${gValue.toStringAsFixed(gValue.truncateToDouble() == gValue ? 0 : 2)} g)';
    } else {
      // Format to remove trailing zeros
      if (totalMedicine == totalMedicine.toInt()) {
        totalMedicineStr = '${totalMedicine.toInt()} $strengthUnit';
      } else {
        totalMedicineStr = '$totalMedicine $strengthUnit';
      }
    }

    // Get confirmation items
    final List<ConfirmationItem> confirmationItems = getConfirmationItems(
      name: name,
      strength: strength,
      inventory: inventory,
      totalMedicineStr: totalMedicineStr,
    );

    // Show confirmation dialog
    final shouldSave = await MedicationConfirmationDialog.show(
      context: context,
      title: 'Save $name?',
      items: confirmationItems,
    );
    
    if (shouldSave == true) {
      saveMedication();
    }
  }
  
  // Method to get confirmation items - can be overridden by subclasses
  List<ConfirmationItem> getConfirmationItems({
    required String name,
    required double strength,
    required double inventory,
    required String totalMedicineStr,
  }) {
    return [
      ConfirmationItem(
        label: 'Medication Name:',
        value: name,
        icon: Icons.medication,
        color: Colors.blue,
        subtitle: 'Type: $injectionTypeName',
      ),
      ConfirmationItem(
        label: 'Strength:',
        value: '$strength $strengthUnit per ${getPackagingUnit()}',
        icon: Icons.fitness_center,
        color: Colors.green,
      ),
      if (routeOfAdministration != null)
        ConfirmationItem(
          label: 'Administration:',
          value: routeOfAdministration!,
          icon: Icons.medical_services,
          color: Colors.teal,
        ),
      ConfirmationItem(
        label: 'In Stock:',
        value: '${inventory.toInt()} $quantityUnit',
        icon: Icons.inventory_2,
        color: Colors.orange,
      ),
      ConfirmationItem(
        label: 'Total Medicine:',
        value: 'You have $totalMedicineStr total',
        icon: Icons.calculate,
        color: Colors.purple,
      ),
    ];
  }
  
  // Get the packaging unit name based on injection type
  String getPackagingUnit() {
    switch (injectionType) {
      case InjectionType.liquidVial:
      case InjectionType.powderVial:
        return 'vial';
      case InjectionType.prefilledSyringe:
        return 'syringe';
      case InjectionType.prefilledPen:
        return 'pen';
      case InjectionType.cartridge:
        return 'cartridge';
      case InjectionType.ampule:
        return 'ampule';
    }
  }
  
  // Build common UI elements
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Dosify'),
            Text(
              'Add $injectionTypeName',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Theme.of(context).colorScheme.onPrimary.withOpacity(0.8),
              ),
            ),
          ],
        ),
        centerTitle: false,
        titleSpacing: 16,
        automaticallyImplyLeading: true,
      ),
      body: Container(
        decoration: AppDecorations.screenBackground(context),
        height: double.infinity,
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Form(
              key: formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Medication Name
                  const Text(
                    'Medication Name',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  TextFormField(
                    controller: nameController,
                    decoration: AppDecorations.inputField(
                      hintText: 'Enter medication name',
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please enter medication name';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 24),
                  
                  // Route of Administration
                  const Text(
                    'Route of Administration',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  DropdownButtonFormField<String>(
                    value: routeOfAdministration,
                    decoration: AppDecorations.inputField(
                      hintText: 'Select route of administration',
                    ),
                    items: routesOfAdministration.map((String route) {
                      return DropdownMenuItem<String>(
                        value: route,
                        child: Text(route),
                      );
                    }).toList(),
                    onChanged: (String? newValue) {
                      setState(() {
                        routeOfAdministration = newValue;
                      });
                    },
                  ),
                  const SizedBox(height: 24),
                  
                  // Strength
                  InputFieldRow(
                    label: 'Strength',
                    controller: strengthController,
                    unitValue: strengthUnit,
                    unitOptions: const ['mg', 'mcg', 'IU'],
                    onUnitChanged: (value) {
                      if (value != null) {
                        setState(() {
                          strengthUnit = value;
                        });
                      }
                    },
                    incrementValue: 0.5,
                    allowDecimals: true,
                    decimalPlaces: 2,
                  ),
                  const SizedBox(height: 16),
                  
                  // Volume/Size
                  InputFieldRow(
                    label: 'Volume/Size',
                    controller: quantityController,
                    unitValue: 'mL',
                    unitOptions: const ['mL'],
                    onUnitChanged: (_) {}, // Volume unit is always mL
                    incrementValue: 0.1,
                    allowDecimals: true,
                    decimalPlaces: 2,
                  ),
                  const SizedBox(height: 16),
                  
                  // Add specific fields for each injection type
                  ...buildSpecificFields(),
                  
                  // Inventory
                  NumberInputField(
                    controller: inventoryController,
                    label: 'Stock',
                    hintText: 'Enter the number of',
                    suffixText: quantityUnit,
                    allowDecimals: false,
                    showIncrementButtons: true,
                    incrementAmount: 1.0,
                    minValue: 0,
                    labelColor: Theme.of(context).brightness == Brightness.dark ? Colors.white : Colors.black87,
                  ),
                  const SizedBox(height: 32),
                  
                  // Save Button
                  ElevatedButton(
                    onPressed: isLoading ? null : showConfirmationDialog,
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                    ),
                    child: isLoading
                        ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : const Text('SAVE MEDICATION'),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
  
  // Method to build fields specific to this injection type
  List<Widget> buildSpecificFields();
} 