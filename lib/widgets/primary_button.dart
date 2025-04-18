import 'package:flutter/material.dart';

class PrimaryButton extends StatelessWidget {
  final String text;
  final VoidCallback? onPressed; // Allow null onPressed to disable the button
  final EdgeInsets padding;
  final double? minWidth; // Optional minimum width

  const PrimaryButton({
    super.key,
    required this.text,
    required this.onPressed,
    this.padding = const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
    this.minWidth,
  });

  @override
  Widget build(BuildContext context) {
    // Use the ElevatedButton theme defined in ThemeProvider
    final ButtonStyle? buttonStyle =
        Theme.of(context).elevatedButtonTheme.style;

    return ElevatedButton(
      style: buttonStyle?.copyWith(
        minimumSize:
            minWidth != null
                ? MaterialStateProperty.all(Size(minWidth!, 0))
                : null,
        padding: MaterialStateProperty.all(padding),
        // Ensure foreground color (text) is handled correctly by the theme
        // foregroundColor: MaterialStateProperty.resolveWith<Color?>(
        //   (Set<MaterialState> states) {
        //     if (states.contains(MaterialState.disabled)) {
        //       return Theme.of(context).colorScheme.onSurface.withOpacity(0.38);
        //     }
        //     return Theme.of(context).colorScheme.onPrimary; // Use onPrimary from theme
        //   },
        // ),
        // Ensure background color is handled correctly by the theme
        // backgroundColor: MaterialStateProperty.resolveWith<Color?>(
        //    (Set<MaterialState> states) {
        //      if (states.contains(MaterialState.disabled)) {
        //         return Theme.of(context).colorScheme.onSurface.withOpacity(0.12);
        //      }
        //      return Theme.of(context).colorScheme.primary; // Use primary from theme
        //    },
        // ),
      ),
      onPressed: onPressed,
      child: Text(text), // Text style should also be inherited or defined
    );
  }
}
