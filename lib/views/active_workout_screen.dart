import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../controllers/tracking_provider.dart';
import '../controllers/voice_coaching_provider.dart';
import '../controllers/workout_provider.dart'; // Import WorkoutProvider
import '../widgets/primary_button.dart';
import '../models/workout_model.dart'; // Import WorkoutModel for saving

class ActiveWorkoutScreen extends StatefulWidget {
  const ActiveWorkoutScreen({super.key});

  @override
  State<ActiveWorkoutScreen> createState() => _ActiveWorkoutScreenState();
}

class _ActiveWorkoutScreenState extends State<ActiveWorkoutScreen> {
  // bool _isPaused = false; // State is now managed by TrackingProvider

  @override
  void initState() {
    super.initState();
    // Start tracking when screen loads
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final trackingProvider = Provider.of<TrackingProvider>(
        context,
        listen: false,
      );
      // Ensure workout provider is set if needed for saving later
      final workoutProvider = Provider.of<WorkoutProvider>(
        context,
        listen: false,
      );
      trackingProvider.setWorkoutProvider(workoutProvider);
      trackingProvider.startWorkout(); // Use renamed method
    });
  }

  @override
  void dispose() {
    // Clean up if user navigates away without stopping
    // Check provider state directly instead of local state
    // final trackingProvider = Provider.of<TrackingProvider>(context, listen: false);
    // if (trackingProvider.isTracking) {
    //   trackingProvider.pauseWorkout(); // Use renamed method
    // }
    // Let WillPopScope handle cleanup via dialogs
    super.dispose();
  }

  // Helper to format duration (moved from bottom for clarity)
  String _formatDuration(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    final hours = twoDigits(duration.inHours);
    final minutes = twoDigits(duration.inMinutes.remainder(60));
    final seconds = twoDigits(duration.inSeconds.remainder(60));
    return [if (duration.inHours > 0) hours, minutes, seconds].join(':');
  }

  // Helper to format pace (e.g., from seconds/km to MM:SS/km)
  String _formatPace(double? paceInSecondsPerKm) {
    if (paceInSecondsPerKm == null ||
        paceInSecondsPerKm.isNaN ||
        paceInSecondsPerKm.isInfinite ||
        paceInSecondsPerKm <= 0) {
      return '-:-- /km';
    }
    final int minutes = paceInSecondsPerKm ~/ 60;
    final int seconds = (paceInSecondsPerKm % 60).round();
    return '${minutes.toString()}:${seconds.toString().padLeft(2, '0')} /km';
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    // Listen to provider changes
    final trackingProvider = Provider.of<TrackingProvider>(context);
    final voiceCoachingProvider = Provider.of<VoiceCoachingProvider>(
      context,
      listen: false,
    ); // Usually don't need to listen

    // Determine pause state from provider
    final bool isPaused = trackingProvider.isPaused;

    return WillPopScope(
      onWillPop: () async {
        // Prevent accidental back navigation during workout
        final shouldPop = await _showExitConfirmationDialog(context);
        return shouldPop ?? false;
      },
      child: Scaffold(
        appBar: AppBar(
          title: Text(
            'Active ${trackingProvider.workoutType.toShortString().capitalize()}',
          ), // Show workout type
          automaticallyImplyLeading: false, // Disable back button
          actions: [
            IconButton(
              icon: const Icon(Icons.close),
              tooltip: 'Stop Workout',
              onPressed:
                  () => _showStopWorkoutDialog(context), // Use stop dialog
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
                        Text('Map View', style: theme.textTheme.titleMedium),
                        const SizedBox(height: 8),
                        Text(
                          'Real map implementation would go here',
                          style: theme.textTheme.bodySmall,
                        ),
                        // Display Lat/Lng for debugging
                        if (trackingProvider.currentPosition != null)
                          Padding(
                            padding: const EdgeInsets.only(top: 8.0),
                            child: Text(
                              'Lat: ${trackingProvider.currentPosition!.latitude.toStringAsFixed(5)}, Lng: ${trackingProvider.currentPosition!.longitude.toStringAsFixed(5)}',
                              style: theme.textTheme.bodySmall?.copyWith(
                                fontSize: 10,
                              ),
                            ),
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
                              _formatDuration(
                                trackingProvider.elapsedTime,
                              ), // Use correct getter
                              Icons.timer,
                            ),
                            const SizedBox(width: 16),
                            // Distance
                            _buildMetricCard(
                              context,
                              'Distance',
                              '${trackingProvider.distance.toStringAsFixed(2)} km', // Use correct getter
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
                              _formatPace(
                                trackingProvider.currentPace,
                              ), // Use correct getter and formatter
                              Icons.speed,
                            ),
                            const SizedBox(width: 16),
                            // Calories
                            _buildMetricCard(
                              context,
                              'Calories',
                              '${trackingProvider.caloriesBurned.round()} kcal', // Use correct getter
                              Icons.local_fire_department,
                            ),
                          ],
                        ),
                      ),

                      // Goal progress
                      if (trackingProvider.hasGoal) // Use correct getter
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
                                value:
                                    trackingProvider
                                        .goalProgress, // Use correct getter
                                backgroundColor: theme.colorScheme.primary
                                    .withOpacity(0.2),
                                valueColor: AlwaysStoppedAnimation<Color>(
                                  theme.colorScheme.primary,
                                ),
                                minHeight: 8,
                              ),
                              const SizedBox(height: 4),
                              Text(
                                trackingProvider
                                        .hasDistanceGoal // Use correct getter
                                    ? '${trackingProvider.distance.toStringAsFixed(2)} / ${trackingProvider.distanceGoal?.toStringAsFixed(2) ?? '-'} km' // Use correct getters + null check
                                    : '${_formatDuration(trackingProvider.elapsedTime)} / ${_formatDuration(trackingProvider.durationGoal ?? Duration.zero)}', // Use correct getters + null check
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
                              backgroundColor:
                                  isPaused
                                      ? theme.colorScheme.primary
                                      : theme.colorScheme.secondary,
                              child: Icon(
                                isPaused ? Icons.play_arrow : Icons.pause,
                                color: Colors.white,
                              ),
                              onPressed: () {
                                // No need for local state _isPaused anymore
                                if (isPaused) {
                                  trackingProvider
                                      .resumeWorkout(); // Use correct method
                                  voiceCoachingProvider.playCue(
                                    'resume',
                                  ); // Use correct method
                                } else {
                                  trackingProvider
                                      .pauseWorkout(); // Use correct method
                                  voiceCoachingProvider.playCue(
                                    'pause',
                                  ); // Use correct method
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

                            // Lock screen button (Placeholder)
                            FloatingActionButton(
                              heroTag: 'lock',
                              backgroundColor: theme.colorScheme.surfaceVariant,
                              child: Icon(
                                Icons.lock_outline,
                                color: theme.colorScheme.onSurfaceVariant,
                              ),
                              onPressed: () {
                                // TODO: Implement screen lock functionality
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text(
                                      'Screen lock not implemented yet',
                                    ),
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

  Widget _buildMetricCard(
    BuildContext context,
    String title,
    String value,
    IconData icon,
  ) {
    final theme = Theme.of(context);

    return Expanded(
      child: Card(
        elevation: 2,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        child: Padding(
          padding: const EdgeInsets.all(12.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(icon, size: 16, color: theme.colorScheme.primary),
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
              FittedBox(
                // Ensure text fits
                fit: BoxFit.scaleDown,
                child: Text(
                  value,
                  style: theme.textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                  textAlign: TextAlign.center,
                  maxLines: 1,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<bool?> _showExitConfirmationDialog(BuildContext context) {
    // Use listen: false as we are only calling methods
    final trackingProvider = Provider.of<TrackingProvider>(
      context,
      listen: false,
    );
    return showDialog<bool>(
      context: context,
      builder:
          (context) => AlertDialog(
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
                child: const Text('EXIT & DISCARD'),
                style: TextButton.styleFrom(foregroundColor: Colors.red),
                onPressed: () async {
                  // Make async
                  Navigator.of(context).pop(true); // Allow pop
                  await trackingProvider.discardWorkout(); // Use correct method
                  // Navigate back to previous screen (likely home or prep)
                  if (mounted) Navigator.of(context).pop();
                },
              ),
            ],
          ),
    );
  }

  Future<void> _showStopWorkoutDialog(BuildContext context) {
    // Use listen: false as we are only calling methods
    final trackingProvider = Provider.of<TrackingProvider>(
      context,
      listen: false,
    );
    return showDialog<void>(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('Finish Workout?'),
            content: const Text(
              'Do you want to finish and save this workout, or discard it?',
            ),
            actions: [
              TextButton(
                child: const Text('CANCEL'),
                onPressed: () => Navigator.of(context).pop(),
              ),
              TextButton(
                child: const Text('DISCARD'),
                style: TextButton.styleFrom(foregroundColor: Colors.red),
                onPressed: () async {
                  // Make async
                  Navigator.of(context).pop(); // Close dialog
                  await trackingProvider.discardWorkout(); // Use correct method
                  // Navigate back to previous screen
                  if (mounted) Navigator.of(context).pop();
                },
              ),
              TextButton(
                child: const Text('SAVE & FINISH'),
                onPressed: () async {
                  // Make async
                  Navigator.of(context).pop(); // Close dialog
                  final savedWorkout =
                      await trackingProvider
                          .stopAndSaveWorkout(); // Use correct method

                  if (mounted) {
                    if (savedWorkout != null) {
                      // Navigate to workout summary
                      Navigator.pushReplacementNamed(
                        context,
                        '/workout_summary',
                        arguments: savedWorkout,
                      );
                    } else {
                      // Handle case where workout wasn't saved (e.g., error in provider)
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Failed to save workout.'),
                        ),
                      );
                      Navigator.of(context).pop(); // Go back anyway
                    }
                  }
                },
              ),
            ],
          ),
    );
  }

  // Removed duplicate _formatDuration helper
}

// Helper extension needed for capitalize
extension StringExtension on String {
  String capitalize() {
    if (this.isEmpty) {
      return "";
    }
    return "${this[0].toUpperCase()}${this.substring(1).toLowerCase()}";
  }
}
