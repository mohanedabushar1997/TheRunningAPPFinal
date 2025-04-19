import 'package:flutter/foundation.dart';
import 'package:intl/intl.dart'; // For date formatting/calculations
// import '../data/database_helper.dart'; // No longer needed directly
import '../models/workout_model.dart';
import '../models/workout_point_model.dart';
import '../models/user_model.dart';
import '../services/calculation_service.dart';
import '../services/storage_service.dart'; // Import StorageService
import 'tracking_provider.dart'; // Added for interaction

// Enum for workout state
enum WorkoutStatus { notStarted, running, paused, stopped }

class WorkoutProvider with ChangeNotifier {
  // final DatabaseHelper _dbHelper = DatabaseHelper(); // Replaced by StorageService
  final StorageService _storageService = StorageService(); // Use StorageService
  final CalculationService? _calculationService;
  final UserModel? _user; // User might be needed for stats calculations
  final TrackingProvider? _trackingProvider; // Added dependency

  // Define state variables for workout history, current workout details, etc.
  List<WorkoutModel> _workouts = [];
  WorkoutModel? _currentWorkout;
  bool _isLoading = false;
  DateTime? _selectedDate; // For history filtering
  WorkoutType? _selectedType; // For history filtering
  WorkoutStatus _workoutStatus = WorkoutStatus.notStarted;

  // Getters
  List<WorkoutModel> get workouts => _workouts;
  WorkoutModel? get currentWorkout => _currentWorkout;
  bool get isLoading => _isLoading;
  DateTime? get selectedDate => _selectedDate;
  WorkoutType? get selectedType => _selectedType;
  WorkoutStatus get workoutStatus => _workoutStatus;

  // Getter for History Screen
  Future<List<WorkoutModel>> getAllWorkouts() async {
    // Ensure workouts are loaded if not already
    if (_workouts.isEmpty && !_isLoading) {
      await _loadWorkouts();
    }
    return List.unmodifiable(_workouts); // Return unmodifiable list
  }

  // --- New Getters for Home Screen ---
  List<WorkoutModel> get recentWorkouts => _workouts.take(3).toList();

  Map<String, dynamic> get statsThisWeek {
    final now = DateTime.now();
    final startOfWeek = now.subtract(Duration(days: now.weekday - 1));
    final endOfWeek = startOfWeek.add(const Duration(days: 6));
    return _calculateStatsForRange(startOfWeek, endOfWeek);
  }

  Map<String, dynamic> get statsThisMonth {
    final now = DateTime.now();
    final startOfMonth = DateTime(now.year, now.month, 1);
    final endOfMonth = DateTime(
      now.year,
      now.month + 1,
      0,
    ); // Day 0 of next month is last day of current
    return _calculateStatsForRange(startOfMonth, endOfMonth);
  }

  double get statsTotalDistance =>
      _workouts.fold(0.0, (sum, w) => sum + (w.distance ?? 0.0));

  double? get statsAveragePace {
    double totalDistance = statsTotalDistance;
    if (totalDistance <= 0) return null;

    Duration totalDuration = _workouts.fold(
      Duration.zero,
      (sum, w) => sum + w.duration,
    );
    if (totalDuration.inSeconds <= 0) return null;

    return totalDuration.inSeconds / totalDistance; // Pace in seconds per km
  }
  // --- End New Getters ---

  // --- Personal Records Getters ---
  WorkoutModel? get longestDistanceWorkout => _getWorkoutWithBestMetric(
    (w) => w.distance,
    includeManual: true,
  ); // Include manual entries for distance PRs

  WorkoutModel? get longestDurationWorkout => _getWorkoutWithBestMetric(
    (w) => w.duration.inSeconds.toDouble(),
    includeManual: true,
  ); // Include manual

  WorkoutModel? get highestElevationGainWorkout => _getWorkoutWithBestMetric(
    (w) => w.elevationGain,
    includeManual: false,
  ); // Exclude manual for elevation

  WorkoutModel? get fastest5kWorkout => _getFastestTimeForDistance(5.0);

  WorkoutModel? get fastest10kWorkout => _getFastestTimeForDistance(10.0);

  // Add more PRs as needed (e.g., 1k, Half Marathon)
  // --- End Personal Records Getters ---

  WorkoutProvider({
    CalculationService? calculationService,
    UserModel? user,
    TrackingProvider? trackingProvider, // Added dependency
  }) : _calculationService = calculationService,
       _user = user,
       _trackingProvider = trackingProvider {
    // Initialize dependency
    _loadWorkouts(); // Load historical workouts on init
  }

