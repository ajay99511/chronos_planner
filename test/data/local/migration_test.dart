import 'package:chronosky/data/local/app_database.dart';
import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Schema Migration', () {
    test('v4 to v5 migration', () async {
      final executor = NativeDatabase.memory();

      // Manually open to run initial setup without drift's MigrationStrategy
      await executor.ensureOpen(_FakeUser());

      // Setup v4 state manually
      await executor.runCustom('''
        CREATE TABLE day_plans (
          id TEXT NOT NULL PRIMARY KEY,
          date_str TEXT NOT NULL,
          day_of_week TEXT NOT NULL,
          date INTEGER NOT NULL,
          week_key TEXT NOT NULL
        );
      ''');

      await executor.runCustom('''
        CREATE TABLE plan_templates (
          id TEXT NOT NULL PRIMARY KEY,
          name TEXT NOT NULL,
          description TEXT NOT NULL DEFAULT '',
          active_days TEXT NOT NULL DEFAULT ''
        );
      ''');

      await executor.runCustom('''
        CREATE TABLE tasks (
          id TEXT NOT NULL PRIMARY KEY,
          title TEXT NOT NULL,
          description TEXT NOT NULL DEFAULT '',
          start_time TEXT NOT NULL,
          end_time TEXT NOT NULL,
          type TEXT NOT NULL,
          priority TEXT NOT NULL DEFAULT 'medium',
          energy_level TEXT NOT NULL DEFAULT 'medium',
          estimated_cost REAL NOT NULL DEFAULT 0.0,
          actual_cost REAL NOT NULL DEFAULT 0.0,
          completed INTEGER NOT NULL DEFAULT 0,
          day_plan_id TEXT NOT NULL REFERENCES day_plans (id),
          source_template_id TEXT NOT NULL DEFAULT ''
        );
      ''');

      await executor.runCustom('''
        CREATE TABLE template_tasks (
          id TEXT NOT NULL PRIMARY KEY,
          template_id TEXT NOT NULL REFERENCES plan_templates (id),
          title TEXT NOT NULL,
          description TEXT NOT NULL DEFAULT '',
          start_time TEXT NOT NULL,
          end_time TEXT NOT NULL,
          type TEXT NOT NULL,
          priority TEXT NOT NULL DEFAULT 'medium',
          energy_level TEXT NOT NULL DEFAULT 'medium',
          estimated_cost REAL NOT NULL DEFAULT 0.0
        );
      ''');

      await executor.runCustom('''
        CREATE TABLE todo_items (
          id TEXT NOT NULL PRIMARY KEY,
          title TEXT NOT NULL,
          description TEXT NOT NULL DEFAULT '',
          completed INTEGER NOT NULL DEFAULT 0,
          created_at INTEGER NOT NULL DEFAULT (strftime('%s', 'now') * 1000)
        );
      ''');

      // Seed v4 data
      await executor.runCustom(
        'INSERT INTO plan_templates (id, name, active_days) VALUES (?, ?, ?)',
        ['t1', 'Template 1', '0, 2, 4'],
      );
      await executor.runCustom(
        'INSERT INTO day_plans (id, date_str, day_of_week, date, week_key) VALUES (?, ?, ?, ?, ?)',
        [
          'd1',
          'Feb 10',
          'Monday',
          DateTime(2026, 2, 10).millisecondsSinceEpoch,
          '2026-W07',
        ],
      );

      // Now use TestDatabase to run the migration
      final database = TestDatabase(executor);

      // Run migration
      final m = database.createMigrator();
      await database.migration.onUpgrade(m, 4, 5);

      // Verify TemplateActiveDays
      final activeDays = await database
          .customSelect('SELECT * FROM template_active_days')
          .get();
      expect(activeDays.length, 3);
      final days = activeDays.map((row) => row.read<int>('day_index')).toSet();
      expect(days, {0, 2, 4});

      // Check PlanTemplates columns
      final templateInfo = await database
          .customSelect('PRAGMA table_info(plan_templates)')
          .get();
      final templateCols =
          templateInfo.map((c) => c.read<String>('name')).toSet();
      expect(templateCols.contains('active_days'), isFalse);

      // Check DayPlans columns
      final dayPlanInfo =
          await database.customSelect('PRAGMA table_info(day_plans)').get();
      final dayPlanCols =
          dayPlanInfo.map((c) => c.read<String>('name')).toSet();
      expect(dayPlanCols.contains('date_str'), isFalse);
      expect(dayPlanCols.contains('day_of_week'), isFalse);

      // Check TodoItems columns
      final todoInfo =
          await database.customSelect('PRAGMA table_info(todo_items)').get();
      final todoCols = todoInfo.map((c) => c.read<String>('name')).toSet();
      expect(
          todoCols,
          containsAll([
            'item_type',
            'duration_minutes',
            'checklist_json',
            'audio_file_path',
          ]),);

      await database.close();
    });

    test('v6 to v7 adds updated_at to todo_items backfilled from created_at',
        () async {
      final executor = NativeDatabase.memory();
      await executor.ensureOpen(_FakeUser());

      await executor.runCustom('''
        CREATE TABLE todo_items (
          id TEXT NOT NULL PRIMARY KEY,
          title TEXT NOT NULL,
          description TEXT NOT NULL DEFAULT '',
          completed INTEGER NOT NULL DEFAULT 0,
          created_at INTEGER NOT NULL,
          item_type TEXT NOT NULL DEFAULT 'note',
          duration_minutes INTEGER NOT NULL DEFAULT 0,
          checklist_json TEXT NOT NULL DEFAULT '',
          audio_file_path TEXT NOT NULL DEFAULT ''
        );
      ''');

      final createdAt = DateTime(2026, 6, 1).millisecondsSinceEpoch ~/ 1000;
      await executor.runCustom(
        'INSERT INTO todo_items (id, title, created_at) VALUES (?, ?, ?)',
        ['n1', 'Note 1', createdAt],
      );

      final database = TestDatabase(executor);
      final m = database.createMigrator();
      await database.migration.onUpgrade(m, 6, 7);

      final todoInfo =
          await database.customSelect('PRAGMA table_info(todo_items)').get();
      final todoCols = todoInfo.map((c) => c.read<String>('name')).toSet();
      expect(todoCols.contains('updated_at'), isTrue);

      final rows = await database.customSelect(
        'SELECT updated_at FROM todo_items WHERE id = ?',
        variables: [Variable.withString('n1')],
      ).get();
      expect(rows.first.read<int>('updated_at'), createdAt);

      // Re-running the migration must be a no-op, not an error.
      await database.migration.onUpgrade(m, 6, 7);

      await database.close();
    });
  });
}

class _FakeUser extends QueryExecutorUser {
  @override
  int get schemaVersion => 1;
  @override
  Future<void> beforeOpen(
      QueryExecutor executor, OpeningDetails details,) async {}
}

class TestDatabase extends AppDatabase {
  TestDatabase(QueryExecutor executor)
      : super.forTesting(DatabaseConnection(executor));

  @override
  Migrator createMigrator() => Migrator(this);
}
