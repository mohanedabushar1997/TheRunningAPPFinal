import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'controllers/achievements_provider.dart';
import 'controllers/settings_provider.dart';
import 'controllers/theme_provider.dart';
import 'controllers/tracking_provider.dart';
import 'controllers/training_plan_provider.dart';
import 'controllers/user_provider.dart';
import 'controllers/voice_coaching_provider.dart';
import 'controllers/workout_provider.dart';
import 'views/splash_screen.dart';
import 'views/profile_setup_screen.dart';
import 'views/home_screen.dart';
import 'views/workout_preparation_screen.dart';
import 'views/active_workout_screen.dart';
import 'views/workout_summary_screen.dart';
import 'views/training_plans_screen.dart';
import 'views/training_plan_details_screen.dart';
import 'data/database_helper.dart';
import 'models/workout_model.dart';
import 'services/location_service.dart'; // Import LocationService
import 'services/calculation_service.dart'; // Import CalculationService
import 'services/audio_service.dart'; // Import AudioService

void main() async {
  // Ensure Flutter is initialized
  WidgetsFlutterBinding.ensureInitialized();

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

class FitStrideApp extends StatelessWidget {
  final LocationService locationService;
  final CalculationService calculationService;
  final AudioService audioService;

  const FitStrideApp({
    super.key,
    required this.locationService,
    required this.calculationService,
    required this.audioService,
  });

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => ThemeProvider()),
        ChangeNotifierProvider(create: (_) => SettingsProvider()),
        ChangeNotifierProvider(create: (_) => UserProvider()),
        // Pass required services to TrackingProvider
        ChangeNotifierProvider(
          create:
              (_) => TrackingProvider(
                locationService: locationService,
                calculationService: calculationService,
              ),
        ),
        ChangeNotifierProvider(create: (_) => WorkoutProvider()),
        ChangeNotifierProvider(create: (_) => AchievementsProvider()),
        ChangeNotifierProvider(create: (_) => TrainingPlanProvider()),
        // Pass required service to VoiceCoachingProvider
        ChangeNotifierProvider(
          create: (_) => VoiceCoachingProvider(audioService: audioService),
        ),
      ],
      child: Consumer<ThemeProvider>(
        builder: (context, themeProvider, child) {
          return MaterialApp(
            title: 'FitStride',
            // Access themes statically via the class name
            theme: ThemeProvider.lightTheme,
            darkTheme: ThemeProvider.darkTheme,
            themeMode: themeProvider.themeMode,
            home: const SplashScreen(),
            onGenerateRoute: (settings) {
              // Handle route generation based on route name and arguments
              switch (settings.name) {
                case '/':
                  return MaterialPageRoute(
                    builder: (_) => const SplashScreen(),
                  );
                case '/profile_setup':
                  return MaterialPageRoute(
                    builder: (_) => const ProfileSetupScreen(),
                  );
                case '/home':
                  return MaterialPageRoute(builder: (_) => const HomeScreen());
                case '/workout_preparation':
                  return MaterialPageRoute(
                    builder: (_) => const WorkoutPreparationScreen(),
                  );
                case '/active_workout':
                  return MaterialPageRoute(
                    builder: (_) => const ActiveWorkoutScreen(),
                  );
                case '/workout_summary':
                  // Extract the workout argument safely
                  final workout = settings.arguments;
                  if (workout is WorkoutModel) {
                    return MaterialPageRoute(
                      builder: (_) => WorkoutSummaryScreen(workout: workout),
                    );
                  }
                  // Handle cases where argument is missing or wrong type
                  print(
                    "Error: Invalid argument type for /workout_summary route.",
                  );
                  return MaterialPageRoute(
                    builder: (_) => const HomeScreen(),
                  ); // Fallback
                case '/training_plans':
                  return MaterialPageRoute(
                    builder: (_) => const TrainingPlansScreen(),
                  );
                case '/training_plan_details':
                  // Extract the plan ID argument safely
                  final planId = settings.arguments;
                  if (planId is String) {
                    // Or int, depending on expected type
                    return MaterialPageRoute(
                      builder: (_) => TrainingPlanDetailsScreen(planId: planId),
                    );
                  }
                  // Handle cases where argument is missing or wrong type
                  print(
                    "Error: Invalid argument type for /training_plan_details route.",
                  );
                  return MaterialPageRoute(
                    builder: (_) => const TrainingPlansScreen(),
                  ); // Fallback
                default:
                  // If the route is not recognized, navigate to the splash screen
                  return MaterialPageRoute(
                    builder: (_) => const SplashScreen(),
                  );
              }
            },
          );
        },
      ),
    );
  }
}
