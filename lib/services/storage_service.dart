import '../data/database_helper.dart';
import '../models/user_model.dart';
import '../models/workout_model.dart';
import '../models/workout_point_model.dart';
import '../models/training_plan_model.dart';
import '../models/training_session_model.dart';
import '../models/achievement_model.dart';
import '../models/weight_record_model.dart'; // Import WeightRecordModel

class StorageService {
  final DatabaseHelper _dbHelper = DatabaseHelper();

  // --- User Data ---
  // TODO: Refine User methods to use UserModel consistently
  Future<int> saveUser(UserModel user) async {
    final userData = user.toMap();
    // Check if user exists based on device_id to decide insert vs update
    final existingUserMap = await getUserByDeviceId(user.deviceId);
    if (existingUserMap != null) {
      // Update requires the ID. Assume UserModel has an ID field.
      // If the passed user object doesn't have an ID but exists in DB, fetch it.
      final userToUpdate =
          user.id == null
              ? user.copyWith(id: existingUserMap['id'] as int?)
              : user;
      return await _dbHelper.updateUser(userToUpdate.toMap());
    } else {
      return await _dbHelper.insertUser(userData);
    }
  }

  // Keep returning Map for now, UserProvider handles conversion
  Future<Map<String, dynamic>?> getUserByDeviceId(String deviceId) async {
    return await _dbHelper.getUserByDeviceId(deviceId);
  }

  Future<int> deleteUser(String deviceId) async {
    // DatabaseHelper uses deviceId for deletion directly
    return await _dbHelper.deleteUser(deviceId);
  }

  // --- Workout Data ---
  Future<int> saveWorkout(WorkoutModel workout) async {
    final workoutId = await _dbHelper.insertWorkout(workout.toMap());
    // Save associated points
    if (workout.routePoints.isNotEmpty) {
      await saveWorkoutPoints(workoutId, workout.routePoints);
    }
    return workoutId;
  }

  Future<List<WorkoutModel>> getAllWorkouts() async {
    final workoutsData = await _dbHelper.getWorkouts();
    List<WorkoutModel> workouts = [];
    for (var workoutMap in workoutsData) {
      final workoutId = workoutMap['id'] as int;
      final points = await getWorkoutPointsByWorkoutId(workoutId);
      workouts.add(WorkoutModel.fromMap(workoutMap, points: points));
    }
    return workouts;
  }

  Future<WorkoutModel?> getWorkoutById(int id) async {
    final workoutMap = await _dbHelper.getWorkoutById(id);
    if (workoutMap != null) {
      final points = await getWorkoutPointsByWorkoutId(id);
      return WorkoutModel.fromMap(workoutMap, points: points);
    }
    return null;
  }

  Future<int> updateWorkout(WorkoutModel workout) async {
    if (workout.id == null) return 0; // Cannot update without ID
    final result = await _dbHelper.updateWorkout(workout.toMap());
    // Update points: delete existing and insert new ones
    await deleteWorkoutPoints(workout.id!);
    await saveWorkoutPoints(workout.id!, workout.routePoints);
    return result;
  }

  Future<int> deleteWorkout(int id) async {
    // Points should be deleted by cascade constraint in DB
    return await _dbHelper.deleteWorkout(id);
  }

  // --- Workout Points ---
  Future<void> saveWorkoutPoints(
    int workoutId,
    List<WorkoutPointModel> points,
  ) async {
    // Use batch insert for efficiency
    final batch = await _dbHelper.database; // Get database instance
    await batch.transaction((txn) async {
      for (var point in points) {
        final pointWithId = point.copyWith(workoutId: workoutId);
        await txn.insert(
          'Workout_Points', // Use string literal for table name
          pointWithId.toMap(),
        );
      }
    });
  }

  Future<List<WorkoutPointModel>> getWorkoutPointsByWorkoutId(
    int workoutId,
  ) async {
    final pointsData = await _dbHelper.getWorkoutPointsByWorkoutId(workoutId);
    return pointsData.map((map) => WorkoutPointModel.fromMap(map)).toList();
  }

  Future<int> deleteWorkoutPoints(int workoutId) async {
    return await _dbHelper.deleteWorkoutPoints(workoutId);
  }

  // --- Training Plans ---
  Future<int> saveTrainingPlan(TrainingPlanModel plan) async {
    return await _dbHelper.insertTrainingPlan(plan.toMap());
  }

  Future<List<TrainingPlanModel>> getAllTrainingPlans() async {
    final plansData = await _dbHelper.getTrainingPlans();
    List<TrainingPlanModel> plans = [];
    for (var planMap in plansData) {
      final sessions = await getTrainingSessionsByPlanId(planMap['id'] as int);
      plans.add(TrainingPlanModel.fromMap(planMap, sessions: sessions));
    }
    return plans;
  }

