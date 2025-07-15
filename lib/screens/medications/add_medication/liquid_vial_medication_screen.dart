import 'package:flutter/material.dart';
import '../../../models/medication.dart';
import '../../../widgets/help_card.dart';
import '../../../theme/app_decorations.dart';
import '../../../widgets/medication_confirmation_dialog.dart';
import 'base_injection_medication_screen.dart';

class LiquidVialMedicationScreen extends BaseInjectionMedicationScreen {
  const LiquidVialMedicationScreen({super.key});

  @override
  State<LiquidVialMedicationScreen> createState() => _LiquidVialMedicationScreenState();
}

class _LiquidVialMedicationScreenState extends BaseInjectionMedicationScreenState<LiquidVialMedicationScreen> {
  // Additional controllers specific to liquid vials
  final TextEditingController _concentrationController = TextEditingController();
  
  @override
  void dispose() {
    _concentrationController.dispose();
    super.dispose();
  }
  
  @override
  InjectionType get injectionType => InjectionType.liquidVial;
  
  @override
  String get injectionTypeName => 'Solution Vial';
  
  @override
  IconData get injectionTypeIcon => Icons.water_drop;
  
  @override
  Color get injectionTypeColor => Colors.blue;
  
  @override
  List<Widget> buildSpecificFields() {
    return [
      // Concentration info (optional)
      const Text(
        'Concentration (Optional)',
        style: TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.bold,
        ),
      ),
      const SizedBox(height: 8),
      TextFormField(
        controller: _concentrationController,
        decoration: AppDecorations.inputField(
          hintText: 'Enter concentration (e.g., 10 mg/mL)',
        ),
        keyboardType: TextInputType.text,
      ),
      const SizedBox(height: 16),
      
      // Help card with information about liquid vials
      CompactHelpCard(
        title: 'About Solution Vials',
        content: 'Solution vials contain medication in liquid form that is ready to use:',
        icon: Icons.water_drop,
        steps: [
          'No reconstitution needed',
          'Withdraw the prescribed dose directly',
          'Store according to manufacturer guidelines',
          'Check for clarity and absence of particles before use'
        ],
      ),
      const SizedBox(height: 16),
    ];
  }
  
  @override
  Medication createMedicationObject({
    required String uuid,
    required double strength,
    required double quantity,
    required double inventory,
  }) {
    return Medication(
      id: uuid,
      name: nameController.text,
      type: MedicationType.injection,
      strength: strength,
      strengthUnit: strengthUnit,
      quantity: quantity,
      quantityUnit: quantityUnit,
      currentInventory: inventory,
      lastInventoryUpdate: DateTime.now(),
      // Injection-specific fields
      injectionType: injectionType,
      isPreFilled: false,
      isPrefillPen: false,
      needsReconstitution: false,
      routeOfAdministration: routeOfAdministration,
    );
  }
  
  @override
  List<ConfirmationItem> getConfirmationItems({
    required String name,
    required double strength,
    required double inventory,
    required String totalMedicineStr,
  }) {
    final items = super.getConfirmationItems(
      name: name,
      strength: strength,
      inventory: inventory,
      totalMedicineStr: totalMedicineStr,
    );
    
    // Add concentration info if provided
    if (_concentrationController.text.isNotEmpty) {
      items.insert(2, ConfirmationItem(
        label: 'Concentration:',
        value: _concentrationController.text,
        icon: Icons.science,
        color: Colors.purple,
      ));
    }
    
    return items;
  }
} 