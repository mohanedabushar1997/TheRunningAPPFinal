import 'package:flutter/foundation.dart';
import '../data/database_helper.dart';
import '../models/training_plan_model.dart';
import '../models/training_session_model.dart';

class TrainingPlanProvider with ChangeNotifier {
  final DatabaseHelper _dbHelper = DatabaseHelper();

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
      final plansData = await _dbHelper.getTrainingPlans();
      
      if (plansData.isEmpty) {
        // If no plans in DB, create default plans
        _availablePlans = _createDefaultTrainingPlans();
        
        // Save default plans to DB
        for (var plan in _availablePlans) {
          final planId = await _dbHelper.insertTrainingPlan(plan.toMap());
          
          // Save sessions for this plan
          for (var session in plan.sessions) {
            final sessionWithPlanId = session.copyWith(planId: planId);
            await _dbHelper.insertTrainingSession(sessionWithPlanId.toMap());
          }
        }
      } else {
        // Convert data to models
        List<TrainingPlanModel> plans = [];
        
        for (var planMap in plansData) {
          // Get sessions for this plan
          final sessionsData = await _dbHelper.getTrainingSessionsByPlanId(
            planMap['id'] as int,
          );
          
          final sessions = sessionsData
              .map((sessionMap) => TrainingSessionModel.fromMap(sessionMap))
              .toList();
          
          // Create plan with sessions
          final plan = TrainingPlanModel.fromMap(planMap, sessions: sessions);
          plans.add(plan);
        }
        
        _availablePlans = plans;
      }
    } catch (e) {
      print('Error loading training plans: $e');
      // Fallback to default plans if error
      _availablePlans = _createDefaultTrainingPlans();
    }
    
    _isLoading = false;
    notifyListeners();
  }

  // Load current active plan
  Future<void> _loadCurrentPlan() async {
    try {
      // Find active plan in available plans
      _currentPlan = _availablePlans.firstWhere(
        (plan) => plan.isActive,
        orElse: () => null,
      );
      
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
      final sessionsData = await _dbHelper.getTrainingSessionsByPlanId(planId);
      
      // Create map of session ID to completion status
      _sessionCompletionStatus = {
        for (var session in sessionsData)
          session['id'] as int: (session['is_completed'] as int? ?? 0) == 1,
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
      if (planIndex < 0) return;
      
      // Activate the plan
      final plan = _availablePlans[planIndex];
      final activatedPlan = plan.activate();
      
      // Update in database
      await _dbHelper.updateTrainingPlan(activatedPlan.toMap());
      
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
    if (_currentPlan == null) return;
    
    try {
      // Deactivate the plan
      final deactivatedPlan = _currentPlan!.deactivate();
      
      // Update in database
      await _dbHelper.updateTrainingPlan(deactivatedPlan.toMap());
      
      // Update in state
      final planIndex = _availablePlans.indexWhere((p) => p.id == _currentPlan!.id);
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
    if (_currentPlan == null) return;
    
    try {
      // Find the session
      final sessionIndex = _currentPlan!.sessions.indexWhere((s) => s.id == sessionId);
      if (sessionIndex < 0) return;
      
      // Mark as completed
      final session = _currentPlan!.sessions[sessionIndex];
      final completedSession = session.markCompleted();
      
      // Update in database
      await _dbHelper.updateTrainingSession(completedSession.toMap());
      
      // Update in state
      final updatedSessions = List<TrainingSessionModel>.from(_currentPlan!.sessions);
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
    if (_currentPlan == null) return;
    
    try {
      // Find the session
      final sessionIndex = _currentPlan!.sessions.indexWhere((s) => s.id == sessionId);
      if (sessionIndex < 0) return;
      
      // Mark as not completed
      final session = _currentPlan!.sessions[sessionIndex];
      final uncompletedSession = session.markNotCompleted();
      
      // Update in database
      await _dbHelper.updateTrainingSession(uncompletedSession.toMap());
      
      // Update in state
      final updatedSessions = List<TrainingSessionModel>.from(_currentPlan!.sessions);
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
    final completedSessions = _sessionCompletionStatus.values.where((v) => v).length;
    
    return completedSessions / totalSessions;
  }

  // Create default training plans
  List<TrainingPlanModel> _createDefaultTrainingPlans() {
    return [
      // Beginner 5K Plan (8 weeks)
      TrainingPlanModel(
        name: "Beginner 5K",
        level: TrainingPlanLevel.beginner,
        description: "An 8-week plan designed for beginners to build up to running a 5K race.",
        durationWeeks: 8,
        goalType: "5K",
        sessions: _createBeginner5KSessions(),
      ),
      
      // Intermediate 10K Plan (10 weeks)
      TrainingPlanModel(
        name: "Intermediate 10K",
        level: TrainingPlanLevel.intermediate,
        description: "A 10-week plan for runners who can already run 5K and want to progress to 10K.",
        durationWeeks: 10,
        goalType: "10K",
        sessions: _createIntermediate10KSessions(),
      ),
      
      // Advanced Half Marathon Plan (12 weeks)
      TrainingPlanModel(
        name: "Advanced Half Marathon",
        level: TrainingPlanLevel.advanced,
        description: "A 12-week plan for experienced runners preparing for a half marathon.",
        durationWeeks: 12,
        goalType: "Half Marathon",
        sessions: _createAdvancedHalfMarathonSessions(),
      ),
    ];
  }

  // Create sessions for Beginner 5K plan
  List<TrainingSessionModel> _createBeginner5KSessions() {
    final List<TrainingSessionModel> sessions = [];
    
    // Week 1
    sessions.add(TrainingSessionModel(
      planId: 0, // Will be updated when saved
      dayNumber: 1,
      description: "Walk 5 minutes, then alternate 1 minute running with 1.5 minutes walking. Repeat 8 times, then walk 5 minutes to cool down.",
      targetDuration: Duration(minutes: 30),
    ));
    
    sessions.add(TrainingSessionModel(
      planId: 0,
      dayNumber: 3,
      description: "Walk 5 minutes, then alternate 1 minute running with 1.5 minutes walking. Repeat 8 times, then walk 5 minutes to cool down.",
      targetDuration: Duration(minutes: 30),
    ));
    
    sessions.add(TrainingSessionModel(
      planId: 0,
      dayNumber: 5,
      description: "Walk 5 minutes, then alternate 1 minute running with 1.5 minutes walking. Repeat 8 times, then walk 5 minutes to cool down.",
      targetDuration: Duration(minutes: 30),
    ));
    
    // Week 2
    sessions.add(TrainingSessionModel(
      planId: 0,
      dayNumber: 8,
      description: "Walk 5 minutes, then alternate 1.5 minutes running with 1 minute walking. Repeat 9 times, then walk 5 minutes to cool down.",
      targetDuration: Duration(minutes: 32),
    ));
    
    sessions.add(TrainingSessionModel(
      planId: 0,
      dayNumber: 10,
      description: "Walk 5 minutes, then alternate 1.5 minutes running with 1 minute walking. Repeat 9 times, then walk 5 minutes to cool down.",
      targetDuration: Duration(minutes: 32),
    ));
    
    sessions.add(TrainingSessionModel(
      planId: 0,
      dayNumber: 12,
      description: "Walk 5 minutes, then alternate 1.5 minutes running with 1 minute walking. Repeat 9 times, then walk 5 minutes to cool down.",
      targetDuration: Duration(minutes: 32),
    ));
    
    // Continue with more weeks...
    // Week 3
    sessions.add(TrainingSessionModel(
      planId: 0,
      dayNumber: 15,
      description: "Walk 5 minutes, then alternate 2 minutes running with 1 minute walking. Repeat 8 times, then walk 5 minutes to cool down.",
      targetDuration: Duration(minutes: 34),
    ));
    
    // Add more sessions for the remaining weeks...
    
    return sessions;
  }

  // Create sessions for Intermediate 10K plan
  List<TrainingSessionModel> _createIntermediate10KSessions() {
    final List<TrainingSessionModel> sessions = [];
    
    // Week 1
    sessions.add(TrainingSessionModel(
      planId: 0, // Will be updated when saved
      dayNumber: 1,
      description: "Easy run: 3 km at comfortable pace",
      targetDistance: 3.0,
      targetDuration: Duration(minutes: 20),
    ));
    
    sessions.add(TrainingSessionModel(
      planId: 0,
      dayNumber: 3,
      description: "Interval training: 5 x 400m fast with 200m recovery jog between each",
      intervals: "5x400m/200m",
      targetDistance: 4.0,
    ));
    
    sessions.add(TrainingSessionModel(
      planId: 0,
      dayNumber: 5,
      description: "Tempo run: 2 km at moderate pace",
      targetDistance: 2.0,
      targetDuration: Duration(minutes: 12),
    ));
    
    sessions.add(TrainingSessionModel(
      planId: 0,
      dayNumber: 7,
      description: "Long run: 5 km at easy pace",
      targetDistance: 5.0,
      targetDuration: Duration(minutes: 35),
    ));
    
    // Add more sessions for the remaining weeks...
    
    return sessions;
  }

  // Create sessions for Advanced Half Marathon plan
  List<TrainingSessionModel> _createAdvancedHalfMarathonSessions() {
    final List<TrainingSessionModel> sessions = [];
    
    // Week 1
    sessions.add(TrainingSessionModel(
      planId: 0, // Will be updated when saved
      dayNumber: 1,
      description: "Easy run: 8 km at comfortable pace",
      targetDistance: 8.0,
      targetDuration: Duration(minutes: 45),
    ));
    
    sessions.add(TrainingSessionModel(
      planId: 0,
      dayNumber: 2,
      description: "Recovery run: 5 km very easy",
      targetDistance: 5.0,
      targetDuration: Duration(minutes: 30),
    ));
    
    sessions.add(TrainingSessionModel(
      planId: 0,
      dayNumber: 4,
      description: "Speed work: 8 x 800m at 5K pace with 400m recovery jog",
      intervals: "8x800m/400m",
      targetDistance: 10.0,
    ));
    
    sessions.add(TrainingSessionModel(
      planId: 0,
      dayNumber: 6,
      description: "Tempo run: 3 km easy, 5 km at half marathon pace, 2 km easy",
      targetDistance: 10.0,
    ));
    
    sessions.add(TrainingSessionModel(
      planId: 0,
      dayNumber: 7,
      description: "Long run: 15 km at easy pace",
      targetDistance: 15.0,
      targetDuration: Duration(minutes: 90),
    ));
    
    // Add more sessions for the remaining weeks...
    
    return sessions;
  }
}
