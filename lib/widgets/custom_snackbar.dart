import 'package:flutter/material.dart';

/// Shows a customized SnackBar notification.
void showAppSnackBar(
  BuildContext context,
  String message, {
  Duration duration = const Duration(seconds: 3),
  Color? backgroundColor,
}) {
  final theme = Theme.of(context);
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      content: Text(
        message,
        style: TextStyle(
          color: theme.colorScheme.onPrimary,
        ), // Use text color suitable for primary background
      ),
      backgroundColor:
          backgroundColor ??
          theme.colorScheme.primary.withOpacity(
            0.9,
          ), // Use primary color with slight transparency
      duration: duration,
      behavior:
          SnackBarBehavior
              .floating, // Make it float above bottom nav bar if any
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8.0)),
      margin: const EdgeInsets.all(10.0), // Add some margin
    ),
  );
}

/// Shows an error SnackBar notification.
void showErrorSnackBar(
  BuildContext context,
  String message, {
  Duration duration = const Duration(seconds: 4),
}) {
  final theme = Theme.of(context);
  showAppSnackBar(
    context,
    message,
    duration: duration,
    backgroundColor: theme.colorScheme.error.withOpacity(
      0.9,
    ), // Use error color
  );
}

/// Shows a success SnackBar notification.
void showSuccessSnackBar(
  BuildContext context,
  String message, {
  Duration duration = const Duration(seconds: 3),
}) {
  final theme = Theme.of(context);
  // Consider using secondary or a dedicated success color if available
  showAppSnackBar(
    context,
    message,
    duration: duration,
    backgroundColor: theme.colorScheme.secondary.withOpacity(
      0.9,
    ), // Use secondary color for success
  );
}
