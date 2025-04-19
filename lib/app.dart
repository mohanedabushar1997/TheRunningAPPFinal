import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'config/environment_config.dart'; // Import EnvironmentConfig
import 'controllers/achievements_provider.dart';
import 'controllers/settings_provider.dart';
import 'controllers/theme_provider.dart';
import 'controllers/tracking_provider.dart';
import 'controllers/training_plan_provider.dart';
import 'controllers/user_provider.dart';
import 'controllers/voice_coaching_provider.dart';
import 'controllers/workout_provider.dart';
import 'controllers/weight_provider.dart'; // Import WeightProvider
import 'views/splash_screen.dart';
import 'views/profile_setup_screen.dart';
import 'views/home_screen.dart';
import 'views/workout_preparation_screen.dart';
import 'views/active_workout_screen.dart';
import 'views/workout_summary_screen.dart';
import 'views/training_plans_screen.dart';
import 'views/training_plan_details_screen.dart';
import 'views/onboarding_screen.dart';
import 'views/statistics_screen.dart';
import 'views/settings_screen.dart';
import 'views/backup_restore_screen.dart'; // Import BackupRestoreScreen
import 'views/weight_entry_screen.dart'; // Import WeightEntryScreen
import 'models/workout_model.dart';
import 'services/location_service.dart';
import 'services/calculation_service.dart';
import 'services/audio_service.dart';

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
        // Use ChangeNotifierProxyProvider to pass SettingsProvider to TrackingProvider
        ChangeNotifierProxyProvider<SettingsProvider, TrackingProvider>(
          create:
              (_) => TrackingProvider(
                locationService: locationService,
                calculationService: calculationService,
                settingsProvider: Provider.of<SettingsProvider>(
                  context,
                  listen: false,
                ), // Provide initial settings
                // UserProvider could also be passed here if needed
              ),
          update:
              (_, settings, previousTracking) =>
                  previousTracking!..updateSettings(
                    settings,
                  ), // Optional: Method in TrackingProvider to react to settings changes
        ),
        ChangeNotifierProvider(
          create:
              (_) => WorkoutProvider(
                // Pass CalculationService and UserProvider if needed
                calculationService: calculationService,
                user:
                    Provider.of<UserProvider>(
                      context,
                      listen: false,
                    ).currentUser,
              ),
        ),
        ChangeNotifierProvider(create: (_) => AchievementsProvider()),
        ChangeNotifierProvider(create: (_) => TrainingPlanProvider()),
        ChangeNotifierProvider(
          create: (_) => VoiceCoachingProvider(audioService: audioService),
        ),
        ChangeNotifierProvider(
          create: (_) => WeightProvider(),
        ), // Add WeightProvider
      ],
      child: Consumer<ThemeProvider>(
        builder: (context, themeProvider, child) {
          return MaterialApp(
            // Use appName from EnvironmentConfig
            title: EnvironmentConfig.instance.appName,
            theme: ThemeProvider.lightTheme,
            darkTheme: ThemeProvider.darkTheme,
            themeMode: themeProvider.themeMode,
            home: const SplashScreen(),
            onGenerateRoute: (settings) {
              switch (settings.name) {
                case '/':
                  return MaterialPageRoute(
                    builder: (_) => const SplashScreen(),
                  );
                case '/onboarding': // Add onboarding route
                  return MaterialPageRoute(
                    builder: (_) => const OnboardingScreen(),
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
                  final workout = settings.arguments;
                  if (workout is WorkoutModel) {
                    return MaterialPageRoute(
                      builder: (_) => WorkoutSummaryScreen(workout: workout),
                    );
                  }
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
                  final planId = settings.arguments;
                  if (planId is String) {
                    return MaterialPageRoute(
                      builder: (_) => TrainingPlanDetailsScreen(planId: planId),
                    );
                  }
                  print(
                    "Error: Invalid argument type for /training_plan_details route.",
                  );
                  return MaterialPageRoute(
                    builder: (_) => const TrainingPlansScreen(),
                  ); // Fallback
                case '/statistics': // Add statistics route
                  return MaterialPageRoute(
                    builder: (_) => const StatisticsScreen(),
                  );
                case '/settings': // Add settings route
                  return MaterialPageRoute(
                    builder: (_) => const SettingsScreen(),
                  );
                case '/backup_restore': // Add backup/restore route
                  return MaterialPageRoute(
                    builder: (_) => const BackupRestoreScreen(),
                  );
                case '/weight_entry': // Add weight entry route
                  return MaterialPageRoute(
                    builder: (_) => const WeightEntryScreen(),
                  );
                default:
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
