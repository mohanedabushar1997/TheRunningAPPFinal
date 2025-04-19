import 'package:flutter/foundation.dart';
import '../models/weight_record_model.dart';
import '../services/storage_service.dart';

class WeightProvider with ChangeNotifier {
  final StorageService _storageService = StorageService();

  List<WeightRecordModel> _weightRecords = [];
  bool _isLoading = false;

  List<WeightRecordModel> get weightRecords => _weightRecords;
  bool get isLoading => _isLoading;

  WeightProvider() {
    loadWeightRecords();
  }

  Future<void> loadWeightRecords() async {
    _isLoading = true;
    notifyListeners();
    try {
      _weightRecords = await _storageService.getWeightRecords();
      // Ensure records are sorted by date, newest first (StorageService already does this)
      // _weightRecords.sort((a, b) => b.date.compareTo(a.date));
    } catch (e) {
      print("Error loading weight records: $e");
      _weightRecords = [];
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> addWeightRecord(
    double weight, {
    DateTime? date,
    String? notes,
  }) async {
    final newRecord = WeightRecordModel(
      date: date ?? DateTime.now(),
      weight: weight,
      notes: notes,
    );
    try {
      await _storageService.saveWeightRecord(newRecord);
      await loadWeightRecords(); // Reload list after adding
      return true;
    } catch (e) {
      print("Error adding weight record: $e");
      return false;
    }
  }

  Future<bool> updateWeightRecord(WeightRecordModel record) async {
    try {
      await _storageService.saveWeightRecord(record); // save handles update
      await loadWeightRecords(); // Reload list after updating
      return true;
    } catch (e) {
      print("Error updating weight record: $e");
      return false;
    }
  }

  Future<bool> deleteWeightRecord(int id) async {
    try {
      await _storageService.deleteWeightRecord(id);
      await loadWeightRecords(); // Reload list after deleting
      return true;
    } catch (e) {
      print("Error deleting weight record: $e");
      return false;
    }
  }

  // Add methods for calculating trends or getting specific data if needed
}
