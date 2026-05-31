import 'dart:developer' as dev;

/// Abstract logger service.
abstract class Logger {
  void debug(String message, [dynamic error, StackTrace? stackTrace]);
  void info(String message, [dynamic error, StackTrace? stackTrace]);
  void warning(String message, [dynamic error, StackTrace? stackTrace]);
  void error(String message, [dynamic error, StackTrace? stackTrace]);
}

/// A logger that prints to the console using dart:developer log().
class ConsoleLogger implements Logger {
  const ConsoleLogger();

  @override
  void debug(String message, [dynamic error, StackTrace? stackTrace]) {
    _log('DEBUG', message, error, stackTrace);
  }

  @override
  void info(String message, [dynamic error, StackTrace? stackTrace]) {
    _log('INFO', message, error, stackTrace);
  }

  @override
  void warning(String message, [dynamic error, StackTrace? stackTrace]) {
    _log('WARNING', message, error, stackTrace);
  }

  @override
  void error(String message, [dynamic error, StackTrace? stackTrace]) {
    _log('ERROR', message, error, stackTrace);
  }

  void _log(String level, String message, dynamic error, StackTrace? stackTrace) {
    dev.log(
      '[$level] $message',
      name: 'ChronosPlanner',
      error: error,
      stackTrace: stackTrace,
      level: _levelToValue(level),
    );
  }

  int _levelToValue(String level) {
    return switch (level) {
      'DEBUG' => 500,
      'INFO' => 800,
      'WARNING' => 900,
      'ERROR' => 1000,
      _ => 0,
    };
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
