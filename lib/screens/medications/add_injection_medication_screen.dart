import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:uuid/uuid.dart';
import '../../models/medication.dart';
import '../../services/firebase_service.dart';
import '../../theme/app_decorations.dart';
import '../../theme/app_text_styles.dart';
import 'reconstitution_calculator_screen.dart';

class AddInjectionMedicationScreen extends StatefulWidget {
  const AddInjectionMedicationScreen({super.key});

  @override
  State<AddInjectionMedicationScreen> createState() => _AddInjectionMedicationScreenState();
}

class _AddInjectionMedicationScreenState extends State<AddInjectionMedicationScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _strengthController = TextEditingController();
  String _strengthUnit = 'mg';
  final _quantityController = TextEditingController();
  String _quantityUnit = 'mL';
  final _inventoryController = TextEditingController();
  final FirebaseService _firebaseService = FirebaseService();
  bool _isLoading = false;
  
  // Injection specific fields
  bool _isPreFilled = false;
  bool _needsReconstitution = false;
  final _reconVolumeController = TextEditingController();
  double? _concentrationAfterReconstitution;

  @override
  void dispose() {
    _nameController.dispose();
    _strengthController.dispose();
    _quantityController.dispose();
    _inventoryController.dispose();
    _reconVolumeController.dispose();
    super.dispose();
  }

  void _updateQuantityUnit() {
    setState(() {
      _quantityUnit = _isPreFilled ? 'syringes' : 'vials';
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
    
    if (_needsReconstitution && (_reconVolumeController.text.isEmpty || _concentrationAfterReconstitution == null)) {
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
        quantity: quantity,
        quantityUnit: _quantityUnit,
        currentInventory: inventory,
        lastInventoryUpdate: DateTime.now(),
        isPreFilled: _isPreFilled,
        needsReconstitution: _needsReconstitution,
        reconstitutionVolume: _needsReconstitution ? double.tryParse(_reconVolumeController.text) : null,
        reconstitutionVolumeUnit: _needsReconstitution ? 'mL' : null,
        concentrationAfterReconstitution: _concentrationAfterReconstitution,
      );
      print('Medication object created: ${medication.name}, ${medication.type}, ${medication.strength} ${medication.strengthUnit}, ${medication.currentInventory} $_quantityUnit');
      
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Add Injection Medication'),
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
                  
                  // Injection Type
                  const Text(
                    'Injection Type',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Theme.of(context).cardColor,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Column(
                      children: [
                        // Pre-filled Syringe Option
                        SwitchListTile(
                          title: const Text('Pre-filled Syringe'),
                          subtitle: const Text('Medication comes in a ready-to-use syringe'),
                          value: _isPreFilled,
                          onChanged: (value) {
                            setState(() {
                              _isPreFilled = value;
                              if (value) {
                                _needsReconstitution = false;
                              }
                              _updateQuantityUnit();
                            });
                          },
                        ),
                        
                        // Needs Reconstitution Option (only for vials)
                        if (!_isPreFilled)
                          SwitchListTile(
                            title: const Text('Needs Reconstitution'),
                            subtitle: const Text('Powdered medication that needs to be mixed with fluid'),
                            value: _needsReconstitution,
                            onChanged: (value) {
                              setState(() {
                                _needsReconstitution = value;
                              });
                            },
                          ),
                      ],
                    ),
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
                  
                  // Volume/Size
                  Text(
                    _isPreFilled ? 'Syringe Volume' : 'Vial Size',
                    style: const TextStyle(
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
                          controller: _quantityController,
                          keyboardType: TextInputType.number,
                          inputFormatters: [
                            FilteringTextInputFormatter.allow(RegExp(r'^\d+\.?\d{0,2}')),
                          ],
                          decoration: AppDecorations.inputField(
                            hintText: _isPreFilled ? 'Enter syringe volume' : 'Enter vial size',
                          ),
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Please enter a value';
                            }
                            if (double.tryParse(value) == null) {
                              return 'Please enter a valid number';
                            }
                            return null;
                          },
                        ),
                      ),
                      const SizedBox(width: 8),
                      const Expanded(
                        child: SizedBox(
                          height: 56,
                          child: Center(
                            child: Text(
                              'mL',
                              style: TextStyle(fontSize: 16),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  
                  // Reconstitution Section (only if needed)
                  if (_needsReconstitution) ...[
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
                                onPressed: _strengthController.text.isEmpty || _quantityController.text.isEmpty
                                    ? null
                                    : _navigateToReconstitutionCalculator,
                                child: const Text('Calculate'),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          if (_concentrationAfterReconstitution != null)
                            Text(
                              'Final concentration: ${_concentrationAfterReconstitution!.toStringAsFixed(2)} $_strengthUnit/mL',
                              style: const TextStyle(
                                color: Colors.white,
                              ),
                            ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                  ],
                  
                  // Inventory
                  Text(
                    'Number of ${_isPreFilled ? 'Syringes' : 'Vials'} in Stock',
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  TextFormField(
                    controller: _inventoryController,
                    keyboardType: TextInputType.number,
                    inputFormatters: [
                      FilteringTextInputFormatter.allow(RegExp(r'^\d+\.?\d{0,2}')),
                    ],
                    decoration: AppDecorations.inputField(
                      hintText: 'Enter number in stock',
                      suffixText: _quantityUnit,
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please enter inventory amount';
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