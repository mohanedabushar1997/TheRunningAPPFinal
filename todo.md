# FitStride Running App - Implementation Todo List

## Models
- [x] Create Achievement model
- [x] Create WorkoutPoint model
- [x] Create Workout model in lib/models/workout_model.dart
- [x] Create TrainingPlan and TrainingSession models

## Services
- [x] Create LocationService for GPS tracking
- [x] Create CalculationService for metrics (pace, calories, etc.)
- [x] Create AudioService for voice coaching

## Controllers Implementation

### AchievementsProvider
- [x] Define state for unlocked achievements and progress
- [x] Implement method to load achievements from DB
- [x] Implement method to check and unlock achievements
- [x] Implement method to define all possible achievements

### SettingsProvider
- [x] Add methods for other settings (audio, map preferences, etc.)

### ThemeProvider
- [x] Define proper typography (Task 4.1.5) for both light and dark themes

### TrackingProvider
- [x] Import models (WorkoutPoint, etc.) and services
- [x] Inject LocationService and CalculationService
- [x] Implement methods to start, pause, resume, stop tracking
- [x] Implement method to update metrics based on new position/data
- [x] Implement proper cleanup in dispose method

### TrainingPlanProvider
- [x] Define state variables for available plans, current plan, progress
- [x] Implement methods to load plans from DB or predefined data
- [x] Implement methods to select, activate, track progress, complete sessions/plans

### UserProvider
- [ ] Use StorageService instead of direct dbHelper access (optional)

### VoiceCoachingProvider
- [x] Import AudioService
- [x] Inject AudioService
- [x] Define state for voice selection, cue frequency
- [x] Implement method to load settings
- [x] Implement method to trigger voice cues based on events/metrics
- [x] Implement method to manage audio queue if multiple cues trigger

### WorkoutProvider
- [x] Define state variables for workout history, current workout details
- [x] Implement method to load workouts from DB
- [x] Implement methods to start, pause, resume, stop, save workouts

## Database Implementation
- [x] Implement CRUD operations for Workouts, Workout_Points, Training_Plans, etc.

## Main Application
- [x] Implement routing and initial screen logic (e.g., check if profile exists)

## Testing
- [x] Test all implemented features
- [x] Verify implementations against requirements in tasks.md
- [x] Ensure compliance with rules.md guidelines

## GitHub Updates
- [ ] Commit changes with descriptive messages
- [ ] Push changes to GitHub repository
