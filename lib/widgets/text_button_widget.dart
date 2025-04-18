import 'package:flutter/material.dart';

class TextButtonWidget extends StatelessWidget {
  final String text;
  final VoidCallback? onPressed; // Allow null onPressed to disable the button
  final EdgeInsets padding;
  final Color? textColor; // Optional override for text color

  const TextButtonWidget({
    super.key,
    required this.text,
    required this.onPressed,
    this.padding = const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
    this.textColor,
  });

  @override
  Widget build(BuildContext context) {
    final Color primaryColor = Theme.of(context).colorScheme.primary;
    final Color onSurfaceColor = Theme.of(context).colorScheme.onSurface;

    return TextButton(
      style: TextButton.styleFrom(
        padding: padding,
        foregroundColor: textColor ?? primaryColor, // Default to primary color
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8.0), // Example border radius
        ),
      ).copyWith(
        foregroundColor: MaterialStateProperty.resolveWith<Color?>((
          Set<MaterialState> states,
        ) {
          if (states.contains(MaterialState.disabled)) {
            return onSurfaceColor.withOpacity(0.38);
          }
          return textColor ?? primaryColor; // Use override or primary color
        }),
      ),
      onPressed: onPressed,
      child: Text(text),
    );
  }
}
