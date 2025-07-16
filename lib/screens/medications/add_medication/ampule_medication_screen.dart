import 'package:flutter/material.dart';
import '../../../models/medication.dart';
import '../../../models/injection_type.dart';
import '../../../widgets/help_card.dart';
import '../../../theme/app_decorations.dart';
import '../../../widgets/medication_confirmation_dialog.dart';
import 'base_injection_medication_screen.dart';

class AmpuleMedicationScreen extends BaseInjectionMedicationScreen {
  const AmpuleMedicationScreen({super.key});

  @override
  State<AmpuleMedicationScreen> createState() => _AmpuleMedicationScreenState();
}

class _AmpuleMedicationScreenState extends BaseInjectionMedicationScreenState<AmpuleMedicationScreen> {
  // Additional controllers specific to ampules
  final TextEditingController _storageConditionsController = TextEditingController();
  bool _requiresFilterNeedle = false;
  
  @override
  void initState() {
    super.initState();
    // Update quantity unit for ampules
    quantityUnit = 'ampules';
  }
  
  @override
  void dispose() {
    _storageConditionsController.dispose();
    super.dispose();
  }
  
  @override
  InjectionType get injectionType => InjectionType.ampule;
  
  @override
  String get injectionTypeName => 'Ampule';
  
  @override
  IconData get injectionTypeIcon => Icons.water_drop;
  
  @override
  Color get injectionTypeColor => Colors.cyan;
  
  @override
  List<Widget> buildSpecificFields() {
    return [
      // Ampule-specific information
      const Text(
        'Ampule Information',
        style: TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.bold,
        ),
      ),
      const SizedBox(height: 8),
      
      // Filter needle requirement
      SwitchListTile(
        title: const Text('Requires Filter Needle'),
        subtitle: const Text('Use filter needle when drawing up medication'),
        value: _requiresFilterNeedle,
        onChanged: (value) {
          setState(() {
            _requiresFilterNeedle = value;
          });
        },
        contentPadding: EdgeInsets.zero,
        tileColor: Theme.of(context).cardColor.withOpacity(0.7),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
      const SizedBox(height: 16),
      
      // Storage conditions
      TextFormField(
        controller: _storageConditionsController,
        decoration: AppDecorations.inputField(
          hintText: 'E.g., Refrigerate, protect from light',
          labelText: 'Storage Conditions',
        ),
        maxLines: 2,
      ),
      const SizedBox(height: 16),
      
      // Help card with information about ampules
      CompactHelpCard(
        title: 'About Medication Ampules',
        content: 'Ampules are sealed glass containers for single-use medications:',
        icon: Icons.water_drop,
        steps: [
          'Break open at the neck to access medication',
          'Often requires a filter needle to draw up medication',
          'Single-use only - discard any unused portion',
          'Take care to avoid glass fragments when opening'
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
    // Create a notes field with ampule-specific information
    final List<String> ampuleInfo = [];
    
    if (_requiresFilterNeedle) {
      ampuleInfo.add('Requires filter needle');
    }
    
    if (_storageConditionsController.text.isNotEmpty) {
      ampuleInfo.add('Storage: ${_storageConditionsController.text}');
    }
    
    String? notes;
    if (ampuleInfo.isNotEmpty) {
      notes = ampuleInfo.join(', ');
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
      isPreFilled: false,
      isPrefillPen: false,
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
    
    // Add filter needle requirement if selected
    if (_requiresFilterNeedle) {
      items.insert(2, ConfirmationItem(
        label: 'Special Handling:',
        value: 'Requires filter needle',
        icon: Icons.filter_alt,
        color: Colors.red[400]!,
      ));
    }
    
    // Add storage conditions if provided
    if (_storageConditionsController.text.isNotEmpty) {
      items.insert(_requiresFilterNeedle ? 3 : 2, ConfirmationItem(
        label: 'Storage:',
        value: _storageConditionsController.text,
        icon: Icons.thermostat,
        color: Colors.blue[700]!,
      ));
    }
    
    return items;
  }
} 