import 'dart:convert'; // For utf8 decoding
import 'dart:io'; // For File access
import 'package:csv/csv.dart'; // For CSV parsing
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart' show rootBundle; // To load asset file
// import '../data/database_helper.dart'; // No longer needed directly
import '../models/training_plan_model.dart';
import '../models/training_session_model.dart';
import '../services/storage_service.dart'; // Import StorageService
import '../data/database_helper.dart'; // Re-import for initial check

class TrainingPlanProvider with ChangeNotifier {
  final DatabaseHelper _dbHelper = DatabaseHelper(); // Keep for initial check
  final StorageService _storageService = StorageService(); // Use StorageService

  // Define state variables for available plans, current plan, progress, etc.
  List<TrainingPlanModel> _availablePlans = [];
  TrainingPlanModel? _currentPlan;
  Map<int, bool> _sessionCompletionStatus = {}; // Map<sessionId, isCompleted>
  bool _isLoading = false;

  // Getters
  List<TrainingPlanModel> get availablePlans => _availablePlans;
  TrainingPlanModel? get currentPlan => _currentPlan;
  Map<int, bool> get sessionCompletionStatus => _sessionCompletionStatus;
  bool get isLoading => _isLoading;

  TrainingPlanProvider() {
    _initialize();
  }

  // Initialize provider
  Future<void> _initialize() async {
    await _loadAvailablePlans();
    await _loadCurrentPlan();
  }

  // Load available training plans from DB or predefined data
  Future<void> _loadAvailablePlans() async {
    _isLoading = true;
    notifyListeners();

    try {
      // Get plans from database
      // Use StorageService (which internally uses DatabaseHelper)
      // Note: StorageService.getAllTrainingPlans returns List<TrainingPlanModel>
      // We need the raw Map data here initially to check if DB is empty before CSV load.
      // Let's adjust StorageService or keep this initial check using dbHelper for simplicity.
      // Sticking with dbHelper for the initial check for emptiness.
      var plansData =
          await _dbHelper
              .getTrainingPlans(); // Keep initial check with dbHelper

      if (plansData.isEmpty) {
        // If no plans in DB, load from CSV and save
        print("No plans found in DB. Loading from CSV...");
        await _loadPlansFromCsvAndSaveToDb();
        // After saving, re-fetch from DB to ensure we have correct IDs and structure
        final updatedPlansData = await _dbHelper.getTrainingPlans();
        plansData = updatedPlansData; // Use the newly fetched data
        if (plansData.isEmpty) {
          print("Error: Plans still empty after attempting to load from CSV.");
          _availablePlans = []; // Set to empty on error
          _isLoading = false;
          notifyListeners();
          return;
        }
      }

      // Convert DB data (either existing or newly loaded from CSV) to models
      List<TrainingPlanModel> plans = [];
      for (var planMap in plansData) {
        final planId = planMap['id'] as int;
        // Use StorageService to get sessions
        final sessions = await _storageService.getTrainingSessionsByPlanId(
          planId,
        );
        // No need to map from data, StorageService returns models
        // final sessions = sessionsData.map((sessionMap) => TrainingSessionModel.fromMap(sessionMap)).toList();
        // Removed duplicate/incorrect session mapping lines

        // Create plan with sessions
        final plan = TrainingPlanModel.fromMap(planMap, sessions: sessions);
        plans.add(plan);
      }
      _availablePlans = plans;
    } catch (e) {
      print('Error loading training plans: $e');
      // Fallback to default plans if error (consider if this is desired)
      // _availablePlans = _createDefaultTrainingPlans();
      _availablePlans = []; // Or set to empty list on error
    }

    _isLoading = false;
    notifyListeners();
  }

  // Load current active plan
  Future<void> _loadCurrentPlan() async {
    TrainingPlanModel? activePlan;
    try {
      // Manually find the first active plan
      for (var plan in _availablePlans) {
        if (plan.isActive) {
          activePlan = plan;
          break; // Found the first active plan
        }
      }
      _currentPlan =
          activePlan; // Assign the found plan (or null if none found)

      // If found, load session completion status
      if (_currentPlan != null) {
        await _loadSessionCompletionStatus(_currentPlan!.id!);
      }
    } catch (e) {
      print('Error loading current plan: $e');
      _currentPlan = null;
    }

    notifyListeners();
  }

  // Load session completion status for a plan
  Future<void> _loadSessionCompletionStatus(int planId) async {
    try {
      // Use StorageService to get sessions
      final sessions = await _storageService.getTrainingSessionsByPlanId(
        planId,
      );

      // Create map of session ID to completion status from models
      _sessionCompletionStatus = {
        for (var session in sessions)
          session.id!: session.isCompleted, // Use model properties
      };
    } catch (e) {
      print('Error loading session completion status: $e');
      _sessionCompletionStatus = {};
    }
  }

