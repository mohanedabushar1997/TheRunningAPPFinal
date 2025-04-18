import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../controllers/user_provider.dart';
import '../controllers/workout_provider.dart';
import '../controllers/training_plan_provider.dart';
import '../widgets/primary_button.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final userProvider = Provider.of<UserProvider>(context);
    final workoutProvider = Provider.of<WorkoutProvider>(context);
    final trainingPlanProvider = Provider.of<TrainingPlanProvider>(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('FitStride'),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: () {
              // Navigate to settings screen
              // Navigator.pushNamed(context, '/settings');
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
        type: BottomNavigationBar.fixed,
        items: const [
          BottomNavigationBar.Item(
            icon: Icon(Icons.home),
            label: 'Home',
          ),
          BottomNavigationBar.Item(
            icon: Icon(Icons.directions_run),
            label: 'Workouts',
          ),
          BottomNavigationBar.Item(
            icon: Icon(Icons.calendar_today),
            label: 'Plans',
          ),
          BottomNavigationBar.Item(
            icon: Icon(Icons.bar_chart),
            label: 'Stats',
          ),
          BottomNavigationBar.Item(
            icon: Icon(Icons.person),
            label: 'Profile',
          ),
        ],
        onTap: (index) {
          // Handle navigation to different tabs
          // This would typically use a TabController or Navigator
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
                  Icons.person,
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
                side: BorderSide(color: theme.colorScheme.onPrimary.withOpacity(0.5)),
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
      height: 100,
      child: PrimaryButton(
        text: 'START QUICK WORKOUT',
        icon: Icons.play_circle_fill,
        onPressed: () {
          // Navigate to Workout Preparation Screen
          // Navigator.pushNamed(context, '/workout_preparation');
          print('Start Quick Workout tapped');
        },
      ),
    );
  }
  
  Widget _buildTrainingPlanProgress(BuildContext context, TrainingPlanProvider planProvider) {
    final theme = Theme.of(context);
    // This would normally come from the TrainingPlanProvider
    final bool hasActivePlan = false;
    final String planName = "5K Beginner Plan";
    final int currentDay = 8;
    final int totalDays = 28;
    final double progress = currentDay / totalDays;
    
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
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
                      // Navigate to training plan details
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
                        planName,
                        style: theme.textTheme.titleSmall,
                      ),
                      const SizedBox(height: 8),
                      LinearProgressIndicator(
                        value: progress,
                        backgroundColor: theme.colorScheme.primary.withOpacity(0.2),
                        valueColor: AlwaysStoppedAnimation<Color>(
                          theme.colorScheme.primary,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Day $currentDay of $totalDays',
                        style: theme.textTheme.bodySmall,
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Icon(
                            Icons.calendar_today,
                            size: 16,
                            color: theme.colorScheme.secondary,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            'Next workout: Today - 30 min Easy Run',
                            style: theme.textTheme.bodySmall,
                          ),
                        ],
                      ),
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
  
  Widget _buildRecentActivitySummary(BuildContext context, WorkoutProvider workoutProvider) {
    final theme = Theme.of(context);
    // This would normally come from the WorkoutProvider
    final bool hasRecentWorkouts = false;
    
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
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
                      // Navigate to workout history
                    },
                  ),
              ],
            ),
            const SizedBox(height: 8),
            hasRecentWorkouts
                ? ListView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: 3, // Show last 3 workouts
                    itemBuilder: (context, index) {
                      return ListTile(
                        contentPadding: EdgeInsets.zero,
                        leading: CircleAvatar(
                          backgroundColor: theme.colorScheme.secondary.withOpacity(0.2),
                          child: Icon(
                            Icons.directions_run,
                            color: theme.colorScheme.secondary,
                          ),
                        ),
                        title: Text('5K Morning Run'),
                        subtitle: Text('Yesterday • 28:45 • 5.2 km'),
                        trailing: Text(
                          '5:32/km',
                          style: TextStyle(
                            color: theme.colorScheme.primary,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        onTap: () {
                          // Navigate to workout details
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
                            color: theme.textTheme.bodySmall?.color?.withOpacity(0.7),
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
  
  Widget _buildQuickStatsOverview(BuildContext context, WorkoutProvider workoutProvider) {
    final theme = Theme.of(context);
    
    // This would normally come from the WorkoutProvider
    final stats = {
      'This Week': '12.4 km',
      'This Month': '58.7 km',
      'Total Distance': '152.3 km',
      'Avg. Pace': '5:42/km',
    };
    
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
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
                childAspectRatio: 2,
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
              ),
              itemCount: stats.length,
              itemBuilder: (context, index) {
                final entry = stats.entries.elementAt(index);
                return Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.surface,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: theme.dividerColor,
                    ),
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
                      ),
                      const SizedBox(height: 4),
                      Text(
                        entry.key,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.textTheme.bodySmall?.color?.withOpacity(0.7),
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
