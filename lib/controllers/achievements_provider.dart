import 'package:flutter/foundation.dart';
// import '../data/database_helper.dart'; // No longer needed directly
import '../models/achievement_model.dart';
import '../models/workout_model.dart';
import '../models/user_model.dart';
import '../services/storage_service.dart'; // Import StorageService

class AchievementsProvider with ChangeNotifier {
  // final DatabaseHelper _dbHelper = DatabaseHelper(); // Replaced by StorageService
  final StorageService _storageService = StorageService(); // Use StorageService

  // Define state for unlocked achievements and progress towards others
  List<AchievementModel> _unlockedAchievements = [];
  Map<String, double> _achievementProgress =
      {}; // Map<achievementName, progressPercent>
  List<AchievementModel> _allAchievements = [];
  bool _isLoading = true; // Declare isLoading state, initialize to true

  // Getters
  List<AchievementModel> get unlockedAchievements => _unlockedAchievements;
  Map<String, double> get achievementProgress => _achievementProgress;
  List<AchievementModel> get allAchievements => _allAchievements;
  bool get isLoading => _isLoading; // Add getter for isLoading

  // Getter for earned achievements (same as unlockedAchievements)
  List<AchievementModel> get earnedAchievements => _unlockedAchievements;

  AchievementsProvider() {
    _initializeAchievements();
  }

  // Initialize achievements
  Future<void> _initializeAchievements() async {
    // Define all possible achievements
    _allAchievements = _defineAllAchievements();

    // Load unlocked achievements from DB
    await _loadAchievements();
    _isLoading = false; // Set loading to false after initialization
    notifyListeners(); // Notify after setting loading state
  }

  // Load achievements from DB
  Future<void> _loadAchievements() async {
    _isLoading = true; // Set loading true at the start
    notifyListeners();
    try {
      // Use StorageService to get all achievements
      final loadedAchievements = await _storageService.getAllAchievements();

      if (loadedAchievements.isNotEmpty) {
        // Populate state from loaded models
        _unlockedAchievements =
            loadedAchievements.where((a) => a.achievedDate != null).toList();

        _achievementProgress = {
          for (var achievement in loadedAchievements)
            achievement.name: achievement.progressValue ?? 0.0,
        };
      } else {
        // Initialize with empty achievements if none in DB
        _unlockedAchievements = [];

        // Initialize progress map with 0 for all achievements
        _achievementProgress = {
          for (var achievement in _allAchievements) achievement.name: 0.0,
        };

        // Save initial achievements to DB via StorageService
        for (var achievement in _allAchievements) {
          await _storageService.saveAchievement(achievement);
        }
      }

      // No need to notify here, will notify after setting isLoading to false
    } catch (e) {
      print('Error loading achievements: $e');
    } finally {
      _isLoading = false; // Ensure loading is set to false even on error
      notifyListeners(); // Notify after loading finishes or fails
    }
  }

