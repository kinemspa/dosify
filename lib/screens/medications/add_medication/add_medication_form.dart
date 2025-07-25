import 'package:flutter/material.dart';
import '../../../models/medication.dart';
import '../../../theme/app_colors.dart';
import '../../../theme/app_text_styles.dart';
import '../../../theme/app_decorations.dart';
import '../../../widgets/medication_confirmation_dialog.dart';
import '../../../utils/input_validator.dart';

class AddMedicationForm extends StatefulWidget {
  final MedicationType medicationType;
  final String title;
  final Widget? additionalFields;
  final Function(Map<String, dynamic> data) onSave;

  const AddMedicationForm({
    super.key,
    required this.medicationType,
    required this.title,
    this.additionalFields,
    required this.onSave,
  });

  @override
  State<AddMedicationForm> createState() => _AddMedicationFormState();
}

class _AddMedicationFormState extends State<AddMedicationForm> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _strengthController = TextEditingController();
  String _strengthUnit = 'mg';
  final _quantityController = TextEditingController();
  String _quantityUnit = '';
  final _currentInventoryController = TextEditingController();

  @override
  void initState() {
    super.initState();
    // Set default quantity unit based on medication type
    _quantityUnit = _getDefaultQuantityUnit();
  }

  String _getDefaultQuantityUnit() {
    switch (widget.medicationType) {
      case MedicationType.tablet:
      case MedicationType.capsule:
        return 'tablets';
      case MedicationType.injection:
        return 'vials';
      case MedicationType.preFilledSyringe:
        return 'syringes';
      case MedicationType.vialPreMixed:
      case MedicationType.vialPowderedKnown:
      case MedicationType.vialPowderedRecon:
        return 'vials';
      default:
        return 'units';
    }
  }

  List<String> _getStrengthUnits() {
    return ['mg', 'mcg', 'g', 'IU', 'mL'];
  }

  void _handleSave() {
    if (_formKey.currentState!.validate()) {
      final data = {
        'name': InputValidator.sanitizeInput(_nameController.text.trim()),
        'type': widget.medicationType,
        'strength': double.parse(_strengthController.text),
        'strengthUnit': _strengthUnit,
        'quantity': double.parse(_quantityController.text),
        'quantityUnit': _quantityUnit,
        'currentInventory': double.parse(_currentInventoryController.text),
      };
      widget.onSave(data);
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _strengthController.dispose();
    _quantityController.dispose();
    _currentInventoryController.dispose();
    super.dispose();
  }

  // Update the confirmation dialog in the add_medication_form.dart file
  // Make it more conversational and improve the display of total medicine

  Future<bool> _showConfirmationDialog(BuildContext context, {
    required String name,
    required double strength,
    required String strengthUnit,
    required double quantity,
    required String quantityUnit,
  }) async {
    // Calculate total medicine
    final double totalMedicine = strength * quantity;
    
    // Format total medicine string with appropriate units
    String totalMedicineStr;
    if (strengthUnit == 'mcg' && totalMedicine >= 1000) {
      // Convert to mg if possible and show both
      final double mgValue = totalMedicine / 1000;
      totalMedicineStr = '${totalMedicine.toInt()} mcg (${mgValue.toStringAsFixed(mgValue.truncateToDouble() == mgValue ? 0 : 2)} mg)';
    } else if (strengthUnit == 'mg' && totalMedicine >= 1000) {
      // Convert to g if possible and show both
      final double gValue = totalMedicine / 1000;
      totalMedicineStr = '${totalMedicine.toInt()} mg (${gValue.toStringAsFixed(gValue.truncateToDouble() == gValue ? 0 : 2)} g)';
    } else {
      // Format to remove trailing zeros
      if (totalMedicine == totalMedicine.toInt()) {
        totalMedicineStr = '${totalMedicine.toInt()} $strengthUnit';
      } else {
        totalMedicineStr = '$totalMedicine $strengthUnit';
      }
    }

    return await MedicationConfirmationDialog.show(
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
          value: '$strength $strengthUnit per $quantityUnit',
          icon: Icons.fitness_center,
          color: Colors.green,
        ),
        ConfirmationItem(
          label: 'In Stock:',
          value: '$quantity $quantityUnit',
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
    ) ?? false;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title),
        actions: [
          TextButton(
            onPressed: _handleSave,
            child: const Text('Save'),
          ),
        ],
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
                final result = InputValidator.validateMedicationName(value);
                return result.hasError ? result.error : null;
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
                      final result = InputValidator.validateMedicationStrength(value);
                      return result.hasError ? result.error : null;
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
                    items: _getStrengthUnits()
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
                      final result = InputValidator.validatePositiveNumber(value, 'Package quantity');
                      return result.hasError ? result.error : null;
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
                final result = InputValidator.validateInventoryCount(value);
                return result.hasError ? result.error : null;
              },
            ),
            if (widget.additionalFields != null) ...[
              const SizedBox(height: 16),
              widget.additionalFields!,
            ],
          ],
        ),
      ),
    );
  }
} 