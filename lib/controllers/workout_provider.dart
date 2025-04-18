import 'package:flutter/foundation.dart';
import '../data/database_helper.dart';
// TODO: Create Workout model in lib/models/workout_model.dart

class WorkoutProvider with ChangeNotifier {
  final DatabaseHelper _dbHelper = DatabaseHelper();

  // TODO: Define state variables for workout history, current workout details, etc.
  // List<WorkoutModel> _workouts = [];
  // WorkoutModel? _currentWorkout;

  // List<WorkoutModel> get workouts => _workouts;
  // WorkoutModel? get currentWorkout => _currentWorkout;

  WorkoutProvider() {
    // TODO: Load workout history on initialization
    // _loadWorkouts();
  }

  // TODO: Implement method to load workouts from DB
  // Future<void> _loadWorkouts() async { ... }

  // TODO: Implement methods to start, pause, resume, stop, save workouts
  // Future<void> startWorkout(...) async { ... }
  // Future<void> saveWorkout(...) async { ... }
  // Future<void> deleteWorkout(int id) async { ... }
}
