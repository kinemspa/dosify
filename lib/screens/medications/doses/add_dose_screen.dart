import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';
import '../../../models/dose.dart';
import '../../../services/firebase_service.dart';
import '../../../theme/app_colors.dart';
import '../../../theme/app_decorations.dart';
import '../../../widgets/number_input_field.dart';
import '../../../widgets/simple_input_row.dart';
import '../../../widgets/confirmation_dialog.dart';
import '../../../widgets/help_card.dart';
import '../../base_service_screen.dart';

class AddDoseScreen extends BaseServiceScreen {
  final String medicationId;
  final String medicationName;
  final Dose? existingDose;

  const AddDoseScreen({
    super.key,
    required this.medicationId,
    required this.medicationName,
    this.existingDose,
  });

  @override
  State<AddDoseScreen> createState() => _AddDoseScreenState();
}

class _AddDoseScreenState extends BaseServiceScreenState<AddDoseScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _amountController = TextEditingController();
  String _unit = 'mg';
  final _notesController = TextEditingController();
  bool _isLoading = false;
  bool _isEdit = false;

  @override
  void initState() {
    super.initState();
    
    // Set default unit if provided
    if (widget.existingDose != null) {
      _unit = widget.existingDose!.unit;
    }
    
    // If editing an existing dose, populate the fields
    if (widget.existingDose != null) {
      _isEdit = true;
      _amountController.text = widget.existingDose!.amount.toString();
      _unit = widget.existingDose!.unit;
      
      if (widget.existingDose!.name != null) {
        _nameController.text = widget.existingDose!.name!;
      } else {
        _nameController.text = '${widget.existingDose!.amount} ${widget.existingDose!.unit}';
      }
      
      if (widget.existingDose!.notes != null) {
        _notesController.text = widget.existingDose!.notes!;
      }
    }
    
    // Add listener to update name when amount changes
    _amountController.addListener(_updateDoseName);
  }

  @override
  void dispose() {
    _amountController.removeListener(_updateDoseName);
    _amountController.dispose();
    _nameController.dispose();
    _notesController.dispose();
    super.dispose();
  }
  
  void _updateDoseName() {
    // Only auto-populate if name field is empty and we're not editing
    if (_nameController.text.isEmpty || (!_isEdit && _nameController.text.contains(_unit))) {
      final amount = _amountController.text;
      if (amount.isNotEmpty) {
        try {
          final double parsedAmount = double.parse(amount);
          String formattedAmount;
          
          // Format to remove trailing zeros
          if (parsedAmount == parsedAmount.toInt()) {
            formattedAmount = parsedAmount.toInt().toString();
          } else {
            formattedAmount = parsedAmount.toString();
          }
          setState(() {
            _nameController.text = '$formattedAmount $_unit';
          });
        } catch (e) {
          // Ignore parsing errors
        }
      }
    }
  }

  Future<void> _saveDose() async {
    if (_formKey.currentState!.validate()) {
      setState(() {
        _isLoading = true;
      });

      try {
        // Get amount
        final amount = double.parse(_amountController.text);
        
        // Get name (use amount + unit if empty)
        final String? name = _nameController.text.isNotEmpty ? 
            _nameController.text : 
           '${amount.toString()} $_unit';
        
        // Get notes
        final String? notes = _notesController.text.isNotEmpty ? 
            _notesController.text : null;
        
        // Create or update dose
        final Dose dose = Dose(
          id: _isEdit ? widget.existingDose!.id : const Uuid().v4(),
          medicationId: widget.medicationId,
          amount: amount,
          unit: _unit,
          name: name,
          notes: notes,
        );
        
        // Save to Firebase
        await firebaseService.addDose(dose);
        
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(_isEdit ? 'Dose updated successfully' : 'Dose added successfully'),
              backgroundColor: Colors.green,
            ),
          );
          
          // Return true to indicate success
          Navigator.pop(context, true);
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error saving dose: $e'),
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
  }

  Future<void> _deleteDose() async {
    if (!_isEdit) return;
    
    final confirmed = await ConfirmationDialog.show(
      context: context,
      title: 'Delete Dose',
      message: 'Are you sure you want to delete this dose?',
      confirmText: 'DELETE',
    );
    
    if (confirmed == true) {
      setState(() {
        _isLoading = true;
      });
      
      try {
        await firebaseService.deleteDose(widget.existingDose!.id, widget.medicationId);
        
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Dose deleted successfully'),
              backgroundColor: Colors.green,
            ),
          );
          
          // Return true to indicate success
          Navigator.pop(context, true);
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error deleting dose: $e'),
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
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_isEdit ? 'Edit Dose' : 'Add Dose'),
        centerTitle: false,
        titleSpacing: 16,
        automaticallyImplyLeading: true,
        actions: _isEdit ? [
          IconButton(
            icon: const Icon(Icons.delete),
            onPressed: _deleteDose,
          ),
        ] : null,
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // Medication name (display only)
            SimpleInputRow(
              label: 'Medication',
              controller: TextEditingController(text: widget.medicationName),
              enabled: false,
            ),
            
            const SizedBox(height: 16),
            
            // Dose amount and unit
            Row(
              children: [
                // Amount field
                Expanded(
                  flex: 2,
                  child: NumericInputRow(
                    label: 'Dose Amount',
                    controller: _amountController,
                    hint: 'Enter amount',
                    helperText: 'Enter the amount of medication for each dose',
                    required: true,
                    allowDecimal: true,
                  ),
                ),
                
                const SizedBox(width: 8),
                
                // Unit dropdown
                Expanded(
                  child: SimpleInputRow(
                    label: 'Unit',
                    controller: TextEditingController(), // Dummy controller
                    suffix: DropdownButtonFormField<String>(
                      value: _unit,
                      decoration: AppDecorations.inputField(),
                      items: const [
                        DropdownMenuItem(value: 'mg', child: Text('mg')),
                        DropdownMenuItem(value: 'mcg', child: Text('mcg')),
                        DropdownMenuItem(value: 'g', child: Text('g')),
                        DropdownMenuItem(value: 'mL', child: Text('mL')),
                        DropdownMenuItem(value: 'units', child: Text('units')),
                      ],
                      onChanged: (value) {
                        if (value != null) {
                          setState(() {
                            _unit = value;
                            // Update dose name when unit changes
                            _updateDoseName();
                          });
                        }
                      },
                    ),
                  ),
                ),
              ],
            ),
            
            const SizedBox(height: 16),
            
            // Dose name (optional)
            SimpleInputRow(
              label: 'Dose Name',
              controller: _nameController,
              hint: 'Enter name (optional)',
              helperText: 'Optionally give this dose a custom name',
            ),
            
            const SizedBox(height: 16),
            
            // Notes (optional)
            SimpleInputRow(
              label: 'Notes',
              controller: _notesController,
              hint: 'Enter notes (optional)',
              helperText: 'Add any additional information about this dose',
              maxLength: 200,
            ),
            
            const SizedBox(height: 16),
            
            // Help card
            CollapsibleHelpCard(
              title: 'About Doses',
              content: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: const [
                  Text('• Doses represent the amount of medication taken at one time'),
                  SizedBox(height: 8),
                  Text('• You can create multiple doses for a medication (e.g., different strengths)'),
                  SizedBox(height: 8),
                  Text('• Schedules are then created for specific doses'),
                ],
              ),
            ),
            
            const SizedBox(height: 24),
            
            // Save button
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed: _isLoading ? null : _saveDose,
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
                    : Text(_isEdit ? 'UPDATE DOSE' : 'SAVE DOSE'),
              ),
            ),
          ],
        ),
      ),
    );
  }
} 