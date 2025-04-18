import 'package:flutter/material.dart';

class InfoCard extends StatelessWidget {
  final Widget child;
  final EdgeInsets padding;
  final EdgeInsets margin;
  final Color? backgroundColor; // Optional override
  final double elevation;
  final BorderRadius borderRadius;
  final VoidCallback? onTap; // Optional tap action

  const InfoCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(16.0),
    this.margin = const EdgeInsets.symmetric(vertical: 8.0, horizontal: 0),
    this.backgroundColor,
    this.elevation = 1.0, // Subtle elevation by default
    this.borderRadius = const BorderRadius.all(Radius.circular(12.0)),
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cardColor =
        backgroundColor ?? theme.cardColor; // Use theme cardColor by default

    return Card(
      elevation: elevation,
      color: cardColor,
      margin: margin,
      shape: RoundedRectangleBorder(
        borderRadius: borderRadius,
        // Optional: Add border if needed
        // side: BorderSide(color: theme.dividerColor, width: 0.5),
      ),
      child: InkWell(
        // Use InkWell if onTap is provided for ripple effect
        onTap: onTap,
        borderRadius: borderRadius, // Match InkWell radius to Card radius
        child: Padding(padding: padding, child: child),
      ),
    );
  }
}
