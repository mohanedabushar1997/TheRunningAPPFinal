import 'package:flutter/foundation.dart';
import '../data/database_helper.dart';
// TODO: Create TrainingPlan and TrainingSession models

class TrainingPlanProvider with ChangeNotifier {
  final DatabaseHelper _dbHelper = DatabaseHelper();

  // TODO: Define state variables for available plans, current plan, progress, etc.
  // List<TrainingPlanModel> _availablePlans = [];
  // TrainingPlanModel? _currentPlan;
  // Map<int, bool> _sessionCompletionStatus = {}; // Map<sessionId, isCompleted>

  // List<TrainingPlanModel> get availablePlans => _availablePlans;
  // TrainingPlanModel? get currentPlan => _currentPlan;

  TrainingPlanProvider() {
    // TODO: Load available plans and current user plan on initialization
    // _loadAvailablePlans();
    // _loadCurrentPlan();
  }

  // TODO: Implement methods to load plans from DB or predefined data
  // Future<void> _loadAvailablePlans() async { ... }
  // Future<void> _loadCurrentPlan() async { ... }

  // TODO: Implement methods to select, activate, track progress, complete sessions/plans
  // Future<void> selectPlan(int planId) async { ... }
  // Future<void> completeSession(int sessionId) async { ... }
}
