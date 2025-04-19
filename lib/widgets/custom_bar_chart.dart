import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import '../controllers/theme_provider.dart'; // For AppColors

class CustomBarChart extends StatelessWidget {
  final List<BarChartGroupData> barGroups;
  final String? title; // Optional chart title
  final double? maxY; // Optional Y-axis max
  final double barWidth;
  final double groupSpace;
  final GetBarTooltipItem? getTooltipItem; // Custom tooltips (Correct typedef)
  final AxisTitles? bottomTitles; // Custom bottom axis titles
  final AxisTitles? leftTitles; // Custom left axis titles

  const CustomBarChart({
    super.key,
    required this.barGroups,
    this.title,
    this.maxY,
    this.barWidth = 22,
    this.groupSpace = 10,
    this.getTooltipItem,
    this.bottomTitles,
    this.leftTitles,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final gridColor = theme.dividerColor.withOpacity(0.5);
    final titleStyle = theme.textTheme.titleMedium;
    final tooltipBgColor = theme.colorScheme.primary.withOpacity(0.8);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (title != null)
          Padding(
            padding: const EdgeInsets.only(bottom: 16.0),
            child: Text(title!, style: titleStyle, textAlign: TextAlign.center),
          ),
        AspectRatio(
          aspectRatio: 1.7, // Adjust aspect ratio as needed
          child: BarChart(
            BarChartData(
              maxY: maxY,
              alignment: BarChartAlignment.spaceAround,
              barGroups: barGroups,
              gridData: FlGridData(
                show: true,
                drawVerticalLine: false, // Typically false for bar charts
                horizontalInterval: _calculateInterval(
                  0,
                  maxY,
                ), // Start Y from 0
                getDrawingHorizontalLine: (value) {
                  return FlLine(color: gridColor, strokeWidth: 1);
                },
              ),
              titlesData: FlTitlesData(
                show: true,
                rightTitles: AxisTitles(
                  sideTitles: SideTitles(showTitles: false),
                ),
                topTitles: AxisTitles(
                  sideTitles: SideTitles(showTitles: false),
                ),
                bottomTitles: bottomTitles ?? _defaultBottomTitles(theme),
                leftTitles: leftTitles ?? _defaultLeftTitles(theme, maxY),
              ),
              borderData: FlBorderData(
                show: true,
                border: Border(
                  bottom: BorderSide(color: theme.dividerColor, width: 1),
                  left: BorderSide(color: theme.dividerColor, width: 1),
                ),
              ),
              barTouchData: BarTouchData(
                touchTooltipData: BarTouchTooltipData(
                  tooltipBgColor: tooltipBgColor,
                  getTooltipItem:
                      getTooltipItem ??
                      (group, groupIndex, rod, rodIndex) {
                        // Default tooltip showing the Y value
                        String text = rod.toY.toStringAsFixed(1);
                        return BarTooltipItem(
                          text,
                          theme.textTheme.bodySmall?.copyWith(
                                color: theme.colorScheme.onPrimary,
                              ) ??
                              const TextStyle(),
                        );
                      },
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  // Helper to calculate a reasonable interval for grid/titles
  double? _calculateInterval(double? min, double? max) {
    min ??= 0; // Default min to 0 for bar charts if not provided
    if (max == null || min == max) return null;
    double range = max - min;
    if (range <= 0) return null;
    if (range <= 10) return 1;
    if (range <= 50) return 5;
    if (range <= 100) return 10;
    return (range / 5).roundToDouble(); // Aim for ~5 intervals
  }

  // Default Axis Titles (can be overridden)
  AxisTitles _defaultBottomTitles(ThemeData theme) {
    // Default bottom titles often depend on the specific data (e.g., days, months)
    // Providing a generic numeric one here, but likely needs customization via parameter
    return AxisTitles(
      sideTitles: SideTitles(
        showTitles: true,
        reservedSize: 30,
        getTitlesWidget: (value, meta) {
          // Assuming value corresponds to the index of barGroups
          return SideTitleWidget(
            axisSide: meta.axisSide,
            space: 8.0,
            child: Text(
              value.toInt().toString(),
              style: theme.textTheme.bodySmall,
            ),
          );
        },
      ),
    );
  }

  AxisTitles _defaultLeftTitles(ThemeData theme, double? maxY) {
    return AxisTitles(
      sideTitles: SideTitles(
        showTitles: true,
        reservedSize: 40,
        interval: _calculateInterval(0, maxY), // Start Y from 0
        getTitlesWidget: (value, meta) {
          return SideTitleWidget(
            axisSide: meta.axisSide,
            space: 8.0,
            child: Text(
              value.toStringAsFixed(0),
              style: theme.textTheme.bodySmall,
            ),
          );
        },
      ),
    );
  }
}
