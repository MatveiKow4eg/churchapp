class AppConfig {
  const AppConfig._(this.baseUrl);

  // Hardcoded base URL for production build.
  static const String _kBaseUrl = 'https://api.kovcheg.ee';

  final String baseUrl;

  factory AppConfig.production() => const AppConfig._(_kBaseUrl);
}
