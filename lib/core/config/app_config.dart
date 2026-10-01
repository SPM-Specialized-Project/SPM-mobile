abstract final class AppConfig {
  /// Android emulator reaches the development computer through 10.0.2.2.
  /// Override with --dart-define=API_BASE_URL=... for another run target.
  static const String apiBaseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'http://10.0.2.2:4000',
  );
}
