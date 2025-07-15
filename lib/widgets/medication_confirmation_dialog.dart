import 'package:flutter/material.dart';

class MedicationConfirmationDialog extends StatelessWidget {
  final String title;
  final List<ConfirmationItem> items;

  const MedicationConfirmationDialog({
    super.key,
    required this.title,
    required this.items,
  });

  static Future<bool?> show({
    required BuildContext context,
    required String title,
    required List<ConfirmationItem> items,
  }) {
    return showDialog<bool>(
      context: context,
      builder: (context) => MedicationConfirmationDialog(
        title: title,
        items: items,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(title),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Please confirm the medication details:',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            
            // Medication details in colored containers
            ...items.map((item) => _buildItemContainer(item)),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context, false),
          child: const Text('CANCEL'),
        ),
        TextButton(
          onPressed: () => Navigator.pop(context, true),
          child: const Text('SAVE'),
        ),
      ],
    );
  }

  Widget _buildItemContainer(ConfirmationItem item) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: item.color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          children: [
            Icon(item.icon, color: item.color),
            const SizedBox(width: 8),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(item.label, style: const TextStyle(fontWeight: FontWeight.bold)),
                  Text(item.value),
                  if (item.subtitle != null)
                    Text(
                      item.subtitle!,
                      style: const TextStyle(fontSize: 12, color: Colors.grey),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class ConfirmationItem {
  final String label;
  final String value;
  final IconData icon;
  final Color color;
  final String? subtitle;

  const ConfirmationItem({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
    this.subtitle,
  });
} 