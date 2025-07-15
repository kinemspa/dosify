import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../theme/app_decorations.dart';
import '../theme/app_colors.dart';

class NumberInputField extends StatefulWidget {
  final TextEditingController controller;
  final String? label;
  final String? hintText;
  final String? suffixText;
  final String? helperText;
  final bool allowDecimals;
  final int decimalPlaces;
  final bool required;
  final double? minValue;
  final double? maxValue;
  final bool showIncrementButtons;
  final double incrementAmount;
  final Function(String)? onChanged;
  final Color? labelColor;

  const NumberInputField({
    super.key,
    required this.controller,
    this.label,
    this.hintText,
    this.suffixText,
    this.helperText,
    this.allowDecimals = true,
    this.decimalPlaces = 2,
    this.required = true,
    this.minValue,
    this.maxValue,
    this.showIncrementButtons = false,
    this.incrementAmount = 1.0,
    this.onChanged,
    this.labelColor,
  });

  @override
  State<NumberInputField> createState() => _NumberInputFieldState();
}

class _NumberInputFieldState extends State<NumberInputField> {
  late final RegExp _inputRegex;
  final FocusNode _focusNode = FocusNode();
  bool _isFocused = false;
  
  @override
  void initState() {
    super.initState();
    
    if (widget.allowDecimals) {
      // Allow digits and at most one decimal point, with specific decimal places
      _inputRegex = RegExp(r'^\d*\.?\d{0,' + widget.decimalPlaces.toString() + r'}');
    } else {
      // Only allow digits
      _inputRegex = RegExp(r'^\d+');
    }
    
    _focusNode.addListener(() {
      setState(() {
        _isFocused = _focusNode.hasFocus;
      });
    });
  }
  
  @override
  void dispose() {
    _focusNode.dispose();
    super.dispose();
  }
  
  void _increment() {
    double currentValue = double.tryParse(widget.controller.text) ?? 0;
    double newValue = currentValue + widget.incrementAmount;
    
    if (widget.maxValue != null && newValue > widget.maxValue!) {
      newValue = widget.maxValue!;
    }
    
    _updateValue(newValue);
  }
  
  void _decrement() {
    double currentValue = double.tryParse(widget.controller.text) ?? 0;
    double newValue = currentValue - widget.incrementAmount;
    
    if (widget.minValue != null && newValue < widget.minValue!) {
      newValue = widget.minValue!;
    } else if (newValue < 0) {
      newValue = 0;
    }
    
    _updateValue(newValue);
  }
  
  void _updateValue(double value) {
    String formattedValue;
    
    if (widget.allowDecimals) {
      if (widget.decimalPlaces > 0) {
        formattedValue = value.toStringAsFixed(widget.decimalPlaces);
        // Remove trailing zeros
        if (formattedValue.contains('.')) {
          formattedValue = formattedValue.replaceAll(RegExp(r'0+$'), '');
          formattedValue = formattedValue.replaceAll(RegExp(r'\.$'), '');
        }
      } else {
        formattedValue = value.toInt().toString();
      }
    } else {
      formattedValue = value.toInt().toString();
    }
    
    widget.controller.text = formattedValue;
    if (widget.onChanged != null) {
      widget.onChanged!(formattedValue);
    }
  }