  Future<TrainingPlanModel?> getActiveTrainingPlan() async {
    final planMap = await _dbHelper.getActiveTrainingPlan();
    if (planMap != null) {
      final sessions = await getTrainingSessionsByPlanId(planMap['id'] as int);
      return TrainingPlanModel.fromMap(planMap, sessions: sessions);
    }
    return null;
  }

  Future<int> updateTrainingPlan(TrainingPlanModel plan) async {
    return await _dbHelper.updateTrainingPlan(plan.toMap());
  }

  Future<int> deleteTrainingPlan(int id) async {
    return await _dbHelper.deleteTrainingPlan(id);
  }

  // --- Training Sessions ---
  Future<int> saveTrainingSession(TrainingSessionModel session) async {
    return await _dbHelper.insertTrainingSession(session.toMap());
  }

  Future<List<TrainingSessionModel>> getTrainingSessionsByPlanId(
    int planId,
  ) async {
    final sessionsData = await _dbHelper.getTrainingSessionsByPlanId(planId);
    return sessionsData
        .map((map) => TrainingSessionModel.fromMap(map))
        .toList();
  }

  Future<int> updateTrainingSession(TrainingSessionModel session) async {
    return await _dbHelper.updateTrainingSession(session.toMap());
  }

  Future<int> deleteTrainingSession(int id) async {
    return await _dbHelper.deleteTrainingSession(id);
  }

  // --- Weight Records ---
  Future<int> saveWeightRecord(WeightRecordModel record) async {
    // Check if exists by ID to decide insert vs update
    if (record.id != null) {
      final existing = await getWeightRecordById(record.id!);
      if (existing != null) {
        return await _dbHelper.updateWeightRecord(record.toMap());
      }
    }
    // If no ID or doesn't exist, insert
    return await _dbHelper.insertWeightRecord(record.toMap());
  }

  Future<List<WeightRecordModel>> getWeightRecords() async {
    final recordsData = await _dbHelper.getWeightRecords();
    return recordsData.map((map) => WeightRecordModel.fromMap(map)).toList();
  }

  Future<WeightRecordModel?> getWeightRecordById(int id) async {
    final map = await _dbHelper.getWeightRecordById(id);
    return map != null ? WeightRecordModel.fromMap(map) : null;
  }

  Future<int> deleteWeightRecord(int id) async {
    return await _dbHelper.deleteWeightRecord(id);
  }

  // --- Achievements ---
  Future<int> saveAchievement(AchievementModel achievement) async {
    // Check if exists by name to decide insert vs update
    final existing = await getAchievementByName(achievement.name);
    if (existing != null) {
      // Ensure ID is included for update
      final achievementToUpdate =
          achievement.id == null
              ? achievement.copyWith(id: existing.id)
              : achievement;
      return await _dbHelper.updateAchievement(achievementToUpdate.toMap());
    } else {
      return await _dbHelper.insertAchievement(achievement.toMap());
    }
  }

  Future<List<AchievementModel>> getAllAchievements() async {
    final achievementsData = await _dbHelper.getAchievements();
    return achievementsData
        .map((map) => AchievementModel.fromMap(map))
        .toList();
  }

  Future<AchievementModel?> getAchievementByName(String name) async {
    final map = await _dbHelper.getAchievementByName(name);
    return map != null ? AchievementModel.fromMap(map) : null;
  }

  Future<int> updateAchievementProgress(String name, double progress) async {
    final achievement = await getAchievementByName(name);
    if (achievement != null && achievement.id != null) {
      final updatedAchievement = achievement.copyWith(progressValue: progress);
      return await _dbHelper.updateAchievement(updatedAchievement.toMap());
    }
    return 0; // Achievement not found
  }

  // --- Settings (Using DB Table) ---
  // These interact with the 'Settings' table in the DB
  Future<int> saveDbSetting(String key, String value) async {
    // Check if exists to decide insert vs update
    final existingValue = await getDbSetting(key);
    // final row = {'key': key, 'value': value}; // Don't need map
    if (existingValue != null) {
      // Call with key and value arguments
      return await _dbHelper.updateSetting(key, value);
    } else {
      // Call with key and value arguments
      return await _dbHelper.insertSetting(key, value);
    }
  }

  Future<String?> getDbSetting(String key) async {
    final map = await _dbHelper.getSetting(key);
    return map?['value'] as String?;
  }

  Future<List<Map<String, dynamic>>> getAllDbSettings() async {
    return await _dbHelper.getSettings();
  }

  Future<int> deleteDbSetting(String key) async {
    // Call with key argument (this was already correct)
    // Call with key argument (this was already correct)
    return await _dbHelper.deleteSetting(key);
  }

  // Close database connection (optional, might be handled by DatabaseHelper singleton)
  Future<void> closeDatabase() async {
    await _dbHelper.close();
  }
}