  // Select and activate a training plan
  Future<void> selectPlan(int planId) async {
    try {
      // Deactivate current plan if exists
      if (_currentPlan != null) {
        await deactivateCurrentPlan();
      }

      // Find the plan to activate
      final planIndex = _availablePlans.indexWhere((p) => p.id == planId);
      if (planIndex < 0) {
        print("Error: Plan with ID $planId not found in available plans.");
        return;
      }

      // Activate the plan
      final plan = _availablePlans[planIndex];
      // Ensure the plan has an ID before activating
      if (plan.id == null) {
        print("Error: Plan ID is null, cannot activate.");
        return;
      }
      final activatedPlan = plan.activate();

      // Update in database via StorageService
      await _storageService.updateTrainingPlan(activatedPlan);

      // Update in state
      _availablePlans[planIndex] = activatedPlan;
      _currentPlan = activatedPlan;

      // Initialize session completion status
      await _loadSessionCompletionStatus(planId);

      notifyListeners();
    } catch (e) {
      print('Error selecting plan: $e');
    }
  }

  // Deactivate current plan
  Future<void> deactivateCurrentPlan() async {
    if (_currentPlan == null || _currentPlan!.id == null) return;

    try {
      // Deactivate the plan
      final deactivatedPlan = _currentPlan!.deactivate();

      // Update in database via StorageService
      await _storageService.updateTrainingPlan(deactivatedPlan);

      // Update in state
      final planIndex = _availablePlans.indexWhere(
        (p) => p.id == _currentPlan!.id,
      );
      if (planIndex >= 0) {
        _availablePlans[planIndex] = deactivatedPlan;
      }

      _currentPlan = null;
      _sessionCompletionStatus = {};

      notifyListeners();
    } catch (e) {
      print('Error deactivating plan: $e');
    }
  }

  // Mark a session as completed
  Future<void> completeSession(int sessionId) async {
    if (_currentPlan == null || _currentPlan!.id == null) return;

    try {
      // Find the session
      final sessionIndex = _currentPlan!.sessions.indexWhere(
        (s) => s.id == sessionId,
      );
      if (sessionIndex < 0) return;

      // Mark as completed
      final session = _currentPlan!.sessions[sessionIndex];
      if (session.id == null) {
        print("Error: Session ID is null, cannot complete.");
        return;
      }
      final completedSession = session.markCompleted();

      // Update in database via StorageService
      await _storageService.updateTrainingSession(completedSession);

      // Update in state
      final updatedSessions = List<TrainingSessionModel>.from(
        _currentPlan!.sessions,
      );
      updatedSessions[sessionIndex] = completedSession;

      _currentPlan = _currentPlan!.copyWith(sessions: updatedSessions);
      _sessionCompletionStatus[sessionId] = true;

      notifyListeners();
    } catch (e) {
      print('Error completing session: $e');
    }
  }

  // Mark a session as not completed
  Future<void> uncompleteSession(int sessionId) async {
    if (_currentPlan == null || _currentPlan!.id == null) return;

    try {
      // Find the session
      final sessionIndex = _currentPlan!.sessions.indexWhere(
        (s) => s.id == sessionId,
      );
      if (sessionIndex < 0) return;

      // Mark as not completed
      final session = _currentPlan!.sessions[sessionIndex];
      if (session.id == null) {
        print("Error: Session ID is null, cannot uncomplete.");
        return;
      }
      final uncompletedSession = session.markNotCompleted();

      // Update in database via StorageService
      await _storageService.updateTrainingSession(uncompletedSession);

      // Update in state
      final updatedSessions = List<TrainingSessionModel>.from(
        _currentPlan!.sessions,
      );
      updatedSessions[sessionIndex] = uncompletedSession;

      _currentPlan = _currentPlan!.copyWith(sessions: updatedSessions);
      _sessionCompletionStatus[sessionId] = false;

      notifyListeners();
    } catch (e) {
      print('Error uncompleting session: $e');
    }
  }

  // Get sessions for the current week of the active plan
  List<TrainingSessionModel> getCurrentWeekSessions() {
    if (_currentPlan == null) return [];

    final currentWeek = _currentPlan!.currentWeek;
    if (currentWeek == null) return [];

    return _currentPlan!.getSessionsForWeek(currentWeek);
  }

  // Get completion percentage for the current plan
  double getCurrentPlanCompletionPercentage() {
    if (_currentPlan == null || _currentPlan!.sessions.isEmpty) return 0.0;

    final totalSessions = _currentPlan!.sessions.length;
    final completedSessions =
        _sessionCompletionStatus.values.where((v) => v).length;

    // Avoid division by zero
    if (totalSessions == 0) return 0.0;

    return completedSessions / totalSessions;
  }

  // Refresh plans from database
  Future<void> refreshPlans() async {
    print("Refreshing training plans...");
    await _loadAvailablePlans();
    await _loadCurrentPlan();
    // No need to notifyListeners here as the load methods already do
  }

  // --- CSV Loading Logic ---