  // Check and unlock achievements based on workout/user data
  Future<List<AchievementModel>> checkAndUnlockAchievements({
    WorkoutModel? workout,
    List<WorkoutModel>? workoutHistory,
    UserModel? user,
  }) async {
    List<AchievementModel> newlyUnlocked = [];

    // Skip if no data provided
    if (workout == null && workoutHistory == null && user == null) {
      return newlyUnlocked;
    }

    // Get current workout history if not provided
    List<WorkoutModel> history = workoutHistory ?? [];
    if (workoutHistory == null && workout != null) {
      // Use StorageService to get workout history
      history = await _storageService.getAllWorkouts();

      // Add current workout if it's not already in history
      if (workout.id == null || !history.any((w) => w.id == workout.id)) {
        history.add(workout);
      }
    }

    // Check distance-based achievements
    if (history.isNotEmpty) {
      // Total distance
      final totalDistance = history.fold<double>(
        0,
        (sum, workout) => sum + (workout.distance ?? 0),
      );

      // Check total distance achievements
      _updateAchievementProgress('total_distance_10km', totalDistance / 10);
      _updateAchievementProgress('total_distance_50km', totalDistance / 50);
      _updateAchievementProgress('total_distance_100km', totalDistance / 100);
      _updateAchievementProgress('total_distance_500km', totalDistance / 500);
      _updateAchievementProgress('total_distance_1000km', totalDistance / 1000);

      // Longest run
      final longestRun = history
          .where((w) => w.type == WorkoutType.run)
          .fold<double>(
            0,
            (max, workout) =>
                (workout.distance ?? 0) > max ? (workout.distance ?? 0) : max,
          );

      // Check longest run achievements
      _updateAchievementProgress('longest_run_5km', longestRun / 5);
      _updateAchievementProgress('longest_run_10km', longestRun / 10);
      _updateAchievementProgress('longest_run_21km', longestRun / 21.1);
      _updateAchievementProgress('longest_run_42km', longestRun / 42.2);
    }

    // Check workout count achievements
    final workoutCount = history.length;
    _updateAchievementProgress('workout_count_5', workoutCount / 5);
    _updateAchievementProgress('workout_count_20', workoutCount / 20);
    _updateAchievementProgress('workout_count_50', workoutCount / 50);
    _updateAchievementProgress('workout_count_100', workoutCount / 100);

    // Check streak achievements (consecutive days)
    if (history.isNotEmpty) {
      final sortedWorkouts = List<WorkoutModel>.from(history)
        ..sort((a, b) => b.date.compareTo(a.date)); // Sort by date descending

      int currentStreak = 1;
      DateTime lastDate = sortedWorkouts.first.date;
      DateTime currentDate = lastDate.subtract(const Duration(days: 1));

      for (int i = 1; i < sortedWorkouts.length; i++) {
        final workoutDate = sortedWorkouts[i].date;

        // Check if this workout is on the expected date for the streak
        if (workoutDate.year == currentDate.year &&
            workoutDate.month == currentDate.month &&
            workoutDate.day == currentDate.day) {
          currentStreak++;
          currentDate = currentDate.subtract(const Duration(days: 1));
        } else if (workoutDate.isBefore(currentDate)) {
          // This workout is from an earlier date, so the streak is broken
          break;
        }
      }

      // Update streak achievements
      _updateAchievementProgress('streak_3_days', currentStreak / 3);
      _updateAchievementProgress('streak_7_days', currentStreak / 7);
      _updateAchievementProgress('streak_14_days', currentStreak / 14);
      _updateAchievementProgress('streak_30_days', currentStreak / 30);
    }

    // Check for newly unlocked achievements
    for (var achievement in _allAchievements) {
      if (_achievementProgress[achievement.name] == 1.0 &&
          !_unlockedAchievements.any((a) => a.name == achievement.name)) {
        // This achievement is newly unlocked
        final unlocked = achievement.copyWith(
          achievedDate: DateTime.now(),
          progressValue: 1.0,
        );

        // Add to unlocked list
        _unlockedAchievements.add(unlocked);
        newlyUnlocked.add(unlocked);

        // Update in database via StorageService
        await _storageService.saveAchievement(unlocked); // save handles update
      }
    }

    if (newlyUnlocked.isNotEmpty) {
      notifyListeners();
    }

    return newlyUnlocked;
  }

  // Update achievement progress
  Future<void> _updateAchievementProgress(
    String achievementName,
    double progress,
  ) async {
    // Clamp progress between 0 and 1
    final clampedProgress = progress.clamp(0.0, 1.0);

    // Update progress map
    _achievementProgress[achievementName] = clampedProgress;

    // Find the achievement
    final achievementIndex = _allAchievements.indexWhere(
      (a) => a.name == achievementName,
    );
    if (achievementIndex >= 0) {
      // Update the achievement
      final achievement = _allAchievements[achievementIndex].copyWith(
        progressValue: clampedProgress,
      );
      _allAchievements[achievementIndex] = achievement;

      // Update in database via StorageService
      await _storageService.updateAchievementProgress(
        achievementName,
        clampedProgress,
      );
    }
  }

