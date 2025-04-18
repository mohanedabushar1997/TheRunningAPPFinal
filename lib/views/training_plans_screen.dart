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
  // Categories based on TrainingPlanModel goalType or level
  final List<String> _categories = [
    'All',
    'Beginner',
    'Intermediate',
    'Advanced',
    '5K',
    '10K',
    'Half Marathon',
    'Marathon',
  ];

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    // Listen for changes in the provider
    final trainingPlanProvider = Provider.of<TrainingPlanProvider>(context);
    final availablePlans = trainingPlanProvider.availablePlans;
    final currentPlanId = trainingPlanProvider.currentPlan?.id;

    // Filter plans based on selected category (using level or goalType)
    final filteredPlans =
        _selectedCategory == 'All'
            ? availablePlans
            : availablePlans.where((plan) {
              // Allow filtering by level (Beginner, Intermediate, Advanced) or goalType (5K, 10K, etc.)
              final levelString =
                  plan.level.toString().split('.').last.capitalize();
              return levelString == _selectedCategory ||
                  plan.goalType == _selectedCategory;
            }).toList();

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
                children:
                    _categories.map((category) {
                      final isSelected = category == _selectedCategory;
                      return Padding(
                        padding: const EdgeInsets.only(right: 8.0),
                        child: ChoiceChip(
                          label: Text(category),
                          selected: isSelected,
                          selectedColor: theme.colorScheme.primary,
                          labelStyle: TextStyle(
                            color:
                                isSelected
                                    ? theme.colorScheme.onPrimary
                                    : theme.colorScheme.onSurface,
                            fontWeight:
                                isSelected
                                    ? FontWeight.bold
                                    : FontWeight.normal,
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
            child:
                trainingPlanProvider.isLoading
                    ? const Center(child: CircularProgressIndicator())
                    : filteredPlans.isEmpty
                    ? Center(
                      child: Text(
                        'No training plans available for $_selectedCategory',
                        style: theme.textTheme.titleMedium,
                        textAlign: TextAlign.center,
                      ),
                    )
                    : ListView.builder(
                      padding: const EdgeInsets.only(
                        left: 16.0,
                        right: 16.0,
                        bottom: 16.0,
                      ), // Adjust padding
                      itemCount: filteredPlans.length,
                      itemBuilder: (context, index) {
                        final plan = filteredPlans[index];
                        final bool isCurrentPlan = plan.id == currentPlanId;
                        return _buildPlanCard(
                          context,
                          plan,
                          isCurrentPlan,
                          trainingPlanProvider,
                        );
                      },
                    ),
          ),
        ],
      ),
    );
  }

  Widget _buildPlanCard(
    BuildContext context,
    TrainingPlanModel plan,
    bool isCurrentPlan,
    TrainingPlanProvider provider,
  ) {
    final theme = Theme.of(context);

    // Determine difficulty color
    Color difficultyColor;
    String difficultyText = plan.level.toString().split('.').last.capitalize();
    switch (plan.level) {
      case TrainingPlanLevel.beginner:
        difficultyColor = Colors.green;
        break;
      case TrainingPlanLevel.intermediate:
        difficultyColor = Colors.orange;
        break;
      case TrainingPlanLevel.advanced:
        difficultyColor = Colors.red;
        break;
      default:
        difficultyColor = theme.colorScheme.primary;
    }

    return Card(
      elevation: isCurrentPlan ? 4 : 2, // Highlight current plan
      margin: const EdgeInsets.only(bottom: 16.0),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side:
            isCurrentPlan
                ? BorderSide(
                  color: theme.colorScheme.primary,
                  width: 2,
                ) // Border for current plan
                : BorderSide.none,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header with category and difficulty
          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: 16.0,
              vertical: 8.0,
            ),
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
                  plan.goalType ?? 'General', // Use goalType or fallback
                  style: theme.textTheme.titleSmall?.copyWith(
                    color: theme.colorScheme.primary,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8.0,
                    vertical: 4.0,
                  ),
                  decoration: BoxDecoration(
                    color: difficultyColor.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    difficultyText,
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
                  plan.name,
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  plan.description ?? 'No description available.',
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
                      '${plan.durationWeeks} weeks',
                    ),
                    const SizedBox(width: 24),
                    _buildDetailItem(
                      context,
                      Icons.fitness_center,
                      'Workouts',
                      // Calculate average workouts per week (approximate)
                      '${(plan.sessions.length / plan.durationWeeks).round()} per week',
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
                          Navigator.pushNamed(
                            context,
                            '/training_plan_details',
                            arguments: plan.id.toString(), // Pass ID
                          );
                        },
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child:
                          isCurrentPlan
                              ? ElevatedButton(
                                // Show different button if active
                                style: ElevatedButton.styleFrom(
                                  backgroundColor:
                                      Colors.grey, // Indicate inactive state
                                ),
                                onPressed: () {
                                  _showDeactivatePlanDialog(
                                    context,
                                    plan,
                                    provider,
                                  );
                                },
                                child: const Text('ACTIVE PLAN'),
                              )
                              : PrimaryButton(
                                text: 'START PLAN',
                                onPressed:
                                    plan.id == null
                                        ? null
                                        : () {
                                          // Disable if ID is null
                                          _showStartPlanDialog(
                                            context,
                                            plan,
                                            provider,
                                          );
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

  Widget _buildDetailItem(
    BuildContext context,
    IconData icon,
    String label,
    String value,
  ) {
    final theme = Theme.of(context);

    return Row(
      children: [
        Icon(icon, size: 16, color: theme.colorScheme.primary),
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
      builder:
          (context) => AlertDialog(
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

  void _showStartPlanDialog(
    BuildContext context,
    TrainingPlanModel plan,
    TrainingPlanProvider provider,
  ) {
    if (plan.id == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Error: Cannot start plan without an ID.'),
        ),
      );
      return;
    }
    final theme = Theme.of(context);

    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: Text('Start ${plan.name}?'),
            content: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'You\'re about to start a ${plan.durationWeeks} week training plan.',
                ),
                const SizedBox(height: 16),
                const Text(
                  'This will:',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                const Text('• Activate this plan and track your progress'),
                const Text('• Deactivate any other currently active plan'),
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
                          'You can switch or stop the plan at any time.',
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
                onPressed: () async {
                  // Make async
                  Navigator.of(context).pop(); // Close dialog first
                  await provider.selectPlan(plan.id!); // Call provider method

                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('${plan.name} started successfully!'),
                      duration: const Duration(seconds: 2),
                    ),
                  );
                  // Optionally navigate somewhere else, e.g., back or to plan details
                },
              ),
            ],
          ),
    );
  }

  void _showDeactivatePlanDialog(
    BuildContext context,
    TrainingPlanModel plan,
    TrainingPlanProvider provider,
  ) {
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: Text('Stop ${plan.name}?'),
            content: const Text(
              'Do you want to stop tracking this training plan? Your progress will be saved, but the plan will no longer be active.',
            ),
            actions: [
              TextButton(
                child: const Text('CANCEL'),
                onPressed: () => Navigator.of(context).pop(),
              ),
              TextButton(
                child: const Text('STOP PLAN'),
                onPressed: () async {
                  Navigator.of(context).pop(); // Close dialog
                  await provider
                      .deactivateCurrentPlan(); // Call provider method
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('${plan.name} stopped.'),
                      duration: const Duration(seconds: 2),
                    ),
                  );
                },
              ),
            ],
          ),
    );
  }
}

// Helper extension for capitalizing strings (optional but used above)
extension StringExtension on String {
  String capitalize() {
    if (this.isEmpty) {
      return "";
    }
    return "${this[0].toUpperCase()}${this.substring(1).toLowerCase()}";
  }
}
