import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import '../controllers/tracking_provider.dart';
import '../models/training_session_model.dart'; // Import TrainingSessionModel
import '../controllers/voice_coaching_provider.dart';
import '../controllers/workout_provider.dart';
import '../controllers/settings_provider.dart'; // Import SettingsProvider
import '../widgets/primary_button.dart';
import '../models/workout_model.dart';
import '../widgets/custom_map_marker.dart'; // Import custom marker

class ActiveWorkoutScreen extends StatefulWidget {
  const ActiveWorkoutScreen({super.key});

  @override
  State<ActiveWorkoutScreen> createState() => _ActiveWorkoutScreenState();
}

class _ActiveWorkoutScreenState extends State<ActiveWorkoutScreen> {
  final MapController _mapController = MapController(); // Add MapController

  @override
  void initState() {
    super.initState();
    // Start tracking when screen loads
    // Start tracking after the first frame, potentially with training session data
    WidgetsBinding.instance.addPostFrameCallback((_) {
      // Check for passed arguments
      final session =
          ModalRoute.of(context)?.settings.arguments as TrainingSessionModel?;

      final trackingProvider = Provider.of<TrackingProvider>(
        context,
        listen: false,
      );
      final workoutProvider = Provider.of<WorkoutProvider>(
        context,
        listen: false,
      );
      trackingProvider.setWorkoutProvider(workoutProvider);
      // Start workout, passing session if available
      trackingProvider.startWorkout(trainingSession: session);
    });
  }

  @override
  void dispose() {
    // Let WillPopScope handle cleanup via dialogs
    // _mapController.dispose(); // Consider disposing if necessary
    super.dispose();
  }

  // --- Formatting Helpers ---
  String _formatDuration(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    final hours = twoDigits(duration.inHours);
    final minutes = twoDigits(duration.inMinutes.remainder(60));
    final seconds = twoDigits(duration.inSeconds.remainder(60));
    return [if (duration.inHours > 0) hours, minutes, seconds].join(':');
  }

  String _formatPace(double? paceInSecondsPerKm) {
    if (paceInSecondsPerKm == null ||
        paceInSecondsPerKm.isNaN ||
        paceInSecondsPerKm.isInfinite ||
        paceInSecondsPerKm <= 0)
      return '-:-- /km';
    final int minutes = paceInSecondsPerKm ~/ 60;
    final int seconds = (paceInSecondsPerKm % 60).round();
    return '${minutes.toString()}:${seconds.toString().padLeft(2, '0')} /km';
  }
  // --- End Formatting Helpers ---

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final trackingProvider = Provider.of<TrackingProvider>(context);
    final voiceCoachingProvider = Provider.of<VoiceCoachingProvider>(
      context,
      listen: false,
    );
    final settingsProvider = Provider.of<SettingsProvider>(context);
    final bool isPaused = trackingProvider.isPaused;

