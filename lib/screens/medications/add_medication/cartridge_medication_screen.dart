import 'package:flutter/material.dart';
import '../../../models/medication.dart';
import '../../../widgets/help_card.dart';
import '../../../theme/app_decorations.dart';
import '../../../widgets/medication_confirmation_dialog.dart';
import 'base_injection_medication_screen.dart';

class CartridgeMedicationScreen extends BaseInjectionMedicationScreen {
  const CartridgeMedicationScreen({super.key});

  @override
  State<CartridgeMedicationScreen> createState() => _CartridgeMedicationScreenState();
}

class _CartridgeMedicationScreenState extends BaseInjectionMedicationScreenState<CartridgeMedicationScreen> {
  // Additional controllers specific to cartridges
  final TextEditingController _deviceController = TextEditingController();
  final TextEditingController _compatibleNeedlesController = TextEditingController();
  
  @override
  void initState() {
    super.initState();
    // Update quantity unit for cartridges
    quantityUnit = 'cartridges';
  }
  
  @override
  void dispose() {
    _deviceController.dispose();
    _compatibleNeedlesController.dispose();
    super.dispose();
  }
  
  @override
  InjectionType get injectionType => InjectionType.cartridge;
  
  @override
  String get injectionTypeName => 'Cartridge';
  
  @override
  IconData get injectionTypeIcon => Icons.battery_std;
  
  @override
  Color get injectionTypeColor => Colors.amber;
  
  @override
  List<Widget> buildSpecificFields() {
    return [
      // Cartridge compatibility information
      const Text(
        'Compatibility Information',
        style: TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.bold,
        ),
      ),
      const SizedBox(height: 8),
      
      // Compatible device
      TextFormField(
        controller: _deviceController,
        decoration: AppDecorations.inputField(
          hintText: 'Enter compatible device(s)',
          labelText: 'Compatible Device',
        ),
      ),
      const SizedBox(height: 16),
      
      // Compatible needles
      TextFormField(
        controller: _compatibleNeedlesController,
        decoration: AppDecorations.inputField(
          hintText: 'Enter compatible needle types',
          labelText: 'Compatible Needles',
        ),
      ),
      const SizedBox(height: 16),
      
      // Help card with information about cartridges
      CompactHelpCard(
        title: 'About Medication Cartridges',
        content: 'Cartridges are replaceable medication containers for reusable pen devices:',
        icon: Icons.battery_std,
        steps: [
          'Must be used with a compatible injection pen device',
          'Allows for multiple doses from a single cartridge',
          'Requires changing needles before each injection',
          'More economical than pre-filled pens for frequent users'
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
    // Create a notes field with compatibility information if provided
    String? notes;
    final List<String> compatInfo = [];
    
    if (_deviceController.text.isNotEmpty) {
      compatInfo.add('Device: ${_deviceController.text}');
    }
    
    if (_compatibleNeedlesController.text.isNotEmpty) {
      compatInfo.add('Needles: ${_compatibleNeedlesController.text}');
    }
    
    if (compatInfo.isNotEmpty) {
      notes = compatInfo.join(', ');
    }
    
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
      isPreFilled: false, // Cartridges are not pre-filled devices
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
    
    // Add compatibility information if provided
    if (_deviceController.text.isNotEmpty) {
      items.insert(2, ConfirmationItem(
        label: 'Compatible Device:',
        value: _deviceController.text,
        icon: Icons.devices,
        color: Colors.amber[700]!,
      ));
    }
    
    if (_compatibleNeedlesController.text.isNotEmpty) {
      items.insert(_deviceController.text.isNotEmpty ? 3 : 2, ConfirmationItem(
        label: 'Compatible Needles:',
        value: _compatibleNeedlesController.text,
        icon: Icons.straighten,
        color: Colors.grey[700]!,
      ));
    }
    
    return items;
  }
} 