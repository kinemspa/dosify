import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../theme/app_decorations.dart';

/// A simple input row with a label and input field
class SimpleInputRow extends StatelessWidget {
  /// The controller for the input field
  final TextEditingController controller;
  
  /// The label text to display
  final String label;
  
  /// Optional hint text for the input field
  final String? hint;
  
  /// Optional helper text to display below the input field
  final String? helperText;
  
  /// Optional error text to display below the input field
  final String? errorText;
  
  /// Input type for the field
  final TextInputType keyboardType;
  
  /// Optional input formatters
  final List<TextInputFormatter>? inputFormatters;
  
  /// Optional validator function
  final String? Function(String?)? validator;
  
  /// Optional suffix widget
  final Widget? suffix;
  
  /// Optional prefix widget
  final Widget? prefix;
  
  /// Whether the field is enabled
  final bool enabled;
  
  /// Whether the field is required
  final bool required;
  
  /// Optional maximum length of input
  final int? maxLength;
  
  /// Optional callback when the value changes
  final Function(String)? onChanged;

  /// Creates a new SimpleInputRow
  const SimpleInputRow({
    super.key,
    required this.controller,
    required this.label,
    this.hint,
    this.helperText,
    this.errorText,
    this.keyboardType = TextInputType.text,
    this.inputFormatters,
    this.validator,
    this.suffix,
    this.prefix,
    this.enabled = true,
    this.required = false,
    this.maxLength,
    this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                label,
                style: TextStyle(
                  fontWeight: FontWeight.w500,
                  color: Theme.of(context).brightness == Brightness.dark
                      ? Colors.white70
                      : Colors.black87,
                ),
              ),
              if (required)
                Text(
                  ' *',
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.error,
                    fontWeight: FontWeight.bold,
                  ),
                ),
            ],
          ),
          const SizedBox(height: 4),
          TextFormField(
            controller: controller,
            decoration: AppDecorations.inputField(
              hintText: hint,
              helperText: helperText,
              errorText: errorText,
              suffixIcon: suffix,
              prefixIcon: prefix,
            ),
            keyboardType: keyboardType,
            inputFormatters: inputFormatters,
            validator: validator,
            enabled: enabled,
            maxLength: maxLength,
            onChanged: onChanged,
          ),
        ],
      ),
    );
  }
}

/// A numeric input row with validation
class NumericInputRow extends StatelessWidget {
  /// The controller for the input field
  final TextEditingController controller;
  
  /// The label text to display
  final String label;
  
  /// Optional hint text for the input field
  final String? hint;
  
  /// Optional helper text to display below the input field
  final String? helperText;
  
  /// Optional error text to display below the input field
  final String? errorText;
  
  /// Whether to allow decimal values
  final bool allowDecimal;
  
  /// Optional suffix widget (like a unit dropdown)
  final Widget? suffix;
  
  /// Whether the field is enabled
  final bool enabled;
  
  /// Whether the field is required
  final bool required;
  
  /// Optional minimum value
  final double? minValue;
  
  /// Optional maximum value
  final double? maxValue;
  
  /// Optional callback when the value changes
  final Function(double?)? onChanged;

  /// Creates a new NumericInputRow
  const NumericInputRow({
    super.key,
    required this.controller,
    required this.label,
    this.hint,
    this.helperText,
    this.errorText,
    this.allowDecimal = true,
    this.suffix,
    this.enabled = true,
    this.required = false,
    this.minValue,
    this.maxValue,
    this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return SimpleInputRow(
      controller: controller,
      label: label,
      hint: hint,
      helperText: helperText,
      errorText: errorText,
      keyboardType: TextInputType.numberWithOptions(
        decimal: allowDecimal,
        signed: false,
      ),
      inputFormatters: [
        FilteringTextInputFormatter.allow(
          allowDecimal ? RegExp(r'^\d*\.?\d*$') : RegExp(r'^\d*$'),
        ),
      ],
      validator: (value) {
        if (required && (value == null || value.isEmpty)) {
          return 'This field is required';
        }
        
        if (value != null && value.isNotEmpty) {
          final numValue = double.tryParse(value);
          if (numValue == null) {
            return 'Please enter a valid number';
          }
          
          if (minValue != null && numValue < minValue!) {
            return 'Value must be at least ${minValue!}';
          }
          
          if (maxValue != null && numValue > maxValue!) {
            return 'Value must be at most ${maxValue!}';
          }
        }
        
        return null;
      },
      suffix: suffix,
      enabled: enabled,
      required: required,
      onChanged: (value) {
        if (onChanged != null) {
          onChanged!(double.tryParse(value));
        }
      },
    );
  }
} 