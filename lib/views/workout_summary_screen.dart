import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../controllers/workout_provider.dart';
import '../controllers/achievements_provider.dart';
import '../models/workout_model.dart';
import '../models/achievement_model.dart'; // Import AchievementModel
import '../widgets/primary_button.dart';
import 'package:intl/intl.dart'; // For date formatting

class WorkoutSummaryScreen extends StatefulWidget {
  final WorkoutModel workout;

  const WorkoutSummaryScreen({super.key, required this.workout});

  @override
  State<WorkoutSummaryScreen> createState() => _WorkoutSummaryScreenState();
}

class _WorkoutSummaryScreenState extends State<WorkoutSummaryScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  List<AchievementModel> _newlyUnlockedAchievements =
      []; // Store AchievementModel
  bool _isMapLoaded = false;
  bool _isLoadingAchievements = true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);

    // Check for achievements unlocked by this workout
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
      // Call the correct async method and await its result
      final unlocked = await achievementsProvider.checkAndUnlockAchievements(
        workout: widget.workout,
      );
      if (mounted) {
        // Check if the widget is still in the tree
        setState(() {
          _newlyUnlockedAchievements = unlocked;
          _isLoadingAchievements = false;
        });
      }
    } catch (e) {
      print("Error checking achievements: $e");
      if (mounted) {
        setState(() => _isLoadingAchievements = false);
        // Optionally show an error message
      }
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  // Helper to format duration
  String _formatDuration(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    final hours = twoDigits(duration.inHours);
    final minutes = twoDigits(duration.inMinutes.remainder(60));
    final seconds = twoDigits(duration.inSeconds.remainder(60));
    return [if (duration.inHours > 0) hours, minutes, seconds].join(':');
  }

  // Helper to format pace
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

  // Helper to format date
  String _formatDate(DateTime date) {
    return DateFormat('MMM d, yyyy').format(date); // Example format
  }

  // Helper to format time
  String _formatTime(DateTime date) {
    return DateFormat('h:mm a').format(date); // Example format
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return WillPopScope(
      onWillPop: () async {
        // Navigate to home instead of previous screen
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
            // SUMMARY TAB
            _buildSummaryTab(context),

            // DETAILS TAB
            _buildDetailsTab(context),

            // MAP TAB
            _buildMapTab(context),
          ],
        ),
        bottomNavigationBar: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: PrimaryButton(
              text: 'DONE', // Changed text
              onPressed: () {
                // Navigate to home
                Navigator.of(context).popUntil((route) => route.isFirst);
              },
            ),
          ),
        ),
      ),
    );
  }

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
                // Add null check
                '${workout.distance?.toStringAsFixed(2) ?? '0.00'} km',
                Icons.straighten,
              ),
              const SizedBox(width: 16),
              _buildMetricCard(
                context,
                'Duration',
                // Pass seconds to helper
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
                // Use correct property and formatter
                _formatPace(workout.avgPace),
                Icons.speed,
              ),
              const SizedBox(width: 16),
              _buildMetricCard(
                context,
                'Calories',
                // Add null check
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
                      // TODO: Use achievement.icon if it's an IconData or load image
                      child: Icon(
                        Icons.emoji_events,
                        color: theme.colorScheme.secondary,
                      ),
                    ),
                    title: Text(achievement.name), // Use name from model
                    subtitle: Text(
                      achievement.description ?? 'New achievement!',
                    ), // Use description
                  );
                },
              ),
            ),
            const SizedBox(height: 24),
          ],

          // Personal records (Placeholder - requires logic)
          // Text(
          //   'Personal Records',
          //   style: theme.textTheme.titleMedium?.copyWith(
          //     fontWeight: FontWeight.bold,
          //   ),
          // ),
          // const SizedBox(height: 8),
          // Card( ... PR display ... ),
        ],
      ),
    );
  }

  Widget _buildDetailsTab(BuildContext context) {
    final theme = Theme.of(context);
    final workout = widget.workout;

    // TODO: Calculate actual splits from workout.routePoints
    final splits = [
      // Sample data
      {'km': 1, 'pace': '5:30', 'elevation': '+12m'},
      {'km': 2, 'pace': '5:42', 'elevation': '+8m'},
      {'km': 3, 'pace': '5:38', 'elevation': '-5m'},
      {'km': 4, 'pace': '5:45', 'elevation': '+3m'},
      {'km': 5, 'pace': '5:35', 'elevation': '-10m'},
    ];

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
                  // Use WorkoutTypeExtension to convert enum to string
                  _buildInfoRow(
                    context,
                    'Type',
                    workout.type.toShortString().capitalize(),
                  ),
                  _buildInfoRow(context, 'Date', _formatDate(workout.date)),
                  _buildInfoRow(context, 'Time', _formatTime(workout.date)),
                  // Pass seconds to helper
                  _buildInfoRow(
                    context,
                    'Duration',
                    _formatDuration(workout.duration),
                  ),
                  // Add null check
                  _buildInfoRow(
                    context,
                    'Distance',
                    '${workout.distance?.toStringAsFixed(2) ?? '-.--'} km',
                  ),
                  // Use correct property and formatter
                  _buildInfoRow(
                    context,
                    'Avg. Pace',
                    _formatPace(workout.avgPace),
                  ),
                  // Add null check
                  _buildInfoRow(
                    context,
                    'Calories',
                    '${workout.calories?.round() ?? 0} kcal',
                  ),
                  // Add null check and formatting
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

          // Splits (Placeholder - requires calculation)
          Text(
            'Splits (Placeholder)',
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
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Row(
                    children: [
                      Expanded(
                        flex: 2,
                        child: Text('KM', style: theme.textTheme.titleSmall),
                      ),
                      Expanded(
                        flex: 3,
                        child: Text('PACE', style: theme.textTheme.titleSmall),
                      ),
                      Expanded(
                        flex: 3,
                        child: Text(
                          'ELEVATION',
                          style: theme.textTheme.titleSmall,
                        ),
                      ),
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
                    final split = splits[index];
                    return Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Row(
                        children: [
                          Expanded(
                            flex: 2,
                            child: Text(
                              '${split['km']}',
                              style: theme.textTheme.bodyMedium,
                            ),
                          ),
                          Expanded(
                            flex: 3,
                            child: Text(
                              '${split['pace']}',
                              style: theme.textTheme.bodyMedium?.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          Expanded(
                            flex: 3,
                            child: Text(
                              '${split['elevation']}',
                              style: theme.textTheme.bodyMedium,
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ],
            ),
          ),

          // Heart rate chart would go here (Placeholder)
          // const SizedBox(height: 24),
          // Text( ... ), Card( ... ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  Widget _buildMapTab(BuildContext context) {
    final theme = Theme.of(context);
    // TODO: Implement actual map view using flutter_map and workout.routePoints

    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.map,
            size: 64,
            color: theme.colorScheme.primary.withOpacity(0.5),
          ),
          const SizedBox(height: 16),
          Text('Route Map', style: theme.textTheme.titleMedium),
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32.0),
            child: Text(
              'Map implementation using workout route points would go here.',
              style: theme.textTheme.bodyMedium,
              textAlign: TextAlign.center,
            ),
          ),
          // const SizedBox(height: 24),
          // OutlinedButton.icon( ... Load Map Button ... ),
        ],
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
