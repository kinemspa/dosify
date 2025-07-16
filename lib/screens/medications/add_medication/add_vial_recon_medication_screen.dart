import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';

import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';

import '../../../models/medication.dart';
import '../../../theme/app_decorations.dart';
import '../../../widgets/input_field_row.dart';
import '../../../screens/base_service_screen.dart';

import 'add_medication_form.dart';

class AddVialReconMedicationScreen extends BaseServiceScreen {
  const AddVialReconMedicationScreen({super.key});

  @override
  State<AddVialReconMedicationScreen> createState() => _AddVialReconMedicationScreenState();
}

class _AddVialReconMedicationScreenState extends BaseServiceScreenState<AddVialReconMedicationScreen> {
  final _reconVolumeController = TextEditingController();
  String _reconVolumeUnit = 'mL';
  final _concentrationController = TextEditingController();

  @override
  void dispose() {
    _reconVolumeController.dispose();
    _concentrationController.dispose();
    super.dispose();
  }

  void showErrorDialog(String title, String message) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(title),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  void showSuccessDialog(String title, String message) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(title),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  OverlayEntry? _loadingOverlay;

  void showLoadingDialog() {
    _loadingOverlay = OverlayEntry(
      builder: (context) => Positioned.fill(
        child: Container(
          color: Colors.black.withOpacity(0.5),
          child: const Center(child: CircularProgressIndicator()),
        ),
      ),
    );
    Overlay.of(context).insert(_loadingOverlay!);
  }

  void hideDialog() {
    _loadingOverlay?.remove();
    _loadingOverlay = null;
  }

  Future<void> _handleSave(BuildContext context, Map<String, dynamic> data) async {
    if (_reconVolumeController.text.isEmpty || _concentrationController.text.isEmpty) {
      showErrorDialog('Validation Error', 'Please fill all required fields');
      return;
    }

    showLoadingDialog();

    try {
      final uuid = const Uuid().v4();

      final medication = Medication(
        id: uuid,
        name: data['name'],
        type: MedicationType.vialPowderedRecon,
        strength: data['strength'],
        strengthUnit: data['strengthUnit'],
        tabletsInStock: data['quantity'],
        quantityUnit: data['quantityUnit'],
        currentInventory: data['currentInventory'],
        lastInventoryUpdate: DateTime.now(),
        reconstitutionVolume: double.parse(_reconVolumeController.text),
        reconstitutionVolumeUnit: _reconVolumeUnit,
        concentrationAfterReconstitution: double.parse(_concentrationController.text),
        needsReconstitution: true,
      );

      await firebaseService.addMedication(medication);

      hideDialog();
      showSuccessDialog('Success', 'Medication saved successfully');
      Navigator.pop(context, true);
    } catch (e) {
      hideDialog();
      showErrorDialog('Error', 'Error saving medication: $e');
    }
  }

  Widget _buildReconstitutionFields() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Text(
          'Reconstitution Information',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 16),
        InputFieldRow(
          label: 'Reconstitution Volume',
          controller: _reconVolumeController,
          unitValue: _reconVolumeUnit,
          unitOptions: const ['mL'],
          onUnitChanged: (value) {
            if (value != null) {
              setState(() {
                _reconVolumeUnit = value;
              });
            }
          },
        ),
        const SizedBox(height: 16),
        TextFormField(
          controller: _concentrationController,
          decoration: AppDecorations.inputField(
            labelText: 'Final Concentration (per mL)',
            hintText: 'Enter concentration',
            suffixText: 'mg/mL',
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
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return AddMedicationForm(
      medicationType: MedicationType.vialPowderedRecon,
      title: 'Add Reconstitution Vial',
      additionalFields: _buildReconstitutionFields(),
      onSave: (data) => _handleSave(context, data),
    );
  }
}
