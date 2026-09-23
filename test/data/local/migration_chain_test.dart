import 'package:chronosky/data/local/app_database.dart';
import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

/// The whole migration chain, v1 to current, against seeded data.
///
/// This is how the code actually runs: drift calls `onUpgrade` **once** with the
/// user's real `from`, and every branch here is gated on `from` alone, so a user
/// on v1 executes all nine steps back to back. Testing steps in isolation — which
/// is all the suite did before — never exercises that, and the interactions are
/// where the risk lives: v5 and v10 both rebuild `tasks` from the current Dart
/// definition, which only works because v2 and v4 added the columns first.
///
/// Four steps (v1→v2, v2→v3, v3→v4, v5→v6) had no coverage at all, and v5→v6
/// performs destructive `TableMigration` rebuilds.
void main() {
  /// The schema as it stood at v1: no `source_template_id`, no energy or cost
  /// columns, no `todo_items`, and `day_plans` still carrying the denormalised
  /// `date_str` / `day_of_week` that v5 removes.
  Future<void> createV1Schema(QueryExecutor executor) async {
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
        description TEXT NOT NULL DEFAULT ''
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
        completed INTEGER NOT NULL DEFAULT 0,
        day_plan_id TEXT NOT NULL REFERENCES day_plans (id)
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
        priority TEXT NOT NULL DEFAULT 'medium'
      );
    ''');
    await executor.runCustom('''
      CREATE TABLE preferences (
        key TEXT NOT NULL PRIMARY KEY,
        value TEXT NOT NULL
      );
    ''');
  }

  Future<void> seedV1Data(QueryExecutor executor) async {
    final date = DateTime(2026, 2, 10).millisecondsSinceEpoch ~/ 1000;
    await executor.runCustom(
      'INSERT INTO day_plans (id, date_str, day_of_week, date, week_key) '
      'VALUES (?, ?, ?, ?, ?)',
      ['dp-1', 'Feb 10', 'Monday', date, '2026-W07'],
    );
    await executor.runCustom(
      'INSERT INTO tasks (id, title, start_time, end_time, type, day_plan_id) '
      'VALUES (?, ?, ?, ?, ?, ?)',
      ['task-1', 'Ancient task', '09:00', '10:00', 'work', 'dp-1'],
    );
    await executor.runCustom(
      'INSERT INTO plan_templates (id, name, description) VALUES (?, ?, ?)',
      ['tmpl-1', 'Deep Work Friday', 'Focused coding'],
    );
    await executor.runCustom(
      'INSERT INTO template_tasks '
      '(id, template_id, title, start_time, end_time, type) '
      'VALUES (?, ?, ?, ?, ?, ?)',
      ['ttask-1', 'tmpl-1', 'Deep Work Block', '09:00', '12:00', 'work'],
    );
    await executor.runCustom(
      'INSERT INTO preferences (key, value) VALUES (?, ?)',
      ['sort_order', 'desc'],
    );
  }

  Future<Set<String>> columnsOf(AppDatabase db, String table) async {
    final info = await db.customSelect('PRAGMA table_info($table)').get();
    return info.map((c) => c.read<String>('name')).toSet();
  }

  Future<bool> tableExists(AppDatabase db, String name) async {
    final row = await db.customSelect(
      "SELECT COUNT(*) AS cnt FROM sqlite_master WHERE type='table' AND name=?",
      variables: [Variable.withString(name)],
    ).getSingle();
    return row.read<int>('cnt') > 0;
  }

  Future<AppDatabase> upgradedFromV1() async {
    final executor = NativeDatabase.memory();
    await executor.ensureOpen(_FakeUser());
    await createV1Schema(executor);
    await seedV1Data(executor);

    final db = _TestDatabase(executor);
    // A genuine v1 database has no active_days column at all -- v2 adds it --
    // so recurrence data is covered separately by the v2 test below.
    await db.migration.onUpgrade(db.createMigrator(), 1, db.schemaVersion);
    return db;
  }

  test('a v1 database upgrades to the current schema with its data intact',
      () async {
    final db = await upgradedFromV1();
    addTearDown(db.close);

    // The task survived nine migrations, two of which rebuild its table.
    final tasks = await db.customSelect('SELECT * FROM tasks').get();
    expect(tasks, hasLength(1));
    expect(tasks.single.read<String>('title'), 'Ancient task');
    expect(tasks.single.read<String>('start_time'), '09:00');
    expect(
      tasks.single.read<String>('day_plan_id'),
      'dp-1',
      reason: 'the task must still point at its day after the v8 merge',
    );

    final templateTasks =
        await db.customSelect('SELECT * FROM template_tasks').get();
    expect(templateTasks.single.read<String>('title'), 'Deep Work Block');

    final prefs = await db.customSelect('SELECT value FROM preferences').get();
    expect(prefs.single.read<String>('value'), 'desc');
  });

  test('columns added along the way are present at the end', () async {
    final db = await upgradedFromV1();
    addTearDown(db.close);

    // v2 added source_template_id; v4 added the energy and cost columns.
    expect(
      await columnsOf(db, 'tasks'),
      containsAll([
        'source_template_id',
        'energy_level',
        'estimated_cost',
        'actual_cost',
      ]),
    );
    expect(
      await columnsOf(db, 'template_tasks'),
      containsAll(['energy_level', 'estimated_cost']),
    );
  });

  test('tables added along the way exist at the end', () async {
    final db = await upgradedFromV1();
    addTearDown(db.close);

    // v3 created todo_items; v5 created the active-days junction table.
    expect(await tableExists(db, 'todo_items'), isTrue);
    expect(await tableExists(db, 'template_active_days'), isTrue);

    // v5 and v7/v8 between them give todo_items its full column set.
    expect(
      await columnsOf(db, 'todo_items'),
      containsAll([
        'item_type',
        'duration_minutes',
        'checklist_json',
        'audio_file_path',
        'updated_at',
        'scheduled_at',
        'enabled',
      ]),
    );
  });

  test('legacy columns are gone by the end', () async {
    final db = await upgradedFromV1();
    addTearDown(db.close);

    // v5 drops these, and v6 exists to finish the job on databases where a
    // partial v5 left them behind.
    final dayPlanCols = await columnsOf(db, 'day_plans');
    expect(dayPlanCols, isNot(contains('date_str')));
    expect(dayPlanCols, isNot(contains('day_of_week')));
    expect(await columnsOf(db, 'plan_templates'), isNot(contains('active_days')));
  });

  test('the v10 constraints are live after upgrading, not just on fresh installs',
      () async {
    final db = await upgradedFromV1();
    addTearDown(db.close);

    // The rebuild has to actually carry the CHECK clauses across, or upgraded
    // users keep the old unguarded tables forever.
    await expectLater(
      db.customStatement(
        'INSERT INTO tasks (id, title, start_time, end_time, type, day_plan_id) '
        "VALUES ('bad', '', '09:00', '10:00', 'work', 'dp-1')",
      ),
      throwsA(isA<Exception>()),
      reason: 'an empty title must be rejected after an upgrade too',
    );
    await expectLater(
      db.customStatement(
        'INSERT INTO tasks (id, title, start_time, end_time, type, day_plan_id) '
        "VALUES ('bad2', 'Fine', '25:00', '10:00', 'work', 'dp-1')",
      ),
      throwsA(isA<Exception>()),
      reason: 'an out-of-range hour must be rejected after an upgrade too',
    );
  });

  test('re-running the whole chain is a no-op', () async {
    final db = await upgradedFromV1();
    addTearDown(db.close);

    // Every step is written to be idempotent; this is the assertion that keeps
    // it that way, since a half-applied upgrade re-runs from the same `from`.
    await db.migration.onUpgrade(db.createMigrator(), 1, db.schemaVersion);

    final tasks = await db.customSelect('SELECT id FROM tasks').get();
    expect(tasks.map((r) => r.read<String>('id')), ['task-1']);
  });

  test('v2 recurrence data lands in the junction table', () async {
    final executor = NativeDatabase.memory();
    await executor.ensureOpen(_FakeUser());
    await createV1Schema(executor);
    await seedV1Data(executor);
    // A v2-era database: active_days exists as a comma-separated column, which
    // v5 migrates into template_active_days.
    await executor.runCustom(
      "ALTER TABLE plan_templates ADD COLUMN active_days TEXT NOT NULL DEFAULT ''",
    );
    await executor.runCustom(
      'UPDATE plan_templates SET active_days = ? WHERE id = ?',
      ['0, 2, 4', 'tmpl-1'],
    );

    final db = _TestDatabase(executor);
    addTearDown(db.close);
    await db.migration.onUpgrade(db.createMigrator(), 2, db.schemaVersion);

    final days = await db
        .customSelect('SELECT day_index FROM template_active_days ORDER BY 1')
        .get();
    expect(days.map((r) => r.read<int>('day_index')).toList(), [0, 2, 4]);
    expect(
      await columnsOf(db, 'plan_templates'),
      isNot(contains('active_days')),
      reason: 'the denormalised column is dropped once migrated',
    );
  });
}

class _FakeUser extends QueryExecutorUser {
  @override
  int get schemaVersion => 1;

  @override
  Future<void> beforeOpen(
    QueryExecutor executor,
    OpeningDetails details,
  ) async {}
}

class _TestDatabase extends AppDatabase {
  _TestDatabase(QueryExecutor executor)
      : super.forTesting(DatabaseConnection(executor));

  @override
  Migrator createMigrator() => Migrator(this);
}
