import 'package:flutter/material.dart';
import 'dart:async';
import 'package:provider/provider.dart';
import '../controllers/user_provider.dart';
import '../controllers/settings_provider.dart'; // Import SettingsProvider
import '../config/environment_config.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _fadeInAnimation;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();

    // Setup animations
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    );

    _fadeInAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: const Interval(0.0, 0.65, curve: Curves.easeOut),
      ),
    );

    _scaleAnimation = Tween<double>(begin: 0.8, end: 1.0).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: const Interval(0.0, 0.65, curve: Curves.easeOut),
      ),
    );

    // Start animation
    _animationController.forward();

    // Start timer for navigation after animation + delay
    Timer(
      const Duration(milliseconds: 2500),
      _navigateToNextScreen,
    ); // Wait for animation (1500ms) + buffer (1000ms)
  }

  void _navigateToNextScreen() {
    // Ensure the widget is still mounted before accessing context or navigating
    if (!mounted) return;

    // Access providers safely
    final userProvider = Provider.of<UserProvider>(context, listen: false);
    final settingsProvider = Provider.of<SettingsProvider>(
      context,
      listen: false,
    );

    // Check if profile is created
    if (userProvider.isProfileCreated) {
      Navigator.pushReplacementNamed(context, '/home');
    } else {
      // If profile doesn't exist, check if onboarding is complete
      if (settingsProvider.isOnboardingComplete) {
        Navigator.pushReplacementNamed(context, '/profile_setup');
      } else {
        Navigator.pushReplacementNamed(context, '/onboarding');
      }
    }
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: theme.colorScheme.background,
      body: Center(
        child: AnimatedBuilder(
          animation: _animationController,
          builder: (context, child) {
            return FadeTransition(
              opacity: _fadeInAnimation,
              child: ScaleTransition(
                scale: _scaleAnimation,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // App Logo - Use Image asset
                    SizedBox(
                      width: 120,
                      height: 120,
                      child: ClipRRect(
                        // Optional: Clip if the image isn't perfectly round/square
                        borderRadius: BorderRadius.circular(24),
                        child: Image.asset(
                          'assets/images/foreground icon.png', // Use the actual logo path
                          fit: BoxFit.contain, // Adjust fit as needed
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),

                    // App Name - Use EnvironmentConfig for potential flavor differences
                    Text(
                      EnvironmentConfig
                          .instance
                          .appName, // Use configured app name
                      style: theme.textTheme.headlineLarge?.copyWith(
                        color: theme.colorScheme.primary,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1.2,
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Tagline
                    Text(
                      'Your Running Journey Starts Here',
                      style: theme.textTheme.bodyLarge?.copyWith(
                        color: theme.colorScheme.onBackground.withOpacity(0.7),
                      ),
                    ),
                    const SizedBox(height: 48),

                    // Loading Indicator
                    SizedBox(
                      width: 40,
                      height: 40,
                      child: CircularProgressIndicator(
                        valueColor: AlwaysStoppedAnimation<Color>(
                          theme.colorScheme.secondary,
                        ),
                        strokeWidth: 3,
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
