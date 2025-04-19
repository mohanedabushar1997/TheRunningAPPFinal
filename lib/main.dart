import 'package:flutter/material.dart';
import 'app.dart'; // Import the FitStrideApp widget
import 'config/environment_config.dart'; // Import EnvironmentConfig
import 'data/database_helper.dart';
import 'services/location_service.dart';
import 'services/calculation_service.dart';
import 'services/audio_service.dart';

// Common function to run the app with a specific environment
Future<void> runFitStrideApp(Environment environment) async {
  // Ensure Flutter is initialized
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Environment Config
  EnvironmentConfig.init(environment: environment);

  // Initialize database
  final dbHelper = DatabaseHelper();
  await dbHelper.database; // Ensure DB is initialized before providers need it

  // Instantiate services needed by providers
  final locationService = LocationService();
  final calculationService = CalculationService();
  final audioService = AudioService();

  runApp(
    FitStrideApp(
      locationService: locationService,
      calculationService: calculationService,
      audioService: audioService,
    ),
  );
}
