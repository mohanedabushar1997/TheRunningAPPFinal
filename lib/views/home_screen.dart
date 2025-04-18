import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../controllers/user_provider.dart'; // To check if profile exists, etc.
import '../widgets/primary_button.dart'; // Example usage of a custom widget

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // Example of accessing a provider
    final userProvider = Provider.of<UserProvider>(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('FitStride Home'),
        // TODO: Add actions (e.g., settings icon)
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              Text(
                'Welcome!',
                style: Theme.of(context).textTheme.headlineMedium,
              ),
              const SizedBox(height: 20),
              // TODO: Add conditional logic based on profile/training plan state
              if (userProvider.isProfileCreated)
                Text(
                  'User Profile exists for Device ID: ${userProvider.deviceId}',
                )
              else
                const Text('No profile found. Consider onboarding.'),
              const SizedBox(height: 40),

              // TODO: Implement Quick start workout button (Task 4.3.3.1)
              PrimaryButton(
                text: 'Start Quick Workout',
                onPressed: () {
                  // TODO: Navigate to Workout Preparation Screen
                  print('Start Quick Workout tapped');
                },
              ),
              const SizedBox(height: 20),

              // TODO: Display Current training plan progress (Task 4.3.3.2)
              const Text('Training Plan Progress: [Placeholder]'),
              const SizedBox(height: 20),

              // TODO: Display Recent activity summary (Task 4.3.3.3)
              const Text('Recent Activity: [Placeholder]'),
              const SizedBox(height: 20),

              // TODO: Display Quick stats overview (Task 4.3.3.4)
              const Text('Quick Stats: [Placeholder]'),
            ],
          ),
        ),
      ),
      // TODO: Add Bottom Navigation Bar if needed for main navigation
    );
  }
}