  // Define all possible achievements
  List<AchievementModel> _defineAllAchievements() {
    return [
      // Distance achievements
      const AchievementModel(
        name: 'total_distance_10km',
        description: 'Run a total of 10 kilometers',
        icon: 'assets/icons/achievements/distance_10km.png',
        category: 'distance',
      ),
      const AchievementModel(
        name: 'total_distance_50km',
        description: 'Run a total of 50 kilometers',
        icon: 'assets/icons/achievements/distance_50km.png',
        category: 'distance',
      ),
      const AchievementModel(
        name: 'total_distance_100km',
        description: 'Run a total of 100 kilometers',
        icon: 'assets/icons/achievements/distance_100km.png',
        category: 'distance',
      ),
      const AchievementModel(
        name: 'total_distance_500km',
        description: 'Run a total of 500 kilometers',
        icon: 'assets/icons/achievements/distance_500km.png',
        category: 'distance',
      ),
      const AchievementModel(
        name: 'total_distance_1000km',
        description: 'Run a total of 1000 kilometers',
        icon: 'assets/icons/achievements/distance_1000km.png',
        category: 'distance',
      ),

      // Longest run achievements
      const AchievementModel(
        name: 'longest_run_5km',
        description: 'Complete a 5K run',
        icon: 'assets/icons/achievements/run_5k.png',
        category: 'milestone',
      ),
      const AchievementModel(
        name: 'longest_run_10km',
        description: 'Complete a 10K run',
        icon: 'assets/icons/achievements/run_10k.png',
        category: 'milestone',
      ),
      const AchievementModel(
        name: 'longest_run_21km',
        description: 'Complete a half marathon',
        icon: 'assets/icons/achievements/run_half_marathon.png',
        category: 'milestone',
      ),
      const AchievementModel(
        name: 'longest_run_42km',
        description: 'Complete a full marathon',
        icon: 'assets/icons/achievements/run_marathon.png',
        category: 'milestone',
      ),

      // Workout count achievements
      const AchievementModel(
        name: 'workout_count_5',
        description: 'Complete 5 workouts',
        icon: 'assets/icons/achievements/workouts_5.png',
        category: 'consistency',
      ),
      const AchievementModel(
        name: 'workout_count_20',
        description: 'Complete 20 workouts',
        icon: 'assets/icons/achievements/workouts_20.png',
        category: 'consistency',
      ),
      const AchievementModel(
        name: 'workout_count_50',
        description: 'Complete 50 workouts',
        icon: 'assets/icons/achievements/workouts_50.png',
        category: 'consistency',
      ),
      const AchievementModel(
        name: 'workout_count_100',
        description: 'Complete 100 workouts',
        icon: 'assets/icons/achievements/workouts_100.png',
        category: 'consistency',
      ),

      // Streak achievements
      const AchievementModel(
        name: 'streak_3_days',
        description: 'Work out for 3 consecutive days',
        icon: 'assets/icons/achievements/streak_3.png',
        category: 'streak',
      ),
      const AchievementModel(
        name: 'streak_7_days',
        description: 'Work out for 7 consecutive days',
        icon: 'assets/icons/achievements/streak_7.png',
        category: 'streak',
      ),
      const AchievementModel(
        name: 'streak_14_days',
        description: 'Work out for 14 consecutive days',
        icon: 'assets/icons/achievements/streak_14.png',
        category: 'streak',
      ),
      const AchievementModel(
        name: 'streak_30_days',
        description: 'Work out for 30 consecutive days',
        icon: 'assets/icons/achievements/streak_30.png',
        category: 'streak',
      ),
    ];
  }

  // Get achievements by category
  List<AchievementModel> getAchievementsByCategory(String category) {
    return _allAchievements.where((a) => a.category == category).toList();
  }
}
