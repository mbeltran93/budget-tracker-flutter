/// Central place for environment-dependent configuration.
///
/// The backend base URL is never hardcoded in the data layer: it is baked in
/// at compile time via `--dart-define=API_BASE_URL=...` so the same app can
/// point at different environments without a code change. See the README
/// for the Android emulator (`10.0.2.2`) vs. real-device (LAN IP) guidance.
class ApiConfig {
  ApiConfig._();

  /// Default target: the standard alias the Android emulator uses to reach
  /// `localhost` on the host machine, which is where `docker compose up`
  /// publishes the budget-tracker-spring backend (port 8080).
  static const String baseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'http://10.0.2.2:8080',
  );
}
