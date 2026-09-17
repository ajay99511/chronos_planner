import 'dart:convert';

import 'package:chronosky/core/services/logger.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('formatLogRecord', () {
    final at = DateTime.utc(2026, 8, 24, 9, 30, 15);

    test('emits parseable JSON rather than prose', () {
      final decoded = jsonDecode(
        formatLogRecord('ERROR', 'Failed to persist dismissals', timestamp: at),
      ) as Map<String, dynamic>;

      expect(decoded['level'], 'ERROR');
      expect(decoded['msg'], 'Failed to persist dismissals');
      expect(decoded['ts'], '2026-08-24T09:30:15.000Z');
    });

    test('carries the operation so a record can be traced to its call site',
        () {
      final decoded = jsonDecode(
        formatLogRecord(
          'WARNING',
          'Background apply failed',
          operation: 'applyTemplate',
          timestamp: at,
        ),
      ) as Map<String, dynamic>;

      expect(decoded['op'], 'applyTemplate');
    });

    test('omits operation when absent instead of writing null', () {
      final decoded = jsonDecode(
        formatLogRecord('INFO', 'App starting', timestamp: at),
      ) as Map<String, dynamic>;

      expect(decoded.containsKey('op'), isFalse);
    });

    test('escapes payloads that would otherwise break the record', () {
      final raw = formatLogRecord(
        'ERROR',
        'Bad input: {"quoted"}\nsecond line',
        timestamp: at,
      );

      // One record per line is the property that makes logs greppable.
      expect(raw, isNot(contains('\n')));
      final decoded = jsonDecode(raw) as Map<String, dynamic>;
      expect(decoded['msg'], 'Bad input: {"quoted"}\nsecond line');
    });
  });

  group('release logging', () {
    test('a release build does not discard records', () {
      // NoOpLogger silently dropped every error in shipped builds, so a
      // production failure left no trace anywhere. See M-3 in the audit.
      expect(createLogger(debugMode: false), isNot(isA<NoOpLogger>()));
    });
  });
}
