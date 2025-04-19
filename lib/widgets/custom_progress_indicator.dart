import 'package:flutter/material.dart';
import '../controllers/theme_provider.dart'; // To access AppColors

enum ProgressIndicatorType { circular, linear }

class CustomProgressIndicator extends StatelessWidget {
  final double? value; // Null for indeterminate
  final ProgressIndicatorType type;
  final Color? color; // Optional override color
  final double strokeWidth; // For circular indicator

  const CustomProgressIndicator({
    super.key,
    this.value,
    this.type = ProgressIndicatorType.circular,
    this.color,
    this.strokeWidth = 4.0, // Default stroke width for circular
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    // Use primary color by default, allow override
    final indicatorColor = color ?? theme.colorScheme.primary;

    if (type == ProgressIndicatorType.linear) {
      return LinearProgressIndicator(
        value: value,
        backgroundColor: indicatorColor.withOpacity(0.2),
        valueColor: AlwaysStoppedAnimation<Color>(indicatorColor),
      );
    } else {
      // Circular
      return SizedBox(
        width: 40, // Standard size, can be adjusted or made configurable
        height: 40,
        child: CircularProgressIndicator(
          value: value,
          strokeWidth: strokeWidth,
          backgroundColor: indicatorColor.withOpacity(0.2),
          valueColor: AlwaysStoppedAnimation<Color>(indicatorColor),
        ),
      );
    }
  }
}
