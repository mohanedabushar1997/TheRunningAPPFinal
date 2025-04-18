import 'package:flutter/material.dart';
import '../controllers/theme_provider.dart'; // To access AppColors

class SecondaryButton extends StatelessWidget {
  final String text;
  final VoidCallback? onPressed; // Allow null onPressed to disable the button
  final EdgeInsets padding;
  final double? minWidth; // Optional minimum width

  const SecondaryButton({
    super.key,
    required this.text,
    required this.onPressed,
    this.padding = const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
    this.minWidth,
  });

  @override
  Widget build(BuildContext context) {
    final Color secondaryColor = Theme.of(context).colorScheme.secondary;
    final Color onSurfaceColor = Theme.of(context).colorScheme.onSurface;

    return OutlinedButton(
      style: OutlinedButton.styleFrom(
        minimumSize: minWidth != null ? Size(minWidth!, 0) : null,
        padding: padding,
        foregroundColor: secondaryColor, // Text color
        side: BorderSide(
          color:
              onPressed != null
                  ? secondaryColor
                  : onSurfaceColor.withOpacity(0.12), // Border color
          width: 1.5, // Slightly thicker border?
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8.0), // Example border radius
        ),
      ).copyWith(
        // Handle disabled state explicitly if needed
        foregroundColor: MaterialStateProperty.resolveWith<Color?>((
          Set<MaterialState> states,
        ) {
          if (states.contains(MaterialState.disabled)) {
            return onSurfaceColor.withOpacity(0.38);
          }
          return secondaryColor; // Use secondary color for text
        }),
      ),
      onPressed: onPressed,
      child: Text(text),
    );
  }
}
