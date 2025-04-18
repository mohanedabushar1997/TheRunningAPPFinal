import 'dart:async';
import 'dart:io';

import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';
import 'package:sqflite/sqflite.dart';

class DatabaseHelper {
  static final DatabaseHelper _instance = DatabaseHelper._internal();
  factory DatabaseHelper() => _instance;

  static Database? _database;

  DatabaseHelper._internal();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    Directory documentsDirectory = await getApplicationDocumentsDirectory();
    String path = join(documentsDirectory.path, 'fitstride.db');
    return await openDatabase(
      path,
      version: 1, // Start with version 1
      onCreate: _onCreate,
      onUpgrade: _onUpgrade, // Implement migration strategy (Task 2.1.4)
    );
  }

  // Called when the database is created for the first time.
  Future<void> _onCreate(Database db, int version) async {
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
        avg_pace REAL
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
        FOREIGN KEY (workout_id) REFERENCES Workouts (id) ON DELETE CASCADE
      )
    ''');

    await db.execute('''
      CREATE TABLE Training_Plans (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL,
        level TEXT NOT NULL,
        description TEXT,
        duration_weeks INTEGER NOT NULL
      )
    ''');

    await db.execute('''
      CREATE TABLE Training_Sessions (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        plan_id INTEGER NOT NULL,
        day_number INTEGER NOT NULL,
        description TEXT,
        intervals TEXT,
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
        achieved_date TEXT
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
  }

  // --- CRUD Operations (Task 2.1.11) ---

  // Example CRUD for User table
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

  // TODO: Implement CRUD operations for Workouts, Workout_Points, Training_Plans, etc.

  // Close the database connection (optional, typically managed by sqflite)
  Future<void> close() async {
    final db = await database;
    db.close();
    _database = null; // Reset the static instance
  }
}
