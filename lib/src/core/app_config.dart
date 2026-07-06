abstract final class AppConfig {
  static const apiBaseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'http://10.0.2.2:8000/api/mobile/v1',
  );

  static const demoMode = bool.fromEnvironment('DEMO_MODE', defaultValue: true);
}
