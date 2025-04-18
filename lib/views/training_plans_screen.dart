import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../controllers/training_plan_provider.dart';
import '../models/training_plan_model.dart';
import '../widgets/primary_button.dart';

class TrainingPlansScreen extends StatefulWidget {
  const TrainingPlansScreen({super.key});

  @override
  State<TrainingPlansScreen> createState() => _TrainingPlansScreenState();
}

class _TrainingPlansScreenState extends State<TrainingPlansScreen> {
  String _selectedCategory = 'All';
  final List<String> _categories = ['All', '5K', '10K', 'Half Marathon', 'Marathon'];
  
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final trainingPlanProvider = Provider.of<TrainingPlanProvider>(context);
    
    // Sample training plans - would come from the provider in a real implementation
    final trainingPlans = [
      {
        'id': '1',
        'title': '5K Beginner Plan',
        'category': '5K',
        'duration': '8 weeks',
        'workoutsPerWeek': 3,
        'description': 'Perfect for first-time runners looking to complete their first 5K race.',
        'difficulty': 'Beginner',
      },
      {
        'id': '2',
        'title': '5K Intermediate Plan',
        'category': '5K',
        'duration': '8 weeks',
        'workoutsPerWeek': 4,
        'description': 'For runners who have completed a 5K and want to improve their time.',
        'difficulty': 'Intermediate',
      },
      {
        'id': '3',
        'title': '10K Beginner Plan',
        'category': '10K',
        'duration': '10 weeks',
        'workoutsPerWeek': 3,
        'description': 'Designed to help you build endurance and complete your first 10K race.',
        'difficulty': 'Beginner',
      },
      {
        'id': '4',
        'title': '10K Intermediate Plan',
        'category': '10K',
        'duration': '10 weeks',
        'workoutsPerWeek': 4,
        'description': 'For runners who have completed a 10K and want to improve their performance.',
        'difficulty': 'Intermediate',
      },
      {
        'id': '5',
        'title': 'Half Marathon Beginner Plan',
        'category': 'Half Marathon',
        'duration': '12 weeks',
        'workoutsPerWeek': 4,
        'description': 'Gradually builds your endurance to complete your first half marathon.',
        'difficulty': 'Beginner',
      },
      {
        'id': '6',
        'title': 'Marathon Beginner Plan',
        'category': 'Marathon',
        'duration': '16 weeks',
        'workoutsPerWeek': 4,
        'description': 'Comprehensive plan to prepare you for your first marathon.',
        'difficulty': 'Intermediate',
      },
    ];
    
    // Filter plans based on selected category
    final filteredPlans = _selectedCategory == 'All'
        ? trainingPlans
        : trainingPlans.where((plan) => plan['category'] == _selectedCategory).toList();
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('Training Plans'),
        actions: [
          IconButton(
            icon: const Icon(Icons.info_outline),
            onPressed: () {
              _showInfoDialog(context);
            },
          ),
        ],
      ),
      body: Column(
        children: [
          // Category filter
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: _categories.map((category) {
                  final isSelected = category == _selectedCategory;
                  return Padding(
                    padding: const EdgeInsets.only(right: 8.0),
                    child: ChoiceChip(
                      label: Text(category),
                      selected: isSelected,
                      selectedColor: theme.colorScheme.primary,
                      labelStyle: TextStyle(
                        color: isSelected ? theme.colorScheme.onPrimary : theme.colorScheme.onSurface,
                        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                      ),
                      onSelected: (selected) {
                        if (selected) {
                          setState(() {
                            _selectedCategory = category;
                          });
                        }
                      },
                    ),
                  );
                }).toList(),
              ),
            ),
          ),
          
          // Plans list
          Expanded(
            child: filteredPlans.isEmpty
                ? Center(
                    child: Text(
                      'No training plans available for $_selectedCategory',
                      style: theme.textTheme.titleMedium,
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.all(16.0),
                    itemCount: filteredPlans.length,
                    itemBuilder: (context, index) {
                      final plan = filteredPlans[index];
                      return _buildPlanCard(context, plan);
                    },
                  ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildPlanCard(BuildContext context, Map<String, String> plan) {
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
    
    return Card(
      elevation: 2,
      margin: const EdgeInsets.only(bottom: 16.0),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header with category and difficulty
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
            decoration: BoxDecoration(
              color: theme.colorScheme.primary.withOpacity(0.1),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(12),
                topRight: Radius.circular(12),
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  plan['category'] ?? '',
                  style: theme.textTheme.titleSmall?.copyWith(
                    color: theme.colorScheme.primary,
                    fontWeight: FontWeight.bold,
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
          ),
          
          // Plan content
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  plan['title'] ?? '',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  plan['description'] ?? '',
                  style: theme.textTheme.bodyMedium,
                ),
                const SizedBox(height: 16),
                
                // Plan details
                Row(
                  children: [
                    _buildDetailItem(
                      context,
                      Icons.calendar_today,
                      'Duration',
                      plan['duration'] ?? '',
                    ),
                    const SizedBox(width: 24),
                    _buildDetailItem(
                      context,
                      Icons.fitness_center,
                      'Workouts',
                      '${plan['workoutsPerWeek']} per week',
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                
                // Action buttons
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        child: const Text('VIEW DETAILS'),
                        onPressed: () {
                          // Navigate to plan details
                          // Navigator.pushNamed(context, '/training_plan_details', arguments: plan['id']);
                        },
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: PrimaryButton(
                        text: 'START PLAN',
                        onPressed: () {
                          _showStartPlanDialog(context, plan);
                        },
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildDetailItem(BuildContext context, IconData icon, String label, String value) {
    final theme = Theme.of(context);
    
    return Row(
      children: [
        Icon(
          icon,
          size: 16,
          color: theme.colorScheme.primary,
        ),
        const SizedBox(width: 4),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurface.withOpacity(0.7),
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
      ],
    );
  }
  
  void _showInfoDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('About Training Plans'),
        content: const SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Training plans help you prepare for specific race distances with structured workouts.',
              ),
              SizedBox(height: 16),
              Text(
                'Each plan includes:',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 8),
              Text('• Progressive workouts that build your endurance'),
              Text('• Rest days for recovery'),
              Text('• Mix of easy runs, tempo runs, and long runs'),
              Text('• Weekly schedule you can follow'),
              SizedBox(height: 16),
              Text(
                'Choose a plan that matches your current fitness level and goals. Beginner plans are perfect if you\'re new to running or the distance.',
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            child: const Text('CLOSE'),
            onPressed: () => Navigator.of(context).pop(),
          ),
        ],
      ),
    );
  }
  
  void _showStartPlanDialog(BuildContext context, Map<String, String> plan) {
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
              // Navigator.popUntil(context, (route) => route.isFirst);
            },
          ),
        ],
      ),
    );
  }
}
