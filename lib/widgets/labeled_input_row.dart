import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../theme/app_colors.dart';
import '../theme/app_text_styles.dart';

/// A customizable labeled input row with validation and accessibility support
class LabeledInputRow extends StatefulWidget {
  /// The label text displayed above the input field
  final String label;
  
  /// Optional information text shown when info icon is tapped
  final String? infoText;
  
  /// Controller for the text input field
  final TextEditingController controller;
  
  /// Placeholder text shown when the input field is empty
  final String? placeholder;
  
  /// The type of keyboard to use for editing the text
  final TextInputType keyboardType;
  
  /// Optional list of input formatters to apply to the input field
  final List<TextInputFormatter>? inputFormatters;
  
  /// Optional validator function to validate the input
  final String? Function(String?)? validator;
  
  /// Optional error text to display below the input field
  final String? errorText;
  
  /// Whether the input field is enabled
  final bool enabled;
  
  /// Optional label for accessibility
  final String? accessibilityLabel;
  
  /// Optional hint for accessibility
  final String? accessibilityHint;
  
  /// Optional focus node for the input field
  final FocusNode? focusNode;
  
  /// Optional callback when editing is complete
  final VoidCallback? onEditingComplete;
  
  /// Optional callback when the input value changes
  final Function(String)? onChanged;
  
  /// Optional suffix widget displayed at the end of the input field
  final Widget? suffix;
  
  /// Optional prefix widget displayed at the beginning of the input field
  final Widget? prefix;
  
  /// Maximum number of lines for the input field
  final int? maxLines;
  
  /// Minimum number of lines for the input field
  final int? minLines;
  
  /// Whether to obscure the text (for passwords)
  final bool obscureText;
  
  /// Optional text style for the input field
  final TextStyle? textStyle;
  
  /// Optional decoration style for the input field
  final InputDecoration? decoration;
  
  /// Optional background color for the input field
  final Color? backgroundColor;

  const LabeledInputRow({
    super.key,
    required this.label,
    this.infoText,
    required this.controller,
    this.placeholder,
    this.keyboardType = TextInputType.text,
    this.inputFormatters,
    this.validator,
    this.errorText,
    this.enabled = true,
    this.accessibilityLabel,
    this.accessibilityHint,
    this.focusNode,
    this.onEditingComplete,
    this.onChanged,
    this.suffix,
    this.prefix,
    this.maxLines = 1,
    this.minLines,
    this.obscureText = false,
    this.textStyle,
    this.decoration,
    this.backgroundColor,
  });

  @override
  State<LabeledInputRow> createState() => _LabeledInputRowState();
}

class _LabeledInputRowState extends State<LabeledInputRow> {
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
  void didUpdateWidget(LabeledInputRow oldWidget) {
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
    final Color textColor = isDarkMode ? AppColors.darkTextPrimary : AppColors.lightTextPrimary;
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionHeader(context, widget.label, widget.infoText ?? ''),
        const SizedBox(height: 4),
        _buildInputField(context),
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

  Widget _buildInputField(BuildContext context) {
    final bool isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final Color fillColor = widget.backgroundColor ?? 
        (isDarkMode ? AppColors.darkSurface : Colors.white);
    final Color textColor = isDarkMode ? AppColors.darkTextPrimary : AppColors.lightTextPrimary;
    
    final String accessibilityLabel = widget.accessibilityLabel ?? 
        '${widget.label} input field, current value: ${widget.controller.text}';
    final String accessibilityHint = widget.accessibilityHint ?? 
        'Enter ${widget.label.toLowerCase()}';
    
    final InputDecoration defaultDecoration = InputDecoration(
      filled: true,
      fillColor: widget.enabled 
          ? fillColor 
          : (isDarkMode ? Colors.grey[800] : Colors.grey[200]),
      hintText: widget.placeholder,
      hintStyle: TextStyle(
        color: isDarkMode ? Colors.grey[400] : Colors.grey[600],
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
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
      prefixIcon: widget.prefix,
      suffixIcon: widget.suffix,
    );
    
    return Semantics(
      label: accessibilityLabel,
      hint: accessibilityHint,
      value: widget.controller.text,
      enabled: widget.enabled,
      textField: true,
      child: TextFormField(
        controller: widget.controller,
        focusNode: _focusNode,
        enabled: widget.enabled,
        keyboardType: widget.keyboardType,
        inputFormatters: widget.inputFormatters,
        decoration: widget.decoration ?? defaultDecoration,
        style: widget.textStyle ?? TextStyle(
          color: widget.enabled ? textColor : Theme.of(context).disabledColor,
        ),
        maxLines: widget.maxLines,
        minLines: widget.minLines,
        obscureText: widget.obscureText,
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
    );
  }
} 