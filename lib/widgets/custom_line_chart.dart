import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import '../controllers/theme_provider.dart'; // For AppColors

class CustomLineChart extends StatelessWidget {
  final List<FlSpot> spots;
  final String? title; // Optional chart title
  final double? minY, maxY; // Optional Y-axis range
  final double? minX, maxX; // Optional X-axis range
  final bool showGrid;
  final bool showDots;
  final Color? lineColor; // Optional override line color
  final GetLineTooltipItems?
  getTooltipItems; // Custom tooltips (Correct typedef)
  final AxisTitles?
  bottomTitles; // Custom bottom axis titles (Type should be AxisTitles)
  final AxisTitles?
  leftTitles; // Custom left axis titles (Type should be AxisTitles)

  const CustomLineChart({
    super.key,
    required this.spots,
    this.title,
    this.minY,
    this.maxY,
    this.minX,
    this.maxX,
    this.showGrid = true,
    this.showDots = true,
    this.lineColor,
    this.getTooltipItems,
    this.bottomTitles,
    this.leftTitles,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final chartLineColor = lineColor ?? theme.colorScheme.primary;
    final gridColor = theme.dividerColor.withOpacity(0.5);
    final titleStyle = theme.textTheme.titleMedium;
    final tooltipStyle = theme.textTheme.bodySmall?.copyWith(
      color: theme.colorScheme.onPrimary,
    ); // Tooltip text on primary bg

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
          child: LineChart(
            LineChartData(
              minY: minY,
              maxY: maxY,
              minX: minX,
              maxX: maxX,
              gridData: FlGridData(
                show: showGrid,
                drawVerticalLine: true,
                horizontalInterval: _calculateInterval(minY, maxY),
                verticalInterval: _calculateInterval(minX, maxX),
                getDrawingHorizontalLine: (value) {
                  return FlLine(color: gridColor, strokeWidth: 1);
                },
                getDrawingVerticalLine: (value) {
                  return FlLine(color: gridColor, strokeWidth: 1);
                },
              ),
              titlesData: FlTitlesData(
                show: true,
                // Remove const
                rightTitles: AxisTitles(
                  sideTitles: SideTitles(showTitles: false),
                ),
                // Remove const
                topTitles: AxisTitles(
                  sideTitles: SideTitles(showTitles: false),
                ),
                bottomTitles: bottomTitles ?? _defaultBottomTitles(theme),
                leftTitles: leftTitles ?? _defaultLeftTitles(theme),
              ),
              borderData: FlBorderData(
                show: true,
                border: Border.all(color: theme.dividerColor, width: 1),
              ),
              lineBarsData: [
                LineChartBarData(
                  spots: spots,
                  isCurved: true,
                  color: chartLineColor,
                  barWidth: 3,
                  isStrokeCapRound: true,
                  dotData: FlDotData(show: showDots),
                  belowBarData: BarAreaData(
                    show: true,
                    color: chartLineColor.withOpacity(0.2),
                  ),
                ),
              ],
              lineTouchData: LineTouchData(
                touchTooltipData: LineTouchTooltipData(
                  tooltipBgColor: theme.colorScheme.primary.withOpacity(0.8),
                  getTooltipItems:
                      getTooltipItems ??
                      (touchedSpots) {
                        return touchedSpots.map((LineBarSpot touchedSpot) {
                          final text =
                              '${touchedSpot.y.toStringAsFixed(1)}'; // Default tooltip
                          return LineTooltipItem(
                            text,
                            tooltipStyle ?? const TextStyle(),
                          );
                        }).toList();
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
    if (min == null || max == null || min == max) return null;
    // Basic logic, can be refined
    double range = max - min;
    if (range <= 0) return null;
    if (range <= 10) return 1;
    if (range <= 50) return 5;
    if (range <= 100) return 10;
    return (range / 5).roundToDouble(); // Aim for ~5 intervals
  }

  // Default Axis Titles (can be overridden)
  AxisTitles _defaultBottomTitles(ThemeData theme) {
    return AxisTitles(
      sideTitles: SideTitles(
        showTitles: true,
        reservedSize: 30,
        interval: _calculateInterval(minX, maxX),
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

  AxisTitles _defaultLeftTitles(ThemeData theme) {
    return AxisTitles(
      sideTitles: SideTitles(
        showTitles: true,
        reservedSize: 40,
        interval: _calculateInterval(minY, maxY),
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
