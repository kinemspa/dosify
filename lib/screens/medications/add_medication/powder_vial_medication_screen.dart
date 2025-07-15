import 'package:flutter/material.dart';
import '../../../models/medication.dart';
import '../../../widgets/help_card.dart';
import '../../../theme/app_decorations.dart';
import '../../../widgets/medication_confirmation_dialog.dart';
import '../tools/reconstitution_calculator_screen.dart';
import 'base_injection_medication_screen.dart';

class PowderVialMedicationScreen extends BaseInjectionMedicationScreen {
  const PowderVialMedicationScreen({super.key});

  @override
  State<PowderVialMedicationScreen> createState() => _PowderVialMedicationScreenState();
}

class _PowderVialMedicationScreenState extends BaseInjectionMedicationScreenState<PowderVialMedicationScreen> {
  // Additional controllers specific to powder vials
  final TextEditingController _reconVolumeController = TextEditingController();
  final TextEditingController _diluentController = TextEditingController();
  double? _concentrationAfterReconstitution;
  
  @override
  void dispose() {
    _reconVolumeController.dispose();
    _diluentController.dispose();
    super.dispose();
  }
  
  @override
  InjectionType get injectionType => InjectionType.powderVial;
  
  @override
  String get injectionTypeName => 'Powdered Vial';
  
  @override
  IconData get injectionTypeIcon => Icons.science;
  
  @override
  Color get injectionTypeColor => Colors.purple;
  
  @override
  bool validateSpecificFields() {
    if (_reconVolumeController.text.isEmpty || _concentrationAfterReconstitution == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please calculate reconstitution volume first'),
          backgroundColor: Colors.red,
        ),
      );
      return false;
    }
    return true;
  }
  
  Future<void> _navigateToReconstitutionCalculator() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ReconstitutionCalculatorScreen(
          initialVialStrength: double.tryParse(strengthController.text),
          initialVialStrengthUnit: strengthUnit,
          initialVialSize: double.tryParse(quantityController.text),
        ),
      ),
    );
    
    if (result != null && result is Map<String, dynamic>) {
      setState(() {
        _reconVolumeController.text = result['reconVolume'].toString();
        _concentrationAfterReconstitution = result['concentration'];
      });
    }
  }
  
  @override
  List<Widget> buildSpecificFields() {
    return [
      // Reconstitution Section
      const Text(
        'Reconstitution',
        style: TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.bold,
        ),
      ),
      const SizedBox(height: 8),
      Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Theme.of(context).cardColor.withOpacity(0.8),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Diluent field
            TextFormField(
              controller: _diluentController,
              decoration: AppDecorations.inputField(
                hintText: 'Diluent (e.g., Sterile Water, Saline)',
                labelText: 'Diluent',
              ),
            ),
            const SizedBox(height: 16),
            
            // Reconstitution volume
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: _reconVolumeController,
                    readOnly: true,
                    decoration: AppDecorations.inputField(
                      hintText: 'Reconstitution volume',
                      suffixText: 'mL',
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                ElevatedButton(
                  onPressed: strengthController.text.isEmpty || quantityController.text.isEmpty
                      ? null
                      : _navigateToReconstitutionCalculator,
                  child: const Text('Calculate'),
                ),
              ],
            ),
            const SizedBox(height: 8),
            if (_concentrationAfterReconstitution != null)
              Text(
                'Final concentration: ${_concentrationAfterReconstitution!.toStringAsFixed(2)} $strengthUnit/mL',
                style: TextStyle(
                  color: Theme.of(context).textTheme.bodyMedium?.color,
                ),
              ),
          ],
        ),
      ),
      const SizedBox(height: 16),
      
      // Help card with information about powder vials
      CompactHelpCard(
        title: 'About Powdered Vials',
        content: 'Powdered vials contain medication that needs to be reconstituted before use:',
        icon: Icons.science,
        steps: [
          'Use the calculator to determine proper reconstitution volume',
          'Add diluent slowly to avoid foaming',
          'Swirl gently to dissolve - do not shake',
          'Use within the recommended time after reconstitution'
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
      needsReconstitution: true,
      reconstitutionVolume: double.tryParse(_reconVolumeController.text),
      reconstitutionVolumeUnit: 'mL',
      concentrationAfterReconstitution: _concentrationAfterReconstitution,
      routeOfAdministration: routeOfAdministration,
      diluent: _diluentController.text.isNotEmpty ? _diluentController.text : null,
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
    
    // Add reconstitution info
    items.insert(2, ConfirmationItem(
      label: 'Reconstitution:',
      value: 'Add ${_reconVolumeController.text} mL to get ${_concentrationAfterReconstitution!.toStringAsFixed(2)} $strengthUnit/mL',
      icon: Icons.science,
      color: Colors.purple,
    ));
    
    // Add diluent info if provided
    if (_diluentController.text.isNotEmpty) {
      items.insert(3, ConfirmationItem(
        label: 'Diluent:',
        value: _diluentController.text,
        icon: Icons.water_drop,
        color: Colors.cyan,
      ));
    }
    
    return items;
  }
} 