    return WillPopScope(
      onWillPop: () async {
        final shouldPop = await _showExitConfirmationDialog(context);
        return shouldPop ?? false;
      },
      child: Scaffold(
        appBar: AppBar(
          title: Text(
            'Active ${trackingProvider.workoutType.toShortString().capitalize()}',
          ),
          automaticallyImplyLeading: false,
          actions: [
            IconButton(
              icon: const Icon(Icons.close),
              tooltip: 'Stop Workout',
              onPressed: () => _showStopWorkoutDialog(context),
            ),
          ],
        ),
        body: SafeArea(
          child: Column(
            children: [
              // Map View Implementation with Controls
              Expanded(
                flex: 2,
                child: Stack(
                  // Use Stack for overlay
                  children: [
                    FlutterMap(
                      mapController: _mapController, // Assign controller
                      options: MapOptions(
                        center:
                            trackingProvider.currentPosition != null
                                ? LatLng(
                                  trackingProvider.currentPosition!.latitude,
                                  trackingProvider.currentPosition!.longitude,
                                )
                                : LatLng(51.5, -0.09), // Default location
                        zoom: 16.0,
                        // Use onPositionChanged to potentially update map center/zoom if needed elsewhere
                        // onPositionChanged: (position, hasGesture) {
                        //   // Update state if needed
                        // },
                      ),
                      children: [
                        // Tile Layer (Dynamic based on settings)
                        TileLayer(
                          urlTemplate: _getMapUrlTemplate(
                            settingsProvider.mapType,
                          ),
                          userAgentPackageName: 'com.fitstride.runningapp',
                          subdomains: _getSubdomains(settingsProvider.mapType),
                        ),
                        // Polyline Layer (Route Track)
                        PolylineLayer(
                          polylines: [
                            Polyline(
                              points:
                                  trackingProvider.routePoints
                                      .map(
                                        (p) => LatLng(p.latitude, p.longitude),
                                      )
                                      .toList(),
                              strokeWidth: 4.0,
                              color: theme.colorScheme.primary,
                            ),
                          ],
                        ),
                        // Marker Layer (Current Location)
                        if (trackingProvider.currentPosition != null)
                          MarkerLayer(
                            markers: [
                              CustomMapMarker(
                                point: LatLng(
                                  trackingProvider.currentPosition!.latitude,
                                  trackingProvider.currentPosition!.longitude,
                                ),
                                type: MarkerType.current,
                                size: 25,
                              ),
                            ],
                          ),
                      ],
                    ),
                    // Map Controls Overlay
                    Positioned(
                      bottom: 10,
                      right: 10,
                      child: Column(
                        children: [
                          FloatingActionButton.small(
                            heroTag: 'zoomIn',
                            tooltip: 'Zoom In',
                            onPressed: () {
                              // Use direct zoom property if available, otherwise keep track via onPositionChanged
                              var currentZoom =
                                  _mapController.zoom; // Try direct access
                              _mapController.move(
                                _mapController.center,
                                currentZoom + 1,
                              ); // Use direct access
                            },
                            child: const Icon(Icons.add),
                          ),
                          const SizedBox(height: 8),
                          FloatingActionButton.small(
                            heroTag: 'zoomOut',
                            tooltip: 'Zoom Out',
                            onPressed: () {
                              var currentZoom =
                                  _mapController.zoom; // Try direct access
                              _mapController.move(
                                _mapController.center,
                                currentZoom - 1,
                              ); // Use direct access
                            },
                            child: const Icon(Icons.remove),
                          ),
                        ],
                      ),
                    ),
                    Positioned(
                      top: 10,
                      right: 10,
                      child: Column(
                        children: [
                          FloatingActionButton.small(
                            heroTag: 'centerMap',
                            tooltip: 'Center on Me',
                            onPressed: () {
                              if (trackingProvider.currentPosition != null) {
                                _mapController.move(
                                  LatLng(
                                    trackingProvider.currentPosition!.latitude,
                                    trackingProvider.currentPosition!.longitude,
                                  ),
                                  _mapController.zoom, // Use direct access
                                );
                              }
                            },
                            child: const Icon(Icons.my_location),
                          ),
                          const SizedBox(height: 8),
                          FloatingActionButton.small(
                            heroTag: 'cycleMap',
                            tooltip: 'Change Map Type',
                            onPressed: () {
                              final currentType = settingsProvider.mapType;
                              String nextType;
                              if (currentType == 'standard')
                                nextType = 'satellite';
                              else if (currentType == 'satellite')
                                nextType = 'terrain';
                              else
                                nextType = 'standard';
                              settingsProvider.setMapType(nextType);
                            },
                            child: Icon(
                              settingsProvider.mapType == 'standard'
                                  ? Icons.layers
                                  : settingsProvider.mapType == 'satellite'
                                  ? Icons.satellite_alt
                                  : Icons.terrain,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
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
                            _buildMetricCard(
                              context,
                              'Time',
                              _formatDuration(trackingProvider.elapsedTime),
                              Icons.timer,
                            ),
                            const SizedBox(width: 16),
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
                            _buildMetricCard(
                              context,
                              'Pace',
                              _formatPace(trackingProvider.currentPace),
                              Icons.speed,
                            ),
                            const SizedBox(width: 16),
                            _buildMetricCard(
                              context,
                              'Calories',
                              '${trackingProvider.caloriesBurned.round()} kcal',
                              Icons.local_fire_department,
                            ),
                          ],
                        ),
                      ),

                      // Interval Display (Conditional)
                      if (trackingProvider.isTrainingPlanWorkout)
                        _buildIntervalDisplay(context, trackingProvider),

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
                                backgroundColor: theme.colorScheme.primary
                                    .withOpacity(0.2),
                                valueColor: AlwaysStoppedAnimation<Color>(
                                  theme.colorScheme.primary,
                                ),
                                minHeight: 8,
                              ),
                              const SizedBox(height: 4),
                              Text(
                                trackingProvider.hasDistanceGoal
                                    ? '${trackingProvider.distance.toStringAsFixed(2)} / ${trackingProvider.distanceGoal?.toStringAsFixed(2) ?? '-'} km'
                                    : '${_formatDuration(trackingProvider.elapsedTime)} / ${_formatDuration(trackingProvider.durationGoal ?? Duration.zero)}',
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
                                if (isPaused) {
                                  trackingProvider.resumeWorkout();
                                  voiceCoachingProvider.playCue('resume');
                                } else {
                                  trackingProvider.pauseWorkout();
                                  voiceCoachingProvider.playCue('pause');
                                }
                              },
                            ),
                            FloatingActionButton(
                              heroTag: 'stop',
                              backgroundColor: Colors.red,
                              child: const Icon(
                                Icons.stop,
                                color: Colors.white,
                              ),
                              onPressed: () => _showStopWorkoutDialog(context),
                            ),
                            FloatingActionButton(
                              heroTag: 'lock',
                              backgroundColor: theme.colorScheme.surfaceVariant,
                              child: Icon(
                                Icons.lock_outline,
                                color: theme.colorScheme.onSurfaceVariant,
                              ),
                              onPressed:
                                  () => ScaffoldMessenger.of(
                                    context,
                                  ).showSnackBar(
                                    const SnackBar(
                                      content: Text(
                                        'Screen lock not implemented yet',
                                      ),
                                      duration: Duration(seconds: 2),
                                    ),
                                  ),
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

  // --- Widget Builders ---
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

  Widget _buildIntervalDisplay(
    BuildContext context,
    TrackingProvider trackingProvider,
  ) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(top: 16.0, bottom: 8.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Text(
            'Current Interval:',
            style: theme.textTheme.titleSmall?.copyWith(color: theme.hintColor),
          ),
          const SizedBox(height: 4),
          Text(
            trackingProvider.currentIntervalDescription ?? 'Training Session',
            style: theme.textTheme.bodyLarge?.copyWith(
              fontWeight: FontWeight.bold,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Text(
            'Time Remaining:',
            style: theme.textTheme.titleSmall?.copyWith(color: theme.hintColor),
          ),
          const SizedBox(height: 4),
          Text(
            _formatDuration(trackingProvider.remainingIntervalTime),
            style: theme.textTheme.headlineMedium?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  // --- Dialogs ---
  Future<bool?> _showExitConfirmationDialog(BuildContext context) {
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
                  Navigator.of(context).pop(true);
                  await trackingProvider.discardWorkout();
                  if (mounted) Navigator.of(context).pop();
                },
              ),
            ],
          ),
    );
  }

  Future<void> _showStopWorkoutDialog(BuildContext context) {
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
                  Navigator.of(context).pop();
                  await trackingProvider.discardWorkout();
                  if (mounted) Navigator.of(context).pop();
                },
              ),
              TextButton(
                child: const Text('SAVE & FINISH'),
                onPressed: () async {
                  Navigator.of(context).pop();
                  final savedWorkout =
                      await trackingProvider.stopAndSaveWorkout();
                  if (mounted) {
                    if (savedWorkout != null) {
                      Navigator.pushReplacementNamed(
                        context,
                        '/workout_summary',
                        arguments: savedWorkout,
                      );
                    } else {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Failed to save workout.'),
                        ),
                      );
                      Navigator.of(context).pop();
                    }
                  }
                },
              ),
            ],
          ),
    );
  }

  // --- Map Type Helpers ---
  String _getMapUrlTemplate(String mapType) {
    switch (mapType) {
      case 'satellite':
        return 'https://server.arcgisonline.com/ArcGIS/rest/services/World_Imagery/MapServer/tile/{z}/{y}/{x}';
      case 'terrain':
        return 'https://{s}.tile.opentopomap.org/{z}/{x}/{y}.png';
      case 'standard':
      default:
        return 'https://tile.openstreetmap.org/{z}/{x}/{y}.png';
    }
  }

  List<String> _getSubdomains(String mapType) {
    switch (mapType) {
      case 'terrain':
        return ['a', 'b', 'c'];
      default:
        return [];
    }
  }

  // --- End Map Type Helpers ---
} // End of _ActiveWorkoutScreenState class

// Helper extension needed for capitalize
extension StringExtension on String {
  String capitalize() {
    if (isEmpty) return "";
    return "${this[0].toUpperCase()}${substring(1).toLowerCase()}";
  }
}
