import 'dart:async';
import 'dart:io';
import 'dart:math'; // For random password generation
import 'dart:convert'; // For base64 encoding

import 'package:flutter_secure_storage/flutter_secure_storage.dart'; // Import secure storage
import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';
import 'package:sqflite/sqflite.dart';
// Import sqlcipher_flutter_libs if needed for specific initialization (often not needed directly here)
// import 'package:sqlcipher_flutter_libs/sqlcipher_flutter_libs.dart';

class DatabaseHelper {
  static final DatabaseHelper _instance = DatabaseHelper._internal();
  factory DatabaseHelper() => _instance;

  static Database? _database;
  static const String _dbPasswordKey =
      'fitstride_db_password'; // Key for secure storage
  final _secureStorage =
      const FlutterSecureStorage(); // Instance of secure storage

  DatabaseHelper._internal();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  // --- Secure Password Management ---
  Future<String> _getDatabasePassword() async {
    String? password = await _secureStorage.read(key: _dbPasswordKey);
    if (password == null) {
      // Generate a strong random password if none exists
      var random = Random.secure();
      // Generate 32 random bytes and encode them in base64
      var values = List<int>.generate(32, (i) => random.nextInt(256));
      password = base64UrlEncode(values);
      await _secureStorage.write(key: _dbPasswordKey, value: password);
      print("Generated and stored new database password.");
    } else {
      print("Retrieved existing database password from secure storage.");
    }
    return password;
  }

  // --- Database Initialization with Encryption ---
  Future<Database> _initDatabase() async {
    Directory documentsDirectory = await getApplicationDocumentsDirectory();
    // Use the original database name. Assumes starting fresh or manual migration if old unencrypted DB exists.
    String path = join(documentsDirectory.path, 'fitstride.db');

    String password;
    try {
      password = await _getDatabasePassword();
    } catch (e) {
      print("Error getting database password: $e");
      // Handle error appropriately
      rethrow;
    }

    print("Opening database at path: $path");
    try {
      // Open the database WITHOUT the password parameter first
      Database db = await openDatabase(
        path,
        version: 1, // Start with version 1
        onCreate: _onCreate,
        onUpgrade: _onUpgrade,
        // DO NOT pass password here
      );

      // Set the password using PRAGMA key immediately after opening
      // Note: Use single quotes around the password in the SQL command
      await db.rawQuery("PRAGMA key = '$password';");
      print("Database password applied via PRAGMA key.");

      // Verify the key by trying to access data (optional but recommended)
      try {
        await db.rawQuery('SELECT count(*) FROM sqlite_master;');
        print("Database key verified successfully.");
      } catch (e) {
        print(
          "Error verifying database key (likely incorrect password or corruption): $e",
        );
        // Handle incorrect password scenario - maybe delete DB and restart?
        await db.close(); // Close the incorrectly opened DB
        _database = null; // Reset static instance
        // Consider deleting the potentially corrupt file: await File(path).delete();
        rethrow; // Rethrow to signal failure
      }

      return db;
    } catch (e) {
      print("Error during database initialization: $e");
      // Handle potential errors like file access issues, etc.
      rethrow; // Rethrow for now
    }
  }

