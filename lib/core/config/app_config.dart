abstract final class AppConfig {
  /// Override with --dart-define=API_BASE_URL=... for another run target.
  /// Repository paths already include the `/api` prefix.
  static const String apiBaseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'https://kidney-truly-ensemble-lease.trycloudflare.com',
  );
}
