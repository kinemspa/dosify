import 'package:flutter/material.dart';
import '../../models/medication.dart';
import '../../services/firebase_service.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_decorations.dart';

class MedicationDetailScreen extends StatefulWidget {
  final Medication medication;

  const MedicationDetailScreen({
    super.key,
    required this.medication,
  });

  @override
  State<MedicationDetailScreen> createState() => _MedicationDetailScreenState();
}

class _MedicationDetailScreenState extends State<MedicationDetailScreen> {
  late Medication _medication;
  final FirebaseService _firebaseService = FirebaseService();
  bool _isLoading = false;
  final TextEditingController _inventoryController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _medication = widget.medication;
    _inventoryController.text = _medication.currentInventory.toString();
  }

  @override
  void dispose() {
    _inventoryController.dispose();
    super.dispose();
  }

  Future<void> _updateInventory() async {
    final inventoryText = _inventoryController.text.trim();
    if (inventoryText.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter a valid inventory amount'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    final newInventory = double.tryParse(inventoryText);
    if (newInventory == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter a valid number'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      await _firebaseService.updateMedicationInventory(
        _medication.id,
        newInventory,
      );

      setState(() {
        _medication = _medication.copyWithNewInventory(newInventory);
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Inventory updated successfully'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error updating inventory: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _showDeleteConfirmation(BuildContext context) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Medication'),
        content: Text('Are you sure you want to delete ${_medication.name}?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('CANCEL'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('DELETE'),
          ),
        ],
      ),
    );

    if (result == true) {
      setState(() => _isLoading = true);

      try {
        await _firebaseService.deleteMedication(_medication.id);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Medication deleted successfully'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.pop(context, true); // Return true to indicate deletion
      } catch (e) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error deleting medication: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  IconData _getMedicationIcon() {
    switch (_medication.type) {
      case MedicationType.tablet:
        return Icons.local_pharmacy;
      case MedicationType.capsule:
        return Icons.medication;
      case MedicationType.injection:
        if (_medication.isPreFilled == true) {
          return Icons.vaccines;
        } else if (_medication.needsReconstitution == true) {
          return Icons.science;
        } else {
          return Icons.water_drop;
        }
    }
  }

  Color _getMedicationColor() {
    switch (_medication.type) {
      case MedicationType.tablet:
        return Colors.blue;
      case MedicationType.capsule:
        return Colors.orange;
      case MedicationType.injection:
        if (_medication.isPreFilled == true) {
          return Colors.green;
        } else if (_medication.needsReconstitution == true) {
          return Colors.teal;
        } else {
          return Colors.purple;
        }
    }
  }

  String _getMedicationTypeName() {
    switch (_medication.type) {
      case MedicationType.tablet:
        return 'Tablet';
      case MedicationType.capsule:
        return 'Capsule';
      case MedicationType.injection:
        if (_medication.isPreFilled == true) {
          return 'Pre-filled Syringe';
        } else if (_medication.needsReconstitution == true) {
          return 'Powdered Vial (Needs Reconstitution)';
        } else {
          return 'Injection Vial';
        }
    }
  }

  @override
  Widget build(BuildContext context) {
    final color = _getMedicationColor();
    final icon = _getMedicationIcon();
    final typeName = _getMedicationTypeName();

    return Scaffold(
      appBar: AppBar(
        title: Text(_medication.name),
        actions: [
          IconButton(
            icon: const Icon(Icons.delete),
            onPressed: () => _showDeleteConfirmation(context),
            tooltip: 'Delete Medication',
          ),
        ],
      ),
      body: Container(
        decoration: AppDecorations.gradientBackground,
        child: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Medication Icon and Type
                    Center(
                      child: Column(
                        children: [
                          Container(
                            width: 80,
                            height: 80,
                            decoration: BoxDecoration(
                              color: color.withOpacity(0.2),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Icon(
                              icon,
                              size: 48,
                              color: color,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            typeName,
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                          const SizedBox(height: 24),
                        ],
                      ),
                    ),
                    
                    // Medication Details Card
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: AppColors.cardBackground,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Medication Details',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                          const SizedBox(height: 16),
                          _buildDetailRow('Strength', '${_medication.strength} ${_medication.strengthUnit}'),
                          
                          // Show reconstitution details if applicable
                          if (_medication.type == MedicationType.injection && _medication.needsReconstitution == true) ...[
                            if (_medication.reconstitutionVolume != null)
                              _buildDetailRow('Reconstitution Volume', '${_medication.reconstitutionVolume} ${_medication.reconstitutionVolumeUnit ?? 'mL'}'),
                            if (_medication.concentrationAfterReconstitution != null)
                              _buildDetailRow('Final Concentration', '${_medication.concentrationAfterReconstitution} ${_medication.strengthUnit}/mL'),
                          ],
                          
                          // Show volume for injections
                          if (_medication.type == MedicationType.injection && _medication.quantity > 0)
                            _buildDetailRow('Volume', '${_medication.quantity} mL'),
                        ],
                      ),
                    ),
                    
                    const SizedBox(height: 24),
                    
                    // Inventory Management Card
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: AppColors.cardBackground,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Inventory Management',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                          const SizedBox(height: 16),
                          _buildDetailRow('Current Inventory', '${_medication.currentInventory} ${_medication.quantityUnit}'),
                          const SizedBox(height: 16),
                          
                          // Update Inventory Form
                          const Text(
                            'Update Inventory',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Expanded(
                                child: TextFormField(
                                  controller: _inventoryController,
                                  keyboardType: TextInputType.number,
                                  decoration: AppDecorations.inputField(
                                    hintText: 'Enter new inventory amount',
                                    suffixText: _medication.quantityUnit,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 8),
                              ElevatedButton(
                                onPressed: _updateInventory,
                                child: const Text('UPDATE'),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              label,
              style: TextStyle(
                color: Colors.white.withOpacity(0.7),
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }
} 