  // Called when the database is created for the first time.
  Future<void> _onCreate(Database db, int version) async {
    // NOTE: onCreate is called *after* the database file is created but *before*
    // the version is set. The PRAGMA key should have already been applied if opening
    // an existing encrypted DB. If this is the very first creation, the PRAGMA key
    // might need to be applied *again* here if the initial PRAGMA fails on a non-existent file,
    // although typically sqflite handles the initial keying. Let's assume the key is set.

    print("Creating database tables for version: $version");
    await db.execute('''
      CREATE TABLE User (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        device_id TEXT UNIQUE NOT NULL,
        name TEXT,
        gender TEXT,
        height REAL,
        weight REAL,
        birth_date TEXT
      )
    ''');

    await db.execute('''
      CREATE TABLE Workouts (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        date TEXT NOT NULL,
        type TEXT NOT NULL,
        duration INTEGER NOT NULL,
        distance REAL,
        calories INTEGER,
        avg_pace REAL,
        avg_speed REAL,
        max_speed REAL,
        elevation_gain REAL,
        elevation_loss REAL,
        notes TEXT,
        is_manual_entry INTEGER DEFAULT 0
      )
    ''');

    await db.execute('''
      CREATE TABLE Workout_Points (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        workout_id INTEGER NOT NULL,
        latitude REAL NOT NULL,
        longitude REAL NOT NULL,
        elevation REAL,
        timestamp TEXT NOT NULL,
        speed REAL,
        heart_rate REAL,
        FOREIGN KEY (workout_id) REFERENCES Workouts (id) ON DELETE CASCADE
      )
    ''');

    await db.execute('''
      CREATE TABLE Training_Plans (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL,
        level TEXT NOT NULL,
        description TEXT,
        duration_weeks INTEGER NOT NULL,
        goal_type TEXT,
        is_active INTEGER DEFAULT 0,
        start_date TEXT
      )
    ''');

    await db.execute('''
      CREATE TABLE Training_Sessions (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        plan_id INTEGER NOT NULL,
        day_number INTEGER NOT NULL,
        description TEXT,
        intervals TEXT,
        target_distance REAL,
        target_duration INTEGER,
        is_completed INTEGER DEFAULT 0,
        completed_date TEXT,
        FOREIGN KEY (plan_id) REFERENCES Training_Plans (id) ON DELETE CASCADE
      )
    ''');

    await db.execute('''
      CREATE TABLE Weight_Records (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        date TEXT NOT NULL,
        weight REAL NOT NULL,
        notes TEXT
      )
    ''');

    await db.execute('''
      CREATE TABLE Achievements (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT UNIQUE NOT NULL,
        description TEXT,
        icon TEXT,
        achieved_date TEXT,
        progress_value REAL DEFAULT 0.0,
        category TEXT DEFAULT 'general'
      )
    ''');

    await db.execute('''
      CREATE TABLE Settings (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        key TEXT UNIQUE NOT NULL,
        value TEXT NOT NULL
      )
    ''');

    // Create Indexes (Task 2.1.12)
    await db.execute('CREATE INDEX idx_workouts_date ON Workouts (date)');
    await db.execute(
      'CREATE INDEX idx_workout_points_workout_id ON Workout_Points (workout_id)',
    );
    await db.execute(
      'CREATE INDEX idx_training_sessions_plan_id ON Training_Sessions (plan_id)',
    );
    await db.execute(
      'CREATE INDEX idx_weight_records_date ON Weight_Records (date)',
    );
    await db.execute(
      'CREATE INDEX idx_achievements_achieved_date ON Achievements (achieved_date)',
    );

    print("Database tables and indexes created successfully.");
  }

