import 'package:flutter/material.dart';

class InfoButton extends StatelessWidget {
  final String title;
  final String content;
  final Color? iconColor;
  final double iconSize;

  const InfoButton({
    super.key,
    required this.title,
    required this.content,
    this.iconColor,
    this.iconSize = 16,
  });

  void _showInfoDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: Text(content),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final color = iconColor ?? (Theme.of(context).brightness == Brightness.dark 
        ? Colors.white70 
        : Theme.of(context).colorScheme.primary.withOpacity(0.7));
    
    return IconButton(
      icon: Icon(Icons.info_outline, size: iconSize, color: color),
      padding: EdgeInsets.zero,
      constraints: const BoxConstraints(),
      visualDensity: VisualDensity.compact,
      onPressed: () => _showInfoDialog(context),
      tooltip: title,
    );
  }
} 