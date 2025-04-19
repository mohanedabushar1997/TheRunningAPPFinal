import 'package:flutter/material.dart';

class CustomTextField extends StatelessWidget {
  final TextEditingController? controller;
  final String? labelText;
  final String? hintText;
  final IconData? prefixIcon;
  final TextInputType? keyboardType;
  final bool obscureText;
  final String? Function(String?)? validator; // For form validation
  final ValueChanged<String>? onChanged;
  final int? maxLines;
  final FocusNode? focusNode;
  final TextCapitalization textCapitalization; // Added

  const CustomTextField({
    super.key,
    this.controller,
    this.labelText,
    this.hintText,
    this.prefixIcon,
    this.keyboardType,
    this.obscureText = false,
    this.validator,
    this.onChanged,
    this.maxLines = 1,
    this.focusNode,
    this.textCapitalization = TextCapitalization.none, // Added with default
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return TextFormField(
      controller: controller,
      focusNode: focusNode,
      keyboardType: keyboardType,
      obscureText: obscureText,
      maxLines: maxLines,
      decoration: InputDecoration(
        labelText: labelText,
        hintText: hintText,
        prefixIcon:
            prefixIcon != null
                ? Icon(prefixIcon, color: colorScheme.primary)
                : null,
        // Style the border - using OutlineInputBorder as an example
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
        // Add content padding
        contentPadding: const EdgeInsets.symmetric(
          vertical: 12.0,
          horizontal: 16.0,
        ),
        // TODO: Customize label/hint styles if needed from theme text styles
        // labelStyle: TextStyle(color: colorScheme.primary),
        // hintStyle: TextStyle(color: colorScheme.onSurface.withOpacity(0.6)),
      ),
      validator: validator, // Integrate validator function
      onChanged: onChanged,
      textCapitalization: textCapitalization, // Pass down parameter
      // TODO: Add input formatters if needed (e.g., for numbers)
      // inputFormatters: [],
    );
  }
}
