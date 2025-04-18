# FitStride Running App - AI Development Rules

This document outlines the rules and guidelines for developing the FitStride running app.
## Core Development Principles
- Follow Flutter framework best practices for all development tasks
- Maintain separation of concerns (UI, business logic, data)
- Implement all features exactly as specified in the project documentation
- Optimize for mobile performance, focusing on battery and resource efficiency
- Ensure all code is well-commented and follows consistent style conventions
- Use statically typed variables with proper type annotations throughout the codebase

## Privacy and Data Handling
- Store all user data locally on the device using secure methods (SQLite with encryption)
- Never implement features that transmit user data to external servers
- Use device ID for identification instead of user accounts or registration
- Implement secure data backup and restore functionality (local only)
- Include clear privacy statements explaining the app's data handling practices
- Do not implement any form of analytics that sends data externally

## User Interface Rules
- Strictly adhere to the color palette:
  - Primary: #FF3366
  - Secondary: #33CC99
  - Accent: #FFCC00
- Implement both light and dark themes as specified in the design documentation
- Ensure all text is readable with proper contrast ratios
- Create responsive layouts that work across all Android device sizes
- Follow material design principles while maintaining the unique FitStride visual identity
- Implement transitions and animations that enhance user experience (not distract)
- Ensure all UI elements are accessible, with proper touch target sizes

## Feature-Specific Rules
- GPS tracking must be battery-efficient with adjustable accuracy settings
- Implement all specified training plans exactly as documented
- Voice coaching must use pre-defined audio files from the assets folder
- Calorie calculations must use scientifically validated formulas
- Music integration should not transfer any user data to music providers
- Implement manual workout entry for treadmill or GPS-unavailable scenarios
- Achievement system must work entirely offline

## Testing and Quality Assurance
- Write comprehensive unit tests for all core functionality
- Implement integration tests for all main user flows
- Test on multiple device types and Android versions
- Test GPS functionality in real-world conditions
- Implement robust error handling for all potential failure points
- Test battery consumption during typical usage scenarios
- Ensure data integrity across app sessions and device restarts

## Prohibited Features
- Do not implement user registration or login functionality
- Do not create cloud-based user accounts
- Do not implement social media sharing capabilities
- Do not include online community features
- Do not integrate with third-party fitness services or APIs
- Do not implement any data collection for analytics purposes
- Do not add features not specified in the project documentation

## Performance Requirements
- App must maintain 60 FPS during normal operation
- Cold start time must be under 2 seconds on mid-range devices
- GPS tracking must use battery-efficient strategies
- App size must remain under 50MB (excluding pre-defined voice assets)
- Memory usage must not exceed 150MB during active tracking
- Optimize database queries for efficient access patterns
- Implement proper resource cleanup to prevent memory leaks

---
*Version 1.0 | 