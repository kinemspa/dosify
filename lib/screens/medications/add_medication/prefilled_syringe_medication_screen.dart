import 'package:flutter/material.dart';
import '../../../models/medication.dart';
import '../../../models/injection_type.dart';
import '../../../widgets/help_card.dart';
import '../../../theme/app_decorations.dart';
import '../../../widgets/medication_confirmation_dialog.dart';
import 'base_injection_medication_screen.dart';

class PrefilledSyringeMedicationScreen extends BaseInjectionMedicationScreen {
  const PrefilledSyringeMedicationScreen({super.key});

  @override
  State<PrefilledSyringeMedicationScreen> createState() => _PrefilledSyringeMedicationScreenState();
}

class _PrefilledSyringeMedicationScreenState extends BaseInjectionMedicationScreenState<PrefilledSyringeMedicationScreen> {
  // Additional controllers specific to pre-filled syringes
  final TextEditingController _needleLengthController = TextEditingController();
  final TextEditingController _needleGaugeController = TextEditingController();
  
  @override
  void initState() {
    super.initState();
    // Update quantity unit for pre-filled syringes
    quantityUnit = 'syringes';
  }
  
  @override
  void dispose() {
    _needleLengthController.dispose();
    _needleGaugeController.dispose();
    super.dispose();
  }
  
  @override
  InjectionType get injectionType => InjectionType.prefilledSyringe;
  
  @override
  String get injectionTypeName => 'Pre-filled Syringe';
  
  @override
  IconData get injectionTypeIcon => Icons.vaccines;
  
  @override
  Color get injectionTypeColor => Colors.teal;
  
  @override
  List<Widget> buildSpecificFields() {
    return [
      // Needle specifications (optional)
      const Text(
        'Needle Specifications (Optional)',
        style: TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.bold,
        ),
      ),
      const SizedBox(height: 8),
      Row(
        children: [
          // Needle length
          Expanded(
            child: TextFormField(
              controller: _needleLengthController,
              decoration: AppDecorations.inputField(
                hintText: 'Length (e.g., 1/2 inch)',
                labelText: 'Needle Length',
              ),
              keyboardType: TextInputType.text,
            ),
          ),
          const SizedBox(width: 16),
          // Needle gauge
          Expanded(
            child: TextFormField(
              controller: _needleGaugeController,
              decoration: AppDecorations.inputField(
                hintText: 'Gauge (e.g., 29G)',
                labelText: 'Needle Gauge',
              ),
              keyboardType: TextInputType.text,
            ),
          ),
        ],
      ),
      const SizedBox(height: 16),
      
      // Help card with information about pre-filled syringes
      CompactHelpCard(
        title: 'About Pre-filled Syringes',
        content: 'Pre-filled syringes contain a ready-to-use dose of medication:',
        icon: Icons.vaccines,
        steps: [
          'No preparation needed before administration',
          'Check for clarity and expiration date before use',
          'Follow proper injection technique for the prescribed route',
          'Dispose of used syringes in a sharps container'
        ],
      ),
      const SizedBox(height: 16),
    ];
  }
  
  @override
  Medication createMedicationObject({
    required String uuid,
    required String name,
    required double strength,
    required double quantity,
    required double inventory,
  }) {
    // Create a notes field with needle specifications if provided
    String? notes;
    if (_needleLengthController.text.isNotEmpty || _needleGaugeController.text.isNotEmpty) {
      final needleLength = _needleLengthController.text.isNotEmpty ? 'Length: ${_needleLengthController.text}' : '';
      final needleGauge = _needleGaugeController.text.isNotEmpty ? 'Gauge: ${_needleGaugeController.text}' : '';
      notes = [needleLength, needleGauge].where((item) => item.isNotEmpty).join(', ');
      if (notes.isNotEmpty) {
        notes = 'Needle: $notes';
      }
    }
    
    return Medication(
      id: uuid,
      name: name,
      type: MedicationType.injection,
      strength: strength,
      strengthUnit: strengthUnit,
      tabletsInStock: quantity,
      quantityUnit: quantityUnit,
      currentInventory: inventory,
      lastInventoryUpdate: DateTime.now(),
      // Injection-specific fields
      injectionType: injectionType,
      isPreFilled: true,
      isPrefillPen: false,
      needsReconstitution: false,
      routeOfAdministration: routeOfAdministration,
      notes: _needleGaugeController.text.isNotEmpty ? 'Needle gauge: ${_needleGaugeController.text}' : null,
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
    
    // Add needle specifications if provided
    if (_needleLengthController.text.isNotEmpty || _needleGaugeController.text.isNotEmpty) {
      final needleSpecs = <String>[];
      if (_needleLengthController.text.isNotEmpty) {
        needleSpecs.add('Length: ${_needleLengthController.text}');
      }
      if (_needleGaugeController.text.isNotEmpty) {
        needleSpecs.add('Gauge: ${_needleGaugeController.text}');
      }
      
      items.insert(2, ConfirmationItem(
        label: 'Needle:',
        value: needleSpecs.join(', '),
        icon: Icons.straighten,
        color: Colors.grey[700]!,
      ));
    }
    
    return items;
  }
} 