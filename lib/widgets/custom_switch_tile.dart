import 'package:flutter/material.dart';

class CustomSwitchTile extends StatelessWidget {
  final String title;
  final String? subtitle; // Optional subtitle
  final bool value;
  final ValueChanged<bool> onChanged;
  final Color? activeColor; // Optional override for active color
  final EdgeInsetsGeometry? contentPadding;

  const CustomSwitchTile({
    super.key,
    required this.title,
    this.subtitle,
    required this.value,
    required this.onChanged,
    this.activeColor,
    this.contentPadding,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final Color effectiveActiveColor = activeColor ?? theme.colorScheme.primary;

    return SwitchListTile(
      title: Text(title, style: theme.textTheme.titleMedium),
      subtitle:
          subtitle != null
              ? Text(subtitle!, style: theme.textTheme.bodySmall)
              : null,
      value: value,
      onChanged: onChanged,
      activeColor: effectiveActiveColor, // Color of the switch track when on
      activeTrackColor: effectiveActiveColor.withOpacity(0.5),
      inactiveThumbColor: theme.disabledColor,
      inactiveTrackColor: theme.disabledColor.withOpacity(0.3),
      contentPadding: contentPadding,
      // Apply visual density for consistency
      visualDensity: VisualDensity.compact,
    );
  }
}
