import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../controllers/tracking_provider.dart';
import '../controllers/settings_provider.dart';
import '../widgets/primary_button.dart';
import '../models/workout_model.dart'; // Import WorkoutType

class WorkoutPreparationScreen extends StatefulWidget {
  const WorkoutPreparationScreen({super.key});

  @override
  State<WorkoutPreparationScreen> createState() =>
      _WorkoutPreparationScreenState();
}

class _WorkoutPreparationScreenState extends State<WorkoutPreparationScreen> {
  // Use WorkoutType enum for internal state where possible, but keep String for UI mapping
  WorkoutType _selectedWorkoutTypeEnum = WorkoutType.run;
  String _selectedWorkoutType =
      'run'; // Keep string for UI chips, map from enum

  String _selectedGoalType = 'Distance';
  double _goalValue = 5.0; // Default 5km
  int _goalDuration = 30; // Default 30 minutes
  bool _useVoiceCoaching = true;
  bool _showMap = true;

  // Map enum to display names for UI
  final Map<WorkoutType, String> _workoutTypeMap = {
    WorkoutType.run: 'Running',
    WorkoutType.walk: 'Walking',
    WorkoutType.cycle: 'Cycling',
    WorkoutType.hike: 'Hiking',
    // Add others if needed
  };
  final List<String> _goalTypes = ['Distance', 'Time', 'Free Run'];

