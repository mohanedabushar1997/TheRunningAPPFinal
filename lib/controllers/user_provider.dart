import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';
import '../data/database_helper.dart';
import '../models/user_model.dart'; // Import UserModel

class UserProvider with ChangeNotifier {
  final DatabaseHelper _dbHelper = DatabaseHelper();
  final Uuid _uuid = const Uuid();
  SharedPreferences? _prefs;

  String? _deviceId; // Holds the unique device ID
  UserModel? _currentUser; // Holds the current user's profile data (UserModel)

  String? get deviceId => _deviceId;
  UserModel? get currentUser => _currentUser; // Return UserModel?

  bool get isProfileCreated => _currentUser != null;

  UserProvider() {
    _initializeUser();
  }

  Future<void> _initializeUser() async {
    await _loadOrGenerateDeviceId(); // Ensure device ID is loaded/generated first
    if (_deviceId != null) {
      await _loadUserProfile(); // Then load the profile associated with that ID
    }
  }

  Future<void> _initPrefs() async {
    _prefs ??= await SharedPreferences.getInstance();
  }

  // Load Device ID from storage or generate a new one (Tasks 3.1.1, 3.1.2, 3.1.3, 3.1.4)
  Future<void> _loadOrGenerateDeviceId() async {
    await _initPrefs();
    _deviceId = _prefs?.getString('device_id');
    if (_deviceId == null) {
      _deviceId = _uuid.v4(); // Generate UUID v4
      await _prefs?.setString('device_id', _deviceId!);
      print("Generated new device ID: $_deviceId");
    } else {
      print("Loaded existing device ID: $_deviceId");
    }
    // Note: Persistence across reinstalls (Task 3.1.6) is limited with SharedPreferences.
    // A reinstall will likely generate a new ID unless platform-specific backup exists.
    notifyListeners(); // Notify listeners about potential deviceId change/load
  }

  // Load user profile from DB using the stored device ID (Task 3.1.4)
  Future<void> _loadUserProfile() async {
    if (_deviceId == null) {
      print("Cannot load profile, device ID is null.");
      return;
    }
    print("Loading profile for device ID: $_deviceId");
    Map<String, dynamic>? userDataMap = await _dbHelper.getUserByDeviceId(
      _deviceId!,
    );
    if (userDataMap != null) {
      _currentUser = UserModel.fromMap(userDataMap); // Convert map to UserModel
      print("User profile loaded: $_currentUser");
    } else {
      _currentUser = null; // No profile found for this device ID
      print("No user profile found for device ID.");
    }
    notifyListeners();
  }

  // Create/update user profile (Task 3.2.7, 3.2.11)
  // Accept UserModel
  Future<void> saveUserProfile(UserModel userProfile) async {
    if (_deviceId == null) {
      print("Cannot save profile, device ID is null.");
      await _loadOrGenerateDeviceId();
      if (_deviceId == null) return;
    }

    // Ensure the UserModel has the correct deviceId (should match the provider's)
    // If they differ, it indicates a logic error elsewhere.
    if (userProfile.deviceId != _deviceId) {
      print("Error: Trying to save profile with mismatched device ID.");
      // Potentially throw an error or handle appropriately
      // For now, force the provider's deviceId onto the model being saved
      userProfile = userProfile.copyWith(deviceId: _deviceId);
    }

    // Convert UserModel to Map for database operation
    Map<String, dynamic> userMap = userProfile.toMap();

    // TODO: Use StorageService instead of direct dbHelper access?
    final existingUserMap = await _dbHelper.getUserByDeviceId(_deviceId!);
    if (existingUserMap != null) {
      // Ensure the ID from the loaded user is used for the update, if necessary
      // userMap['id'] = existingUserMap['id']; // Uncomment if dbHelper.updateUser requires ID
      await _dbHelper.updateUser(userMap);
      print("Updated user profile for device ID: $_deviceId");
    } else {
      await _dbHelper.insertUser(userMap);
      print("Created new user profile for device ID: $_deviceId");
    }

    _currentUser =
        userProfile; // Update local state with the UserModel instance
    notifyListeners();
  }

  // Delete user profile (Task 3.3.5)
  Future<void> deleteUserProfile() async {
    if (_deviceId == null) {
      print("Cannot delete profile, device ID is null.");
      return;
    }
    // TODO: Use StorageService?
    await _dbHelper.deleteUser(_deviceId!);
    _currentUser = null; // Clear local state
    print("Deleted user profile for device ID: $_deviceId");
    // Optionally, delete the device ID itself from SharedPreferences?
    // await _prefs?.remove('device_id');
    // _deviceId = null;
    notifyListeners();
  }
}
