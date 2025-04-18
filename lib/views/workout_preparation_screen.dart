import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../controllers/tracking_provider.dart';
import '../controllers/settings_provider.dart';
import '../widgets/primary_button.dart';

class WorkoutPreparationScreen extends StatefulWidget {
  const WorkoutPreparationScreen({super.key});

  @override
  State<WorkoutPreparationScreen> createState() => _WorkoutPreparationScreenState();
}

class _WorkoutPreparationScreenState extends State<WorkoutPreparationScreen> {
  String _selectedWorkoutType = 'Running';
  String _selectedGoalType = 'Distance';
  double _goalValue = 5.0; // Default 5km
  int _goalDuration = 30; // Default 30 minutes
  bool _useVoiceCoaching = true;
  bool _showMap = true;

  final List<String> _workoutTypes = ['Running', 'Walking', 'Cycling', 'Hiking'];
  final List<String> _goalTypes = ['Distance', 'Time', 'Free Run'];

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final trackingProvider = Provider.of<TrackingProvider>(context);
    final settingsProvider = Provider.of<SettingsProvider>(context);
    
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
                    icon: Icons.play_arrow,
                    onPressed: () {
                      // Configure tracking provider with selected options
                      trackingProvider.setWorkoutType(_selectedWorkoutType);
                      
                      if (_selectedGoalType == 'Distance') {
                        trackingProvider.setDistanceGoal(_goalValue);
                      } else if (_selectedGoalType == 'Time') {
                        trackingProvider.setDurationGoal(_goalDuration * 60); // Convert to seconds
                      } else {
                        trackingProvider.clearGoals();
                      }
                      
                      // Navigate to active workout screen
                      // Navigator.pushNamed(context, '/active_workout');
                      print('Starting workout with type: $_selectedWorkoutType, goal: $_selectedGoalType');
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
      style: theme.textTheme.titleMedium?.copyWith(
        fontWeight: FontWeight.bold,
      ),
    );
  }
  
  Widget _buildWorkoutTypeSelector(BuildContext context) {
    final theme = Theme.of(context);
    
    return Wrap(
      spacing: 8,
      children: _workoutTypes.map((type) {
        final isSelected = type == _selectedWorkoutType;
        return ChoiceChip(
          label: Text(type),
          selected: isSelected,
          selectedColor: theme.colorScheme.primary,
          labelStyle: TextStyle(
            color: isSelected ? theme.colorScheme.onPrimary : theme.colorScheme.onSurface,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
          ),
          onSelected: (selected) {
            if (selected) {
              setState(() {
                _selectedWorkoutType = type;
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
          children: _goalTypes.map((type) {
            final isSelected = type == _selectedGoalType;
            return ChoiceChip(
              label: Text(type),
              selected: isSelected,
              selectedColor: theme.colorScheme.primary,
              labelStyle: TextStyle(
                color: isSelected ? theme.colorScheme.onPrimary : theme.colorScheme.onSurface,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
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
              'Run at your own pace without a specific goal.',
              style: theme.textTheme.bodyMedium,
            ),
          ),
      ],
    );
  }
  
  Widget _buildDistanceGoalInput(BuildContext context) {
    final theme = Theme.of(context);
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Target Distance: ${_goalValue.toStringAsFixed(1)} km',
          style: theme.textTheme.bodyMedium,
        ),
        Slider(
          value: _goalValue,
          min: 1.0,
          max: 42.2, // Marathon distance
          divisions: 412,
          label: '${_goalValue.toStringAsFixed(1)} km',
          activeColor: theme.colorScheme.primary,
          onChanged: (value) {
            setState(() {
              _goalValue = value;
            });
          },
        ),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('1 km', style: theme.textTheme.bodySmall),
            Text('42.2 km', style: theme.textTheme.bodySmall),
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
          divisions: 35,
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
      color: theme.colorScheme.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: theme.dividerColor),
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
              });
            },
          ),
          // Additional options could be added here
        ],
      ),
    );
  }
  
  Widget _buildGpsStatusSection(BuildContext context, TrackingProvider trackingProvider) {
    final theme = Theme.of(context);
    // This would normally come from the TrackingProvider
    final bool gpsReady = true;
    final String gpsStatus = gpsReady ? 'GPS Signal Ready' : 'Waiting for GPS Signal...';
    
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: gpsReady ? Colors.green.withOpacity(0.1) : Colors.orange.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: gpsReady ? Colors.green : Colors.orange,
        ),
      ),
      child: Row(
        children: [
          Icon(
            gpsReady ? Icons.gps_fixed : Icons.gps_not_fixed,
            color: gpsReady ? Colors.green : Colors.orange,
          ),
          const SizedBox(width: 12),
          Text(
            gpsStatus,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: gpsReady ? Colors.green : Colors.orange,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}
