import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../controllers/workout_provider.dart';
import '../widgets/custom_line_chart.dart'; // Import custom charts
import '../widgets/custom_bar_chart.dart';
import 'package:fl_chart/fl_chart.dart'; // Import FlSpot for chart data

class StatisticsScreen extends StatefulWidget {
  const StatisticsScreen({super.key});

  @override
  State<StatisticsScreen> createState() => _StatisticsScreenState();
}

class _StatisticsScreenState extends State<StatisticsScreen> {
  String _selectedTimeRange = 'Weekly'; // Default view
  final List<String> _timeRanges = ['Weekly', 'Monthly', 'Yearly', 'All Time'];

  // TODO: Fetch and process data based on selectedTimeRange from WorkoutProvider/StatisticsService

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    // Access providers - listen might be needed if data changes dynamically
    final workoutProvider = Provider.of<WorkoutProvider>(context);

    // Placeholder data - replace with actual data fetching and processing
    final weeklyDistanceData = [
      FlSpot(0, 5),
      FlSpot(1, 7),
      FlSpot(2, 4),
      FlSpot(3, 6),
      FlSpot(4, 8),
      FlSpot(5, 5),
      FlSpot(6, 9),
    ];
    final monthlyPaceData = [
      FlSpot(0, 330),
      FlSpot(1, 325),
      FlSpot(2, 340),
      FlSpot(3, 335),
    ]; // Pace in sec/km
    final yearlyWorkoutCountData = [
      BarChartGroupData(
        x: 0,
        barRods: [BarChartRodData(toY: 15, color: theme.colorScheme.primary)],
      ), // Jan
      BarChartGroupData(
        x: 1,
        barRods: [BarChartRodData(toY: 12, color: theme.colorScheme.primary)],
      ), // Feb
      BarChartGroupData(
        x: 2,
        barRods: [BarChartRodData(toY: 18, color: theme.colorScheme.primary)],
      ), // Mar
      // ... add other months
    ];

    return Scaffold(
      appBar: AppBar(title: const Text('Statistics & Trends')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Time Range Selector
            _buildTimeRangeSelector(context),
            const SizedBox(height: 24),

            // Example Chart 1: Distance Trend (Line Chart)
            CustomLineChart(
              title: 'Distance Trend ($_selectedTimeRange)',
              spots: weeklyDistanceData, // Replace with dynamic data
              // TODO: Configure axes based on time range and data
            ),
            const SizedBox(height: 32),

            // Example Chart 2: Average Pace Trend (Line Chart)
            CustomLineChart(
              title: 'Average Pace Trend ($_selectedTimeRange)',
              spots: monthlyPaceData, // Replace with dynamic data
              // TODO: Configure axes, maybe invert Y axis for pace
            ),
            const SizedBox(height: 32),

            // Example Chart 3: Workout Frequency (Bar Chart)
            CustomBarChart(
              title: 'Workout Frequency ($_selectedTimeRange)',
              barGroups: yearlyWorkoutCountData, // Replace with dynamic data
              // TODO: Configure axes (e.g., month names for bottom axis)
            ),
            const SizedBox(height: 32),

            // Add more charts as needed (e.g., Calories, Elevation)
          ],
        ),
      ),
    );
  }

  Widget _buildTimeRangeSelector(BuildContext context) {
    return DropdownButton<String>(
      value: _selectedTimeRange,
      isExpanded: true, // Make dropdown take available width
      items:
          _timeRanges.map((String value) {
            return DropdownMenuItem<String>(value: value, child: Text(value));
          }).toList(),
      onChanged: (String? newValue) {
        if (newValue != null) {
          setState(() {
            _selectedTimeRange = newValue;
            // TODO: Trigger data refresh based on the new time range
            print('Selected time range: $_selectedTimeRange');
          });
        }
      },
    );
  }
}
