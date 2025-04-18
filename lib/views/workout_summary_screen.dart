import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../controllers/workout_provider.dart';
import '../controllers/achievements_provider.dart';
import '../models/workout_model.dart';
import '../widgets/primary_button.dart';

class WorkoutSummaryScreen extends StatefulWidget {
  final WorkoutModel workout;
  
  const WorkoutSummaryScreen({
    super.key,
    required this.workout,
  });

  @override
  State<WorkoutSummaryScreen> createState() => _WorkoutSummaryScreenState();
}

class _WorkoutSummaryScreenState extends State<WorkoutSummaryScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  List<String> _achievementsUnlocked = [];
  bool _isMapLoaded = false;
  
  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    
    // Check for achievements unlocked by this workout
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final achievementsProvider = Provider.of<AchievementsProvider>(context, listen: false);
      setState(() {
        _achievementsUnlocked = achievementsProvider.getUnlockedAchievements(widget.workout);
      });
    });
  }
  
  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
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
            onPressed: () => Navigator.of(context).popUntil((route) => route.isFirst),
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
              text: 'SAVE AND CONTINUE',
              onPressed: () {
                // Save workout if needed and navigate to home
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
                '${workout.distance.toStringAsFixed(2)} km',
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
                '${workout.averagePace}/km',
                Icons.speed,
              ),
              const SizedBox(width: 16),
              _buildMetricCard(
                context,
                'Calories',
                '${workout.calories.round()} kcal',
                Icons.local_fire_department,
              ),
            ],
          ),
          const SizedBox(height: 24),
          
          // Achievements unlocked
          if (_achievementsUnlocked.isNotEmpty) ...[
            Text(
              'Achievements Unlocked',
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
                itemCount: _achievementsUnlocked.length,
                separatorBuilder: (context, index) => const Divider(height: 1),
                itemBuilder: (context, index) {
                  final achievement = _achievementsUnlocked[index];
                  return ListTile(
                    leading: CircleAvatar(
                      backgroundColor: theme.colorScheme.secondary.withOpacity(0.2),
                      child: Icon(
                        Icons.emoji_events,
                        color: theme.colorScheme.secondary,
                      ),
                    ),
                    title: Text(achievement),
                    subtitle: const Text('New achievement unlocked'),
                  );
                },
              ),
            ),
            const SizedBox(height: 24),
          ],
          
          // Personal records
          Text(
            'Personal Records',
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
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        Icons.emoji_events,
                        size: 20,
                        color: theme.colorScheme.primary,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'Fastest 5K',
                        style: theme.textTheme.titleSmall,
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '28:45',
                    style: theme.textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    'Previous: 29:12',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: Colors.green,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildDetailsTab(BuildContext context) {
    final theme = Theme.of(context);
    final workout = widget.workout;
    
    // Sample split data - would come from actual workout data
    final splits = [
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
                  _buildInfoRow(context, 'Type', workout.type),
                  _buildInfoRow(context, 'Date', _formatDate(workout.date)),
                  _buildInfoRow(context, 'Time', _formatTime(workout.date)),
                  _buildInfoRow(context, 'Duration', _formatDuration(workout.duration)),
                  _buildInfoRow(context, 'Distance', '${workout.distance.toStringAsFixed(2)} km'),
                  _buildInfoRow(context, 'Avg. Pace', '${workout.averagePace}/km'),
                  _buildInfoRow(context, 'Calories', '${workout.calories.round()} kcal'),
                  _buildInfoRow(context, 'Elevation Gain', '+45m'),
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),
          
          // Splits
          Text(
            'Splits',
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
                        child: Text(
                          'KM',
                          style: theme.textTheme.titleSmall,
                        ),
                      ),
                      Expanded(
                        flex: 3,
                        child: Text(
                          'PACE',
                          style: theme.textTheme.titleSmall,
                        ),
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
                  separatorBuilder: (context, index) => const Divider(height: 1),
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
          
          // Heart rate chart would go here
          const SizedBox(height: 24),
          Text(
            'Heart Rate',
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
            child: Container(
              height: 200,
              width: double.infinity,
              padding: const EdgeInsets.all(16.0),
              child: Center(
                child: Text(
                  'Heart Rate Chart Placeholder',
                  style: theme.textTheme.bodyMedium,
                ),
              ),
            ),
          ),
          
          const SizedBox(height: 24),
        ],
      ),
    );
  }
  
  Widget _buildMapTab(BuildContext context) {
    final theme = Theme.of(context);
    
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
          Text(
            'Route Map',
            style: theme.textTheme.titleMedium,
          ),
          const SizedBox(height: 8),
          Text(
            'Map implementation would display the workout route here',
            style: theme.textTheme.bodyMedium,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          OutlinedButton.icon(
            icon: const Icon(Icons.refresh),
            label: const Text('Load Map'),
            onPressed: () {
              setState(() {
                _isMapLoaded = !_isMapLoaded;
              });
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(_isMapLoaded ? 'Map loaded!' : 'Map unloaded'),
                  duration: const Duration(seconds: 2),
                ),
              );
            },
          ),
        ],
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
          padding: const EdgeInsets.all(16.0),
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
                style: theme.textTheme.titleLarge?.copyWith(
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
  
  Widget _buildInfoRow(BuildContext context, String label, String value) {
    final theme = Theme.of(context);
    
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.textTheme.bodyMedium?.color?.withOpacity(0.7),
            ),
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
  
  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }
  
  String _formatTime(DateTime date) {
    return '${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
  }
}
