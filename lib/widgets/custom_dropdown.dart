import 'package:flutter/material.dart';

// Generic Custom Dropdown Widget
class CustomDropdown<T> extends StatelessWidget {
  final T? value; // The currently selected value
  final List<DropdownMenuItem<T>> items; // List of items to display
  final ValueChanged<T?>? onChanged; // Callback when value changes
  final String? hintText;
  final String? labelText;
  final IconData? prefixIcon;
  final String? Function(T?)? validator; // For form validation
  final FocusNode? focusNode;

  const CustomDropdown({
    super.key,
    required this.items,
    required this.onChanged,
    this.value,
    this.hintText,
    this.labelText,
    this.prefixIcon,
    this.validator,
    this.focusNode,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return DropdownButtonFormField<T>(
      value: value,
      items: items,
      onChanged: onChanged,
      focusNode: focusNode,
      validator: validator,
      // Style the dropdown to match the text field
      decoration: InputDecoration(
        labelText: labelText,
        hintText: hintText,
        prefixIcon:
            prefixIcon != null
                ? Icon(prefixIcon, color: colorScheme.primary)
                : null,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8.0),
          borderSide: BorderSide(color: colorScheme.onSurface.withOpacity(0.3)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8.0),
          borderSide: BorderSide(color: colorScheme.onSurface.withOpacity(0.3)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8.0),
          borderSide: BorderSide(color: colorScheme.primary, width: 1.5),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8.0),
          borderSide: BorderSide(color: colorScheme.error, width: 1.5),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8.0),
          borderSide: BorderSide(color: colorScheme.error, width: 1.5),
        ),
        contentPadding: const EdgeInsets.symmetric(
          vertical: 12.0,
          horizontal: 16.0,
        ),
      ),
      // Customize dropdown appearance
      isExpanded: true, // Make dropdown take full width available
      icon: Icon(
        Icons.arrow_drop_down,
        color: colorScheme.onSurface.withOpacity(0.6),
      ),
      // TODO: Customize dropdown menu style if needed (background color, etc.)
      // dropdownColor: colorScheme.surface,
    );
  }
}

// Example Usage:
//
// CustomDropdown<String>(
//   labelText: 'Select Gender',
//   value: _selectedGender, // Your state variable
//   items: ['Male', 'Female', 'Other', 'Prefer not to say']
//       .map((label) => DropdownMenuItem(
//             value: label,
//             child: Text(label),
//           ))
//       .toList(),
//   onChanged: (newValue) {
//     setState(() {
//       _selectedGender = newValue;
//     });
//   },
//   validator: (value) => value == null ? 'Please select a gender' : null,
// ),
