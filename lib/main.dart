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

void main() async {
  // Ensure Flutter is initialized
  WidgetsFlutterBinding.ensureInitialized();
  
  // Initialize database
  final dbHelper = DatabaseHelper();
  await dbHelper.database;
  
  runApp(const FitStrideApp());
}

class FitStrideApp extends StatelessWidget {
  const FitStrideApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => ThemeProvider()),
        ChangeNotifierProvider(create: (_) => SettingsProvider()),
        ChangeNotifierProvider(create: (_) => UserProvider()),
        ChangeNotifierProvider(create: (_) => TrackingProvider()),
        ChangeNotifierProvider(create: (_) => WorkoutProvider()),
        ChangeNotifierProvider(create: (_) => AchievementsProvider()),
        ChangeNotifierProvider(create: (_) => TrainingPlanProvider()),
        ChangeNotifierProvider(create: (_) => VoiceCoachingProvider()),
      ],
      child: Consumer<ThemeProvider>(
        builder: (context, themeProvider, child) {
          return MaterialApp(
            title: 'FitStride',
            theme: themeProvider.lightTheme,
            darkTheme: themeProvider.darkTheme,
            themeMode: themeProvider.themeMode,
            home: const SplashScreen(),
            onGenerateRoute: (settings) {
              // Handle route generation based on route name and arguments
              switch (settings.name) {
                case '/':
                  return MaterialPageRoute(builder: (_) => const SplashScreen());
                case '/profile_setup':
                  return MaterialPageRoute(builder: (_) => const ProfileSetupScreen());
                case '/home':
                  return MaterialPageRoute(builder: (_) => const HomeScreen());
                case '/workout_preparation':
                  return MaterialPageRoute(builder: (_) => const WorkoutPreparationScreen());
                case '/active_workout':
                  return MaterialPageRoute(builder: (_) => const ActiveWorkoutScreen());
                case '/workout_summary':
                  // Extract the workout argument
                  final workout = settings.arguments as WorkoutModel;
                  return MaterialPageRoute(
                    builder: (_) => WorkoutSummaryScreen(workout: workout),
                  );
                case '/training_plans':
                  return MaterialPageRoute(builder: (_) => const TrainingPlansScreen());
                case '/training_plan_details':
                  // Extract the plan ID argument
                  final planId = settings.arguments as String;
                  return MaterialPageRoute(
                    builder: (_) => TrainingPlanDetailsScreen(planId: planId),
                  );
                default:
                  // If the route is not recognized, navigate to the splash screen
                  return MaterialPageRoute(builder: (_) => const SplashScreen());
              }
            },
          );
        },
      ),
    );
  }
}
