enum Environment { dev, staging, prod }

class EnvironmentConfig {
  final Environment environment;
  final String appName;

  // Add other environment-specific variables here if needed in the future
  // final String apiBaseUrl;

  EnvironmentConfig({
    required this.environment,
    required this.appName,
    // required this.apiBaseUrl,
  });

  static EnvironmentConfig? _instance;

  static void init({required Environment environment}) {
    String appNameSuffix = '';
    switch (environment) {
      case Environment.dev:
        appNameSuffix = ' Dev';
        break;
      case Environment.staging:
        appNameSuffix = ' Staging';
        break;
      case Environment.prod:
        appNameSuffix = ''; // No suffix for prod
        break;
    }
    _instance = EnvironmentConfig(
      environment: environment,
      appName: 'FitStride$appNameSuffix',
      // Initialize other variables based on environment
    );
  }

  static EnvironmentConfig get instance {
    if (_instance == null) {
      throw Exception(
        "EnvironmentConfig not initialized. Call EnvironmentConfig.init() first.",
      );
    }
    return _instance!;
  }
}
