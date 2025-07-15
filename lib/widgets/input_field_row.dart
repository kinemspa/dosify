import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../theme/app_colors.dart';

class InputFieldRow extends StatefulWidget {
  final String label;
  final String? infoText;
  final TextEditingController controller;
  final String unitValue;
  final List<String> unitOptions;
  final Function(String?) onUnitChanged;
  final double? incrementValue;
  final double minValue;
  final double? maxValue;
  final bool allowDecimals;
  final int decimalPlaces;
  final String? Function(String?)? validator;
  final String? errorText;
  final bool enabled;
  final String? accessibilityLabel;
  final String? accessibilityHint;
  final FocusNode? focusNode;
  final VoidCallback? onEditingComplete;
  final Function(String)? onChanged;

  const InputFieldRow({
    super.key,
    required this.label,
    this.infoText,
    required this.controller,
    required this.unitValue,
    required this.unitOptions,
    required this.onUnitChanged,
    this.incrementValue = 1.0,
    this.minValue = 0.0,
    this.maxValue,
    this.allowDecimals = true,
    this.decimalPlaces = 1,
    this.validator,
    this.errorText,
    this.enabled = true,
    this.accessibilityLabel,
    this.accessibilityHint,
    this.focusNode,
    this.onEditingComplete,
    this.onChanged,
  });

  @override
  State<InputFieldRow> createState() => _InputFieldRowState();
}

class _InputFieldRowState extends State<InputFieldRow> {
  late FocusNode _focusNode;
  String? _errorText;
  bool _hasFocus = false;

  @override
  void initState() {
    super.initState();
    _focusNode = widget.focusNode ?? FocusNode();
    _focusNode.addListener(_handleFocusChange);
    _errorText = widget.errorText;
  }