  @override
  void initState() {
    super.initState();
    // Initialize string representation from enum default
    _selectedWorkoutType =
        _workoutTypeMap[_selectedWorkoutTypeEnum] ?? 'Running';
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final trackingProvider = Provider.of<TrackingProvider>(context);
    // final settingsProvider = Provider.of<SettingsProvider>(context); // Not used directly here

    return Scaffold(
      appBar: AppBar(
        title: const Text('Prepare Workout'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Workout Type Selection
                _buildSectionTitle(context, 'Workout Type'),
                const SizedBox(height: 8),
                _buildWorkoutTypeSelector(context),
                const SizedBox(height: 24),

                // Goal Setting
                _buildSectionTitle(context, 'Goal'),
                const SizedBox(height: 8),
                _buildGoalSelector(context),
                const SizedBox(height: 24),

                // Options
                _buildSectionTitle(context, 'Options'),
                const SizedBox(height: 8),
                _buildOptionsSection(context),
                const SizedBox(height: 32),

                // GPS Status
                _buildGpsStatusSection(context, trackingProvider),
                const SizedBox(height: 32),

                // Start Button
                SizedBox(
                  width: double.infinity,
                  height: 56,
                  child: PrimaryButton(
                    text: 'START WORKOUT',
                    // icon: Icons.play_arrow, // Removed invalid parameter
                    onPressed: () {
                      // Configure tracking provider with selected options
                      // Convert the string back to enum using the extension
                      trackingProvider.setWorkoutType(_selectedWorkoutTypeEnum);

                      if (_selectedGoalType == 'Distance') {
                        trackingProvider.setDistanceGoal(_goalValue);
                      } else if (_selectedGoalType == 'Time') {
                        // Pass duration in seconds
                        trackingProvider.setDurationGoal(_goalDuration * 60);
                      } else {
                        trackingProvider.clearGoals();
                      }

                      // TODO: Pass options like voice coaching, map visibility to provider if needed

                      // Navigate to active workout screen
                      Navigator.pushReplacementNamed(
                        context,
                        '/active_workout',
                      ); // Use pushReplacement
                      print(
                        'Starting workout with type: $_selectedWorkoutTypeEnum, goal: $_selectedGoalType',
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSectionTitle(BuildContext context, String title) {
    final theme = Theme.of(context);
    return Text(
      title,
      style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
    );
  }

  Widget _buildWorkoutTypeSelector(BuildContext context) {
    final theme = Theme.of(context);

    return Wrap(
      spacing: 8,
      children:
          _workoutTypeMap.entries.map((entry) {
            final typeEnum = entry.key;
            final typeName = entry.value;
            final isSelected = typeEnum == _selectedWorkoutTypeEnum;
            return ChoiceChip(
              label: Text(typeName),
              selected: isSelected,
              selectedColor: theme.colorScheme.primary,
              labelStyle: TextStyle(
                color:
                    isSelected
                        ? theme.colorScheme.onPrimary
                        : theme.colorScheme.onSurface,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              ),
              onSelected: (selected) {
                if (selected) {
                  setState(() {
                    _selectedWorkoutTypeEnum = typeEnum;
                    _selectedWorkoutType =
                        typeName; // Keep string in sync if needed elsewhere
                  });
                }
              },
            );
          }).toList(),
    );
  }

  Widget _buildGoalSelector(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Wrap(
          spacing: 8,
          children:
              _goalTypes.map((type) {
                final isSelected = type == _selectedGoalType;
                return ChoiceChip(
                  label: Text(type),
                  selected: isSelected,
                  selectedColor: theme.colorScheme.primary,
                  labelStyle: TextStyle(
                    color:
                        isSelected
                            ? theme.colorScheme.onPrimary
                            : theme.colorScheme.onSurface,
                    fontWeight:
                        isSelected ? FontWeight.bold : FontWeight.normal,
                  ),
                  onSelected: (selected) {
                    if (selected) {
                      setState(() {
                        _selectedGoalType = type;
                      });
                    }
                  },
                );
              }).toList(),
        ),
        const SizedBox(height: 16),

        // Show appropriate goal input based on selection
        if (_selectedGoalType == 'Distance')
          _buildDistanceGoalInput(context)
        else if (_selectedGoalType == 'Time')
          _buildTimeGoalInput(context)
        else
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 8.0),
            child: Text(
              'Run freely without a specific distance or time goal.',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.hintColor,
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildDistanceGoalInput(BuildContext context) {
    final theme = Theme.of(context);
    // TODO: Get units from SettingsProvider
    final String unit = 'km'; // Assume km for now

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Target Distance: ${_goalValue.toStringAsFixed(1)} $unit',
          style: theme.textTheme.bodyMedium,
        ),
        Slider(
          value: _goalValue,
          min: 1.0,
          max: 42.2, // Marathon distance in km
          divisions: 412, // Allows 0.1 km increments
          label: '${_goalValue.toStringAsFixed(1)} $unit',
          activeColor: theme.colorScheme.primary,
          onChanged: (value) {
            setState(() {
              // Round to one decimal place
              _goalValue = (value * 10).round() / 10;
            });
          },
        ),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('1 $unit', style: theme.textTheme.bodySmall),
            Text('42.2 $unit', style: theme.textTheme.bodySmall),
          ],
        ),
      ],
    );
  }

  Widget _buildTimeGoalInput(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Target Duration: $_goalDuration minutes',
          style: theme.textTheme.bodyMedium,
        ),
        Slider(
          value: _goalDuration.toDouble(),
          min: 5,
          max: 180, // 3 hours
          divisions: (180 - 5) ~/ 5, // Divisions every 5 minutes
          label: '$_goalDuration min',
          activeColor: theme.colorScheme.primary,
          onChanged: (value) {
            setState(() {
              _goalDuration = value.round();
            });
          },
        ),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('5 min', style: theme.textTheme.bodySmall),
            Text('180 min', style: theme.textTheme.bodySmall),
          ],
        ),
      ],
    );
  }

  Widget _buildOptionsSection(BuildContext context) {
    final theme = Theme.of(context);

    return Card(
      elevation: 0,
      color:
          theme
              .colorScheme
              .surfaceVariant, // Use a slightly different background
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        // side: BorderSide(color: theme.dividerColor), // Optional border
      ),
      child: Column(
        children: [
          SwitchListTile(
            title: const Text('Voice Coaching'),
            subtitle: const Text('Receive audio updates during your workout'),
            value: _useVoiceCoaching,
            activeColor: theme.colorScheme.primary,
            onChanged: (value) {
              setState(() {
                _useVoiceCoaching = value;
                // TODO: Update VoiceCoachingProvider if needed
              });
            },
          ),
          Divider(height: 1, thickness: 1, indent: 16, endIndent: 16),
          SwitchListTile(
            title: const Text('Show Map'),
            subtitle: const Text('Display map during workout'),
            value: _showMap,
            activeColor: theme.colorScheme.primary,
            onChanged: (value) {
              setState(() {
                _showMap = value;
                // TODO: Update TrackingProvider or relevant provider if needed
              });
            },
          ),
          // Additional options could be added here
        ],
      ),
    );
  }

  Widget _buildGpsStatusSection(
    BuildContext context,
    TrackingProvider trackingProvider,
  ) {
    final theme = Theme.of(context);
    // TODO: Get actual GPS status from TrackingProvider or LocationService
    final bool gpsReady =
        trackingProvider.currentPosition != null; // Basic check
    final String gpsStatus =
        gpsReady ? 'GPS Signal Ready' : 'Waiting for GPS Signal...';
    final Color statusColor = gpsReady ? Colors.green : Colors.orange;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: statusColor.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: statusColor),
      ),
      child: Row(
        children: [
          Icon(
            gpsReady ? Icons.gps_fixed : Icons.gps_not_fixed,
            color: statusColor,
          ),
          const SizedBox(width: 12),
          Expanded(
            // Allow text to wrap if needed
            child: Text(
              gpsStatus,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: statusColor,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          // Show accuracy when available
          if (gpsReady && trackingProvider.currentPosition?.accuracy != null)
            Padding(
              padding: const EdgeInsets.only(left: 8.0),
              child: Text(
                '(${trackingProvider.currentPosition!.accuracy.toStringAsFixed(0)}m acc.)',
                style: theme.textTheme.bodySmall?.copyWith(color: statusColor),
              ),
            ),
        ],
      ),
    );
  }
}
