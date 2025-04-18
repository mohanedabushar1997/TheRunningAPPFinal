import '../data/database_helper.dart';
// TODO: Import models (User, Workout, etc.)

class StorageService {
  final DatabaseHelper _dbHelper = DatabaseHelper();

  // --- User Data ---
  // TODO: Use UserModel instead of Map<String, dynamic>
  Future<int> saveUser(Map<String, dynamic> userData) async {
    // Check if user exists based on device_id to decide insert vs update
    final existingUser = await getUserByDeviceId(userData['device_id']);
    if (existingUser != null) {
      // Ensure ID is included for update if needed by dbHelper.updateUser implementation
      // userData['id'] = existingUser['id']; // Assuming dbHelper needs id for update
      return await _dbHelper.updateUser(userData);
    } else {
      return await _dbHelper.insertUser(userData);
    }
  }

  Future<Map<String, dynamic>?> getUserByDeviceId(String deviceId) async {
    return await _dbHelper.getUserByDeviceId(deviceId);
  }

  Future<int> deleteUser(String deviceId) async {
    return await _dbHelper.deleteUser(deviceId);
  }

  // --- Workout Data ---
  // TODO: Implement methods for saving, retrieving, deleting workouts
  // Future<int> saveWorkout(WorkoutModel workout) async { ... }
  // Future<List<WorkoutModel>> getAllWorkouts() async { ... }
  // Future<WorkoutModel?> getWorkoutById(int id) async { ... }

  // --- Workout Points ---
  // TODO: Implement methods for saving workout points (potentially batch insert)
  // Future<void> saveWorkoutPoints(int workoutId, List<WorkoutPoint> points) async { ... }

  // --- Training Plans ---
  // TODO: Implement methods for training plans and sessions

  // --- Weight Records ---
  // TODO: Implement methods for weight records

  // --- Achievements ---
  // TODO: Implement methods for achievements

  // --- Settings ---
  // TODO: Decide if settings are handled here (via DB) or solely by SettingsProvider (via SharedPreferences)
  // Future<void> saveSetting(String key, String value) async { ... }
  // Future<String?> getSetting(String key) async { ... }

  // Close database connection (optional, might be handled by DatabaseHelper singleton)
  Future<void> closeDatabase() async {
    await _dbHelper.close();
  }
}
