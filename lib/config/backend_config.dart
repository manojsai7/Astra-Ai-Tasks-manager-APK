abstract final class BackendConfig {
  static const String baseUrl =
      String.fromEnvironment(
    'ASTRA_BACKEND_URL',
    defaultValue: 'http://10.0.2.2:8000',
  );
}
