import 'package:logger/logger.dart';

/// Centralized logging utility for NextWave
/// 
/// Usage:
/// ```dart
/// import '../utils/app_logger.dart';
/// 
/// AppLogger.debug('Debug message');
/// AppLogger.info('Info message');
/// AppLogger.warning('Warning message');
/// AppLogger.error('Error message', error: e, stackTrace: stackTrace);
/// ```
class AppLogger {
  static final Logger _logger = Logger(
    printer: PrettyPrinter(
      methodCount: 2, // Number of method calls to be displayed
      errorMethodCount: 8, // Number of method calls if stacktrace is provided
      lineLength: 120, // Width of the output
      colors: true, // Colorful log messages
      printEmojis: true, // Print an emoji for each log message
      dateTimeFormat: DateTimeFormat.onlyTimeAndSinceStart,
    ),
  );

  /// Debug log - for detailed information during development
  static void debug(dynamic message, {dynamic error, StackTrace? stackTrace}) {
    _logger.d(message, error: error, stackTrace: stackTrace);
  }

  /// Info log - for general informational messages
  static void info(dynamic message, {dynamic error, StackTrace? stackTrace}) {
    _logger.i(message, error: error, stackTrace: stackTrace);
  }

  /// Warning log - for potentially harmful situations
  static void warning(dynamic message, {dynamic error, StackTrace? stackTrace}) {
    _logger.w(message, error: error, stackTrace: stackTrace);
  }

  /// Error log - for error events that might still allow the app to continue
  static void error(dynamic message, {dynamic error, StackTrace? stackTrace}) {
    _logger.e(message, error: error, stackTrace: stackTrace);
  }

  /// Fatal log - for very severe error events that will presumably lead the app to abort
  static void fatal(dynamic message, {dynamic error, StackTrace? stackTrace}) {
    _logger.f(message, error: error, stackTrace: stackTrace);
  }

  /// Trace log - for very detailed information
  static void trace(dynamic message, {dynamic error, StackTrace? stackTrace}) {
    _logger.t(message, error: error, stackTrace: stackTrace);
  }
}
