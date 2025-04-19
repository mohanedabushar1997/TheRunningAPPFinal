import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import '../controllers/workout_provider.dart';
import '../controllers/achievements_provider.dart';
import '../controllers/settings_provider.dart'; // Import SettingsProvider
import '../models/workout_model.dart';
import '../models/achievement_model.dart';
import '../widgets/primary_button.dart';
import 'package:intl/intl.dart';
import '../widgets/custom_map_marker.dart';
import '../models/workout_point_model.dart';
import '../widgets/custom_line_chart.dart';
import 'package:fl_chart/fl_chart.dart';

class WorkoutSummaryScreen extends StatefulWidget {
  final WorkoutModel workout;

  const WorkoutSummaryScreen({super.key, required this.workout});

  @override
  State<WorkoutSummaryScreen> createState() => _WorkoutSummaryScreenState();
}

class _WorkoutSummaryScreenState extends State<WorkoutSummaryScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  List<AchievementModel> _newlyUnlockedAchievements = [];
  bool _isLoadingAchievements = true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _checkAchievements();
    });
  }

  Future<void> _checkAchievements() async {
    setState(() => _isLoadingAchievements = true);
    try {
      final achievementsProvider = Provider.of<AchievementsProvider>(
        context,
        listen: false,
      );
      final unlocked = await achievementsProvider.checkAndUnlockAchievements(
        workout: widget.workout,
      );
      if (mounted) {
        setState(() {
          _newlyUnlockedAchievements = unlocked;
          _isLoadingAchievements = false;
        });
      }
    } catch (e) {
      print("Error checking achievements: $e");
      if (mounted) {
        setState(() => _isLoadingAchievements = false);
      }
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
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

  String _formatDate(DateTime date) => DateFormat('MMM d, yyyy').format(date);
  String _formatTime(DateTime date) => DateFormat('h:mm a').format(date);
  // --- End Formatting Helpers ---

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return WillPopScope(
      onWillPop: () async {
        Navigator.of(context).popUntil((route) => route.isFirst);
        return false;
      },
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Workout Summary'),
          leading: IconButton(
            icon: const Icon(Icons.home),
            tooltip: 'Go Home',
            onPressed:
                () => Navigator.of(context).popUntil((route) => route.isFirst),
          ),
          bottom: TabBar(
            controller: _tabController,
            tabs: const [
              Tab(text: 'SUMMARY'),
              Tab(text: 'DETAILS'),
              Tab(text: 'MAP'),
            ],
          ),
        ),
        body: TabBarView(
          controller: _tabController,
          children: [
            _buildSummaryTab(context),
            _buildDetailsTab(context),
            _buildMapTab(context),
          ],
        ),
        bottomNavigationBar: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: PrimaryButton(
              text: 'DONE',
              onPressed:
                  () =>
                      Navigator.of(context).popUntil((route) => route.isFirst),
            ),
          ),
        ),
      ),
    );
  }

  // --- Tab Builders ---
  Widget _buildSummaryTab(BuildContext context) {
    final theme = Theme.of(context);
    final workout = widget.workout;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Congratulations card
          Card(
            elevation: 2,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16.0),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    theme.colorScheme.primary,
                    theme.colorScheme.primary.withOpacity(0.8),
                  ],
                ),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                children: [
                  Icon(
                    Icons.emoji_events,
                    size: 48,
                    color: theme.colorScheme.onPrimary,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Great Job!',
                    style: theme.textTheme.headlineMedium?.copyWith(
                      color: theme.colorScheme.onPrimary,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'You\'ve completed your workout',
                    style: theme.textTheme.bodyLarge?.copyWith(
                      color: theme.colorScheme.onPrimary.withOpacity(0.9),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),
          // Main metrics
          Row(
            children: [
              _buildMetricCard(
                context,
                'Distance',
                '${workout.distance?.toStringAsFixed(2) ?? '0.00'} km',
                Icons.straighten,
              ),
              const SizedBox(width: 16),
              _buildMetricCard(
                context,
                'Duration',
                _formatDuration(workout.duration),
                Icons.timer,
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              _buildMetricCard(
                context,
                'Avg. Pace',
                _formatPace(workout.avgPace),
                Icons.speed,
              ),
              const SizedBox(width: 16),
              _buildMetricCard(
                context,
                'Calories',
                '${workout.calories?.round() ?? 0} kcal',
                Icons.local_fire_department,
              ),
            ],
          ),
          const SizedBox(height: 24),
          // Achievements unlocked
          if (_isLoadingAchievements)
            const Center(
              child: Padding(
                padding: EdgeInsets.all(8.0),
                child: CircularProgressIndicator(),
              ),
            )
          else if (_newlyUnlockedAchievements.isNotEmpty) ...[
            Text(
              'Achievements Unlocked!',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Card(
              elevation: 1,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              child: ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: _newlyUnlockedAchievements.length,
                separatorBuilder: (context, index) => const Divider(height: 1),
                itemBuilder: (context, index) {
                  final achievement = _newlyUnlockedAchievements[index];
                  return ListTile(
                    leading: CircleAvatar(
                      backgroundColor: theme.colorScheme.secondary.withOpacity(
                        0.2,
                      ),
                      child: Icon(
                        Icons.emoji_events,
                        color: theme.colorScheme.secondary,
                      ),
                    ),
                    title: Text(achievement.name),
                    subtitle: Text(
                      achievement.description ?? 'New achievement!',
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 24),
          ],
        ],
      ),
    );
  }

  Widget _buildDetailsTab(BuildContext context) {
    final theme = Theme.of(context);
    final workout = widget.workout;
    final settingsProvider = Provider.of<SettingsProvider>(
      context,
      listen: false,
    ); // Get settings
    final bool useImperial = settingsProvider.units == 'imperial';
    final String unitLabel = useImperial ? 'MILE' : 'KM';
    final List<Duration>? splits = workout.splits; // Get actual splits

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Workout info card
          Card(
            elevation: 1,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Workout Info',
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 16),
                  _buildInfoRow(
                    context,
                    'Type',
                    workout.type.toShortString().capitalize(),
                  ),
                  _buildInfoRow(context, 'Date', _formatDate(workout.date)),
                  _buildInfoRow(context, 'Time', _formatTime(workout.date)),
                  _buildInfoRow(
                    context,
                    'Duration',
                    _formatDuration(workout.duration),
                  ),
                  _buildInfoRow(
                    context,
                    'Distance',
                    '${workout.distance?.toStringAsFixed(2) ?? '-.--'} km',
                  ),
                  _buildInfoRow(
                    context,
                    'Avg. Pace',
                    _formatPace(workout.avgPace),
                  ),
                  _buildInfoRow(
                    context,
                    'Calories',
                    '${workout.calories?.round() ?? 0} kcal',
                  ),
                  _buildInfoRow(
                    context,
                    'Elevation Gain',
                    '+${workout.elevationGain?.toStringAsFixed(0) ?? 0}m',
                  ),
                  _buildInfoRow(
                    context,
                    'Elevation Loss',
                    '-${workout.elevationLoss?.toStringAsFixed(0) ?? 0}m',
                  ),
                  _buildInfoRow(
                    context,
                    'Max Speed',
                    '${workout.maxSpeed?.toStringAsFixed(1) ?? '-.-'} km/h',
                  ),
                  if (workout.notes != null && workout.notes!.isNotEmpty)
                    _buildInfoRow(context, 'Notes', workout.notes!),
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),
          // Splits
          Text(
            'Splits', // Updated title
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          // Display splits or 'No data' message
          (splits == null || splits.isEmpty)
              ? Card(
                elevation: 1,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Padding(
                  padding: EdgeInsets.all(16.0),
                  child: Center(child: Text('No split data recorded.')),
                ),
              )
              : Card(
                elevation: 1,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  children: [
                    Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16.0,
                        vertical: 12.0,
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            flex: 2,
                            child: Text(
                              unitLabel,
                              style: theme.textTheme.titleSmall,
                            ),
                          ),
                          Expanded(
                            flex: 3,
                            child: Text(
                              'TIME',
                              style: theme.textTheme.titleSmall,
                            ),
                          ),
                          // Removed Elevation column header
                        ],
                      ),
                    ),
                    const Divider(height: 1),
                    ListView.separated(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: splits.length,
                      separatorBuilder:
                          (context, index) => const Divider(height: 1),
                      itemBuilder: (context, index) {
                        final splitDuration = splits[index];
                        return Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16.0,
                            vertical: 12.0,
                          ),
                          child: Row(
                            children: [
                              Expanded(
                                flex: 2,
                                child: Text(
                                  '${index + 1}', // Split number
                                  style: theme.textTheme.bodyMedium,
                                ),
                              ),
                              Expanded(
                                flex: 3,
                                child: Text(
                                  _formatDuration(
                                    splitDuration,
                                  ), // Formatted split time
                                  style: theme.textTheme.bodyMedium?.copyWith(
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                              // Removed Elevation data display
                            ],
                          ),
                        );
                      },
                    ),
                  ],
                ),
              ), // End of Card for splits list
          const SizedBox(height: 24),
          // Elevation Profile Chart
          _buildElevationChart(context),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  Widget _buildMapTab(BuildContext context) {
    final theme = Theme.of(context);
    final workout = widget.workout;
    // Access settings provider
    final settingsProvider = Provider.of<SettingsProvider>(
      context,
      listen: false,
    );
    final List<WorkoutPointModel> routePoints = workout.routePoints ?? [];
    final List<LatLng> latLngPoints =
        routePoints.map((p) => LatLng(p.latitude, p.longitude)).toList();

    if (latLngPoints.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.map_outlined, size: 64, color: theme.disabledColor),
            const SizedBox(height: 16),
            Text('No Route Data Available', style: theme.textTheme.titleMedium),
          ],
        ),
      );
    }

    final bounds = LatLngBounds.fromPoints(latLngPoints);
    final center = bounds.center;
    double zoom = 14.0;
    double distance = const Distance().distance(
      bounds.northEast,
      bounds.southWest,
    );
    if (distance > 0) {
      zoom = 15 - (distance / 20000);
      if (zoom < 10) zoom = 10;
      if (zoom > 18) zoom = 18;
    }

    return FlutterMap(
      options: MapOptions(center: center, zoom: zoom),
      children: [
        TileLayer(
          urlTemplate: _getMapUrlTemplate(
            settingsProvider.mapType,
          ), // Use helper
          userAgentPackageName: 'com.fitstride.runningapp',
          subdomains: _getSubdomains(settingsProvider.mapType), // Use helper
        ),
        PolylineLayer(
          polylines: [
            Polyline(
              points: latLngPoints,
              strokeWidth: 4.0,
              color: theme.colorScheme.primary,
            ),
          ],
        ),
        MarkerLayer(
          markers: [
            if (latLngPoints.isNotEmpty)
              CustomMapMarker(
                point: latLngPoints.first,
                type: MarkerType.start,
              ),
            if (latLngPoints.length > 1)
              CustomMapMarker(point: latLngPoints.last, type: MarkerType.end),
          ],
        ),
      ],
    );
  }
  // --- End Tab Builders ---

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

  Widget _buildInfoRow(BuildContext context, String label, String value) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: theme.textTheme.bodyMedium?.copyWith(color: theme.hintColor),
          ),
          Text(
            value,
            style: theme.textTheme.bodyMedium?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildElevationChart(BuildContext context) {
    final theme = Theme.of(context);
    final workout = widget.workout;
    final List<WorkoutPointModel> points = workout.routePoints ?? [];
    if (points.length < 2) return const SizedBox.shrink();

    List<FlSpot> spots = [];
    double cumulativeDistance = 0.0;
    double minElevation = double.maxFinite;
    double maxElevation = double.minPositive;

    for (int i = 0; i < points.length; i++) {
      final point = points[i];
      if (point.elevation != null) {
        if (point.elevation! < minElevation) minElevation = point.elevation!;
        if (point.elevation! > maxElevation) maxElevation = point.elevation!;
      }
      if (i > 0) {
        cumulativeDistance +=
            const Distance().distance(
              LatLng(points[i - 1].latitude, points[i - 1].longitude),
              LatLng(point.latitude, point.longitude),
            ) /
            1000.0;
      }
      if (point.elevation != null)
        spots.add(FlSpot(cumulativeDistance, point.elevation!));
    }

    final elevationRange = maxElevation - minElevation;
    minElevation -= elevationRange * 0.1;
    maxElevation += elevationRange * 0.1;
    if (minElevation == maxElevation) {
      minElevation -= 5;
      maxElevation += 5;
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Elevation Profile',
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 8),
        CustomLineChart(
          spots: spots,
          minY: minElevation,
          maxY: maxElevation,
          showDots: false,
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 40,
              interval: (maxElevation - minElevation) / 4,
              getTitlesWidget: (value, meta) {
                final interval = (meta.max - meta.min) / 4;
                if (value == meta.min ||
                    value == meta.max ||
                    (interval > 0 && (value - meta.min) % interval < 1e-6)) {
                  return SideTitleWidget(
                    axisSide: meta.axisSide,
                    space: 8.0,
                    child: Text(
                      '${value.toStringAsFixed(0)}m',
                      style: theme.textTheme.bodySmall,
                    ),
                  );
                }
                return const SizedBox.shrink();
              },
            ),
          ),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 30,
              interval: (spots.last.x - spots.first.x) / 4,
              getTitlesWidget: (value, meta) {
                final interval = (meta.max - meta.min) / 4;
                if (value == meta.min ||
                    value == meta.max ||
                    (interval > 0 && (value - meta.min) % interval < 1e-6)) {
                  return SideTitleWidget(
                    axisSide: meta.axisSide,
                    space: 8.0,
                    child: Text(
                      '${value.toStringAsFixed(1)}km',
                      style: theme.textTheme.bodySmall,
                    ),
                  );
                }
                return const SizedBox.shrink();
              },
            ),
          ),
        ),
      ],
    );
  }
  // --- End Widget Builders ---

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
} // End of _WorkoutSummaryScreenState class

// Helper extension needed for capitalize
extension StringExtension on String {
  String capitalize() {
    if (isEmpty) return "";
    return "${this[0].toUpperCase()}${substring(1).toLowerCase()}";
  }
}
