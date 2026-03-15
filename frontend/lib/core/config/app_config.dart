// ============================================================================
// Nelna Maintenance System - Environment Configuration
// ============================================================================

import 'dart:io' show Platform;
import 'package:flutter/foundation.dart' show kIsWeb;

/// Build environments.
enum Environment { dev, staging, prod }

/// Centralised, environment-aware configuration.
///
/// The active environment is determined at compile-time via
/// `--dart-define=ENV=dev` (default), `staging`, or `prod`.
///
/// Usage:
/// ```
/// flutter run --dart-define=ENV=dev
/// flutter build apk --dart-define=ENV=prod
/// ```
class AppConfig {
  // Private constructor — not instantiable.
  AppConfig._();

  /// Resolved once from the compile-time constant.
  static const String _envString =
      String.fromEnvironment('ENV', defaultValue: 'dev');

  static final Environment environment = _resolveEnv(_envString);

  // ── Base URLs per environment ──────────────────────────────────────
  static String get _devBaseUrl {
    // Web uses window.location
    if (kIsWeb) {
      return 'http://localhost:3000/api/v1';
    }
    // Android emulator needs 10.0.2.2 to reach host machine
    if (Platform.isAndroid) {
      return 'http://10.0.2.2:3000/api/v1';
    }
    // iOS simulator, Windows, macOS, Linux use localhost
    return 'http://localhost:3000/api/v1';
  }

  static final Map<Environment, String> _baseUrls = {
    Environment.dev: _devBaseUrl,
    Environment.staging: 'https://nelna-maintance-app-d3dn.vercel.app/api/v1',
    Environment.prod: 'https://nelna-maintance-app-d3dn.vercel.app/api/v1',
  };

  /// The API base URL for the current environment.
  static String get baseUrl => _baseUrls[environment]!;

  /// Human-readable label shown in debug banners, etc.
  static String get envLabel => environment.name.toUpperCase();

  /// Whether the current build should show debug helpers.
  static bool get isDebug => environment == Environment.dev;

  /// Whether the build targets production.
  static bool get isProduction => environment == Environment.prod;

  // ── Sentry / Error-monitoring DSN ──────────────────────────────────
  static const String _sentryDsn =
      String.fromEnvironment('SENTRY_DSN', defaultValue: '');
  static String get sentryDsn => _sentryDsn;

  // ── helpers ────────────────────────────────────────────────────────
  static Environment _resolveEnv(String value) {
    switch (value.toLowerCase()) {
      case 'staging':
        return Environment.staging;
      case 'prod':
      case 'production':
        return Environment.prod;
      default:
        return Environment.dev;
    }
  }
}