  Future<void> _loadPlansFromCsvAndSaveToDb() async {
    try {
      // Define Plan Metadata (adjust descriptions/durations as needed)
      final plansMeta = [
        {
          'name': "Beginner 5K",
          'level': TrainingPlanLevel.beginner,
          'description':
              "An 8-week plan designed for beginners to build up to running a 5K race.",
          'durationWeeks': 8, // Adjust if CSV has different duration
          'goalType': "5K",
          'csvColumnIndex': 3, // Index of 'Beginner Workout' column
        },
        {
          'name': "Intermediate 10K",
          'level': TrainingPlanLevel.intermediate,
          'description':
              "A 10-week plan for runners who can already run 5K and want to progress to 10K.",
          'durationWeeks': 10, // Adjust if CSV has different duration
          'goalType': "10K",
          'csvColumnIndex': 4, // Index of 'Intermediate Workout' column
        },
        {
          'name': "Advanced Half Marathon",
          'level': TrainingPlanLevel.advanced,
          'description':
              "A 12-week plan for experienced runners preparing for a half marathon.",
          'durationWeeks': 12, // Adjust if CSV has different duration
          'goalType': "Half Marathon",
          'csvColumnIndex': 5, // Index of 'Advanced Workout' column
        },
      ];

      // 1. Save Plan Metadata first to get IDs
      final Map<String, int> planNameToId = {};
      for (var meta in plansMeta) {
        final planModel = TrainingPlanModel(
          name: meta['name'] as String,
          level: meta['level'] as TrainingPlanLevel,
          description: meta['description'] as String,
          durationWeeks: meta['durationWeeks'] as int,
          goalType: meta['goalType'] as String,
          sessions: [], // Sessions added later
          isActive: false, // Initially inactive
          startDate: null,
        );
        // Use StorageService to save plan
        final planId = await _storageService.saveTrainingPlan(planModel);
        planNameToId[meta['name'] as String] = planId;
        print("Saved plan '${meta['name']}' with ID: $planId");
      }

      // 2. Read and Parse CSV
      // Assuming the CSV is in the assets folder and declared in pubspec.yaml
      String csvString; // Changed final to non-final
      try {
        // Load the CSV file from assets
        csvString = await rootBundle.loadString(
          'assets/data/predifined_workouts.csv',
        );
        print("Successfully loaded CSV from assets.");
      } catch (e) {
        print("Error loading CSV from assets: $e");
        // Attempt to load from direct path as fallback (useful for testing/dev)
        final filePath = 'TheRunningAPPFinal/predifined_workouts.csv';
        final file = File(filePath);
        if (await file.exists()) {
          print("Loading CSV from direct path: $filePath");
          csvString = await file.readAsString(encoding: utf8);
        } else {
          print("Error: CSV file not found at $filePath or in assets.");
          return; // Cannot proceed without CSV data
        }
      }

      final List<List<dynamic>> csvTable = const CsvToListConverter().convert(
        csvString,
      );

      // 3. Iterate CSV rows and save sessions
      if (csvTable.length <= 1) {
        print("Error: CSV file has no data rows.");
        return;
      }

      // Skip header row (index 0)
      for (int i = 1; i < csvTable.length; i++) {
        final row = csvTable[i];

        // Basic validation
        if (row.length < 6) {
          print("Skipping malformed CSV row ${i + 1}: $row");
          continue;
        }

        // Ignore the event rows at the end
        if (row[0] is String && (row[0] as String).toLowerCase() == 'event')
          break;

        try {
          final week = int.tryParse(row[1]?.toString() ?? '');
          final dayOfWeek = int.tryParse(
            row[2]?.toString() ?? '',
          ); // Day within the week (1-7)

          if (week == null ||
              dayOfWeek == null ||
              week <= 0 ||
              dayOfWeek <= 0) {
            print("Skipping row ${i + 1} due to invalid week/day: $row");
            continue;
          }

          // Calculate overall day number
          final dayNumber = (week - 1) * 7 + dayOfWeek;

          // Create sessions for each plan level defined in meta
          for (var meta in plansMeta) {
            final planName = meta['name'] as String;
            final planId = planNameToId[planName];
            final columnIndex = meta['csvColumnIndex'] as int;

            if (planId == null) {
              print("Error: Could not find ID for plan '$planName'");
              continue;
            }

            if (columnIndex >= row.length ||
                row[columnIndex] == null ||
                row[columnIndex].toString().trim().isEmpty) {
              // print("Skipping session for plan '$planName' on row ${i+1}: No description found at index $columnIndex.");
              continue; // No workout defined for this plan on this day
            }

            final description = row[columnIndex].toString().trim();

            final session = TrainingSessionModel(
              planId: planId,
              dayNumber: dayNumber,
              description: description,
              // Other fields like targetDuration, intervals, etc., are null
              // as we are only parsing the description string for now.
              isCompleted: false,
            );

            // Use StorageService to save session
            await _storageService.saveTrainingSession(session);
          }
        } catch (e) {
          print("Error processing CSV row ${i + 1}: $row. Error: $e");
        }
      }
      print("Finished processing CSV and saving sessions to DB.");
    } catch (e) {
      print('FATAL Error loading plans from CSV and saving to DB: $e');
      // Consider how to handle this failure - maybe delete partial plans?
    }
  }

  // Removed _createDefaultTrainingPlans and related session creation methods
}
