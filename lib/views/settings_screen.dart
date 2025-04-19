import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../controllers/settings_provider.dart';
import '../controllers/theme_provider.dart'; // Import ThemeProvider
import '../widgets/custom_switch_tile.dart'; // For other settings later

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    // Use watch to rebuild when settings change
    final settingsProvider = Provider.of<SettingsProvider>(context);

    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: ListView(
        children: [
          // --- General Section ---
          _buildSectionHeader(context, 'General'),
          ListTile(
            leading: const Icon(Icons.straighten),
            title: const Text('Measurement Units'),
            trailing: DropdownButton<String>(
              value: settingsProvider.units,
              underline: Container(), // Hide default underline
              items: const [
                DropdownMenuItem(
                  value: 'metric',
                  child: Text('Metric (km, kg)'),
                ),
                DropdownMenuItem(
                  value: 'imperial',
                  child: Text('Imperial (mi, lbs)'),
                ),
              ],
              onChanged: (String? newValue) {
                if (newValue != null) {
                  // Use listen: false when calling methods inside callbacks
                  Provider.of<SettingsProvider>(
                    context,
                    listen: false,
                  ).setUnits(newValue);
                }
              },
            ),
          ),
          const Divider(),

          // --- Voice Coaching Section ---
          _buildSectionHeader(context, 'Voice Coaching'),
          CustomSwitchTile(
            title: 'Enable Voice Coaching',
            value: settingsProvider.voiceCoachingEnabled,
            onChanged:
                (value) => Provider.of<SettingsProvider>(
                  context,
                  listen: false,
                ).setVoiceCoachingEnabled(value),
          ),
          // Frequency Setting
          ListTile(
            leading: const Icon(Icons.volume_up),
            title: const Text('Coaching Frequency'),
            trailing: DropdownButton<int>(
              value: settingsProvider.voiceCoachingFrequency,
              underline: Container(),
              items: const [
                DropdownMenuItem(value: 0, child: Text('Minimal')),
                DropdownMenuItem(value: 1, child: Text('Moderate')),
                DropdownMenuItem(value: 2, child: Text('Detailed')),
              ],
              onChanged: (int? newValue) {
                if (newValue != null) {
                  Provider.of<SettingsProvider>(
                    context,
                    listen: false,
                  ).setVoiceCoachingFrequency(newValue);
                }
              },
            ),
          ),
          // Voice Selection Setting (Placeholder - assumes only 'default' for now)
          ListTile(
            leading: const Icon(Icons.record_voice_over),
            title: const Text('Coach Voice'),
            trailing: DropdownButton<String>(
              value: settingsProvider.voiceCoachingVoice,
              underline: Container(),
              items: const [
                // TODO: Populate with actual available voices if more than one exists
                DropdownMenuItem(value: 'default', child: Text('Default')),
              ],
              onChanged: (String? newValue) {
                if (newValue != null) {
                  Provider.of<SettingsProvider>(
                    context,
                    listen: false,
                  ).setVoiceCoachingVoice(newValue);
                }
              },
            ),
          ),
          const Divider(),

          // --- Map Section ---
          _buildSectionHeader(context, 'Map Display'),
          // Map Type Setting
          ListTile(
            leading: const Icon(Icons.map),
            title: const Text('Map Type'),
            trailing: DropdownButton<String>(
              value: settingsProvider.mapType,
              underline: Container(),
              items: const [
                DropdownMenuItem(value: 'standard', child: Text('Standard')),
                DropdownMenuItem(value: 'satellite', child: Text('Satellite')),
                DropdownMenuItem(
                  value: 'terrain',
                  child: Text('Terrain'),
                ), // Assuming terrain is an option
              ],
              onChanged: (String? newValue) {
                if (newValue != null) {
                  Provider.of<SettingsProvider>(
                    context,
                    listen: false,
                  ).setMapType(newValue);
                }
              },
            ),
          ),
          // Show Mile Markers Setting
          CustomSwitchTile(
            title: 'Show Mile/KM Markers',
            subtitle: 'Display markers on the map during workouts',
            value: settingsProvider.showMileMarkers,
            onChanged:
                (value) => Provider.of<SettingsProvider>(
                  context,
                  listen: false,
                ).setShowMileMarkers(value),
          ),
          // Show Elevation Profile Setting (Note: Actual display might be elsewhere)
          CustomSwitchTile(
            title: 'Show Elevation Profile',
            subtitle:
                'Display elevation graph (if available)', // Clarify where it shows
            value: settingsProvider.showElevationProfile,
            onChanged:
                (value) => Provider.of<SettingsProvider>(
                  context,
                  listen: false,
                ).setShowElevationProfile(value),
          ),
          const Divider(),

          // --- GPS Settings Section ---
          _buildSectionHeader(context, 'GPS Settings'),
          ListTile(
            leading: const Icon(Icons.gps_fixed),
            title: const Text('Tracking Accuracy'),
            trailing: DropdownButton<LocationAccuracyLevel>(
              value: settingsProvider.gpsAccuracy,
              underline: Container(),
              items:
                  LocationAccuracyLevel.values.map((level) {
                    String levelName = level.toString().split('.').last;
                    levelName =
                        levelName[0].toUpperCase() + levelName.substring(1);
                    return DropdownMenuItem(
                      value: level,
                      child: Text(levelName),
                    );
                  }).toList(),
              onChanged: (LocationAccuracyLevel? newValue) {
                if (newValue != null) {
                  Provider.of<SettingsProvider>(
                    context,
                    listen: false,
                  ).setGpsAccuracy(newValue);
                  // TODO: Ensure TrackingProvider applies this setting to LocationService
                }
              },
            ),
          ),
          // TODO: Add control for update interval (Task 228)
          const Divider(),

          // --- Notifications Section ---
          _buildSectionHeader(context, 'Notifications'),
          // TODO: Add controls for notifications (Task 203 related?)
          const Divider(),

          // --- Data Management Section ---
          _buildSectionHeader(context, 'Data Management'),
          ListTile(
            leading: const Icon(Icons.backup),
            title: const Text('Backup & Restore'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () {
              Navigator.pushNamed(context, '/backup_restore');
            },
          ),
          ListTile(
            leading: const Icon(Icons.delete_forever, color: Colors.red),
            title: const Text(
              'Delete All Data',
              style: TextStyle(color: Colors.red),
            ),
            onTap: () {
              // TODO: Show confirmation dialog and call data deletion logic
              print('Show Delete Data confirmation');
            },
          ),
          const Divider(),

          // --- Appearance Section ---
          _buildSectionHeader(context, 'Appearance'),
          ListTile(
            leading: const Icon(Icons.brightness_6),
            title: const Text('Theme'),
            trailing: DropdownButton<ThemeMode>(
              value:
                  Provider.of<ThemeProvider>(
                    context,
                  ).themeMode, // Access ThemeProvider
              underline: Container(),
              items: const [
                DropdownMenuItem(
                  value: ThemeMode.system,
                  child: Text('System Default'),
                ),
                DropdownMenuItem(value: ThemeMode.light, child: Text('Light')),
                DropdownMenuItem(value: ThemeMode.dark, child: Text('Dark')),
              ],
              onChanged: (ThemeMode? newValue) {
                if (newValue != null) {
                  Provider.of<ThemeProvider>(
                    context,
                    listen: false,
                  ).setThemeMode(newValue);
                }
              },
            ),
          ),
          const Divider(),

          // --- About Section ---
          _buildSectionHeader(context, 'About'),
          ListTile(
            leading: const Icon(Icons.policy),
            title: const Text('Privacy Policy'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () {
              Navigator.pushNamed(
                context,
                '/privacy_policy',
              ); // Assuming route exists
            },
          ),
          ListTile(
            leading: const Icon(Icons.info_outline),
            title: const Text('App Version'),
            subtitle: const Text('1.0.0'), // TODO: Get version dynamically
            onTap: null, // No action needed
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(BuildContext context, String title) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(
        left: 16.0,
        right: 16.0,
        top: 20.0,
        bottom: 8.0,
      ),
      child: Text(
        title.toUpperCase(),
        style: theme.textTheme.labelSmall?.copyWith(
          color: theme.colorScheme.primary,
          fontWeight: FontWeight.bold,
          letterSpacing: 1.1,
        ),
      ),
    );
  }
}

// Removed placeholder ThemeProvider