  @override
  void didUpdateWidget(InputFieldRow oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.errorText != widget.errorText) {
      setState(() {
        _errorText = widget.errorText;
      });
    }
  }

  void _handleFocusChange() {
    if (mounted) {
      setState(() {
        _hasFocus = _focusNode.hasFocus;
        if (!_hasFocus && widget.validator != null) {
          _errorText = widget.validator!(widget.controller.text);
        }
      });
    }
  }

  @override
  void dispose() {
    if (widget.focusNode == null) {
      _focusNode.removeListener(_handleFocusChange);
      _focusNode.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final bool isDarkMode = Theme.of(context).brightness == Brightness.dark;
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionHeader(context, widget.label, widget.infoText ?? ''),
        const SizedBox(height: 4),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Input Field
            Expanded(
              flex: 1,
              child: _buildNumberInput(
                context,
                widget.controller,
                widget.incrementValue ?? 1.0,
                widget.minValue,
                widget.maxValue,
              ),
            ),
            const SizedBox(width: 8),
            // Unit Dropdown
            Expanded(
              flex: 1,
              child: _buildDropdown<String>(
                value: widget.unitValue,
                items: widget.unitOptions.map((unit) => DropdownMenuItem(
                  value: unit,
                  child: Text(unit),
                )).toList(),
                onChanged: widget.enabled ? widget.onUnitChanged : null,
                context: context,
              ),
            ),
          ],
        ),
        if (_errorText != null)
          Padding(
            padding: const EdgeInsets.only(top: 4.0, left: 4.0),
            child: Text(
              _errorText!,
              style: TextStyle(
                color: Theme.of(context).colorScheme.error,
                fontSize: 12.0,
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildSectionHeader(BuildContext context, String title, String infoText) {
    final bool isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final Color textColor = isDarkMode ? AppColors.darkTextPrimary : AppColors.lightTextPrimary;
    final Color iconColor = isDarkMode ? Colors.white70 : Colors.black54;
    
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          title,
          style: TextStyle(
            color: textColor,
            fontWeight: FontWeight.bold,
            fontSize: 14,
          ),
        ),
        if (infoText.isNotEmpty)
          IconButton(
            icon: Icon(Icons.info_outline, size: 16, color: iconColor),
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(),
            visualDensity: VisualDensity.compact,
            onPressed: () => _showInfoDialog(context, title, infoText),
            tooltip: infoText,
          ),
      ],
    );
  }

  void _showInfoDialog(BuildContext context, String title, String content) {
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

  // Build a number input with increment/decrement buttons
  Widget _buildNumberInput(
    BuildContext context,
    TextEditingController controller,
    double incrementValue,
    double minValue,
    double? maxValue,
  ) {
    final bool isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final Color fillColor = isDarkMode ? AppColors.darkSurface : Colors.white;
    final Color textColor = isDarkMode ? AppColors.darkTextPrimary : AppColors.lightTextPrimary;
    final Color iconColor = widget.enabled 
        ? Theme.of(context).colorScheme.primary
        : Theme.of(context).disabledColor;
    
    // Create a formatter that respects decimal places
    final inputFormatters = [
      FilteringTextInputFormatter.allow(
        widget.allowDecimals 
            ? RegExp(r'^\d*\.?\d*') 
            : RegExp(r'^\d+')
      ),
    ];
    
    // For accessibility
    final String accessibilityLabel = widget.accessibilityLabel ?? 
        '${widget.label} input field, current value: ${controller.text} ${widget.unitValue}';
    final String accessibilityHint = widget.accessibilityHint ?? 
        'Enter a value between $minValue${maxValue != null ? ' and $maxValue' : ''}';
    
    return Semantics(
      label: accessibilityLabel,
      hint: accessibilityHint,
      value: controller.text,
      enabled: widget.enabled,
      textField: true,
      child: SizedBox(
        height: 48,
        child: TextFormField(
          controller: controller,
          focusNode: _focusNode,
          enabled: widget.enabled,
          keyboardType: TextInputType.numberWithOptions(decimal: widget.allowDecimals),
          inputFormatters: inputFormatters,
          decoration: InputDecoration(
            filled: true,
            fillColor: widget.enabled ? fillColor : (isDarkMode ? Colors.grey[800] : Colors.grey[200]),
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 0),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(4),
              borderSide: _hasFocus || _errorText != null
                  ? BorderSide(
                      color: _errorText != null
                          ? Theme.of(context).colorScheme.error
                          : Theme.of(context).colorScheme.primary,
                      width: 1.5,
                    )
                  : BorderSide.none,
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(4),
              borderSide: _errorText != null
                  ? BorderSide(
                      color: Theme.of(context).colorScheme.error,
                      width: 1.5,
                    )
                  : BorderSide.none,
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(4),
              borderSide: BorderSide(
                color: _errorText != null
                    ? Theme.of(context).colorScheme.error
                    : Theme.of(context).colorScheme.primary,
                width: 1.5,
              ),
            ),
            prefixIcon: IconButton(
              icon: Icon(Icons.remove, size: 20, color: iconColor),
              onPressed: widget.enabled ? () {
                final currentValue = double.tryParse(controller.text) ?? 0;
                if (currentValue > minValue) {
                  final newValue = (currentValue - incrementValue).clamp(
                    minValue,
                    maxValue ?? double.infinity,
                  );
                  controller.text = newValue.toStringAsFixed(
                    incrementValue < 1 ? widget.decimalPlaces : 0
                  );
                  if (widget.onChanged != null) {
                    widget.onChanged!(controller.text);
                  }
                  // Validate on change if validator exists
                  if (widget.validator != null) {
                    setState(() {
                      _errorText = widget.validator!(controller.text);
                    });
                  }
                }
              } : null,
              tooltip: 'Decrease value',
            ),
            suffixIcon: IconButton(
              icon: Icon(Icons.add, size: 20, color: iconColor),
              onPressed: widget.enabled ? () {
                final currentValue = double.tryParse(controller.text) ?? 0;
                if (maxValue == null || currentValue < maxValue) {
                  final newValue = (currentValue + incrementValue).clamp(
                    minValue,
                    maxValue ?? double.infinity,
                  );
                  controller.text = newValue.toStringAsFixed(
                    incrementValue < 1 ? widget.decimalPlaces : 0
                  );
                  if (widget.onChanged != null) {
                    widget.onChanged!(controller.text);
                  }
                  // Validate on change if validator exists
                  if (widget.validator != null) {
                    setState(() {
                      _errorText = widget.validator!(controller.text);
                    });
                  }
                }
              } : null,
              tooltip: 'Increase value',
            ),
          ),
          style: TextStyle(
            color: widget.enabled ? textColor : Theme.of(context).disabledColor,
          ),
          onChanged: (value) {
            if (widget.onChanged != null) {
              widget.onChanged!(value);
            }
            // Validate on change if validator exists
            if (widget.validator != null) {
              setState(() {
                _errorText = widget.validator!(value);
              });
            }
          },
          onEditingComplete: widget.onEditingComplete,
          validator: widget.validator,
        ),
      ),
    );
  }

  // Build a dropdown with consistent styling
  Widget _buildDropdown<T>({
    required BuildContext context,
    required T value,
    required List<DropdownMenuItem<T>> items,
    required void Function(T?)? onChanged,
  }) {
    final bool isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final Color fillColor = isDarkMode ? AppColors.darkSurface : Colors.white;
    final Color textColor = isDarkMode ? AppColors.darkTextPrimary : AppColors.lightTextPrimary;
    final Color dropdownColor = isDarkMode ? AppColors.darkSurface : Colors.white;
    
    return Semantics(
      label: '${widget.label} unit selection',
      value: value.toString(),
      enabled: widget.enabled,
      child: SizedBox(
        height: 48,
        child: DropdownButtonFormField<T>(
          value: value,
          items: items,
          onChanged: onChanged,
          decoration: InputDecoration(
            filled: true,
            fillColor: widget.enabled ? fillColor : (isDarkMode ? Colors.grey[800] : Colors.grey[200]),
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 0),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(4),
              borderSide: BorderSide.none,
            ),
            disabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(4),
              borderSide: BorderSide.none,
            ),
          ),
          style: TextStyle(
            color: widget.enabled ? textColor : Theme.of(context).disabledColor,
          ),
          dropdownColor: dropdownColor,
          icon: Icon(
            Icons.arrow_drop_down,
            color: widget.enabled ? null : Theme.of(context).disabledColor,
          ),
          isExpanded: true,
          isDense: false,
        ),
      ),
    );
  }
}