import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'services/location_service.dart';
import 'services/calculation_service.dart';
import 'services/audio_service.dart';
import 'controllers/user_provider.dart';
import 'controllers/workout_provider.dart';
import 'controllers/training_plan_provider.dart';
import 'controllers/settings_provider.dart';
import 'controllers/theme_provider.dart';
import 'controllers/achievements_provider.dart';
import 'controllers/tracking_provider.dart';
import 'controllers/voice_coaching_provider.dart';
import 'views/home_screen.dart';
import 'views/profile_setup_screen.dart';
import 'views/splash_screen.dart';

void main() {
  // Ensure Flutter bindings are initialized
  WidgetsFlutterBinding.ensureInitialized();

  // Create service instances
  final locationService = LocationService();
  final calculationService = CalculationService();
  final audioService = AudioService();

  runApp(
    MultiProvider(
      providers: [
        // Providers that don't depend on other providers
        ChangeNotifierProvider(create: (_) => ThemeProvider()),
        ChangeNotifierProvider(create: (_) => SettingsProvider()),
        ChangeNotifierProvider(create: (_) => UserProvider()),
        
        // Providers that depend on other providers or services
        ChangeNotifierProxyProvider<UserProvider, WorkoutProvider>(
          create: (_) => WorkoutProvider(calculationService: calculationService),
          update: (_, userProvider, previous) => WorkoutProvider(
            calculationService: calculationService,
            user: userProvider.currentUser,
          ),
        ),
        ChangeNotifierProvider(create: (_) => TrainingPlanProvider()),
        ChangeNotifierProvider(create: (_) => AchievementsProvider()),
        
        // Tracking provider depends on services
        ChangeNotifierProxyProvider<UserProvider, TrackingProvider>(
          create: (_) => TrackingProvider(
            locationService: locationService,
            calculationService: calculationService,
          ),
          update: (_, userProvider, previous) => TrackingProvider(
            locationService: locationService,
            calculationService: calculationService,
            user: userProvider.currentUser,
          ),
        ),
        
        // Voice coaching provider depends on audio service
        ChangeNotifierProvider(
          create: (_) => VoiceCoachingProvider(audioService: audioService),
        ),
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
    final userProvider = Provider.of<UserProvider>(context);

    return MaterialApp(
      title: 'FitStride',
      themeMode: themeProvider.themeMode,
      theme: ThemeProvider.lightTheme,
      darkTheme: ThemeProvider.darkTheme,
      
      // Implement routing and initial screen logic
      home: FutureBuilder(
        // Wait for user profile to load
        future: Future.delayed(const Duration(milliseconds: 1500), () => userProvider.isProfileCreated),
        builder: (context, snapshot) {
          // Show splash screen while loading
          if (snapshot.connectionState != ConnectionState.done) {
            return const SplashScreen();
          }
          
          // If profile exists, show home screen, otherwise show profile setup
          if (snapshot.data == true) {
            return const HomeScreen();
          } else {
            return const ProfileSetupScreen();
          }
        },
      ),
      
      // Define named routes
      routes: {
        '/home': (context) => const HomeScreen(),
        '/profile_setup': (context) => const ProfileSetupScreen(),
      },
    );
  }
}
