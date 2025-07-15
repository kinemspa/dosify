import 'package:flutter/material.dart';
import '../../widgets/input_field_row.dart';
import '../../widgets/number_input_field.dart';
import '../../widgets/unit_dropdown.dart';
import '../../theme/app_decorations.dart';

class ExampleFormScreen extends StatefulWidget {
  const ExampleFormScreen({super.key});

  @override
  State<ExampleFormScreen> createState() => _ExampleFormScreenState();
}

class _ExampleFormScreenState extends State<ExampleFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _doseController = TextEditingController();
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _notesController = TextEditingController();
  
  String _selectedUnit = 'mg';
  
  @override
  void dispose() {
    _doseController.dispose();
    _nameController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Dosify'),
            Text(
              'Example Form',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Theme.of(context).colorScheme.onPrimary.withOpacity(0.8),
              ),
            ),
          ],
        ),
      ),
      body: Container(
        decoration: AppDecorations.screenBackground(context),
        height: double.infinity,
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Title
                  Text(
                    'Form Components Example',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Theme.of(context).brightness == Brightness.dark ? Colors.white : Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 24),
                  
                  // Dose Amount and Unit Row
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Dose Amount
                      Expanded(
                        flex: 2,
                        child: InputFieldRow(
                          label: 'Dose Amount',
                          infoText: 'Enter the amount of medication for this dose',
                          child: NumberInputField(
                            controller: _doseController,
                            hintText: 'Enter the dose amount',
                            helperText: 'This is helper text below the field',
                            allowDecimals: true,
                            decimalPlaces: 1,
                            showIncrementButtons: true,
                            incrementAmount: 0.5,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      // Unit Dropdown
                      Expanded(
                        child: InputFieldRow(
                          label: 'Unit',
                          alignWithDropdown: true,
                          verticalOffset: 4.0, // Adjusted from 8.0 to 4.0 for better alignment
                          child: UnitDropdown(
                            value: _selectedUnit,
                            units: ['mg', 'mcg', 'mL', 'units'],
                            onChanged: (value) {
                              if (value != null) {
                                setState(() {
                                  _selectedUnit = value;
                                });
                              }
                            },
                            helperText: 'Select a unit',
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  
                  // Name Field
                  InputFieldRow(
                    label: 'Name',
                    infoText: 'Enter a name for this dose',
                    child: TextFormField(
                      controller: _nameController,
                      decoration: AppDecorations.inputField(
                        hintText: 'Enter a name',
                        helperText: 'This is a standard text field',
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  
                  // Notes Field
                  InputFieldRow(
                    label: 'Notes',
                    child: TextFormField(
                      controller: _notesController,
                      decoration: AppDecorations.inputField(
                        hintText: 'Add any additional notes',
                      ),
                      maxLines: 3,
                    ),
                  ),
                  const SizedBox(height: 32),
                  
                  // Save Button
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () {
                        if (_formKey.currentState!.validate()) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Form is valid!')),
                          );
                        }
                      },
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                      ),
                      child: const Text('SAVE'),
                    ),
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