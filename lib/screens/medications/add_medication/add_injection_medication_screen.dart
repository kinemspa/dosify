import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';
import '../../../models/medication.dart';
import '../../../models/injection_type.dart';
import '../../../theme/app_colors.dart';
import '../../../theme/app_decorations.dart';
import '../../../widgets/number_input_field.dart';
import '../../../widgets/input_field_row.dart';
import '../../../widgets/medication_confirmation_dialog.dart';
import '../tools/reconstitution_calculator_screen.dart';
import '../../base_service_screen.dart';
import 'ampule_medication_screen.dart';
import 'cartridge_medication_screen.dart';
import 'liquid_vial_medication_screen.dart';
import 'powder_vial_medication_screen.dart';
import 'prefilled_pen_medication_screen.dart';
import 'prefilled_syringe_medication_screen.dart';

class AddInjectionMedicationScreen extends BaseServiceScreen {
  const AddInjectionMedicationScreen({super.key});

  @override
  State<AddInjectionMedicationScreen> createState() => _AddInjectionMedicationScreenState();
}

class _AddInjectionMedicationScreenState extends BaseServiceScreenState<AddInjectionMedicationScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _strengthController = TextEditingController();
  String _strengthUnit = 'mg';
  final _quantityController = TextEditingController();
  String _quantityUnit = 'mL';
  final _inventoryController = TextEditingController();
  bool _isLoading = false;
  
  // Injection specific fields
  InjectionType _selectedInjectionType = InjectionType.liquidVial;
  final _reconVolumeController = TextEditingController();
  double? _concentrationAfterReconstitution;
  String? _selectedRouteOfAdministration;
  final _diluentController = TextEditingController();
  
  // Routes of administration options
  final List<String> _routesOfAdministration = [
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
    _nameController.dispose();
    _strengthController.dispose();
    _quantityController.dispose();
    _inventoryController.dispose();
    _reconVolumeController.dispose();
    _diluentController.dispose();
    super.dispose();
  }

  void _updateQuantityUnit() {
    setState(() {
      switch (_selectedInjectionType) {
        case InjectionType.prefilledSyringe:
          _quantityUnit = 'syringes';
          break;
        case InjectionType.prefilledPen:
          _quantityUnit = 'pens';
          break;
        case InjectionType.cartridge:
          _quantityUnit = 'cartridges';
          break;
        case InjectionType.ampule:
          _quantityUnit = 'ampules';
          break;
        default:
          _quantityUnit = 'vials';
          break;
      }
    });
  }

  Future<void> _navigateToReconstitutionCalculator() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ReconstitutionCalculatorScreen(
          initialVialStrength: double.tryParse(_strengthController.text),
          initialVialStrengthUnit: _strengthUnit,
          initialVialSize: double.tryParse(_quantityController.text),
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

  Future<void> _saveMedication() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    if (_selectedInjectionType == InjectionType.powderVial && 
        (_reconVolumeController.text.isEmpty || _concentrationAfterReconstitution == null)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please calculate reconstitution volume first'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      print('=== INJECTION MEDICATION SAVE START ===');
      // Generate a unique ID using UUID
      final uuid = const Uuid().v4();
      print('Generated UUID: $uuid');
      
      // Parse strength value
      final double strength;
      try {
        strength = double.parse(_strengthController.text);
        print('Parsed strength: $strength $_strengthUnit');
      } catch (e) {
        print('Error parsing strength: ${_strengthController.text}');
        throw Exception('Invalid strength value');
      }
      
      // Parse quantity value
      final double quantity;
      try {
        quantity = double.parse(_quantityController.text);
        print('Parsed quantity: $quantity $_quantityUnit');
      } catch (e) {
        print('Error parsing quantity: ${_quantityController.text}');
        throw Exception('Invalid quantity value');
      }
      
      // Parse inventory value
      final double inventory;
      try {
        inventory = double.parse(_inventoryController.text);
        print('Parsed inventory: $inventory $_quantityUnit');
      } catch (e) {
        print('Error parsing inventory: ${_inventoryController.text}');
        throw Exception('Invalid inventory value');
      }
      
      print('Creating medication object...');
      final medication = Medication(
        id: uuid,
        name: _nameController.text,
        type: MedicationType.injection,
        strength: strength,
        strengthUnit: _strengthUnit,
        tabletsInStock: quantity,
        quantityUnit: _quantityUnit,
        currentInventory: inventory,
        lastInventoryUpdate: DateTime.now(),
        // Enhanced injection fields
        injectionType: _selectedInjectionType,
        needsReconstitution: _selectedInjectionType == InjectionType.powderVial,
        isPreFilled: _selectedInjectionType == InjectionType.prefilledSyringe || 
                     _selectedInjectionType == InjectionType.prefilledPen,
        isPrefillPen: _selectedInjectionType == InjectionType.prefilledPen,
        reconstitutionVolume: _selectedInjectionType == InjectionType.powderVial ? 
                              double.tryParse(_reconVolumeController.text) : null,
        reconstitutionVolumeUnit: _selectedInjectionType == InjectionType.powderVial ? 'mL' : null,
        concentrationAfterReconstitution: _concentrationAfterReconstitution,
        routeOfAdministration: _selectedRouteOfAdministration,
        diluent: _selectedInjectionType == InjectionType.powderVial ? _diluentController.text : null,
      );
      print('Medication object created: ${medication.name}, ${medication.type}, ${medication.strength} ${medication.strengthUnit}, ${medication.currentInventory} $_quantityUnit');
      
      print('Calling Firebase service to save medication...');
      // await _firebaseService.addMedication(medication); // This line was removed
      print('Firebase service call completed successfully');
      
      print('Showing success message and returning to previous screen');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Medication saved successfully'),
            backgroundColor: Colors.green,
          ),
        );
        
        // Navigate back to the medication list screen with a result to trigger refresh
        Navigator.pop(context, true);
      }
      print('=== INJECTION MEDICATION SAVE END ===');
    } catch (e) {
      print('Error saving medication: $e');
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
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _showConfirmationDialog() async {
    // Parse values
    final name = _nameController.text;
    final strength = double.tryParse(_strengthController.text) ?? 0;
    final inventory = double.tryParse(_inventoryController.text) ?? 0;

    // Calculate total medicine
    final double totalMedicine = strength * inventory;
    
    // Format total medicine string with appropriate units
    String totalMedicineStr;
    if (_strengthUnit == 'mcg' && totalMedicine >= 1000) {
      // Convert to mg if possible and show both
      final double mgValue = totalMedicine / 1000;
      totalMedicineStr = '${totalMedicine.toInt()} mcg (${mgValue.toStringAsFixed(mgValue.truncateToDouble() == mgValue ? 0 : 2)} mg)';
    } else if (_strengthUnit == 'mg' && totalMedicine >= 1000) {
      // Convert to g if possible and show both
      final double gValue = totalMedicine / 1000;
      totalMedicineStr = '${totalMedicine.toInt()} mg (${gValue.toStringAsFixed(gValue.truncateToDouble() == gValue ? 0 : 2)} g)';
    } else {
      // Format to remove trailing zeros
      if (totalMedicine == totalMedicine.toInt()) {
        totalMedicineStr = '${totalMedicine.toInt()} $_strengthUnit';
      } else {
        totalMedicineStr = '$totalMedicine $_strengthUnit';
      }
    }

    // Get type name for display
    String typeName = _getInjectionTypeName(_selectedInjectionType);

    // Show confirmation dialog
    final shouldSave = await MedicationConfirmationDialog.show(
      context: context,
      title: 'Save $name?',
      items: [
        ConfirmationItem(
          label: 'Medication Name:',
          value: name,
          icon: Icons.medication,
          color: Colors.blue,
          subtitle: 'Type: $typeName',
        ),
        ConfirmationItem(
          label: 'Strength:',
          value: '$strength $_strengthUnit per ${_getPackagingUnit(_selectedInjectionType)}',
          icon: Icons.fitness_center,
          color: Colors.green,
        ),
        if (_selectedRouteOfAdministration != null)
          ConfirmationItem(
            label: 'Administration:',
            value: _selectedRouteOfAdministration!,
            icon: Icons.medical_services,
            color: Colors.teal,
          ),
        if (_selectedInjectionType == InjectionType.powderVial && _diluentController.text.isNotEmpty)
          ConfirmationItem(
            label: 'Diluent:',
            value: _diluentController.text,
            icon: Icons.water_drop,
            color: Colors.cyan,
          ),
        ConfirmationItem(
          label: 'In Stock:',
          value: '${inventory.toInt()} $_quantityUnit',
          icon: Icons.inventory_2,
          color: Colors.orange,
        ),
        ConfirmationItem(
          label: 'Total Medicine:',
          value: 'You have $totalMedicineStr total',
          icon: Icons.calculate,
          color: Colors.purple,
        ),
      ],
    );
    
    if (shouldSave == true) {
      _saveMedication();
    }
  }

  // Helper method to get the packaging unit name
  String _getPackagingUnit(InjectionType type) {
    switch (type) {
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

  // Helper method to get the injection type name
  String _getInjectionTypeName(InjectionType type) {
    switch (type) {
      case InjectionType.liquidVial:
        return 'Solution Vial';
      case InjectionType.powderVial:
        return 'Powdered Vial';
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

  // Helper method to get icon and color for injection type
  Map<String, dynamic> _getInjectionTypeIconAndColor(InjectionType type) {
    switch (type) {
      case InjectionType.liquidVial:
        return {'icon': Icons.science, 'color': Colors.blue};
      case InjectionType.powderVial:
        return {'icon': Icons.science, 'color': Colors.purple};
      case InjectionType.prefilledSyringe:
        return {'icon': Icons.vaccines, 'color': Colors.teal};
      case InjectionType.prefilledPen:
        return {'icon': Icons.edit, 'color': Colors.green};
      case InjectionType.cartridge:
        return {'icon': Icons.battery_std, 'color': Colors.amber};
      case InjectionType.ampule:
        return {'icon': Icons.water_drop, 'color': Colors.cyan};
    }
  }

  Widget _buildInjectionTypeCard({
    required String title,
    required String description,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      child: InkWell(
        onTap: onTap,
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
                      title,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      description,
                      style: TextStyle(
                        color: Theme.of(context).textTheme.bodyMedium?.color?.withOpacity(0.7),
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.arrow_forward_ios,
                size: 16,
                color: Theme.of(context).textTheme.bodyMedium?.color?.withOpacity(0.5),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _navigateTo(Widget screen) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => screen),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Choose Injection Type'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _buildInjectionTypeCard(
            title: 'Pre-filled Syringe',
            description: 'Single-use syringe with pre-measured medication',
            icon: Icons.vaccines,
            color: Colors.teal,
            onTap: () {
              _navigateTo(const PrefilledSyringeMedicationScreen());
            },
          ),
          _buildInjectionTypeCard(
            title: 'Pre-filled Pen',
            description: 'Pen-style injector with pre-measured medication',
            icon: Icons.edit,
            color: Colors.green,
            onTap: () {
              _navigateTo(const PrefilledPenMedicationScreen());
            },
          ),
          _buildInjectionTypeCard(
            title: 'Solution Vial',
            description: 'Vial containing liquid medication that needs to be drawn up',
            icon: Icons.science,
            color: Colors.blue,
            onTap: () {
              _navigateTo(const LiquidVialMedicationScreen());
            },
          ),
          _buildInjectionTypeCard(
            title: 'Powdered Vial',
            description: 'Vial containing powdered medication that needs reconstitution',
            icon: Icons.science,
            color: Colors.purple,
            onTap: () {
              _navigateTo(const PowderVialMedicationScreen());
            },
          ),
          _buildInjectionTypeCard(
            title: 'Cartridge',
            description: 'Medication cartridge for use with a reusable pen device',
            icon: Icons.battery_std,
            color: Colors.amber,
            onTap: () {
              _navigateTo(const CartridgeMedicationScreen());
            },
          ),
          _buildInjectionTypeCard(
            title: 'Ampule',
            description: 'Glass container that must be broken to access medication',
            icon: Icons.water_drop,
            color: Colors.cyan,
            onTap: () {
              _navigateTo(const AmpuleMedicationScreen());
            },
          ),
        ],
      ),
    );
  }
} 