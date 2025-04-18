import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../controllers/training_plan_provider.dart';
import '../models/training_plan_model.dart';
import '../models/training_session_model.dart';
import '../widgets/primary_button.dart';

class TrainingPlanDetailsScreen extends StatefulWidget {
  final String planId;
  
  const TrainingPlanDetailsScreen({
    super.key,
    required this.planId,
  });

  @override
  State<TrainingPlanDetailsScreen> createState() => _TrainingPlanDetailsScreenState();
}

class _TrainingPlanDetailsScreenState extends State<TrainingPlanDetailsScreen> {
  int _selectedWeek = 0;
  
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final trainingPlanProvider = Provider.of<TrainingPlanProvider>(context);
    
    // Sample plan details - would come from the provider in a real implementation
    final plan = {
      'id': '1',
      'title': '5K Beginner Plan',
      'category': '5K',
      'duration': '8 weeks',
      'workoutsPerWeek': 3,
      'description': 'Perfect for first-time runners looking to complete their first 5K race.',
      'difficulty': 'Beginner',
      'totalWorkouts': 24,
      'restDays': 4,
      'longRuns': 8,
      'creator': 'FitStride Team',
    };
    
    // Sample weeks data
    final weeks = List.generate(8, (index) => 'Week ${index + 1}');
    
    // Sample workouts for each week
    final weeklyWorkouts = [
      // Week 1
      [
        {
          'day': 'Monday',
          'type': 'Rest',
          'description': 'Rest day',
          'duration': '0 min',
          'distance': '0 km',
          'completed': false,
        },
        {
          'day': 'Tuesday',
          'type': 'Easy Run',
          'description': 'Easy pace, focus on form',
          'duration': '20 min',
          'distance': '2-3 km',
          'completed': false,
        },
        {
          'day': 'Wednesday',
          'type': 'Rest',
          'description': 'Rest day',
          'duration': '0 min',
          'distance': '0 km',
          'completed': false,
        },
        {
          'day': 'Thursday',
          'type': 'Easy Run',
          'description': 'Easy pace, focus on breathing',
          'duration': '20 min',
          'distance': '2-3 km',
          'completed': false,
        },
        {
          'day': 'Friday',
          'type': 'Rest',
          'description': 'Rest day',
          'duration': '0 min',
          'distance': '0 km',
          'completed': false,
        },
        {
          'day': 'Saturday',
          'type': 'Long Run',
          'description': 'Slow and steady pace',
          'duration': '25 min',
          'distance': '3 km',
          'completed': false,
        },
        {
          'day': 'Sunday',
          'type': 'Rest',
          'description': 'Rest day',
          'duration': '0 min',
          'distance': '0 km',
          'completed': false,
        },
      ],
      // Week 2
      [
        {
          'day': 'Monday',
          'type': 'Rest',
          'description': 'Rest day',
          'duration': '0 min',
          'distance': '0 km',
          'completed': false,
        },
        {
          'day': 'Tuesday',
          'type': 'Easy Run',
          'description': 'Easy pace, focus on form',
          'duration': '22 min',
          'distance': '2.5-3.5 km',
          'completed': false,
        },
        {
          'day': 'Wednesday',
          'type': 'Rest',
          'description': 'Rest day',
          'duration': '0 min',
          'distance': '0 km',
          'completed': false,
        },
        {
          'day': 'Thursday',
          'type': 'Intervals',
          'description': '5 min warm-up, 5x1 min fast/1 min slow, 5 min cool-down',
          'duration': '25 min',
          'distance': '3 km',
          'completed': false,
        },
        {
          'day': 'Friday',
          'type': 'Rest',
          'description': 'Rest day',
          'duration': '0 min',
          'distance': '0 km',
          'completed': false,
        },
        {
          'day': 'Saturday',
          'type': 'Long Run',
          'description': 'Slow and steady pace',
          'duration': '30 min',
          'distance': '3.5 km',
          'completed': false,
        },
        {
          'day': 'Sunday',
          'type': 'Rest',
          'description': 'Rest day',
          'duration': '0 min',
          'distance': '0 km',
          'completed': false,
        },
      ],
      // Weeks 3-8 would follow similar pattern with progressive increases
    ];
    
    // For demo purposes, duplicate week 2 data for remaining weeks
    for (int i = 2; i < 8; i++) {
      weeklyWorkouts.add(List.from(weeklyWorkouts[1]));
    }
    
