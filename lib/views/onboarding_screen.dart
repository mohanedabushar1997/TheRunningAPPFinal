import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart'; // To save completion flag
import '../widgets/primary_button.dart';
import '../controllers/theme_provider.dart'; // For colors

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final PageController _pageController = PageController();
  int _currentPage = 0;

  // Define onboarding pages content
  final List<Map<String, String>> _onboardingPages = [
    {
      'title': 'Welcome to FitStride!',
      'description':
          'Your personal running companion, designed for privacy and performance.',
      'image': 'assets/images/onboarding_welcome.png', // Placeholder image path
    },
    {
      'title': 'Track Your Runs',
      'description':
          'Accurately track your distance, pace, calories, and route using GPS. All data stays on your device.',
      'image': 'assets/images/onboarding_track.png', // Placeholder image path
    },
    {
      'title': 'Training Plans & Coaching',
      'description':
          'Choose from various training plans and get optional voice coaching during your workouts.',
      'image': 'assets/images/onboarding_plans.png', // Placeholder image path
    },
    {
      'title': 'Stay Motivated',
      'description':
          'Monitor your progress, earn achievements, and track personal records. Ready to start?',
      'image':
          'assets/images/onboarding_motivated.png', // Placeholder image path
    },
  ];

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  // Mark onboarding as complete and navigate
  Future<void> _completeOnboarding() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('onboarding_complete', true);
    if (mounted) {
      Navigator.pushReplacementNamed(context, '/profile_setup');
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: PageView.builder(
                controller: _pageController,
                itemCount: _onboardingPages.length,
                onPageChanged: (index) {
                  setState(() {
                    _currentPage = index;
                  });
                },
                itemBuilder: (context, index) {
                  return _buildPage(
                    context: context,
                    title: _onboardingPages[index]['title']!,
                    description: _onboardingPages[index]['description']!,
                    imagePath: _onboardingPages[index]['image']!,
                  );
                },
              ),
            ),
            _buildControls(context, theme),
          ],
        ),
      ),
    );
  }

  Widget _buildPage({
    required BuildContext context,
    required String title,
    required String description,
    required String imagePath,
  }) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.all(32.0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Placeholder for image - replace with actual Image.asset if images exist
          Container(
            height: 250,
            width: double.infinity,
            decoration: BoxDecoration(
              color: theme.colorScheme.surface,
              borderRadius: BorderRadius.circular(16),
              // image: DecorationImage(
              //   image: AssetImage(imagePath),
              //   fit: BoxFit.contain, // Or BoxFit.cover
              //   onError: (exception, stackTrace) {
              //     // Handle image loading error gracefully
              //     print('Error loading onboarding image: $imagePath');
              //   },
              // ),
            ),
            child: Center(
              child: Icon(Icons.image, size: 100, color: theme.dividerColor),
            ), // Placeholder icon
          ),
          const SizedBox(height: 40),
          Text(
            title,
            style: theme.textTheme.headlineMedium?.copyWith(
              fontWeight: FontWeight.bold,
              color: theme.colorScheme.primary,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          Text(
            description,
            style: theme.textTheme.bodyLarge,
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildControls(BuildContext context, ThemeData theme) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 20.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Skip Button (only show on first few pages)
          _currentPage < _onboardingPages.length - 1
              ? TextButton(
                onPressed: _completeOnboarding,
                child: const Text('Skip'),
              )
              : const SizedBox(width: 60), // Placeholder for alignment
          // Dots Indicator
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(
              _onboardingPages.length,
              (index) => _buildDot(index, theme),
            ),
          ),

          // Next / Done Button
          _currentPage == _onboardingPages.length - 1
              ? PrimaryButton(
                text: 'Get Started',
                onPressed: _completeOnboarding,
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 10,
                ), // Smaller padding
              )
              : TextButton(
                onPressed: () {
                  _pageController.nextPage(
                    duration: const Duration(milliseconds: 300),
                    curve: Curves.easeIn,
                  );
                },
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text('Next'),
                    SizedBox(width: 4),
                    Icon(Icons.arrow_forward, size: 18),
                  ],
                ),
              ),
        ],
      ),
    );
  }

  Widget _buildDot(int index, ThemeData theme) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      margin: const EdgeInsets.symmetric(horizontal: 4),
      height: 8,
      width: _currentPage == index ? 24 : 8,
      decoration: BoxDecoration(
        color:
            _currentPage == index
                ? theme.colorScheme.primary
                : theme.disabledColor,
        borderRadius: BorderRadius.circular(4),
      ),
    );
  }
}
