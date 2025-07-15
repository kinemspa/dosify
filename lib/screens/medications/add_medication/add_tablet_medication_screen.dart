import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';
import '../../../models/medication.dart';
import '../../../services/firebase_service.dart';
import '../../../theme/app_colors.dart';
import '../../../theme/app_decorations.dart';
import '../../../widgets/medication_confirmation_dialog.dart';
import '../../base_service_screen.dart';

class AddTabletMedicationScreen extends BaseServiceScreen {
  const AddTabletMedicationScreen({super.key});

  @override
  State<AddTabletMedicationScreen> createState() => _AddTabletMedicationScreenState();
}

class _AddTabletMedicationScreenState extends BaseServiceScreenState<AddTabletMedicationScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _strengthController = TextEditingController();
  String _strengthUnit = 'mg';
  final _quantityController = TextEditingController();
  String _quantityUnit = 'tablets';
  final _currentInventoryController = TextEditingController();
  bool _isLoading = false;

  @override
  void dispose() {
    _nameController.dispose();
    _strengthController.dispose();
    _quantityController.dispose();
    _currentInventoryController.dispose();
    super.dispose();
  }

  Future<void> _saveMedication() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }
    
    setState(() {
      _isLoading = true;
    });

    try {
      // Parse name
      final String name = _nameController.text;
      print('Parsed name: $name');
      
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
        print('Parsed quantity: $quantity tablets');
      } catch (e) {
        print('Error parsing quantity: ${_quantityController.text}');
        throw Exception('Invalid quantity value');
      }
      
      // Parse inventory value
      final double inventory;
      try {
        inventory = double.parse(_currentInventoryController.text);
        print('Parsed inventory: $inventory tablets');
      } catch (e) {
        print('Error parsing inventory: ${_currentInventoryController.text}');
        throw Exception('Invalid inventory value');
      }
      
      // Create medication object
      final medication = Medication(
        id: const Uuid().v4(),
        name: name,
        type: MedicationType.tablet,
        strength: strength,
        strengthUnit: _strengthUnit,
        quantity: quantity,
        quantityUnit: _quantityUnit,
        currentInventory: inventory,
        lastInventoryUpdate: DateTime.now(),
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
          _isLoading = false;
        });
      }
    }
  }
  
  Future<void> _showConfirmationDialog() async {
    // Parse values for confirmation
    final name = _nameController.text;
    final strength = double.tryParse(_strengthController.text) ?? 0;
    final quantity = double.tryParse(_quantityController.text) ?? 0;
    final inventory = double.tryParse(_currentInventoryController.text) ?? 0;

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
        ),
        ConfirmationItem(
          label: 'Strength:',
          value: '$strength $_strengthUnit per tablet',
          icon: Icons.fitness_center,
          color: Colors.green,
        ),
        ConfirmationItem(
          label: 'In Stock:',
          value: '${inventory.toInt()} tablets',
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
  
  // Helper method to build detail rows for confirmation dialog
  Widget _buildDetailRow(String label, String value, {bool isHighlighted = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              fontWeight: FontWeight.w500,
              color: isHighlighted 
                  ? Theme.of(context).colorScheme.primary
                  : Theme.of(context).textTheme.bodyMedium?.color,
            ),
          ),
          Text(
            value,
            style: TextStyle(
              fontWeight: isHighlighted ? FontWeight.bold : FontWeight.normal,
              color: isHighlighted 
                  ? Theme.of(context).colorScheme.primary
                  : Theme.of(context).textTheme.bodyMedium?.color,
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Add Tablet Medication'),
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            TextFormField(
              controller: _nameController,
              decoration: AppDecorations.inputField(
                labelText: 'Medication Name',
                hintText: 'Enter medication name',
              ),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Please enter medication name';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  flex: 2,
                  child: TextFormField(
                    controller: _strengthController,
                    decoration: AppDecorations.inputField(
                      labelText: 'Strength',
                      hintText: 'Enter strength',
                    ),
                    keyboardType: TextInputType.number,
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Required';
                      }
                      if (double.tryParse(value) == null) {
                        return 'Invalid number';
                      }
                      return null;
                    },
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: DropdownButtonFormField<String>(
                    value: _strengthUnit,
                    decoration: AppDecorations.inputField(
                      labelText: 'Unit',
                    ),
                    items: ['mg', 'mcg', 'g', 'IU', 'mL']
                        .map((unit) => DropdownMenuItem(
                              value: unit,
                              child: Text(unit),
                            ))
                        .toList(),
                    onChanged: (value) {
                      if (value != null) {
                        setState(() {
                          _strengthUnit = value;
                        });
                      }
                    },
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  flex: 2,
                  child: TextFormField(
                    controller: _quantityController,
                    decoration: AppDecorations.inputField(
                      labelText: 'Package Quantity',
                      hintText: 'Enter quantity',
                    ),
                    keyboardType: TextInputType.number,
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Required';
                      }
                      if (double.tryParse(value) == null) {
                        return 'Invalid number';
                      }
                      return null;
                    },
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: TextFormField(
                    enabled: false,
                    initialValue: _quantityUnit,
                    decoration: AppDecorations.inputField(
                      labelText: 'Unit',
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _currentInventoryController,
              decoration: AppDecorations.inputField(
                labelText: 'Current Inventory',
                hintText: 'Enter current inventory',
              ),
              keyboardType: TextInputType.number,
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Required';
                }
                if (double.tryParse(value) == null) {
                  return 'Invalid number';
                }
                return null;
              },
            ),
            const SizedBox(height: 32),
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed: _isLoading ? null : _showConfirmationDialog,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.actionButton,
                  foregroundColor: Colors.white,
                ),
                child: _isLoading
                    ? const SizedBox(
                        width: 24,
                        height: 24,
                        child: CircularProgressIndicator(
                          color: Colors.white,
                          strokeWidth: 2,
                        ),
                      )
                    : const Text('SAVE MEDICATION'),
              ),
            ),
          ],
        ),
      ),
    );
  }
} 