  // Load workout history from DB
  Future<void> _loadWorkouts() async {
    _isLoading = true;
    notifyListeners();

    try {
      // Use StorageService to get all workouts (includes points)
      _workouts = await _storageService.getAllWorkouts();
    } catch (e) {
      print('Error loading workouts: $e');
      _workouts = [];
    }

    _isLoading = false;
    notifyListeners();
  }

  // Set current workout (e.g., from tracking provider)
  void setCurrentWorkout(WorkoutModel workout) {
    _currentWorkout = workout;
    notifyListeners();
  }

  // --- Active Workout Control Methods ---

  Future<void> startNewWorkout(WorkoutType type) async {
    if (_workoutStatus != WorkoutStatus.notStarted &&
        _workoutStatus != WorkoutStatus.stopped) {
      print("Workout already in progress or not properly stopped.");
      return; // Don't start a new one if already active/paused
    }
    if (_trackingProvider == null) {
      print("Error: TrackingProvider is not available.");
      return;
    }

    print("Starting new workout of type: $type");
    // Reset current workout details
    _currentWorkout = WorkoutModel(
      date: DateTime.now(),
      type: type,
      duration: Duration.zero, // Will be updated by TrackingProvider
      distance: 0.0,
      calories: 0,
      avgPace: null,
      avgSpeed: null,
      maxSpeed: null,
      elevationGain: null,
      routePoints: [], // Will be populated by TrackingProvider
      isManualEntry: false,
    );
    _workoutStatus = WorkoutStatus.running;
    notifyListeners();

    // Tell TrackingProvider to start
    try {
      // Use the correct method name from TrackingProvider
      await _trackingProvider!.startWorkout();
      print("TrackingProvider started successfully.");
    } catch (e) {
      print("Error starting TrackingProvider: $e");
      // Handle error - maybe revert status?
      _workoutStatus = WorkoutStatus.stopped; // Or notStarted?
      _currentWorkout = null;
      notifyListeners();
    }
  }

  Future<void> pauseWorkout() async {
    if (_workoutStatus != WorkoutStatus.running) return;
    if (_trackingProvider == null) {
      print("Error: TrackingProvider is not available.");
      return;
    }

    print("Pausing workout.");
    _workoutStatus = WorkoutStatus.paused;
    notifyListeners();

    // Tell TrackingProvider to pause
    try {
      // Use the correct method name from TrackingProvider
      _trackingProvider!
          .pauseWorkout(); // This method is synchronous in TrackingProvider
      print("TrackingProvider paused successfully.");
    } catch (e) {
      print("Error pausing TrackingProvider: $e");
      // Handle error - status is already paused, maybe log?
    }
  }

  Future<void> resumeWorkout() async {
    if (_workoutStatus != WorkoutStatus.paused) return;
    if (_trackingProvider == null) {
      print("Error: TrackingProvider is not available.");
      return;
    }

    print("Resuming workout.");
    _workoutStatus = WorkoutStatus.running;
    notifyListeners();

    // Tell TrackingProvider to resume
    try {
      // Use the correct method name from TrackingProvider
      _trackingProvider!
          .resumeWorkout(); // This method is synchronous in TrackingProvider
      print("TrackingProvider resumed successfully.");
    } catch (e) {
      print("Error resuming TrackingProvider: $e");
      // Handle error - maybe revert status?
      _workoutStatus = WorkoutStatus.paused; // Revert to paused
      notifyListeners();
    }
  }

  Future<void> stopWorkout() async {
    if (_workoutStatus != WorkoutStatus.running &&
        _workoutStatus != WorkoutStatus.paused) {
      print("Workout not running or paused, cannot stop.");
      return;
    }
    if (_trackingProvider == null) {
      print("Error: TrackingProvider is not available.");
      return;
    }

    print("Stopping workout.");
    _workoutStatus = WorkoutStatus.stopped;

    try {
      // Tell TrackingProvider to stop and save the workout.
      // stopAndSaveWorkout handles calling saveWorkout internally if successful.
      final WorkoutModel? savedWorkout =
          await _trackingProvider!.stopAndSaveWorkout();
      print("TrackingProvider stopAndSaveWorkout completed.");

      if (savedWorkout != null) {
        // Workout was successfully stopped and saved by TrackingProvider
        print("Workout saved via TrackingProvider with ID: ${savedWorkout.id}");
        // Update _currentWorkout to the final saved version for the summary screen
        _currentWorkout = savedWorkout;
        // Reload history to include the new workout
        await _loadWorkouts();
      } else {
        print(
          "Error: Workout was not saved successfully by TrackingProvider or was discarded.",
        );
        // Clear the local _currentWorkout as it wasn't saved
        _currentWorkout = null;
      }
    } catch (e) {
      print("Error stopping TrackingProvider or saving workout: $e");
      // Handle error - status is stopped, but data might be lost/incomplete
      _currentWorkout = null; // Clear potentially incomplete workout
    } finally {
      // Ensure state is updated even if errors occurred during stop/save
      notifyListeners();
    }
  }

