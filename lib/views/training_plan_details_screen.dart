import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../controllers/training_plan_provider.dart';
import '../models/training_plan_model.dart';
import '../models/training_session_model.dart';
import '../widgets/primary_button.dart';
import 'package:intl/intl.dart'; // For date formatting

class TrainingPlanDetailsScreen extends StatefulWidget {
  final String planId; // Assuming ID is passed as String, parse if needed

  const TrainingPlanDetailsScreen({super.key, required this.planId});

  @override
  State<TrainingPlanDetailsScreen> createState() =>
      _TrainingPlanDetailsScreenState();
}

class _TrainingPlanDetailsScreenState extends State<TrainingPlanDetailsScreen> {
  int _selectedWeek = 0;
  TrainingPlanModel? _plan; // State variable to hold the fetched plan
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    // Use addPostFrameCallback to fetch data after the first frame
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _fetchPlanDetails();
    });
  }

  Future<void> _fetchPlanDetails() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });
    try {
      final provider = Provider.of<TrainingPlanProvider>(
        context,
        listen: false,
      );
      final planIdInt = int.tryParse(widget.planId);
      if (planIdInt == null) {
        throw Exception("Invalid Plan ID format");
      }

      // Find the plan in the provider's list using a loop
      TrainingPlanModel? foundPlan;
      for (var p in provider.availablePlans) {
        if (p.id == planIdInt) {
          foundPlan = p;
          break;
        }
      }

      if (foundPlan == null) {
        // Try refreshing the provider's list in case it wasn't loaded yet
        await provider.refreshPlans(); // Assuming provider has a refresh method
        for (var p in provider.availablePlans) {
          if (p.id == planIdInt) {
            foundPlan = p;
            break;
          }
        }
        // If still not found after refresh, throw error
        if (foundPlan == null) {
          throw Exception("Training plan not found (ID: $planIdInt).");
        }
      }

      setState(() {
        _plan = foundPlan;
        _isLoading = false;
      });
    } catch (e) {
      print("Error fetching plan details: $e");
      setState(() {
        _isLoading = false;
        _error = "Failed to load plan details: $e";
      });
    }
  }

  // Helper to format duration
  String _formatDuration(Duration? duration) {
    if (duration == null) return '-';
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    final minutes = twoDigits(duration.inMinutes.remainder(60));
    final seconds = twoDigits(duration.inSeconds.remainder(60));
    if (duration.inHours > 0) {
      final hours = twoDigits(duration.inHours);
      return "$hours:$minutes:$seconds";
    }
    return "$minutes:$seconds";
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    // Listen for provider updates (e.g., if plan is activated/deactivated)
    final trainingPlanProvider = Provider.of<TrainingPlanProvider>(context);

    if (_isLoading) {
      return Scaffold(
        appBar: AppBar(title: const Text('Loading Plan...')),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    if (_error != null || _plan == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Error')),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Text(
              _error ?? 'Could not load training plan.',
              textAlign: TextAlign.center,
            ),
          ),
        ),
      );
    }

    // Plan loaded successfully
    final plan = _plan!;
    // Check current plan status directly from provider in case it changed
    final bool isCurrentPlan = trainingPlanProvider.currentPlan?.id == plan.id;
    final weeks = List.generate(
      plan.durationWeeks,
      (index) => 'Week ${index + 1}',
    );
    final weeklyWorkouts = List.generate(plan.durationWeeks, (weekIndex) {
      return plan.getSessionsForWeek(weekIndex + 1);
    });

    // Ensure selected week is valid
    if (_selectedWeek >= plan.durationWeeks) {
      _selectedWeek = 0;
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(plan.name),
        actions: [
          IconButton(
            icon: const Icon(Icons.share),
            tooltip: 'Share Plan (Not Implemented)',
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
            padding: const EdgeInsets.symmetric(
              horizontal: 16.0,
              vertical: 8.0,
            ),
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
            child:
                _selectedWeek < weeklyWorkouts.length &&
                        weeklyWorkouts[_selectedWeek].isNotEmpty
                    ? ListView.builder(
                      padding: const EdgeInsets.only(
                        left: 16.0,
                        right: 16.0,
                        bottom: 16.0,
                      ),
                      itemCount: weeklyWorkouts[_selectedWeek].length,
                      itemBuilder: (context, index) {
                        final session = weeklyWorkouts[_selectedWeek][index];
                        // Get completion status from provider, checking for null session ID
                        final isCompleted =
                            session.id != null
                                ? trainingPlanProvider
                                        .sessionCompletionStatus[session.id] ??
                                    false
                                : false;
                        return _buildWorkoutCard(
                          context,
                          session,
                          isCompleted,
                          trainingPlanProvider,
                        );
                      },
                    )
                    : Center(
                      child: Text(
                        'No workouts scheduled for this week',
                        style: theme.textTheme.titleMedium,
                      ),
                    ),
          ),
        ],
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child:
              isCurrentPlan
                  ? ElevatedButton.icon(
                    // Show different button if active
                    icon: const Icon(Icons.stop_circle_outlined),
                    label: const Text('STOP THIS PLAN'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.grey, // Indicate inactive state
                    ),
                    onPressed: () {
                      _showDeactivatePlanDialog(
                        context,
                        plan,
                        trainingPlanProvider,
                      );
                    },
                  )
                  : PrimaryButton(
                    text: 'START THIS PLAN',
                    onPressed: () {
                      _showStartPlanDialog(context, plan, trainingPlanProvider);
                    },
                  ),
        ),
      ),
    );
  }

  Widget _buildPlanOverview(BuildContext context, TrainingPlanModel plan) {
    final theme = Theme.of(context);

    // Determine difficulty color
    Color difficultyColor;
    String difficultyText = plan.level.toString().split('.').last;
    if (difficultyText.isNotEmpty) {
      difficultyText =
          difficultyText[0].toUpperCase() + difficultyText.substring(1);
    }
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

    return Container(
      padding: const EdgeInsets.all(16.0),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface, // Use surface color
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
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Text(
                  plan.name,
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const SizedBox(width: 8), // Add spacing
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
          const SizedBox(height: 8),

          // Description
          Text(
            plan.description ?? 'No description available.',
            style: theme.textTheme.bodyMedium,
          ),
          const SizedBox(height: 16),

          // Plan stats
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildStatItem(
                context,
                '${plan.durationWeeks} weeks',
                'Duration',
              ),
              _buildStatItem(context, '${plan.sessions.length}', 'Workouts'),
              // Calculate average workouts per week
              _buildStatItem(
                context,
                plan.durationWeeks > 0
                    ? '${(plan.sessions.length / plan.durationWeeks).round()} / week'
                    : '- / week',
                'Avg Workouts',
              ),
              // Could add more stats like total distance if available
            ],
          ),
          // Removed Creator info as it's not in the model
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

  Widget _buildWorkoutCard(
    BuildContext context,
    TrainingSessionModel session,
    bool isCompleted,
    TrainingPlanProvider provider,
  ) {
    final theme = Theme.of(context);

    // Determine workout type color and icon based on description or type
    // This is a basic example; might need more sophisticated logic
    Color typeColor = theme.colorScheme.primary;
    IconData typeIcon = Icons.fitness_center;
    String sessionType = "Workout";

    if (session.description?.toLowerCase().contains('easy run') ?? false) {
      typeColor = Colors.green;
      typeIcon = Icons.directions_run;
      sessionType = "Easy Run";
    } else if (session.description?.toLowerCase().contains('long run') ??
        false) {
      typeColor = Colors.orange;
      typeIcon = Icons.trending_up;
      sessionType = "Long Run";
    } else if (session.description?.toLowerCase().contains('interval') ??
        false) {
      typeColor = Colors.red;
      typeIcon = Icons.timer;
      sessionType = "Intervals";
    } else if (session.description?.toLowerCase().contains('tempo') ?? false) {
      typeColor = Colors.purple;
      typeIcon = Icons.speed;
      sessionType = "Tempo Run";
    } else if (session.description?.toLowerCase().contains('rest') ?? false) {
      typeColor = Colors.blue;
      typeIcon = Icons.hotel;
      sessionType = "Rest";
    } else if (session.description?.toLowerCase().contains('walk') ?? false) {
      typeColor = Colors.lightBlue;
      typeIcon = Icons.directions_walk;
      sessionType = "Walk";
    }

    bool isRestDay = sessionType == "Rest";

    return Card(
      elevation: 1,
      margin: const EdgeInsets.only(bottom: 12.0),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color:
              isCompleted ? Colors.green.withOpacity(0.7) : Colors.transparent,
          width: isCompleted ? 1.5 : 0,
        ),
      ),
      child: InkWell(
        onTap:
            isRestDay
                ? null // Disable tap for rest days
                : () {
                  // Navigate to ActiveWorkoutScreen, passing the session
                  Navigator.pushNamed(
                    context,
                    '/active_workout',
                    arguments: session,
                  );
                },
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Row(
            crossAxisAlignment:
                CrossAxisAlignment.center, // Align center vertically
            children: [
              // Day indicator (using day number)
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
                    'D${session.dayNumber}', // Display Day Number
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
                            Icon(typeIcon, size: 16, color: typeColor),
                            const SizedBox(width: 4),
                            Text(
                              sessionType,
                              style: theme.textTheme.titleSmall?.copyWith(
                                color: typeColor,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                        // Completion Checkbox
                        if (!isRestDay &&
                            session.id !=
                                null) // Don't show checkbox for rest days or if ID is null
                          Checkbox(
                            value: isCompleted,
                            onChanged: (bool? value) {
                              if (value == true) {
                                provider.completeSession(session.id!);
                              } else {
                                provider.uncompleteSession(session.id!);
                              }
                            },
                            activeColor: Colors.green,
                            visualDensity:
                                VisualDensity.compact, // Make checkbox smaller
                            materialTapTargetSize:
                                MaterialTapTargetSize.shrinkWrap,
                          ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      session.description ?? 'No description',
                      style: theme.textTheme.bodyMedium,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    if (session.targetDuration != null ||
                        session.targetDistance != null)
                      const SizedBox(height: 4),
                    if (session.targetDuration != null)
                      Text(
                        'Target: ${_formatDuration(session.targetDuration)}',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.hintColor,
                        ),
                      ),
                    if (session.targetDistance != null)
                      Text(
                        'Target: ${session.targetDistance} km',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.hintColor,
                        ),
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

  void _showWorkoutDetailsDialog(
    BuildContext context,
    TrainingSessionModel session,
  ) {
    final theme = Theme.of(context);
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: Text('Workout Details (Day ${session.dayNumber})'),
            content: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    session.description ?? 'No description available.',
                    style: theme.textTheme.bodyLarge,
                  ),
                  const SizedBox(height: 16),
                  if (session.targetDuration != null)
                    Text(
                      'Target Duration: ${_formatDuration(session.targetDuration)}',
                    ),
                  if (session.targetDistance != null)
                    Text('Target Distance: ${session.targetDistance} km'),
                  if (session.intervals != null)
                    Text('Intervals: ${session.intervals}'),
                  // Add more details if needed
                ],
              ),
            ),
            actions: [
              TextButton(
                child: const Text('CLOSE'),
                onPressed: () => Navigator.of(context).pop(),
              ),
              // Optionally add a "Start Workout" button here
              // TextButton(
              //   child: const Text('START WORKOUT'),
              //   onPressed: () {
              //     Navigator.of(context).pop();
              //     // TODO: Navigate to active workout screen with session details
              //   },
              // ),
            ],
          ),
    );
  }

  // Re-use dialogs from training_plans_screen or adapt them
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

// Removed duplicate StringExtension and incorrect TrainingPlanProviderExtension
