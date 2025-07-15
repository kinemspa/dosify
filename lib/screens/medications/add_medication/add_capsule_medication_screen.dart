import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';
import '../../../models/medication.dart';
import '../../../services/firebase_service.dart';
import '../../../theme/app_colors.dart';
import '../../../theme/app_decorations.dart';
import '../../../widgets/medication_confirmation_dialog.dart';
import '../../../widgets/input_field_row.dart';
import '../../base_service_screen.dart';

class AddCapsuleMedicationScreen extends BaseServiceScreen {
  const AddCapsuleMedicationScreen({super.key});

  @override
  State<AddCapsuleMedicationScreen> createState() => _AddCapsuleMedicationScreenState();
}

class _AddCapsuleMedicationScreenState extends BaseServiceScreenState<AddCapsuleMedicationScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _strengthController = TextEditingController();
  String _strengthUnit = 'mg';
  final _quantityController = TextEditingController();
  String _quantityUnit = 'capsules';
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
        print('Parsed quantity: $quantity $_quantityUnit');
      } catch (e) {
        print('Error parsing quantity: ${_quantityController.text}');
        throw Exception('Invalid quantity value');
      }
      
      // Parse current inventory value
      final double currentInventory;
      try {
        currentInventory = double.parse(_currentInventoryController.text);
        print('Parsed current inventory: $currentInventory $_quantityUnit');
      } catch (e) {
        print('Error parsing current inventory: ${_currentInventoryController.text}');
        throw Exception('Invalid current inventory value');
      }
      
      // Create medication object
      final medication = Medication(
        id: const Uuid().v4(),
        name: name,
        type: MedicationType.capsule,
        strength: strength,
        strengthUnit: _strengthUnit,
        quantity: quantity,
        quantityUnit: _quantityUnit,
        currentInventory: currentInventory,
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
  
  Widget _buildDetailRow(String label, String value, {bool isHighlighted = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(
              '$label:',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: isHighlighted ? Colors.orange[800] : null,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: TextStyle(
                fontWeight: isHighlighted ? FontWeight.bold : FontWeight.normal,
                fontSize: isHighlighted ? 16 : null,
                color: isHighlighted ? Colors.orange[800] : null,
              ),
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
        title: const Text('Add Capsule Medication'),
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
                onPressed: _isLoading ? null : _saveMedication,
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