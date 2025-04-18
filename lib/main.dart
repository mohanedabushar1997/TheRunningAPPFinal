import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'controllers/user_provider.dart';
import 'controllers/workout_provider.dart';
import 'controllers/training_plan_provider.dart';
import 'controllers/settings_provider.dart';
import 'controllers/theme_provider.dart';
import 'controllers/achievements_provider.dart';
import 'controllers/tracking_provider.dart';
import 'controllers/voice_coaching_provider.dart';
import 'views/home_screen.dart'; // Import HomeScreen

void main() {
  // Ensure Flutter bindings are initialized
  WidgetsFlutterBinding.ensureInitialized();

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => UserProvider()),
        ChangeNotifierProvider(create: (_) => WorkoutProvider()),
        ChangeNotifierProvider(create: (_) => TrainingPlanProvider()),
        ChangeNotifierProvider(create: (_) => SettingsProvider()),
        ChangeNotifierProvider(create: (_) => ThemeProvider()),
        ChangeNotifierProvider(create: (_) => AchievementsProvider()),
        ChangeNotifierProvider(create: (_) => TrackingProvider()),
        ChangeNotifierProvider(create: (_) => VoiceCoachingProvider()),
      ],
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    // Access ThemeProvider
    final themeProvider = Provider.of<ThemeProvider>(context);

    return MaterialApp(
      title: 'The Running App', // Updated App Title
      themeMode: themeProvider.themeMode, // Use ThemeProvider
      theme: ThemeProvider.lightTheme, // Use defined light theme
      darkTheme: ThemeProvider.darkTheme, // Use defined dark theme
      // TODO: Implement routing and initial screen logic (e.g., check if profile exists)
      home: const HomeScreen(), // Use HomeScreen
    );
  }
}

// Removed PlaceholderHomeScreen class
