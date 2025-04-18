import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../controllers/tracking_provider.dart';
import '../controllers/voice_coaching_provider.dart';
import '../widgets/primary_button.dart';

class ActiveWorkoutScreen extends StatefulWidget {
  const ActiveWorkoutScreen({super.key});

  @override
  State<ActiveWorkoutScreen> createState() => _ActiveWorkoutScreenState();
}

class _ActiveWorkoutScreenState extends State<ActiveWorkoutScreen> {
  bool _isPaused = false;
  
  @override
  void initState() {
    super.initState();
    // Start tracking when screen loads
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final trackingProvider = Provider.of<TrackingProvider>(context, listen: false);
      trackingProvider.startWorkout();
    });
  }
  
  @override
  void dispose() {
    // Clean up if user navigates away without stopping
    final trackingProvider = Provider.of<TrackingProvider>(context, listen: false);
    if (trackingProvider.isTracking) {
      trackingProvider.pauseWorkout();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final trackingProvider = Provider.of<TrackingProvider>(context);
    final voiceCoachingProvider = Provider.of<VoiceCoachingProvider>(context);
    
    return WillPopScope(
      onWillPop: () async {
        // Prevent accidental back navigation during workout
        final shouldPop = await _showExitConfirmationDialog(context);
        return shouldPop ?? false;
      },
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Active Workout'),
          automaticallyImplyLeading: false, // Disable back button
          actions: [
            IconButton(
              icon: const Icon(Icons.close),
              onPressed: () => _showExitConfirmationDialog(context),
            ),
          ],
        ),
        body: SafeArea(
          child: Column(
            children: [
              // Map View (Placeholder)
              Expanded(
                flex: 2,
                child: Container(
                  color: Colors.grey[200],
                  child: Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.map,
                          size: 64,
                          color: theme.colorScheme.primary.withOpacity(0.5),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'Map View',
                          style: theme.textTheme.titleMedium,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Real map implementation would go here',
                          style: theme.textTheme.bodySmall,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              
              // Metrics Display
              Expanded(
                flex: 3,
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    children: [
                      // Primary metrics row
                      Expanded(
                        child: Row(
                          children: [
                            // Time
                            _buildMetricCard(
                              context,
                              'Time',
                              _formatDuration(trackingProvider.elapsedTime),
                              Icons.timer,
                            ),
                            const SizedBox(width: 16),
                            // Distance
                            _buildMetricCard(
                              context,
                              'Distance',
                              '${trackingProvider.distance.toStringAsFixed(2)} km',
                              Icons.straighten,
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),
                      
                      // Secondary metrics row
                      Expanded(
                        child: Row(
                          children: [
                            // Pace
                            _buildMetricCard(
                              context,
                              'Pace',
                              '${trackingProvider.currentPace}/km',
                              Icons.speed,
                            ),
                            const SizedBox(width: 16),
                            // Calories
                            _buildMetricCard(
                              context,
                              'Calories',
                              '${trackingProvider.caloriesBurned.round()} kcal',
                              Icons.local_fire_department,
                            ),
                          ],
                        ),
                      ),
                      
                      // Goal progress
                      if (trackingProvider.hasGoal)
                        Padding(
                          padding: const EdgeInsets.only(top: 16.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Goal Progress',
                                style: theme.textTheme.titleSmall,
                              ),
                              const SizedBox(height: 8),
                              LinearProgressIndicator(
                                value: trackingProvider.goalProgress,
                                backgroundColor: theme.colorScheme.primary.withOpacity(0.2),
                                valueColor: AlwaysStoppedAnimation<Color>(
                                  theme.colorScheme.primary,
                                ),
                                minHeight: 8,
                              ),
                              const SizedBox(height: 4),
                              Text(
                                trackingProvider.hasDistanceGoal
                                    ? '${trackingProvider.distance.toStringAsFixed(2)} / ${trackingProvider.distanceGoal.toStringAsFixed(2)} km'
                                    : '${_formatDuration(trackingProvider.elapsedTime)} / ${_formatDuration(trackingProvider.durationGoal)}',
                                style: theme.textTheme.bodySmall,
                              ),
                            ],
                          ),
                        ),
                      
                      // Workout controls
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 24.0),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                          children: [
                            // Pause/Resume button
                            FloatingActionButton(
                              heroTag: 'pauseResume',
                              backgroundColor: _isPaused
                                  ? theme.colorScheme.primary
                                  : theme.colorScheme.secondary,
                              child: Icon(
                                _isPaused ? Icons.play_arrow : Icons.pause,
                                color: Colors.white,
                              ),
                              onPressed: () {
                                setState(() {
                                  _isPaused = !_isPaused;
                                });
                                if (_isPaused) {
                                  trackingProvider.pauseWorkout();
                                  voiceCoachingProvider.announcePause();
                                } else {
                                  trackingProvider.resumeWorkout();
                                  voiceCoachingProvider.announceResume();
                                }
                              },
                            ),
                            
                            // Stop button
                            FloatingActionButton(
                              heroTag: 'stop',
                              backgroundColor: Colors.red,
                              child: const Icon(
                                Icons.stop,
                                color: Colors.white,
                              ),
                              onPressed: () => _showStopWorkoutDialog(context),
                            ),
                            
                            // Lock screen button
                            FloatingActionButton(
                              heroTag: 'lock',
                              backgroundColor: theme.colorScheme.surface,
                              child: Icon(
                                Icons.lock_outline,
                                color: theme.colorScheme.onSurface,
                              ),
                              onPressed: () {
                                // TODO: Implement screen lock functionality
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text('Screen lock not implemented yet'),
                                    duration: Duration(seconds: 2),
                                  ),
                                );
                              },
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
  
  Widget _buildMetricCard(BuildContext context, String title, String value, IconData icon) {
    final theme = Theme.of(context);
    
    return Expanded(
      child: Card(
        elevation: 2,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        child: Padding(
          padding: const EdgeInsets.all(12.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    icon,
                    size: 16,
                    color: theme.colorScheme.primary,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    title,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.primary,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                value,
                style: theme.textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }
  
  Future<bool?> _showExitConfirmationDialog(BuildContext context) {
    return showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Exit Workout?'),
        content: const Text(
          'Are you sure you want to exit? Your current workout progress will be lost.',
        ),
        actions: [
          TextButton(
            child: const Text('CANCEL'),
            onPressed: () => Navigator.of(context).pop(false),
          ),
          TextButton(
            child: const Text('EXIT'),
            onPressed: () {
              // Clean up tracking
              final trackingProvider = Provider.of<TrackingProvider>(context, listen: false);
              trackingProvider.discardWorkout();
              
              // Navigate back to home
              Navigator.of(context).pop(true);
              Navigator.of(context).pop();
            },
          ),
        ],
      ),
    );
  }
  
  Future<void> _showStopWorkoutDialog(BuildContext context) {
    return showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Finish Workout?'),
        content: const Text(
          'Do you want to finish and save this workout?',
        ),
        actions: [
          TextButton(
            child: const Text('CANCEL'),
            onPressed: () => Navigator.of(context).pop(),
          ),
          TextButton(
            child: const Text('DISCARD'),
            onPressed: () {
              // Discard workout
              final trackingProvider = Provider.of<TrackingProvider>(context, listen: false);
              trackingProvider.discardWorkout();
              
              // Navigate back to home
              Navigator.of(context).pop();
              Navigator.of(context).pop();
            },
          ),
          TextButton(
            child: const Text('SAVE'),
            onPressed: () {
              // Save workout
              final trackingProvider = Provider.of<TrackingProvider>(context, listen: false);
              trackingProvider.stopAndSaveWorkout();
              
              // Navigate to workout summary
              Navigator.of(context).pop();
              // Navigator.pushReplacementNamed(context, '/workout_summary');
              Navigator.of(context).pop(); // Temporary until summary screen is implemented
            },
          ),
        ],
      ),
    );
  }
  
  String _formatDuration(int seconds) {
    final hours = seconds ~/ 3600;
    final minutes = (seconds % 3600) ~/ 60;
    final remainingSeconds = seconds % 60;
    
    if (hours > 0) {
      return '${hours.toString().padLeft(2, '0')}:${minutes.toString().padLeft(2, '0')}:${remainingSeconds.toString().padLeft(2, '0')}';
    } else {
      return '${minutes.toString().padLeft(2, '0')}:${remainingSeconds.toString().padLeft(2, '0')}';
    }
  }
}
