# FitStride Running App

FitStride is a privacy-focused running application designed for Android devices. It provides comprehensive tracking, training plans, and progress monitoring, all while ensuring user data remains strictly local and secure.

## Features

*   GPS-based activity tracking (running, walking)
*   Real-time metrics (distance, pace, calories, elevation)
*   Map visualization of routes
*   Pre-defined training plans (5K, 10K, Half Marathon, Marathon, Interval Walking)
*   Voice coaching with audio cues
*   Manual workout entry
*   Workout history and statistics
*   Offline achievement system
*   Personal records tracking
*   Weight tracking
*   Local data backup and restore
*   Light and Dark themes
*   Strictly local data storage - no cloud accounts or external data transmission.

## Getting Started

This project uses the Flutter framework.

1.  Ensure you have the Flutter SDK (version 3.10.0+) installed.
2.  Clone the repository.
3.  Navigate to the `fitstride_app` directory.
4.  Run `flutter pub get` to install dependencies.
5.  Run `flutter run` to launch the application on a connected device or emulator.

## Project Structure

The project follows a standard Flutter structure with clear separation of concerns:

*   `lib/models`: Data models
*   `lib/views`: UI screens
*   `lib/controllers`: Business logic
*   `lib/services`: Background services (GPS, audio, etc.)
*   `lib/utils`: Helper functions
*   `lib/widgets`: Reusable UI components
*   `lib/data`: Local database interaction (SQLite)
*   `lib/themes`: App themes and styling
*   `assets/`: Static resources (images, audio, fonts)

## Contributing

Please refer to the `CONTRIBUTING.md` file for guidelines.
