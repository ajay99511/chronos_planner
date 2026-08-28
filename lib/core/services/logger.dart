import 'dart:convert';
import 'dart:developer' as dev;

/// Abstract logger service.
abstract class Logger {
  void debug(String message, [dynamic error, StackTrace? stackTrace]);
  void info(String message, [dynamic error, StackTrace? stackTrace]);
  void warning(String message, [dynamic error, StackTrace? stackTrace]);
  void error(String message, [dynamic error, StackTrace? stackTrace]);
}

/// Serializes one log record as a single line of JSON.
///
/// Kept pure and separate from the sink so the wire format is testable without
/// capturing developer-log output. Records are structured rather than
/// interpolated prose so they can be filtered by level or operation instead of
/// grepped; one record per line keeps them greppable regardless.
///
/// [timestamp] is injectable to keep tests deterministic; it defaults to now.
String formatLogRecord(
  String level,
  String message, {
  String? operation,
  DateTime? timestamp,
}) {
  return jsonEncode({
    'ts': (timestamp ?? DateTime.now().toUtc()).toIso8601String(),
    'level': level,
    if (operation != null) 'op': operation,
    'msg': message,
  });
}

/// Severity threshold below which records are dropped.
enum LogLevel {
  debug(500),
  info(800),
  warning(900),
  error(1000);

  const LogLevel(this.value);

  /// Maps to `dart:developer` levels, which follow the same scale.
  final int value;
}

/// Chooses the logger for the current build.
///
/// Release builds previously used [NoOpLogger], which meant every `error` and
/// `warning` call in the app discarded its payload — a production failure left
/// no trace anywhere. Records now reach the platform log in both modes;
/// release drops only [LogLevel.debug] chatter, which is per-operation noise
/// with no diagnostic value once a build ships.
Logger createLogger({required bool debugMode}) => ConsoleLogger(
      minLevel: debugMode ? LogLevel.debug : LogLevel.info,
    );

/// Writes structured records to the platform log via `dart:developer`.
class ConsoleLogger implements Logger {
  const ConsoleLogger({this.minLevel = LogLevel.debug});

  /// Records below this severity are dropped.
  final LogLevel minLevel;

  @override
  void debug(String message, [dynamic error, StackTrace? stackTrace]) {
    _log(LogLevel.debug, message, error, stackTrace);
  }

  @override
  void info(String message, [dynamic error, StackTrace? stackTrace]) {
    _log(LogLevel.info, message, error, stackTrace);
  }

  @override
  void warning(String message, [dynamic error, StackTrace? stackTrace]) {
    _log(LogLevel.warning, message, error, stackTrace);
  }

  @override
  void error(String message, [dynamic error, StackTrace? stackTrace]) {
    _log(LogLevel.error, message, error, stackTrace);
  }

  void _log(
    LogLevel level,
    String message,
    dynamic error,
    StackTrace? stackTrace,
  ) {
    if (level.value < minLevel.value) return;
    dev.log(
      formatLogRecord(level.name.toUpperCase(), message),
      name: 'ChronosPlanner',
      error: error,
      stackTrace: stackTrace,
      level: level.value,
    );
  }
}

/// A logger that does nothing.
class NoOpLogger implements Logger {
  const NoOpLogger();

  @override
  void debug(String message, [dynamic error, StackTrace? stackTrace]) {}
  @override
  void info(String message, [dynamic error, StackTrace? stackTrace]) {}
  @override
  void warning(String message, [dynamic error, StackTrace? stackTrace]) {}
  @override
  void error(String message, [dynamic error, StackTrace? stackTrace]) {}
}

/// A stub for a crash reporting logger (e.g., Sentry, Firebase).
class CrashReportingLogger implements Logger {
  const CrashReportingLogger();

  @override
  void debug(String message, [dynamic error, StackTrace? stackTrace]) {}
  @override
  void info(String message, [dynamic error, StackTrace? stackTrace]) {}
  @override
  void warning(String message, [dynamic error, StackTrace? stackTrace]) {
    // In a real implementation, this would send to a service
  }
  @override
  void error(String message, [dynamic error, StackTrace? stackTrace]) {
    // In a real implementation, this would send to a service
  }
}
