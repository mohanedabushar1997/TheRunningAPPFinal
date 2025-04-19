import 'package:flutter/material.dart';

/// Shows a customized AlertDialog styled according to the app's theme.
Future<T?> showAppDialog<T>({
  required BuildContext context,
  required String title,
  required Widget content, // Use Widget for flexible content
  List<Widget>? actions, // Optional custom actions
  bool barrierDismissible = true,
}) {
  final theme = Theme.of(context);

  return showDialog<T>(
    context: context,
    barrierDismissible: barrierDismissible,
    builder: (BuildContext context) {
      return AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12.0),
        ),
        backgroundColor: theme.cardColor, // Use card color for background
        title: Text(
          title,
          style: theme.textTheme.headlineSmall?.copyWith(
            color: theme.colorScheme.primary, // Use primary color for title
          ),
        ),
        content: DefaultTextStyle(
          // Ensure content uses default text theme
          style: theme.textTheme.bodyLarge ?? const TextStyle(),
          child: content,
        ),
        actions:
            actions ?? // Default actions if none provided
            [
              TextButton(
                child: Text(
                  'OK',
                  style: TextStyle(color: theme.colorScheme.primary),
                ),
                onPressed: () {
                  Navigator.of(context).pop(); // Pop with null
                },
              ),
            ],
        actionsPadding: const EdgeInsets.symmetric(
          horizontal: 16.0,
          vertical: 8.0,
        ),
      );
    },
  );
}

/// Shows a confirmation dialog with Yes/No options.
/// Returns `true` if 'Yes' is pressed, `false` if 'No' is pressed, `null` otherwise.
Future<bool?> showConfirmationDialog({
  required BuildContext context,
  required String title,
  required Widget content,
  String confirmText = 'Yes',
  String cancelText = 'No',
}) {
  final theme = Theme.of(context);
  return showAppDialog<bool>(
    context: context,
    title: title,
    content: content,
    barrierDismissible:
        false, // Usually confirmation dialogs aren't dismissible
    actions: [
      TextButton(
        child: Text(
          cancelText,
          style: TextStyle(
            color: theme.textTheme.bodyLarge?.color?.withOpacity(0.7),
          ), // Muted color
        ),
        onPressed: () {
          Navigator.of(context).pop(false); // Pop with false
        },
      ),
      TextButton(
        child: Text(
          confirmText,
          style: TextStyle(
            color: theme.colorScheme.primary,
            fontWeight: FontWeight.bold,
          ),
        ),
        onPressed: () {
          Navigator.of(context).pop(true); // Pop with true
        },
      ),
    ],
  );
}

/// Shows a simple informational dialog.
Future<void> showInfoDialog({
  required BuildContext context,
  required String title,
  required Widget content,
}) {
  return showAppDialog<void>(
    context: context,
    title: title,
    content: content,
    // Default OK action is sufficient
  );
}