  // Implement database version management and migration (Task 2.1.3, 2.1.4)
  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    print("Upgrading database from version $oldVersion to $newVersion");
    // Example migration:
    // if (oldVersion < 2) {
    //   await db.execute("ALTER TABLE User ADD COLUMN email TEXT;");
    // }
    // Add more migration steps as needed for future versions
    // Note: Migrating an encrypted DB might require specific SQLCipher commands (e.g., PRAGMA rekey)
  }

  // --- CRUD Operations (Task 2.1.11) ---
  // CRUD operations remain largely the same, as they operate on the opened DB instance

  // User CRUD operations
  Future<int> insertUser(Map<String, dynamic> row) async {
    Database db = await database;
    return await db.insert('User', row);
  }

  Future<Map<String, dynamic>?> getUserByDeviceId(String deviceId) async {
    Database db = await database;
    List<Map<String, dynamic>> results = await db.query(
      'User',
      where: 'device_id = ?',
      whereArgs: [deviceId],
    );
    if (results.isNotEmpty) {
      return results.first;
    }
    return null;
  }

  Future<int> updateUser(Map<String, dynamic> row) async {
    Database db = await database;
    String deviceId = row['device_id'];
    return await db.update(
      'User',
      row,
      where: 'device_id = ?',
      whereArgs: [deviceId],
    );
  }

  Future<int> deleteUser(String deviceId) async {
    Database db = await database;
    return await db.delete(
      'User',
      where: 'device_id = ?',
      whereArgs: [deviceId],
    );
  }

  // Workout CRUD operations
  Future<int> insertWorkout(Map<String, dynamic> row) async {
    Database db = await database;
    return await db.insert('Workouts', row);
  }

  Future<List<Map<String, dynamic>>> getWorkouts() async {
    Database db = await database;
    return await db.query('Workouts', orderBy: 'date DESC');
  }

  Future<Map<String, dynamic>?> getWorkoutById(int id) async {
    Database db = await database;
    List<Map<String, dynamic>> results = await db.query(
      'Workouts',
      where: 'id = ?',
      whereArgs: [id],
    );
    if (results.isNotEmpty) {
      return results.first;
    }
    return null;
  }

  Future<List<Map<String, dynamic>>> getWorkoutsByDateRange(
    String startDate,
    String endDate,
  ) async {
    Database db = await database;
    return await db.query(
      'Workouts',
      where: 'date BETWEEN ? AND ?',
      whereArgs: [startDate, endDate],
      orderBy: 'date DESC',
    );
  }

  Future<int> updateWorkout(Map<String, dynamic> row) async {
    Database db = await database;
    return await db.update(
      'Workouts',
      row,
      where: 'id = ?',
      whereArgs: [row['id']],
    );
  }

  Future<int> deleteWorkout(int id) async {
    Database db = await database;
    return await db.delete('Workouts', where: 'id = ?', whereArgs: [id]);
  }

  // Workout Points CRUD operations
  Future<int> insertWorkoutPoint(Map<String, dynamic> row) async {
    Database db = await database;
    return await db.insert('Workout_Points', row);
  }

  Future<List<Map<String, dynamic>>> getWorkoutPointsByWorkoutId(
    int workoutId,
  ) async {
    Database db = await database;
    return await db.query(
      'Workout_Points',
      where: 'workout_id = ?',
      whereArgs: [workoutId],
      orderBy: 'timestamp ASC',
    );
  }

  Future<int> updateWorkoutPoint(Map<String, dynamic> row) async {
    Database db = await database;
    return await db.update(
      'Workout_Points',
      row,
      where: 'id = ?',
      whereArgs: [row['id']],
    );
  }

  Future<int> deleteWorkoutPoints(int workoutId) async {
    Database db = await database;
    return await db.delete(
      'Workout_Points',
      where: 'workout_id = ?',
      whereArgs: [workoutId],
    );
  }

  // Training Plans CRUD operations
  Future<int> insertTrainingPlan(Map<String, dynamic> row) async {
    Database db = await database;
    return await db.insert('Training_Plans', row);
  }

  Future<List<Map<String, dynamic>>> getTrainingPlans() async {
    Database db = await database;
    return await db.query('Training_Plans');
  }

  Future<Map<String, dynamic>?> getTrainingPlanById(int id) async {
    Database db = await database;
    List<Map<String, dynamic>> results = await db.query(
      'Training_Plans',
      where: 'id = ?',
      whereArgs: [id],
    );
    if (results.isNotEmpty) {
      return results.first;
    }
    return null;
  }

  Future<Map<String, dynamic>?> getActiveTrainingPlan() async {
    Database db = await database;
    List<Map<String, dynamic>> results = await db.query(
      'Training_Plans',
      where: 'is_active = 1',
    );
    if (results.isNotEmpty) {
      return results.first;
    }
    return null;
  }

  Future<int> updateTrainingPlan(Map<String, dynamic> row) async {
    Database db = await database;
    return await db.update(
      'Training_Plans',
      row,
      where: 'id = ?',
      whereArgs: [row['id']],
    );
  }

  Future<int> deleteTrainingPlan(int id) async {
    Database db = await database;
    return await db.delete('Training_Plans', where: 'id = ?', whereArgs: [id]);
  }

  // Training Sessions CRUD operations
  Future<int> insertTrainingSession(Map<String, dynamic> row) async {
    Database db = await database;
    return await db.insert('Training_Sessions', row);
  }

  Future<List<Map<String, dynamic>>> getTrainingSessionsByPlanId(
    int planId,
  ) async {
    Database db = await database;
    return await db.query(
      'Training_Sessions',
      where: 'plan_id = ?',
      whereArgs: [planId],
      orderBy: 'day_number ASC',
    );
  }

  Future<Map<String, dynamic>?> getTrainingSessionById(int id) async {
    Database db = await database;
    List<Map<String, dynamic>> results = await db.query(
      'Training_Sessions',
      where: 'id = ?',
      whereArgs: [id],
    );
    if (results.isNotEmpty) {
      return results.first;
    }
    return null;
  }

  Future<int> updateTrainingSession(Map<String, dynamic> row) async {
    Database db = await database;
    return await db.update(
      'Training_Sessions',
      row,
      where: 'id = ?',
      whereArgs: [row['id']],
    );
  }

  Future<int> deleteTrainingSession(int id) async {
    Database db = await database;
    return await db.delete(
      'Training_Sessions',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  // Achievement CRUD operations
  Future<int> insertAchievement(Map<String, dynamic> row) async {
    Database db = await database;
    return await db.insert('Achievements', row);
  }

  Future<List<Map<String, dynamic>>> getAchievements() async {
    Database db = await database;
    return await db.query('Achievements');
  }

  Future<Map<String, dynamic>?> getAchievementByName(String name) async {
    Database db = await database;
    List<Map<String, dynamic>> results = await db.query(
      'Achievements',
      where: 'name = ?',
      whereArgs: [name],
    );
    if (results.isNotEmpty) {
      return results.first;
    }
    return null;
  }

  Future<int> updateAchievement(Map<String, dynamic> row) async {
    Database db = await database;
    return await db.update(
      'Achievements',
      row,
      where: 'name = ?',
      whereArgs: [row['name']],
    );
  }

  Future<int> updateAchievementProgress(String name, double progress) async {
    Database db = await database;
    return await db.update(
      'Achievements',
      {'progress_value': progress},
      where: 'name = ?',
      whereArgs: [name],
    );
  }

  Future<int> deleteAchievement(String name) async {
    Database db = await database;
    return await db.delete(
      'Achievements',
      where: 'name = ?',
      whereArgs: [name],
    );
  }

  // Settings CRUD operations
  Future<int> insertSetting(String key, String value) async {
    Database db = await database;
    return await db.insert('Settings', {
      'key': key,
      'value': value,
    }, conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<List<Map<String, dynamic>>> getSettings() async {
    Database db = await database;
    return await db.query('Settings');
  }

  Future<String?> getSetting(String key) async {
    Database db = await database;
    List<Map<String, dynamic>> results = await db.query(
      'Settings',
      where: 'key = ?',
      whereArgs: [key],
    );
    if (results.isNotEmpty) {
      return results.first['value'] as String;
    }
    return null;
  }

  Future<int> updateSetting(String key, String value) async {
    Database db = await database;
    return await db.update(
      'Settings',
      {'value': value},
      where: 'key = ?',
      whereArgs: [key],
    );
  }

  Future<int> deleteSetting(String key) async {
    Database db = await database;
    return await db.delete('Settings', where: 'key = ?', whereArgs: [key]);
  }

  // Weight Records CRUD operations
  Future<int> insertWeightRecord(Map<String, dynamic> row) async {
    Database db = await database;
    return await db.insert('Weight_Records', row);
  }

  Future<List<Map<String, dynamic>>> getWeightRecords() async {
    Database db = await database;
    return await db.query('Weight_Records', orderBy: 'date DESC');
  }

  Future<int> updateWeightRecord(Map<String, dynamic> row) async {
    Database db = await database;
    return await db.update(
      'Weight_Records',
      row,
      where: 'id = ?',
      whereArgs: [row['id']],
    );
  }

  Future<int> deleteWeightRecord(int id) async {
    Database db = await database;
    return await db.delete('Weight_Records', where: 'id = ?', whereArgs: [id]);
  }

  // Close the database connection (optional, typically managed by sqflite)
  Future<void> close() async {
    // Check if database is initialized and open before closing
    if (_database != null && _database!.isOpen) {
      await _database!.close();
      _database = null; // Reset the static instance
      print("Database connection closed.");
    }
  }
}
