import 'package:flutter/foundation.dart';
import '../data/database_helper.dart';
import '../models/workout_model.dart';
import '../models/workout_point_model.dart';
import '../models/user_model.dart';
import '../services/calculation_service.dart';

class WorkoutProvider with ChangeNotifier {
  final DatabaseHelper _dbHelper = DatabaseHelper();
  final CalculationService? _calculationService;
  final UserModel? _user;

  // Define state variables for workout history, current workout details, etc.
  List<WorkoutModel> _workouts = [];
  WorkoutModel? _currentWorkout;
  bool _isLoading = false;
  DateTime? _selectedDate;
  WorkoutType? _selectedType;

  // Getters
  List<WorkoutModel> get workouts => _workouts;
  WorkoutModel? get currentWorkout => _currentWorkout;
  bool get isLoading => _isLoading;
  DateTime? get selectedDate => _selectedDate;
  WorkoutType? get selectedType => _selectedType;

  WorkoutProvider({CalculationService? calculationService, UserModel? user}) 
      : _calculationService = calculationService,
        _user = user {
    _loadWorkouts();
  }

  // Load workout history from DB
  Future<void> _loadWorkouts() async {
    _isLoading = true;
    notifyListeners();

    try {
      // Get workouts from database
      final workoutsData = await _dbHelper.getWorkouts();
      
      // Convert to WorkoutModel objects
      List<WorkoutModel> loadedWorkouts = [];
      
      for (var workoutMap in workoutsData) {
        final workoutId = workoutMap['id'] as int;
        
        // Get route points for this workout
        final pointsData = await _dbHelper.getWorkoutPointsByWorkoutId(workoutId);
        final points = pointsData
            .map((pointMap) => WorkoutPointModel.fromMap(pointMap))
            .toList();
        
        // Create workout with points
        final workout = WorkoutModel.fromMap(workoutMap, points: points);
        loadedWorkouts.add(workout);
      }
      
      // Sort by date (newest first)
      loadedWorkouts.sort((a, b) => b.date.compareTo(a.date));
      
      _workouts = loadedWorkouts;
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

  // Save workout to database
  Future<bool> saveWorkout(WorkoutModel workout) async {
    try {
      _isLoading = true;
      notifyListeners();
      
      // Insert workout
      final workoutMap = workout.toMap();
      final workoutId = await _dbHelper.insertWorkout(workoutMap);
      
      // Insert route points
      if (workout.routePoints.isNotEmpty) {
        for (var point in workout.routePoints) {
          final pointWithWorkoutId = point.copyWith(workoutId: workoutId);
          await _dbHelper.insertWorkoutPoint(pointWithWorkoutId.toMap());
        }
      }
      
      // Update current workout with ID
      if (_currentWorkout != null && _currentWorkout!.date == workout.date) {
        _currentWorkout = workout.copyWith(id: workoutId);
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
      
      // Update workout
      await _dbHelper.updateWorkout(workout.toMap());
      
      // Update route points if needed
      if (workout.routePoints.isNotEmpty) {
        // First delete existing points
        await _dbHelper.deleteWorkoutPoints(workout.id!);
        
        // Then insert updated points
        for (var point in workout.routePoints) {
          final pointWithWorkoutId = point.copyWith(workoutId: workout.id!);
          await _dbHelper.insertWorkoutPoint(pointWithWorkoutId.toMap());
        }
      }
      
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
      
      // Delete workout (cascade will delete points)
      await _dbHelper.deleteWorkout(id);
      
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
      
      if (distance != null && distance > 0) {
        avgPace = duration.inSeconds / distance;
        avgSpeed = (distance / duration.inSeconds) * 3600;
        
        if (_calculationService != null && _user != null) {
          calories = _calculationService!.calculateCaloriesBurned(
            workoutType: type,
            duration: duration,
            weightInKg: _user!.weight ?? 70.0,
            distanceInKm: distance,
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

  // Filter workouts by date range
  List<WorkoutModel> getWorkoutsByDateRange(DateTime start, DateTime end) {
    return _workouts.where((w) => 
      w.date.isAfter(start.subtract(const Duration(days: 1))) && 
      w.date.isBefore(end.add(const Duration(days: 1)))
    ).toList();
  }

  // Filter workouts by type
  List<WorkoutModel> getWorkoutsByType(WorkoutType type) {
    return _workouts.where((w) => w.type == type).toList();
  }

  // Get total stats for a date range
  Map<String, dynamic> getTotalStats(DateTime start, DateTime end) {
    final filteredWorkouts = getWorkoutsByDateRange(start, end);
    
    double totalDistance = 0;
    Duration totalDuration = Duration.zero;
    int totalCalories = 0;
    
    for (var workout in filteredWorkouts) {
      if (workout.distance != null) totalDistance += workout.distance!;
      totalDuration += workout.duration;
      if (workout.calories != null) totalCalories += workout.calories!;
    }
    
    // Calculate average pace if there's distance
    double? avgPace;
    if (totalDistance > 0) {
      avgPace = totalDuration.inSeconds / totalDistance;
    }
    
    return {
      'workoutCount': filteredWorkouts.length,
      'totalDistance': totalDistance,
      'totalDuration': totalDuration,
      'totalCalories': totalCalories,
      'avgPace': avgPace,
    };
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

  // Get filtered workouts
  List<WorkoutModel> getFilteredWorkouts() {
    List<WorkoutModel> filtered = List.from(_workouts);
    
    if (_selectedDate != null) {
      filtered = filtered.where((w) => 
        w.date.year == _selectedDate!.year && 
        w.date.month == _selectedDate!.month && 
        w.date.day == _selectedDate!.day
      ).toList();
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
