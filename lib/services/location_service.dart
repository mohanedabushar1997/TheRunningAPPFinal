import 'dart:async';
import 'package:geolocator/geolocator.dart';

class LocationService {
  StreamSubscription<Position>? _positionStreamSubscription;
  bool _isTracking = false;

  // Stream controller to broadcast position updates
  final StreamController<Position> _positionController =
      StreamController<Position>.broadcast();
  Stream<Position> get positionStream => _positionController.stream;

  // Check if location services are enabled
  Future<bool> isLocationServiceEnabled() async {
    return await Geolocator.isLocationServiceEnabled();
  }

  // Check and request location permissions
  Future<LocationPermission> checkAndRequestPermission() async {
    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        // Permissions are denied, next time you could try requesting permissions again
        // (this is also where Android's shouldShowRequestPermissionRationale returns true).
        // According to Android guidelines your App should show an explanatory UI now.
        print('Location permissions are denied');
        return permission;
      }
    }

    if (permission == LocationPermission.deniedForever) {
      // Permissions are denied forever, handle appropriately.
      print(
        'Location permissions are permanently denied, we cannot request permissions.',
      );
      return permission;
    }
    // When we reach here, permissions are granted and we can continue accessing the position of the device.
    print('Location permissions granted.');
    return permission;
  }

  // Start listening to location updates
  Future<void> startTracking({
    LocationAccuracy accuracy =
        LocationAccuracy.high, // Default to high accuracy
    int distanceFilter = 10, // Minimum distance (meters) to trigger update
  }) async {
    if (_isTracking) return; // Already tracking

    bool serviceEnabled = await isLocationServiceEnabled();
    if (!serviceEnabled) {
      print("Location services disabled.");
      // TODO: Optionally prompt user to enable location services
      return;
    }

    LocationPermission permission = await checkAndRequestPermission();
    if (permission == LocationPermission.denied ||
        permission == LocationPermission.deniedForever) {
      print("Location permission not granted.");
      return;
    }

    print("Starting location tracking...");
    _isTracking = true;

    // Configure location settings for Android
    final LocationSettings locationSettings = AndroidSettings(
      accuracy: accuracy,
      distanceFilter: distanceFilter,
      // foregroundNotificationConfig: const ForegroundNotificationConfig( // TODO: Configure foreground notification for background tracking
      //     notificationText: "FitStride is tracking your workout",
      //     notificationTitle: "Workout in Progress",
      //     enableWakeLock: true,
      // ),
      // intervalDuration: const Duration(seconds: 5), // Optional: Adjust update interval
    );

    _positionStreamSubscription = Geolocator.getPositionStream(
      locationSettings: locationSettings,
    ).listen(
      (Position position) {
        print("Position update: ${position.latitude}, ${position.longitude}");
        _positionController.add(position); // Broadcast the position
      },
      onError: (error) {
        print("Error getting position stream: $error");
        // TODO: Handle stream errors (e.g., notify user, attempt restart)
        stopTracking();
      },
      onDone: () {
        print("Position stream done.");
        _isTracking = false;
      },
    );
  }

  // Stop listening to location updates
  void stopTracking() {
    print("Stopping location tracking...");
    _positionStreamSubscription?.cancel();
    _positionStreamSubscription = null;
    _isTracking = false;
  }

  // Get current location once
  Future<Position?> getCurrentLocation() async {
    bool serviceEnabled = await isLocationServiceEnabled();
    if (!serviceEnabled) {
      print("Location services disabled.");
      return null;
    }

    LocationPermission permission = await checkAndRequestPermission();
    if (permission == LocationPermission.denied ||
        permission == LocationPermission.deniedForever) {
      print("Location permission not granted.");
      return null;
    }

    try {
      return await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.medium,
      );
    } catch (e) {
      print("Error getting current location: $e");
      return null;
    }
  }

  // Dispose the stream controller when the service is no longer needed
  void dispose() {
    _positionStreamSubscription?.cancel();
    _positionController.close();
  }
}