    return Scaffold(
      appBar: AppBar(
        title: Text(plan['title'] ?? 'Plan Details'),
        actions: [
          IconButton(
            icon: const Icon(Icons.share),
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Share functionality not implemented yet'),
                  duration: Duration(seconds: 2),
                ),
              );
            },
          ),
        ],
      ),
      body: Column(
        children: [
          // Plan overview
          _buildPlanOverview(context, plan),
          
          // Week selector
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Training Schedule',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                SizedBox(
                  height: 40,
                  child: ListView.builder(
                    scrollDirection: Axis.horizontal,
                    itemCount: weeks.length,
                    itemBuilder: (context, index) {
                      final isSelected = index == _selectedWeek;
                      return Padding(
                        padding: const EdgeInsets.only(right: 8.0),
                        child: ChoiceChip(
                          label: Text(weeks[index]),
                          selected: isSelected,
                          selectedColor: theme.colorScheme.primary,
                          labelStyle: TextStyle(
                            color: isSelected ? theme.colorScheme.onPrimary : theme.colorScheme.onSurface,
                            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                          ),
                          onSelected: (selected) {
                            if (selected) {
                              setState(() {
                                _selectedWeek = index;
                              });
                            }
                          },
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
          
          // Weekly workouts
          Expanded(
            child: _selectedWeek < weeklyWorkouts.length
                ? ListView.builder(
                    padding: const EdgeInsets.all(16.0),
                    itemCount: weeklyWorkouts[_selectedWeek].length,
                    itemBuilder: (context, index) {
                      final workout = weeklyWorkouts[_selectedWeek][index];
                      return _buildWorkoutCard(context, workout);
                    },
                  )
                : Center(
                    child: Text(
                      'No workouts available for this week',
                      style: theme.textTheme.titleMedium,
                    ),
                  ),
          ),
        ],
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: PrimaryButton(
            text: 'START THIS PLAN',
            onPressed: () {
              _showStartPlanDialog(context, plan);
            },
          ),
        ),
      ),
    );
  }
  
  Widget _buildPlanOverview(BuildContext context, Map<String, dynamic> plan) {
    final theme = Theme.of(context);
    
    // Determine difficulty color
    Color difficultyColor;
    switch (plan['difficulty']) {
      case 'Beginner':
        difficultyColor = Colors.green;
        break;
      case 'Intermediate':
        difficultyColor = Colors.orange;
        break;
      case 'Advanced':
        difficultyColor = Colors.red;
        break;
      default:
        difficultyColor = theme.colorScheme.primary;
    }
    
    return Container(
      padding: const EdgeInsets.all(16.0),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Title and difficulty
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  plan['title'] ?? '',
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
                decoration: BoxDecoration(
                  color: difficultyColor.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  plan['difficulty'] ?? '',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: difficultyColor,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          
          // Description
          Text(
            plan['description'] ?? '',
            style: theme.textTheme.bodyMedium,
          ),
          const SizedBox(height: 16),
          
          // Plan stats
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildStatItem(context, '${plan['duration']}', 'Duration'),
              _buildStatItem(context, '${plan['totalWorkouts']}', 'Workouts'),
              _buildStatItem(context, '${plan['restDays']} per week', 'Rest Days'),
              _buildStatItem(context, '${plan['longRuns']}', 'Long Runs'),
            ],
          ),
          const SizedBox(height: 8),
          
          // Creator info
          Row(
            children: [
              Icon(
                Icons.person,
                size: 16,
                color: theme.colorScheme.onSurface.withOpacity(0.6),
              ),
              const SizedBox(width: 4),
              Text(
                'Created by ${plan['creator']}',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurface.withOpacity(0.6),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
  
  Widget _buildStatItem(BuildContext context, String value, String label) {
    final theme = Theme.of(context);
    
    return Column(
      children: [
        Text(
          value,
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
            color: theme.colorScheme.primary,
          ),
        ),
        Text(
          label,
          style: theme.textTheme.bodySmall?.copyWith(
            color: theme.colorScheme.onSurface.withOpacity(0.7),
          ),
        ),
      ],
    );
  }
  
  Widget _buildWorkoutCard(BuildContext context, Map<String, dynamic> workout) {
    final theme = Theme.of(context);
    
    // Determine workout type color
    Color typeColor;
    IconData typeIcon;
    
    switch (workout['type']) {
      case 'Easy Run':
        typeColor = Colors.green;
        typeIcon = Icons.directions_run;
        break;
      case 'Long Run':
        typeColor = Colors.orange;
        typeIcon = Icons.trending_up;
        break;
      case 'Intervals':
        typeColor = Colors.red;
        typeIcon = Icons.timer;
        break;
      case 'Rest':
        typeColor = Colors.blue;
        typeIcon = Icons.hotel;
        break;
      default:
        typeColor = theme.colorScheme.primary;
        typeIcon = Icons.fitness_center;
    }
    
    return Card(
      elevation: 1,
      margin: const EdgeInsets.only(bottom: 12.0),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: workout['completed'] == true
              ? Colors.green.withOpacity(0.5)
              : Colors.transparent,
          width: workout['completed'] == true ? 1 : 0,
        ),
      ),
      child: InkWell(
        onTap: () {
          if (workout['type'] != 'Rest') {
            _showWorkoutDetailsDialog(context, workout);
          }
        },
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Day indicator
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: theme.colorScheme.surface,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: theme.dividerColor),
                ),
                child: Center(
                  child: Text(
                    workout['day']?.substring(0, 3) ?? '',
                    style: theme.textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 16),
              
              // Workout details
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            Icon(
                              typeIcon,
                              size: 16,
                              color: typeColor,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              workout['type'] ?? '',
                              style: theme.textTheme.titleSmall?.copyWith(
                                color: typeColor,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                        if (workout['completed'] == true)
                          Icon(
                            Icons.check_circle,
                            color: Colors.green,
                            size: 20,
                          ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      workout['description'] ?? '',
                      style: theme.textTheme.bodyMedium,
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Icon(
                          Icons.timer,
                          size: 16,
                          color: theme.colorScheme.onSurface.withOpacity(0.6),
                        ),
                        const SizedBox(width: 4),
                        Text(
                          workout['duration'] ?? '',
                          style: theme.textTheme.bodySmall,
                        ),
                        const SizedBox(width: 16),
                        Icon(
                          Icons.straighten,
                          size: 16,
                          color: theme.colorScheme.onSurface.withOpacity(0.6),
                        ),
                        const SizedBox(width: 4),
                        Text(
                          workout['distance'] ?? '',
                          style: theme.textTheme.bodySmall,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
  
  void _showWorkoutDetailsDialog(BuildContext context, Map<String, dynamic> workout) {
    final theme = Theme.of(context);
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(workout['type'] ?? 'Workout Details'),
        content: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              workout['description'] ?? '',
              style: theme.textTheme.bodyMedium,
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Icon(
                  Icons.timer,
                  size: 16,
                  color: theme.colorScheme.primary,
                ),
                const SizedBox(width: 8),
                Text(
                  'Duration: ${workout['duration']}',
                  style: theme.textTheme.bodyMedium,
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Icon(
                  Icons.straighten,
                  size: 16,
                  color: theme.colorScheme.primary,
                ),
                const SizedBox(width: 8),
                Text(
                  'Distance: ${workout['distance']}',
                  style: theme.textTheme.bodyMedium,
                ),
              ],
            ),
            const SizedBox(height: 16),
            const Text(
              'Tips:',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            const Text('• Warm up properly before starting'),
            const Text('• Stay hydrated throughout'),
            const Text('• Focus on maintaining good form'),
            const Text('• Cool down with light stretching after'),
          ],
        ),
        actions: [
          TextButton(
            child: const Text('CLOSE'),
            onPressed: () => Navigator.of(context).pop(),
          ),
          if (workout['type'] != 'Rest')
            TextButton(
              child: const Text('START WORKOUT'),
              onPressed: () {
                Navigator.of(context).pop();
                // Navigate to workout preparation with this workout
                // Navigator.pushNamed(context, '/workout_preparation', arguments: workout);
              },
            ),
        ],
      ),
    );
  }
  
  void _showStartPlanDialog(BuildContext context, Map<String, dynamic> plan) {
    final theme = Theme.of(context);
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Start ${plan['title']}?'),
        content: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'You\'re about to start a ${plan['duration']} training plan with ${plan['workoutsPerWeek']} workouts per week.',
            ),
            const SizedBox(height: 16),
            const Text(
              'This will:',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            const Text('• Add scheduled workouts to your calendar'),
            const Text('• Track your progress throughout the plan'),
            const Text('• Provide guidance for each workout'),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: theme.colorScheme.surface,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: theme.dividerColor),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.info_outline,
                    color: theme.colorScheme.primary,
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'You can modify or cancel the plan at any time.',
                      style: theme.textTheme.bodySmall,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            child: const Text('CANCEL'),
            onPressed: () => Navigator.of(context).pop(),
          ),
          TextButton(
            child: const Text('START PLAN'),
            onPressed: () {
              // Start training plan
              final trainingPlanProvider = Provider.of<TrainingPlanProvider>(context, listen: false);
              // trainingPlanProvider.startTrainingPlan(plan['id']);
              
              // Show confirmation and navigate back
              Navigator.of(context).pop();
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('${plan['title']} started successfully!'),
                  duration: const Duration(seconds: 2),
                ),
              );
              
              // Navigate to home or training plan detail
              Navigator.popUntil(context, (route) => route.isFirst);
            },
          ),
        ],
      ),
    );
  }
}