  // Discard the currently active workout without saving
  Future<void> discardWorkout() async {
    // Added async and Future<void>
    if (_workoutStatus == WorkoutStatus.running ||
        _workoutStatus == WorkoutStatus.paused) {
      if (_trackingProvider != null) {
        // Use the correct method name from TrackingProvider
        await _trackingProvider!.discardWorkout();
      }
    }
    print("Discarding current workout.");
    _currentWorkout = null;
    _workoutStatus =
        WorkoutStatus
            .stopped; // Or notStarted? Let's use stopped for consistency after an attempt.
    notifyListeners();
  }

  // --- End Active Workout Control Methods ---

  // Save workout to database
  Future<bool> saveWorkout(WorkoutModel workout) async {
    try {
      _isLoading = true;
      notifyListeners();

      // Use StorageService to save workout (handles points internally)
      final workoutId = await _storageService.saveWorkout(workout);

      // Update current workout with ID if it was the one being saved
      if (_currentWorkout != null && _currentWorkout!.date == workout.date) {
        // Fetch the saved workout to ensure we have the final state with ID
        final savedWorkout = await _storageService.getWorkoutById(workoutId);
        if (savedWorkout != null) {
          _currentWorkout = savedWorkout;
        } else {
          // Fallback: copy ID if fetch fails for some reason
          _currentWorkout = workout.copyWith(id: workoutId);
        }
      }

      // Reload workouts to include the new one
      await _loadWorkouts();

      return true;
    } catch (e) {
      print('Error saving workout: $e');
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  // Update existing workout
  Future<bool> updateWorkout(WorkoutModel workout) async {
    if (workout.id == null) return false;

    try {
      _isLoading = true;
      notifyListeners();

      // Use StorageService to update workout (handles points internally)
      await _storageService.updateWorkout(workout);

      // Update current workout if it's the same one
      if (_currentWorkout != null && _currentWorkout!.id == workout.id) {
        _currentWorkout = workout;
      }

      // Update workout in list
      final index = _workouts.indexWhere((w) => w.id == workout.id);
      if (index >= 0) {
        _workouts[index] = workout;
      }

      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      print('Error updating workout: $e');
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  // Delete workout
  Future<bool> deleteWorkout(int id) async {
    try {
      _isLoading = true;
      notifyListeners();

      // Use StorageService to delete workout
      await _storageService.deleteWorkout(id);

      // Remove from list
      _workouts.removeWhere((w) => w.id == id);

      // Clear current workout if it's the same one
      if (_currentWorkout != null && _currentWorkout!.id == id) {
        _currentWorkout = null;
      }

      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      print('Error deleting workout: $e');
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  // Create a manual workout entry
  Future<bool> createManualWorkout({
    required WorkoutType type,
    required DateTime date,
    required Duration duration,
    double? distance,
    String? notes,
  }) async {
    try {
      // Calculate metrics if possible
      double? avgPace;
      double? avgSpeed;
      int? calories;

      if (distance != null && distance > 0 && duration.inSeconds > 0) {
        avgPace = duration.inSeconds / distance; // seconds per km
        avgSpeed = (distance / duration.inSeconds) * 3600; // km per hour

        if (_calculationService != null && _user != null) {
          calories = _calculationService!.calculateCaloriesBurned(
            workoutType: type,
            duration: duration,
            weightInKg: _user!.weight ?? 70.0, // Use user weight or default
            distanceInKm: distance,
            // Add other relevant parameters if CalculationService needs them
          );
        }
      }

      // Create workout model
      final workout = WorkoutModel(
        date: date,
        type: type,
        duration: duration,
        distance: distance,
        avgPace: avgPace,
        avgSpeed: avgSpeed,
        calories: calories,
        notes: notes,
        isManualEntry: true,
      );

      // Save to database
      return await saveWorkout(workout);
    } catch (e) {
      print('Error creating manual workout: $e');
      return false;
    }
  }

  // Filter workouts by date range (inclusive)
  List<WorkoutModel> getWorkoutsByDateRange(DateTime start, DateTime end) {
    // Ensure start is the beginning of the day and end is the end of the day
    final startDate = DateTime(start.year, start.month, start.day);
    final endDate = DateTime(end.year, end.month, end.day, 23, 59, 59);
    return _workouts
        .where((w) => !w.date.isBefore(startDate) && !w.date.isAfter(endDate))
        .toList();
  }

  // Filter workouts by type
  List<WorkoutModel> getWorkoutsByType(WorkoutType type) {
    return _workouts.where((w) => w.type == type).toList();
  }

  // Calculate total stats for a given list of workouts
  Map<String, dynamic> _calculateStats(List<WorkoutModel> workouts) {
    double totalDistance = 0;
    Duration totalDuration = Duration.zero;
    int totalCalories = 0;

    for (var workout in workouts) {
      if (workout.distance != null) totalDistance += workout.distance!;
      totalDuration += workout.duration;
      if (workout.calories != null) totalCalories += workout.calories!;
    }

    // Calculate average pace if there's distance
    double? avgPace;
    if (totalDistance > 0 && totalDuration.inSeconds > 0) {
      avgPace = totalDuration.inSeconds / totalDistance;
    }

    return {
      'workoutCount': workouts.length,
      'totalDistance': totalDistance,
      'totalDuration': totalDuration,
      'totalCalories': totalCalories,
      'avgPace': avgPace,
    };
  }

  // Calculate total stats for a date range (uses _calculateStats)
  Map<String, dynamic> _calculateStatsForRange(DateTime start, DateTime end) {
    final filteredWorkouts = getWorkoutsByDateRange(start, end);
    return _calculateStats(filteredWorkouts);
  }

  // Set filters
  void setDateFilter(DateTime? date) {
    _selectedDate = date;
    notifyListeners();
  }

  void setTypeFilter(WorkoutType? type) {
    _selectedType = type;
    notifyListeners();
  }

  // --- PR Helper Methods ---

  // Generic helper to find the workout with the maximum value for a given metric
  WorkoutModel? _getWorkoutWithBestMetric(
    double? Function(WorkoutModel) getMetric, {
    required bool includeManual,
  }) {
    WorkoutModel? bestWorkout;
    double? maxMetric;

    final workoutsToConsider =
        includeManual
            ? _workouts
            : _workouts.where((w) => !w.isManualEntry).toList();

    if (workoutsToConsider.isEmpty) return null;

    for (final workout in workoutsToConsider) {
      final metricValue = getMetric(workout);
      if (metricValue != null) {
        if (maxMetric == null || metricValue > maxMetric) {
          maxMetric = metricValue;
          bestWorkout = workout;
        }
      }
    }
    return bestWorkout;
  }

  // Helper to find the fastest time for a specific distance
  // This is a simplified version - assumes the workout *exactly* matches the distance.
  // A more robust implementation would check segments within longer workouts.
  WorkoutModel? _getFastestTimeForDistance(double targetDistanceKm) {
    WorkoutModel? fastestWorkout;
    Duration? fastestDuration;

    // Filter workouts that are approximately the target distance (allow small tolerance)
    final relevantWorkouts =
        _workouts
            .where(
              (w) =>
                  !w.isManualEntry && // Exclude manual entries
                  w.distance != null &&
                  (w.distance! - targetDistanceKm).abs() <
                      0.1, // Allow 100m tolerance
            )
            .toList();

    if (relevantWorkouts.isEmpty) return null;

    for (final workout in relevantWorkouts) {
      if (fastestDuration == null || workout.duration < fastestDuration) {
        fastestDuration = workout.duration;
        fastestWorkout = workout;
      }
    }
    return fastestWorkout;
  }
  // --- End PR Helper Methods ---

  // Get filtered workouts
  List<WorkoutModel> getFilteredWorkouts() {
    List<WorkoutModel> filtered = List.from(_workouts);

    if (_selectedDate != null) {
      final dayStart = DateTime(
        _selectedDate!.year,
        _selectedDate!.month,
        _selectedDate!.day,
      );
      final dayEnd = dayStart.add(const Duration(days: 1));
      filtered =
          filtered
              .where(
                (w) => !w.date.isBefore(dayStart) && w.date.isBefore(dayEnd),
              )
              .toList();
    }

    if (_selectedType != null) {
      filtered = filtered.where((w) => w.type == _selectedType).toList();
    }

    return filtered;
  }

  // Clear filters
  void clearFilters() {
    _selectedDate = null;
    _selectedType = null;
    notifyListeners();
  }

  // Refresh workouts from database
  Future<void> refreshWorkouts() async {
    await _loadWorkouts();
  }
}
