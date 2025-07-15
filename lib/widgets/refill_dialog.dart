import 'package:flutter/material.dart';
import 'number_input_field.dart';

class RefillDialog extends StatelessWidget {
  final String medicationName;
  final int currentInventory;
  final String quantityUnit;
  final TextEditingController refillAmountController;

  const RefillDialog({
    super.key,
    required this.medicationName,
    required this.currentInventory,
    required this.quantityUnit,
    required this.refillAmountController,
  });

  static TextEditingController? _refillAmountController;

  static Future<bool?> show({
    required BuildContext context,
    required String medicationName,
    required int currentInventory,
    required String quantityUnit,
  }) {
    _refillAmountController = TextEditingController(text: '0');
    
    return showDialog<bool>(
      context: context,
      builder: (context) => RefillDialog(
        medicationName: medicationName,
        currentInventory: currentInventory,
        quantityUnit: quantityUnit,
        refillAmountController: _refillAmountController!,
      ),
    ).then((result) {
      // Controller will be disposed when no longer needed
      return result;
    });
  }

  static String getRefillAmount() {
    if (_refillAmountController == null) {
      return '0';
    }
    final amount = _refillAmountController!.text;
    _refillAmountController!.dispose();
    _refillAmountController = null;
    return amount;
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Refill Medication Stock'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Current inventory: $currentInventory $quantityUnit',
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          const Text(
            'Enter the amount to add to your current stock:',
          ),
          const SizedBox(height: 8),
          NumberInputField(
            controller: refillAmountController,
            label: 'Amount to Add',
            hintText: 'Enter amount',
            suffixText: quantityUnit,
            allowDecimals: false,
            showIncrementButtons: true,
            incrementAmount: 1.0,
            minValue: 0,
          ),
          const SizedBox(height: 16),
          const Text(
            'Note: This will add to your current inventory, not replace it.',
            style: TextStyle(
              fontSize: 12,
              fontStyle: FontStyle.italic,
            ),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context, false),
          child: const Text('CANCEL'),
        ),
        TextButton(
          onPressed: () => Navigator.pop(context, true),
          child: const Text('REFILL'),
        ),
      ],
    );
  }
} 