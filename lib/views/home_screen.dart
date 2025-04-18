import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../controllers/user_provider.dart';
import '../controllers/workout_provider.dart';
import '../controllers/training_plan_provider.dart';
import '../widgets/primary_button.dart';
import '../models/workout_model.dart'; // Import WorkoutModel for type safety

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  // Helper to format duration (e.g., from Duration to HH:MM:SS)
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
        paceInSecondsPerKm.isInfinite) {
      return '-:--/km';
    }
    final int minutes = paceInSecondsPerKm ~/ 60;
    final int seconds = (paceInSecondsPerKm % 60).round();
    return '${minutes.toString()}:${seconds.toString().padLeft(2, '0')}/km';
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final userProvider = Provider.of<UserProvider>(context);
    // Listen false if only using methods/getters that don't change often
    final workoutProvider = Provider.of<WorkoutProvider>(context);
    final trainingPlanProvider = Provider.of<TrainingPlanProvider>(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('FitStride'),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: () {
              // TODO: Navigate to settings screen
              Navigator.pushNamed(
                context,
                '/settings',
              ); // Assuming '/settings' route exists
            },
          ),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                // Welcome section with user info
                _buildWelcomeSection(context, userProvider),
                const SizedBox(height: 24),

                // Quick start workout button
                _buildQuickStartButton(context),
                const SizedBox(height: 24),

                // Current training plan progress
                _buildTrainingPlanProgress(context, trainingPlanProvider),
                const SizedBox(height: 24),

                // Recent activity summary
                _buildRecentActivitySummary(context, workoutProvider),
                const SizedBox(height: 24),

                // Quick stats overview
                _buildQuickStatsOverview(context, workoutProvider),
              ],
            ),
          ),
        ),
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: 0, // Home is selected
        type: BottomNavigationBarType.fixed, // Corrected type
        items: const [
          // Can be const now
          BottomNavigationBarItem(
            // Corrected class name
            icon: Icon(Icons.home),
            label: 'Home',
          ),
          BottomNavigationBarItem(
            // Corrected class name
            icon: Icon(Icons.directions_run),
            label: 'Workouts',
          ),
          BottomNavigationBarItem(
            // Corrected class name
            icon: Icon(Icons.calendar_today),
            label: 'Plans',
          ),
          BottomNavigationBarItem(
            // Corrected class name
            icon: Icon(Icons.bar_chart),
            label: 'Stats',
          ),
          BottomNavigationBarItem(
            // Corrected class name
            icon: Icon(Icons.person),
            label: 'Profile',
          ),
        ],
        onTap: (index) {
          // TODO: Handle navigation to different tabs
          switch (index) {
            case 0:
              // Already on home
              break;
            case 1:
              Navigator.pushNamed(
                context,
                '/workout_history',
              ); // Assuming route exists
              break;
            case 2:
              Navigator.pushNamed(context, '/training_plans');
              break;
            case 3:
              Navigator.pushNamed(
                context,
                '/statistics',
              ); // Assuming route exists
              break;
            case 4:
              Navigator.pushNamed(context, '/profile'); // Assuming route exists
              break;
          }
          print('Tapped on tab $index');
        },
      ),
    );
  }

  Widget _buildWelcomeSection(BuildContext context, UserProvider userProvider) {
    final theme = Theme.of(context);
    final userName = userProvider.currentUser?.name ?? 'Runner';

    return Container(
      padding: const EdgeInsets.all(16),
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
        boxShadow: [
          BoxShadow(
            color: theme.colorScheme.primary.withOpacity(0.3),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 24,
                backgroundColor: theme.colorScheme.onPrimary.withOpacity(0.2),
                child: Icon(
                  userProvider.currentUser?.gender == 'female'
                      ? Icons.female
                      : userProvider.currentUser?.gender == 'male'
                      ? Icons.male
                      : Icons.person,
                  color: theme.colorScheme.onPrimary,
                ),
              ),
              const SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Welcome back,',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.colorScheme.onPrimary.withOpacity(0.8),
                    ),
                  ),
                  Text(
                    userName,
                    style: theme.textTheme.titleLarge?.copyWith(
                      color: theme.colorScheme.onPrimary,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 16),
          if (!userProvider.isProfileCreated)
            OutlinedButton.icon(
              icon: const Icon(Icons.edit),
              label: const Text('Complete Your Profile'),
              style: OutlinedButton.styleFrom(
                foregroundColor: theme.colorScheme.onPrimary,
                side: BorderSide(
                  color: theme.colorScheme.onPrimary.withOpacity(0.5),
                ),
              ),
              onPressed: () {
                Navigator.pushNamed(context, '/profile_setup');
              },
            ),
        ],
      ),
    );
  }

  Widget _buildQuickStartButton(BuildContext context) {
    return Container(
      width: double.infinity,
      // Using intrinsic height or removing fixed height might be better
      // height: 100,
      child: PrimaryButton(
        text: 'START QUICK WORKOUT',
        // icon: Icons.play_circle_fill, // Removed invalid parameter
        onPressed: () {
          // Navigate to Workout Preparation Screen
          Navigator.pushNamed(context, '/workout_preparation');
          print('Start Quick Workout tapped');
        },
      ),
    );
  }

  Widget _buildTrainingPlanProgress(
    BuildContext context,
    TrainingPlanProvider planProvider,
  ) {
    final theme = Theme.of(context);
    // Use actual provider data
    final currentPlan = planProvider.currentPlan;
    final hasActivePlan = currentPlan != null;

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Training Plan',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                if (hasActivePlan)
                  TextButton(
                    child: const Text('View Details'),
                    onPressed: () {
                      if (currentPlan?.id != null) {
                        // Navigate to training plan details
                        Navigator.pushNamed(
                          context,
                          '/training_plan_details',
                          arguments:
                              currentPlan!.id.toString(), // Pass ID as argument
                        );
                      }
                    },
                  ),
              ],
            ),
            const SizedBox(height: 8),
            hasActivePlan
                ? Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      currentPlan?.name ?? 'Unknown Plan',
                      style: theme.textTheme.titleSmall,
                    ),
                    const SizedBox(height: 8),
                    LinearProgressIndicator(
                      value: planProvider.getCurrentPlanCompletionPercentage(),
                      backgroundColor: theme.colorScheme.primary.withOpacity(
                        0.2,
                      ),
                      valueColor: AlwaysStoppedAnimation<Color>(
                        theme.colorScheme.primary,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      // Improve progress display
                      '${(planProvider.getCurrentPlanCompletionPercentage() * 100).toStringAsFixed(0)}% Complete',
                      style: theme.textTheme.bodySmall,
                    ),
                    const SizedBox(height: 12),
                    // TODO: Display next workout based on planProvider state
                    // Row(
                    //   children: [
                    //     Icon(
                    //       Icons.calendar_today,
                    //       size: 16,
                    //       color: theme.colorScheme.secondary,
                    //     ),
                    //     const SizedBox(width: 8),
                    //     Text(
                    //       'Next workout: Today - 30 min Easy Run', // Placeholder
                    //       style: theme.textTheme.bodySmall,
                    //     ),
                    //   ],
                    // ),
                  ],
                )
                : Center(
                  child: Column(
                    children: [
                      const SizedBox(height: 16),
                      Icon(
                        Icons.fitness_center,
                        size: 48,
                        color: theme.colorScheme.primary.withOpacity(0.5),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'No active training plan',
                        style: theme.textTheme.bodyMedium,
                      ),
                      const SizedBox(height: 8),
                      OutlinedButton(
                        child: const Text('Find a Plan'),
                        onPressed: () {
                          // Navigate to training plans selection
                          Navigator.pushNamed(context, '/training_plans');
                        },
                      ),
                      const SizedBox(height: 8),
                    ],
                  ),
                ),
          ],
        ),
      ),
    );
  }

  Widget _buildRecentActivitySummary(
    BuildContext context,
    WorkoutProvider workoutProvider,
  ) {
    final theme = Theme.of(context);
    // Use actual provider data
    final recentWorkouts = workoutProvider.recentWorkouts;
    final bool hasRecentWorkouts = recentWorkouts.isNotEmpty;

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Recent Activity',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                if (hasRecentWorkouts)
                  TextButton(
                    child: const Text('See All'),
                    onPressed: () {
                      // TODO: Navigate to workout history
                      Navigator.pushNamed(
                        context,
                        '/workout_history',
                      ); // Assuming route exists
                    },
                  ),
              ],
            ),
            const SizedBox(height: 8),
            hasRecentWorkouts
                ? ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: recentWorkouts.length, // Already limited by getter
                  itemBuilder: (context, index) {
                    final workout = recentWorkouts[index];
                    // Format data for display
                    final formattedDate =
                        workout.date.toString().split(
                          ' ',
                        )[0]; // Basic date format
                    final formattedDuration = _formatDuration(workout.duration);
                    final formattedDistance =
                        workout.distance?.toStringAsFixed(1) ?? '-.-';
                    final formattedPace = _formatPace(workout.avgPace);

                    return ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: CircleAvatar(
                        backgroundColor: theme.colorScheme.secondary
                            .withOpacity(0.2),
                        child: Icon(
                          workout.type == WorkoutType.run
                              ? Icons.directions_run
                              : workout.type == WorkoutType.walk
                              ? Icons.directions_walk
                              : workout.type == WorkoutType.cycle
                              ? Icons.directions_bike
                              : Icons.fitness_center, // Default icon
                          color: theme.colorScheme.secondary,
                        ),
                      ),
                      title: Text(
                        '${workout.type.toString().split('.').last.capitalize()} Workout', // Better title
                      ),
                      subtitle: Text(
                        '$formattedDate • $formattedDuration • $formattedDistance km',
                      ),
                      trailing: Text(
                        formattedPace,
                        style: TextStyle(
                          color: theme.colorScheme.primary,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      onTap: () {
                        // Navigate to workout details
                        Navigator.pushNamed(
                          context,
                          '/workout_summary',
                          arguments: workout,
                        );
                      },
                    );
                  },
                )
                : Center(
                  child: Column(
                    children: [
                      const SizedBox(height: 16),
                      Icon(
                        Icons.directions_run,
                        size: 48,
                        color: theme.colorScheme.primary.withOpacity(0.5),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'No workout history yet',
                        style: theme.textTheme.bodyMedium,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Your completed workouts will appear here',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.textTheme.bodySmall?.color?.withOpacity(
                            0.7,
                          ),
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 8),
                    ],
                  ),
                ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuickStatsOverview(
    BuildContext context,
    WorkoutProvider workoutProvider,
  ) {
    final theme = Theme.of(context);

    // Get stats using the provider's getters/methods
    final weeklyStats = workoutProvider.statsThisWeek;
    final monthlyStats = workoutProvider.statsThisMonth;
    final totalDistance = workoutProvider.statsTotalDistance;
    final avgPace = workoutProvider.statsAveragePace;

    // Format the stats for display
    final stats = {
      'This Week':
          '${(weeklyStats['totalDistance'] as double?)?.toStringAsFixed(1) ?? '0.0'} km',
      'This Month':
          '${(monthlyStats['totalDistance'] as double?)?.toStringAsFixed(1) ?? '0.0'} km',
      'Total Distance': '${totalDistance.toStringAsFixed(1)} km',
      'Avg. Pace': _formatPace(avgPace),
    };

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Quick Stats',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                childAspectRatio: 2, // Adjust aspect ratio if needed
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
              ),
              itemCount: stats.length,
              itemBuilder: (context, index) {
                final entry = stats.entries.elementAt(index);
                return Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.surface, // Use surface color
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: theme.dividerColor.withOpacity(0.5),
                    ), // Subtle border
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        entry.value,
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: theme.colorScheme.primary,
                        ),
                        overflow: TextOverflow.ellipsis, // Prevent overflow
                        maxLines: 1,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        entry.key,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.textTheme.bodySmall?.color?.withOpacity(
                            0.7,
                          ),
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
    );
  }
}

// Helper extension for capitalizing strings (optional)
extension StringExtension on String {
  String capitalize() {
    if (this.isEmpty) {
      return "";
    }
    return "${this[0].toUpperCase()}${this.substring(1).toLowerCase()}";
  }
}
