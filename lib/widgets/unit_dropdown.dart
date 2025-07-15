import 'package:flutter/material.dart';

class UnitDropdown extends StatelessWidget {
  final String value;
  final List<String> units;
  final Function(String?) onChanged;
  final String? helperText;

  const UnitDropdown({
    super.key,
    required this.value,
    required this.units,
    required this.onChanged,
    this.helperText,
  });

  @override
  Widget build(BuildContext context) {
    final FocusNode focusNode = FocusNode();
    final ValueNotifier<bool> isFocused = ValueNotifier<bool>(false);

    focusNode.addListener(() {
      isFocused.value = focusNode.hasFocus;
    });

    return ValueListenableBuilder<bool>(
      valueListenable: isFocused,
      builder: (context, focused, _) {
        final borderColor = focused 
          ? Theme.of(context).colorScheme.primary 
          : Theme.of(context).inputDecorationTheme.enabledBorder?.borderSide.color ?? 
              Colors.grey.withOpacity(0.3);
        
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              height: 48, // Fixed height to match NumberInputField
              decoration: BoxDecoration(
                color: Theme.of(context).brightness == Brightness.dark 
                  ? Theme.of(context).inputDecorationTheme.fillColor
                  : Colors.white,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: borderColor,
                  width: focused ? 2.0 : 1.0,
                ),
                boxShadow: focused ? [
                  BoxShadow(
                    color: Theme.of(context).colorScheme.primary.withOpacity(0.2),
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
                ] : null,
              ),
              child: DropdownButtonFormField<String>(
                value: value,
                focusNode: focusNode,
                decoration: const InputDecoration(
                  contentPadding: EdgeInsets.symmetric(horizontal: 12),
                  border: InputBorder.none,
                  enabledBorder: InputBorder.none,
                  focusedBorder: InputBorder.none,
                  errorBorder: InputBorder.none,
                  disabledBorder: InputBorder.none,
                ),
                dropdownColor: Theme.of(context).cardColor,
                items: units
                    .map((unit) => DropdownMenuItem(
                          value: unit,
                          child: Text(unit),
                        ))
                    .toList(),
                onChanged: onChanged,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please select a unit';
                  }
                  return null;
                },
                isExpanded: true, // Make sure dropdown uses full width
              ),
            ),
            if (helperText != null)
              Padding(
                padding: const EdgeInsets.only(top: 4.0, left: 8.0),
                child: Text(
                  helperText!,
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
    );
  }
} 