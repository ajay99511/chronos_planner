import 'package:chronosky/data/local/app_database.dart';
import 'package:chronosky/data/local/migration_helper.dart';
import 'package:drift/drift.dart' show DatabaseConnection;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../helpers/mocks.dart';

void main() {
  late AppDatabase db;
  late MockLogger logger;

  setUpAll(() {
    registerFallbackValue(StackTrace.empty);
  });

  setUp(() {
    db = AppDatabase.forTesting(DatabaseConnection(NativeDatabase.memory()));
    logger = MockLogger();
  });

  tearDown(() async {
    await db.close();
  });

  group('MigrationHelper', () {
    test('does nothing once the migration flag is set', () async {
      SharedPreferences.setMockInitialValues({
        'chronos-drift-migrated': true,
        'chronos-week': '[]',
      });

      await MigrationHelper.migrateIfNeeded(db, logger);

      verifyNever(() => logger.info(any()));
      // The legacy key survives, proving the migration body never ran.
      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getString('chronos-week'), '[]');
    });

    test('migrates a stored week plan and clears the legacy keys', () async {
      SharedPreferences.setMockInitialValues({
        'chronos-week': '['
            '{"id":"dp-1","date":"2026-08-24T00:00:00.000",'
            '"tasks":[{"id":"t-1","title":"Legacy task",'
            '"startTime":"09:00","endTime":"10:00","type":"work",'
            '"priority":"medium","completed":false}]}'
            ']',
        'chronos-sort-order': 'desc',
      });

      await MigrationHelper.migrateIfNeeded(db, logger);

      final tasks = await db.select(db.tasks).get();
      expect(tasks.single.title, 'Legacy task');

      final sortOrder = await db.preferenceDao.getValue('sort_order');
      expect(sortOrder, 'desc');

      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getBool('chronos-drift-migrated'), isTrue);
      expect(prefs.getString('chronos-week'), isNull);
      expect(prefs.getString('chronos-sort-order'), isNull);
    });

    // The failure used to be swallowed with only a debugPrint, so a migration
    // that failed every launch was invisible in production. See M-3.
    test('reports a failure and leaves the flag unset so it retries',
        () async {
      SharedPreferences.setMockInitialValues({
        'chronos-week': 'this is not json',
      });

      await MigrationHelper.migrateIfNeeded(db, logger);

      verify(
        () => logger.error(
          any(that: contains('migration failed')),
          any<dynamic>(),
          any(),
        ),
      ).called(1);

      final prefs = await SharedPreferences.getInstance();
      expect(
        prefs.getBool('chronos-drift-migrated'),
        isNull,
        reason: 'an unfinished migration must be retried on the next launch',
      );
      expect(
        prefs.getString('chronos-week'),
        'this is not json',
        reason: 'legacy data must not be deleted before it is migrated',
      );
    });
  });
}
