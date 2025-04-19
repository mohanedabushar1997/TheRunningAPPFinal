import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:fl_chart/fl_chart.dart'; // Import fl_chart for FlSpot
import '../controllers/achievements_provider.dart'; // Import AchievementsProvider
import '../controllers/user_provider.dart';
import '../controllers/weight_provider.dart'; // Import WeightProvider
import '../controllers/workout_provider.dart'; // Import WorkoutProvider
import '../models/user_model.dart';
import '../models/weight_record_model.dart'; // Import WeightRecordModel
import '../widgets/custom_line_chart.dart'; // Import CustomLineChart
import '../widgets/primary_button.dart';
import 'package:intl/intl.dart'; // For date formatting

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameController;
  late String _selectedGender;
  late TextEditingController _heightController;
  late TextEditingController _weightController;
  DateTime? _selectedBirthDate;
  bool _isLoading = true;
  UserModel? _initialUser;

  final List<String> _genderOptions = [
    'Male',
    'Female',
    'Non-binary',
    'Prefer not to say',
  ];

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    final userProvider = Provider.of<UserProvider>(context, listen: false);
    // Ensure user data is loaded in the provider if not already
    // This might involve calling an initialization method if UserProvider doesn't load automatically
    // For now, assume UserProvider loads its data on instantiation or via an init method called elsewhere.
    _initialUser = userProvider.currentUser;

    if (_initialUser != null) {
      _nameController = TextEditingController(text: _initialUser!.name);
      _selectedGender = _initialUser!.gender ?? 'Prefer not to say';
      _heightController = TextEditingController(
        text: _initialUser!.height?.toString() ?? '',
      );
      _weightController = TextEditingController(
        text: _initialUser!.weight?.toString() ?? '',
      );
      _selectedBirthDate = _initialUser!.birthDate;
    } else {
      // Handle case where user data is unexpectedly null (e.g., navigate back or show error)
      // For now, initialize with empty controllers
      _nameController = TextEditingController();
      _selectedGender = 'Prefer not to say';
      _heightController = TextEditingController();
      _weightController = TextEditingController();
      _selectedBirthDate = null;
      // Optionally show a message or navigate away if profile MUST exist here
      print(
        "Error: ProfileScreen loaded but no user data found in UserProvider.",
      );
    }

    setState(() {
      _isLoading = false;
    });
  }

  @override
  void dispose() {
    _nameController.dispose();
    _heightController.dispose();
    _weightController.dispose();
    super.dispose();
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate:
          _selectedBirthDate ??
          DateTime.now().subtract(const Duration(days: 365 * 25)),
      firstDate: DateTime(1920),
      lastDate: DateTime.now(),
      // Consider reusing the theme builder from ProfileSetupScreen if needed
    );
    if (picked != null && picked != _selectedBirthDate) {
      setState(() {
        _selectedBirthDate = picked;
      });
    }
  }

  void _updateProfile() async {
    if (_formKey.currentState!.validate()) {
      final userProvider = Provider.of<UserProvider>(context, listen: false);
      if (userProvider.deviceId == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Error: Cannot update profile. Device ID missing.'),
          ),
        );
        return;
      }

      // Create updated user model
      final updatedUser = UserModel(
        deviceId: userProvider.deviceId!, // Use the existing device ID
        name: _nameController.text,
        gender: _selectedGender,
        height: double.tryParse(_heightController.text),
        weight: double.tryParse(_weightController.text),
        birthDate: _selectedBirthDate,
      );

      try {
        await userProvider.saveUserProfile(updatedUser);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Profile updated successfully!')),
        );
        // Optionally pop or refresh state if needed
      } catch (e) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error updating profile: $e')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(title: const Text('Edit Profile'), centerTitle: true),
      body:
          _isLoading
              ? const Center(child: CircularProgressIndicator())
              : _initialUser ==
                  null // Handle case where profile doesn't exist
              ? Center(
                child: Padding(
                  padding: const EdgeInsets.all(20.0),
                  child: Text(
                    'Profile not found. Please set up your profile first.',
                    style: theme.textTheme.bodyLarge,
                    textAlign: TextAlign.center,
                  ),
                ),
              )
              : SingleChildScrollView(
                child: Padding(
                  padding: const EdgeInsets.all(24.0),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Text(
                          'Update Your Information',
                          style: theme.textTheme.headlineMedium?.copyWith(
                            color: theme.colorScheme.primary,
                            fontWeight: FontWeight.bold,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 24),

                        // Name field
                        TextFormField(
                          controller: _nameController,
                          decoration: const InputDecoration(
                            labelText: 'Name',
                            border: OutlineInputBorder(),
                            prefixIcon: Icon(Icons.person),
                          ),
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Please enter your name';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 16),

                        // Gender dropdown
                        DropdownButtonFormField<String>(
                          value: _selectedGender,
                          decoration: const InputDecoration(
                            labelText: 'Gender',
                            border: OutlineInputBorder(),
                            prefixIcon: Icon(Icons.people),
                          ),
                          items:
                              _genderOptions.map((String gender) {
                                return DropdownMenuItem<String>(
                                  value: gender,
                                  child: Text(gender),
                                );
                              }).toList(),
                          onChanged: (String? newValue) {
                            if (newValue != null) {
                              setState(() {
                                _selectedGender = newValue;
                              });
                            }
                          },
                        ),
                        const SizedBox(height: 16),

                        // Height field
                        TextFormField(
                          controller: _heightController,
                          decoration: const InputDecoration(
                            labelText: 'Height (cm)',
                            hintText: 'Enter height in centimeters',
                            border: OutlineInputBorder(),
                            prefixIcon: Icon(Icons.height),
                          ),
                          keyboardType: TextInputType.number,
                          validator: (value) {
                            if (value != null && value.isNotEmpty) {
                              final height = double.tryParse(value);
                              if (height == null) {
                                return 'Please enter a valid number';
                              }
                              if (height < 50 || height > 250) {
                                return 'Please enter a realistic height (50-250 cm)';
                              }
                            }
                            return null; // Optional field
                          },
                        ),
                        const SizedBox(height: 16),

                        // Weight field
                        TextFormField(
                          controller: _weightController,
                          decoration: const InputDecoration(
                            labelText: 'Weight (kg)',
                            hintText: 'Enter weight in kilograms',
                            border: OutlineInputBorder(),
                            prefixIcon: Icon(Icons.monitor_weight),
                          ),
                          keyboardType: TextInputType.number,
                          validator: (value) {
                            if (value != null && value.isNotEmpty) {
                              final weight = double.tryParse(value);
                              if (weight == null) {
                                return 'Please enter a valid number';
                              }
                              if (weight < 30 || weight > 300) {
                                return 'Please enter a realistic weight (30-300 kg)';
                              }
                            }
                            return null; // Optional field
                          },
                        ),
                        const SizedBox(height: 16),

                        // Birth date picker
                        InkWell(
                          onTap: () => _selectDate(context),
                          child: InputDecorator(
                            decoration: const InputDecoration(
                              labelText: 'Birth Date',
                              border: OutlineInputBorder(),
                              prefixIcon: Icon(Icons.calendar_today),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  _selectedBirthDate == null
                                      ? 'Select birth date'
                                      : DateFormat('dd/MM/yyyy').format(
                                        _selectedBirthDate!,
                                      ), // Use intl for formatting
                                  style: TextStyle(
                                    color:
                                        _selectedBirthDate == null
                                            ? theme.hintColor
                                            : theme.textTheme.bodyLarge?.color,
                                  ),
                                ),
                                const Icon(Icons.arrow_drop_down),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: 32),

                        // Update button
                        PrimaryButton(
                          text: 'Update Profile',
                          onPressed: _updateProfile,
                        ),
                        const SizedBox(height: 32),

                        // Weight Chart Section
                        _buildWeightChartSection(context),
                        const SizedBox(height: 24),

                        // Achievements Section
                        _buildAchievementsSection(context),
                        const SizedBox(height: 24),

                        // Personal Records Section
                        _buildPersonalRecordsSection(context),
                        const SizedBox(height: 24),
                      ],
                    ),
                  ),
                ),
              ),
    );
  }

  // --- Achievements Section Builder ---
  Widget _buildAchievementsSection(BuildContext context) {
    final theme = Theme.of(context);
    // Listen to achievement updates
    final achievementsProvider = Provider.of<AchievementsProvider>(context);
    final earnedAchievements =
        achievementsProvider.earnedAchievements; // Assuming getter exists

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Achievements',
          style: theme.textTheme.headlineSmall?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 16),
        if (achievementsProvider.isLoading) // Assuming isLoading getter exists
          const Center(child: CircularProgressIndicator())
        else if (earnedAchievements.isEmpty)
          Center(
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 24.0),
              child: Text(
                'No achievements unlocked yet. Keep running!',
                style: theme.textTheme.bodyLarge?.copyWith(
                  color: theme.hintColor,
                ),
                textAlign: TextAlign.center,
              ),
            ),
          )
        else
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 3, // Adjust number of columns
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
              childAspectRatio: 0.8, // Adjust aspect ratio for icon + text
            ),
            itemCount: earnedAchievements.length,
            itemBuilder: (context, index) {
              final achievement = earnedAchievements[index];
              return Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircleAvatar(
                    radius: 30,
                    backgroundColor: theme.colorScheme.secondary.withOpacity(
                      0.2,
                    ),
                    // TODO: Use achievement.icon if available
                    child: Icon(
                      Icons.emoji_events,
                      size: 30,
                      color: theme.colorScheme.secondary,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    achievement.name,
                    style: theme.textTheme.bodySmall,
                    textAlign: TextAlign.center,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              );
            },
          ),
      ],
    );
  }
  // --- End Achievements Section ---

  // --- Weight Chart Section Builder ---
  Widget _buildWeightChartSection(BuildContext context) {
    final theme = Theme.of(context);
    final weightProvider = Provider.of<WeightProvider>(
      context,
    ); // Listen for changes

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          // Wrap title and button in a Row
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Weight Trend',
              style: theme.textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            TextButton.icon(
              // Add button to navigate to entry screen
              icon: const Icon(Icons.add, size: 18),
              label: const Text('Log Weight'),
              onPressed: () {
                Navigator.pushNamed(
                  context,
                  '/weight_entry',
                ); // Navigate to new screen
              },
            ),
          ],
        ),
        const SizedBox(height: 16),
        if (weightProvider.isLoading)
          const Center(child: CircularProgressIndicator())
        else if (weightProvider.weightRecords.isEmpty)
          Center(
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 24.0),
              child: Text(
                'No weight data recorded yet.',
                style: theme.textTheme.bodyLarge?.copyWith(
                  color: theme.hintColor,
                ),
                textAlign: TextAlign.center,
              ),
            ),
          )
        else
          _buildWeightChart(context, weightProvider.weightRecords),
      ],
    );
  }

  Widget _buildWeightChart(
    BuildContext context,
    List<WeightRecordModel> records,
  ) {
    // Sort records by date ascending for the chart's X-axis
    final sortedRecords = List<WeightRecordModel>.from(records)
      ..sort((a, b) => a.date.compareTo(b.date));

    // Create FlSpot data
    final List<FlSpot> spots = [];
    double minY = double.maxFinite;
    double maxY = double.minPositive;
    double minX = 0; // Start X from 0 (index)
    double maxX = (sortedRecords.length - 1).toDouble(); // End X at last index

    for (int i = 0; i < sortedRecords.length; i++) {
      final record = sortedRecords[i];
      final xValue = i.toDouble(); // Use index as X value
      final yValue = record.weight;
      spots.add(FlSpot(xValue, yValue));

      // Find min/max Y for axis range
      if (yValue < minY) minY = yValue;
      if (yValue > maxY) maxY = yValue;
    }

    // Add some padding to Y range
    minY = (minY - 2).floorToDouble();
    maxY = (maxY + 2).ceilToDouble();
    if (minY < 0) minY = 0; // Ensure min Y is not negative

    return CustomLineChart(
      spots: spots,
      minY: minY,
      maxY: maxY,
      minX: minX,
      maxX: maxX,
      // Customize bottom titles to show dates (e.g., first and last)
      bottomTitles: AxisTitles(
        sideTitles: SideTitles(
          showTitles: true,
          reservedSize: 30,
          interval: (maxX / 4).ceilToDouble(), // Show ~5 labels
          getTitlesWidget: (value, meta) {
            final index = value.toInt();
            if (index >= 0 && index < sortedRecords.length) {
              // Show date for specific indices (e.g., first, last, middle)
              if (index == 0 ||
                  index == sortedRecords.length - 1 ||
                  index == (sortedRecords.length / 2).floor()) {
                return SideTitleWidget(
                  axisSide: meta.axisSide,
                  space: 8.0,
                  child: Text(
                    DateFormat(
                      'MMM d',
                    ).format(sortedRecords[index].date), // Format date
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                );
              }
            }
            return const SizedBox.shrink(); // Hide other labels
          },
        ),
      ),
      // Customize left titles for weight
      leftTitles: AxisTitles(
        sideTitles: SideTitles(
          showTitles: true,
          reservedSize: 40,
          getTitlesWidget: (value, meta) {
            // Show integer weights
            if (value == meta.max || value == meta.min || value % 5 == 0) {
              // Show min, max and multiples of 5
              return SideTitleWidget(
                axisSide: meta.axisSide,
                space: 8.0,
                child: Text(
                  value.toStringAsFixed(0), // Format weight
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              );
            }
            return const SizedBox.shrink();
          },
        ),
      ),
    );
  }

  // --- End Weight Chart Section ---

  // --- Personal Records Section Builder ---
  Widget _buildPersonalRecordsSection(BuildContext context) {
    final theme = Theme.of(context);
    // Use listen: false if PRs don't need to update live on this screen
    // Need to import WorkoutProvider
    final workoutProvider = Provider.of<WorkoutProvider>(
      context,
      listen: false,
    );

    // Get PRs
    final longestDist = workoutProvider.longestDistanceWorkout;
    final longestTime = workoutProvider.longestDurationWorkout;
    final highestGain = workoutProvider.highestElevationGainWorkout;
    final fastest5k = workoutProvider.fastest5kWorkout;
    final fastest10k = workoutProvider.fastest10kWorkout;

    // Helper to build a PR row
    Widget buildPrRow(String label, String value, IconData icon) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 8.0),
        child: Row(
          children: [
            Icon(icon, size: 20, color: theme.colorScheme.secondary),
            const SizedBox(width: 12),
            Text('$label:', style: theme.textTheme.bodyMedium),
            const Spacer(),
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

    // Helper to format duration (copy from elsewhere or make utility)
    String formatDurationLocal(Duration duration) {
      String twoDigits(int n) => n.toString().padLeft(2, '0');
      final hours = twoDigits(duration.inHours);
      final minutes = twoDigits(duration.inMinutes.remainder(60));
      final seconds = twoDigits(duration.inSeconds.remainder(60));
      return [if (duration.inHours > 0) hours, minutes, seconds].join(':');
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Personal Records',
          style: theme.textTheme.headlineSmall?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 16),
        Card(
          elevation: 1,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              children: [
                buildPrRow(
                  'Longest Distance',
                  longestDist != null
                      ? '${longestDist.distance?.toStringAsFixed(2) ?? '-'} km'
                      : '-',
                  Icons.straighten,
                ),
                const Divider(height: 1),
                buildPrRow(
                  'Longest Duration',
                  longestTime != null
                      ? formatDurationLocal(
                        longestTime.duration,
                      ) // Use local helper
                      : '-',
                  Icons.timer,
                ),
                const Divider(height: 1),
                buildPrRow(
                  'Highest Elevation Gain',
                  highestGain != null
                      ? '+${highestGain.elevationGain?.toStringAsFixed(0) ?? '-'} m'
                      : '-',
                  Icons.landscape,
                ),
                const Divider(height: 1),
                buildPrRow(
                  'Fastest 5K',
                  fastest5k != null
                      ? formatDurationLocal(fastest5k.duration)
                      : '-',
                  Icons.speed, // Consider a specific 5k icon
                ),
                const Divider(height: 1),
                buildPrRow(
                  'Fastest 10K',
                  fastest10k != null
                      ? formatDurationLocal(fastest10k.duration)
                      : '-',
                  Icons.speed, // Consider a specific 10k icon
                ),
                // Add more PRs here if calculated
              ],
            ),
          ),
        ),
      ],
    );
  }

  // --- End Personal Records Section ---
} // End of _ProfileScreenState class
