import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:uuid/uuid.dart';
import '../../models/medication.dart';
import '../../services/firebase_service.dart';
import '../../theme/app_decorations.dart';
import '../../theme/app_text_styles.dart';

class AddCapsuleMedicationScreen extends StatefulWidget {
  const AddCapsuleMedicationScreen({super.key});

  @override
  State<AddCapsuleMedicationScreen> createState() => _AddCapsuleMedicationScreenState();
}

class _AddCapsuleMedicationScreenState extends State<AddCapsuleMedicationScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _strengthController = TextEditingController();
  String _strengthUnit = 'mg';
  final _capsulesInStockController = TextEditingController();
  final FirebaseService _firebaseService = FirebaseService();
  bool _isLoading = false;

  @override
  void dispose() {
    _nameController.dispose();
    _strengthController.dispose();
    _capsulesInStockController.dispose();
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
      print('=== CAPSULE MEDICATION SAVE START ===');
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
      
      // Parse inventory value
      final double inventory;
      try {
        inventory = double.parse(_capsulesInStockController.text);
        print('Parsed inventory: $inventory capsules');
      } catch (e) {
        print('Error parsing inventory: ${_capsulesInStockController.text}');
        throw Exception('Invalid inventory value');
      }
      
      print('Creating medication object...');
      final medication = Medication(
        id: uuid,
        name: _nameController.text,
        type: MedicationType.capsule,
        strength: strength,
        strengthUnit: _strengthUnit,
        quantity: inventory, // Set to same value as inventory for backward compatibility
        quantityUnit: 'capsules',
        currentInventory: inventory,
        lastInventoryUpdate: DateTime.now(),
      );
      print('Medication object created: ${medication.name}, ${medication.type}, ${medication.strength} ${medication.strengthUnit}, ${medication.currentInventory} capsules');
      
      print('Calling Firebase service to save medication...');
      await _firebaseService.addMedication(medication);
      print('Firebase service call completed successfully');
      
      print('Showing success message and returning to previous screen');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Medication saved successfully'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.pop(context, true);
      }
      print('=== CAPSULE MEDICATION SAVE END ===');
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Add Capsule Medication'),
      ),
      body: Container(
        decoration: AppDecorations.gradientBackground,
        height: double.infinity,
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Form(
              key: _formKey,
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
                    controller: _nameController,
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
                  const SizedBox(height: 16),
                  
                  // Strength
                  const Text(
                    'Strength',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        flex: 2,
                        child: TextFormField(
                          controller: _strengthController,
                          keyboardType: TextInputType.number,
                          inputFormatters: [
                            FilteringTextInputFormatter.allow(RegExp(r'^\d+\.?\d{0,2}')),
                          ],
                          decoration: AppDecorations.inputField(
                            hintText: 'Enter strength',
                          ),
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Please enter strength';
                            }
                            if (double.tryParse(value) == null) {
                              return 'Please enter a valid number';
                            }
                            return null;
                          },
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: DropdownButtonFormField<String>(
                          value: _strengthUnit,
                          decoration: AppDecorations.inputField(),
                          dropdownColor: Theme.of(context).cardColor,
                          items: ['mg', 'mcg', 'g', 'IU']
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
                  
                  // Capsules in Stock
                  const Text(
                    'Capsules in Stock',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  TextFormField(
                    controller: _capsulesInStockController,
                    keyboardType: TextInputType.number,
                    inputFormatters: [
                      FilteringTextInputFormatter.allow(RegExp(r'^\d+\.?\d{0,2}')),
                    ],
                    decoration: AppDecorations.inputField(
                      hintText: 'Enter number of capsules',
                      suffixText: 'capsules',
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please enter number of capsules';
                      }
                      if (double.tryParse(value) == null) {
                        return 'Please enter a valid number';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 32),
                  
                  // Save Button
                  ElevatedButton(
                    onPressed: _isLoading ? null : _saveMedication,
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                    ),
                    child: _isLoading
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
} 