  @override
  Widget build(BuildContext context) {
    // Use theme-aware colors
    final Color iconColor = Theme.of(context).colorScheme.primary;
    
    final Color labelTextColor = widget.labelColor ?? 
        (Theme.of(context).brightness == Brightness.dark 
            ? Colors.white 
            : Theme.of(context).colorScheme.onSurface);

    final borderColor = _isFocused 
        ? Theme.of(context).colorScheme.primary 
        : Theme.of(context).inputDecorationTheme.enabledBorder?.borderSide.color ?? 
            Colors.grey.withOpacity(0.3);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (widget.label != null) ...[
          Text(
            widget.label!,
            style: TextStyle(
              color: labelTextColor,
              fontWeight: FontWeight.bold,
              fontSize: 14,
            ),
          ),
          const SizedBox(height: 8),
        ],
        Container(
          height: 48,
          decoration: BoxDecoration(
            color: Theme.of(context).brightness == Brightness.dark 
                ? Theme.of(context).inputDecorationTheme.fillColor
                : Colors.white,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: borderColor,
              width: _isFocused ? 2.0 : 1.0,
            ),
            boxShadow: _isFocused ? [
              BoxShadow(
                color: Theme.of(context).colorScheme.primary.withOpacity(0.2),
                blurRadius: 4,
                offset: const Offset(0, 2),
              ),
            ] : null,
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              if (widget.showIncrementButtons)
                InkWell(
                  onTap: _decrement,
                  child: Container(
                    height: 48,
                    width: 40,
                    decoration: BoxDecoration(
                      color: Theme.of(context).brightness == Brightness.dark 
                          ? Theme.of(context).inputDecorationTheme.fillColor
                          : Colors.white,
                      borderRadius: const BorderRadius.only(
                        topLeft: Radius.circular(8),
                        bottomLeft: Radius.circular(8),
                      ),
                    ),
                    child: Icon(
                      Icons.remove,
                      size: 20,
                      color: iconColor,
                    ),
                  ),
                ),
              Expanded(
                child: TextFormField(
                  controller: widget.controller,
                  focusNode: _focusNode,
                  keyboardType: TextInputType.numberWithOptions(
                    decimal: widget.allowDecimals,
                  ),
                  inputFormatters: [
                    FilteringTextInputFormatter.allow(_inputRegex),
                  ],
                  textAlign: TextAlign.center,
                  decoration: InputDecoration(
                    hintText: widget.hintText,
                    filled: true,
                    fillColor: Colors.transparent,
                    contentPadding: EdgeInsets.only(
                      top: 12, 
                      bottom: 12,
                      left: widget.showIncrementButtons ? 0 : 12,
                      right: widget.suffixText != null ? 0 : (widget.showIncrementButtons ? 0 : 12),
                    ),
                    // Remove all borders
                    border: InputBorder.none,
                    enabledBorder: InputBorder.none,
                    focusedBorder: InputBorder.none,
                    errorBorder: InputBorder.none,
                    disabledBorder: InputBorder.none,
                  ),
                  validator: (value) {
                    if (widget.required && (value == null || value.isEmpty)) {
                      return 'This field is required';
                    }
                    
                    final double? numValue = double.tryParse(value ?? '');
                    if (numValue == null) {
                      return 'Please enter a valid number';
                    }
                    
                    if (widget.minValue != null && numValue < widget.minValue!) {
                      return 'Value must be at least ${widget.minValue}';
                    }
                    
                    if (widget.maxValue != null && numValue > widget.maxValue!) {
                      return 'Value must be at most ${widget.maxValue}';
                    }
                    
                    return null;
                  },
                  onChanged: widget.onChanged,
                  style: TextStyle(
                    color: Theme.of(context).brightness == Brightness.dark 
                        ? Colors.white 
                        : Colors.black87,
                  ),
                ),
              ),
              if (widget.suffixText != null)
                Padding(
                  padding: const EdgeInsets.only(right: 12.0),
                  child: Text(
                    widget.suffixText!,
                    style: TextStyle(
                      color: iconColor,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              if (widget.showIncrementButtons)
                InkWell(
                  onTap: _increment,
                  child: Container(
                    height: 48,
                    width: 40,
                    decoration: BoxDecoration(
                      color: Theme.of(context).brightness == Brightness.dark 
                          ? Theme.of(context).inputDecorationTheme.fillColor
                          : Colors.white,
                      borderRadius: const BorderRadius.only(
                        topRight: Radius.circular(8),
                        bottomRight: Radius.circular(8),
                      ),
                    ),
                    child: Icon(
                      Icons.add,
                      size: 20,
                      color: iconColor,
                    ),
                  ),
                ),
            ],
          ),
        ),
        if (widget.helperText != null)
          Padding(
            padding: const EdgeInsets.only(top: 4.0, left: 8.0),
            child: Text(
              widget.helperText!,
              style: TextStyle(
                fontSize: 12,
                color: Theme.of(context).brightness == Brightness.dark 
                    ? Colors.white70 
                    : Colors.black54,
              ),
            ),
          ),
      ],
    );
  }
} 