import 'package:flutter/material.dart';
import '../../../models/medication.dart';
import '../../../models/injection_type.dart';
import '../../../widgets/help_card.dart';
import '../../../theme/app_decorations.dart';
import '../../../widgets/medication_confirmation_dialog.dart';
import 'base_injection_medication_screen.dart';

class PrefilledPenMedicationScreen extends BaseInjectionMedicationScreen {
  const PrefilledPenMedicationScreen({super.key});

  @override
  State<PrefilledPenMedicationScreen> createState() => _PrefilledPenMedicationScreenState();
}

class _PrefilledPenMedicationScreenState extends BaseInjectionMedicationScreenState<PrefilledPenMedicationScreen> {
  // Additional controllers specific to pre-filled pens
  final TextEditingController _maxDoseController = TextEditingController();
  final TextEditingController _doseIncrementController = TextEditingController();
  bool _hasAdjustableDose = true;
  
  @override
  void initState() {
    super.initState();
    // Update quantity unit for pre-filled pens
    quantityUnit = 'pens';
  }
  
  @override
  void dispose() {
    _maxDoseController.dispose();
    _doseIncrementController.dispose();
    super.dispose();
  }
  
  @override
  InjectionType get injectionType => InjectionType.prefilledPen;
  
  @override
  String get injectionTypeName => 'Pre-filled Pen';
  
  @override
  IconData get injectionTypeIcon => Icons.edit;
  
  @override
  Color get injectionTypeColor => Colors.green;
  
  @override
  List<Widget> buildSpecificFields() {
    return [
      // Dose adjustment settings
      const Text(
        'Pen Settings',
        style: TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.bold,
        ),
      ),
      const SizedBox(height: 8),
      
      // Adjustable dose toggle
      SwitchListTile(
        title: const Text('Adjustable Dose'),
        subtitle: const Text('Pen allows setting different dose amounts'),
        value: _hasAdjustableDose,
        onChanged: (value) {
          setState(() {
            _hasAdjustableDose = value;
            if (!value) {
              _maxDoseController.clear();
              _doseIncrementController.clear();
            }
          });
        },
        contentPadding: EdgeInsets.zero,
        tileColor: Theme.of(context).cardColor.withOpacity(0.7),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
      const SizedBox(height: 16),
      
      // Dose adjustment fields (only if adjustable)
      if (_hasAdjustableDose) ...[
        Row(
          children: [
            // Maximum dose
            Expanded(
              child: TextFormField(
                controller: _maxDoseController,
                decoration: AppDecorations.inputField(
                  hintText: 'Max dose (e.g., 80)',
                  labelText: 'Maximum Dose',
                  suffixText: strengthUnit,
                ),
                keyboardType: TextInputType.number,
              ),
            ),
            const SizedBox(width: 16),
            // Dose increment
            Expanded(
              child: TextFormField(
                controller: _doseIncrementController,
                decoration: AppDecorations.inputField(
                  hintText: 'Increment (e.g., 1)',
                  labelText: 'Dose Increment',
                  suffixText: strengthUnit,
                ),
                keyboardType: TextInputType.number,
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
      ],
      
      // Help card with information about pre-filled pens
      CompactHelpCard(
        title: 'About Pre-filled Pens',
        content: 'Pre-filled pens are injection devices with pre-loaded medication:',
        icon: Icons.edit,
        steps: [
          'Easy to use with minimal training',
          'May have fixed or adjustable dose settings',
          'Often used for insulin, growth hormone, and other regular injections',
          'Typically requires changing needles before each use'
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
    // Create a notes field with pen specifications if provided
    String? notes;
    if (_hasAdjustableDose) {
      final List<String> penDetails = [];
      
      if (_maxDoseController.text.isNotEmpty) {
        penDetails.add('Max dose: ${_maxDoseController.text} $strengthUnit');
      }
      
      if (_doseIncrementController.text.isNotEmpty) {
        penDetails.add('Increment: ${_doseIncrementController.text} $strengthUnit');
      }
      
      if (penDetails.isNotEmpty) {
        notes = 'Pen details: ${penDetails.join(', ')}';
      }
    } else {
      notes = 'Fixed dose pen';
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
      isPrefillPen: true,
      needsReconstitution: false,
      routeOfAdministration: routeOfAdministration,
      notes: notes,
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
    
    // Add pen specifications
    if (_hasAdjustableDose) {
      final List<String> penSpecs = ['Adjustable dose'];
      
      if (_maxDoseController.text.isNotEmpty) {
        penSpecs.add('Max: ${_maxDoseController.text} $strengthUnit');
      }
      
      if (_doseIncrementController.text.isNotEmpty) {
        penSpecs.add('Steps: ${_doseIncrementController.text} $strengthUnit');
      }
      
      items.insert(2, ConfirmationItem(
        label: 'Pen Type:',
        value: penSpecs.join(', '),
        icon: Icons.tune,
        color: Colors.green,
      ));
    } else {
      items.insert(2, ConfirmationItem(
        label: 'Pen Type:',
        value: 'Fixed dose pen',
        icon: Icons.lock,
        color: Colors.green,
      ));
    }
    
    return items;
  }
} 