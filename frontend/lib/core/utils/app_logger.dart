// ============================================================================
// Nelna Maintenance System — AppLogger
// Thin wrapper around the `logger` package that forwards log events to
// Sentry as breadcrumbs (and exceptions to Sentry's error stream).
// ============================================================================
import 'package:logger/logger.dart';
import 'package:sentry_flutter/sentry_flutter.dart';

/// Singleton logger used across the Flutter app.
///
/// Usage:
/// ```dart
/// AppLogger.info('User logged in', extra: {'userId': userId});
/// AppLogger.error('API call failed', error: e, stackTrace: st);
/// ```
class AppLogger {
  AppLogger._();

  static final Logger _logger = Logger(
    printer: PrettyPrinter(
      methodCount: 2,
      errorMethodCount: 8,
      lineLength: 100,
      colors: true,
      printEmojis: true,
    ),
  );

  // ── Info ──────────────────────────────────────────────────────────────
  static void info(String message, {Map<String, dynamic>? extra}) {
    _logger.i(message);
    Sentry.addBreadcrumb(
      Breadcrumb(
        message: message,
        level: SentryLevel.info,
        data: extra,
        category: 'app.info',
      ),
    );
  }

  // ── Debug ─────────────────────────────────────────────────────────────
  static void debug(String message, {Map<String, dynamic>? extra}) {
    _logger.d(message);
    Sentry.addBreadcrumb(
      Breadcrumb(
        message: message,
        level: SentryLevel.debug,
        data: extra,
        category: 'app.debug',
      ),
    );
  }

  // ── Warning ───────────────────────────────────────────────────────────
  static void warning(String message, {Map<String, dynamic>? extra}) {
    _logger.w(message);
    Sentry.addBreadcrumb(
      Breadcrumb(
        message: message,
        level: SentryLevel.warning,
        data: extra,
        category: 'app.warning',
      ),
    );
  }

  // ── Error ─────────────────────────────────────────────────────────────
  // Logs the error locally AND sends it to Sentry.
  static void error(
    String message, {
    Object? error,
    StackTrace? stackTrace,
    Map<String, dynamic>? extra,
  }) {
    _logger.e(message, error: error, stackTrace: stackTrace);
    if (error != null) {
      Sentry.captureException(
        error,
        stackTrace: stackTrace,
        hint: extra != null ? Hint.withMap(extra) : null,
      );
    } else {
      Sentry.addBreadcrumb(
        Breadcrumb(
          message: message,
          level: SentryLevel.error,
          data: extra,
          category: 'app.error',
        ),
      );
    }
  }

  // ── Navigation breadcrumb ─────────────────────────────────────────────
  static void navigation(String from, String to) {
    Sentry.addBreadcrumb(
      Breadcrumb(
        type: 'navigation',
        data: {'from': from, 'to': to},
        category: 'app.navigation',
      ),
    );
  }
}
