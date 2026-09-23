import 'dart:io';

import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:meta/meta.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;
import 'package:sqlite3/sqlite3.dart';
import 'package:sqlite3_flutter_libs/sqlite3_flutter_libs.dart';

import 'package:chronosky/data/local/tables.dart';
import 'package:chronosky/data/local/daos/task_dao.dart';
import 'package:chronosky/data/local/daos/day_plan_dao.dart';
import 'package:chronosky/data/local/daos/template_dao.dart';
import 'package:chronosky/data/local/daos/preference_dao.dart';
import 'package:chronosky/data/local/daos/todo_item_dao.dart';

part 'app_database.g.dart';

/// Main Drift database for Chronos Planner.
///
/// ## Responsibilities:
/// - Singleton database connection management
/// - Schema version control and migrations
/// - DAO factory (provides access to all data access objects)
///
/// ## Schema Version: 10
/// Migration history:
/// - **v1→v2**: Added `sourceTemplateId` to tasks, `activeDays` to templates
/// - **v2→v3**: Added `TodoItems` table
/// - **v3→v4**: Added energy/cost fields to tasks and template tasks
/// - **v4→v5**: Added itemType/durationMinutes/checklistJson/audioFilePath to TodoItems
/// - **v5→v6**: Cleanup of legacy columns from partial v5 migrations
/// - **v6→v7**: Added `updatedAt` to TodoItems (backfilled from createdAt)
/// - **v7→v8**: Merged duplicate DayPlans rows, made `day_plans.date` unique,
///   added `scheduledAt`/`enabled` to TodoItems for alarms
/// - **v8→v9**: Swept rows orphaned while `PRAGMA foreign_keys` was off (see
///   [_sweepOrphans]); enforcement is now enabled in `beforeOpen`
/// - **v9→v10**: Added SQL CHECK constraints to task title, clock times and
///   costs (see [_quarantineInvalidTaskRows]); rows that violate them are
///   moved aside rather than blocking the upgrade
///
/// ## Tables:
/// | Table | Purpose |
/// |-------|---------|
/// | [Tasks] | Individual scheduled tasks |
/// | [DayPlans] | Day containers (7 per week) |
/// | [PlanTemplates] | Reusable plan templates |
/// | [TemplateTasks] | Tasks belonging to templates |
/// | [Preferences] | Key-value store |
/// | [TodoItems] | Standalone todo tasks |
///
/// ## Usage:
/// ```dart
/// // Get singleton instance
/// final db = AppDatabase.instance;
///
/// // Access DAOs
/// final tasks = await db.taskDao.getTasksForDay(dayPlanId);
/// await db.dayPlanDao.insertDayPlan(plan);
/// ```
///
/// ## Storage Location:
/// Platform-specific documents directory:
/// - Windows: `C:\Users\<user>\AppData\Roaming\...`
/// - macOS: `~/Library/Application Support/...`
/// - Linux: `~/.local/share/...`
/// Database file: `chronos_planner.sqlite`
@DriftDatabase(
  tables: [
    Tasks,
    DayPlans,
    PlanTemplates,
    TemplateActiveDays,
    TemplateTasks,
    Preferences,
    TodoItems,
  ],
  daos: [TaskDao, DayPlanDao, TemplateDao, PreferenceDao, TodoItemDao],
)
class AppDatabase extends _$AppDatabase {
  AppDatabase._() : super(_openConnection());

  @visibleForTesting
  AppDatabase.forTesting(DatabaseConnection super.connection);

  static AppDatabase? _instance;

  /// Singleton accessor. Lazily initializes on first access.
  static AppDatabase get instance {
    _instance ??= AppDatabase._();
    return _instance!;
  }

  @override
  int get schemaVersion => 10;

  /// Tables whose child rows could be orphaned while foreign keys were off,
  /// paired with the parent they must reference.
  ///
  /// `(child table, child column, parent table, parent column)`.
  ///
  /// These identifiers are interpolated into SQL by [_sweepOrphans] because
  /// SQL cannot parameterize table or column names. That is safe only because
  /// this list is a private compile-time constant — never widen it to accept
  /// runtime input.
  static const List<(String, String, String, String)> _childToParent = [
    ('tasks', 'day_plan_id', 'day_plans', 'id'),
    ('template_tasks', 'template_id', 'plan_templates', 'id'),
    ('template_active_days', 'template_id', 'plan_templates', 'id'),
  ];

  /// Removes rows whose parent no longer exists.
  ///
  /// `ON DELETE CASCADE` was declared from schema v5 but never enforced,
  /// because SQLite defaults `PRAGMA foreign_keys` to OFF per connection and
  /// nothing turned it on. Any delete performed before v9 therefore left its
  /// children behind. Enabling enforcement does not clean those up — SQLite
  /// only validates rows it touches — so they are swept once here.
  ///
  /// Orphans are copied to `<table>_orphaned_v8` before deletion. They are
  /// unreachable by the app (every read joins through the missing parent), but
  /// they are still user-authored rows, so the removal stays reversible.
  Future<void> _sweepOrphans() async {
    Future<bool> tableExists(String name) async {
      final result = await customSelect(
        "SELECT COUNT(*) AS cnt FROM sqlite_master WHERE type='table' AND name=?",
        variables: [Variable.withString(name)],
      ).getSingle();
      return result.read<int>('cnt') > 0;
    }

    for (final (child, childCol, parent, parentCol) in _childToParent) {
      // A partially-built schema is normal here: onUpgrade steps are gated on
      // `from` alone, so this runs against databases that predate some of
      // these tables. Matches the existence checks in the v5 and v8 steps.
      if (!await tableExists(child) || !await tableExists(parent)) continue;

      final orphanFilter = '$childCol NOT IN (SELECT $parentCol FROM $parent)';

      final count = await customSelect(
        'SELECT COUNT(*) AS cnt FROM $child WHERE $orphanFilter',
      ).getSingle();
      if (count.read<int>('cnt') == 0) continue;

      await customStatement(
        'CREATE TABLE IF NOT EXISTS ${child}_orphaned_v8 '
        'AS SELECT * FROM $child WHERE $orphanFilter',
      );
      await customStatement('DELETE FROM $child WHERE $orphanFilter');
    }
  }

  /// Columns guarded by the v10 CHECK constraints, per table.
  ///
  /// The predicate matches rows that would *violate* the new constraints, so
  /// they can be moved aside before the table is rebuilt with them.
  static const List<(String, String)> _taskLikeTables = [
    ('tasks', 'actual_cost'),
    ('template_tasks', ''),
  ];

  /// Columns the v10 constraints reference.
  static const List<String> _constrainedColumns = [
    'title',
    'start_time',
    'end_time',
    'estimated_cost',
  ];

  /// Whether [table] exists and carries every column v10 constrains.
  ///
  /// onUpgrade branches are gated on `from` alone, so every v10 step also runs
  /// against schemas that predate some of these columns. Both the quarantine
  /// and the table rebuild have to tolerate that.
  Future<bool> _isConstrainable(String table) async {
    final cols = await customSelect('PRAGMA table_info($table)').get();
    final names = cols.map((c) => c.read<String>('name')).toSet();
    return names.containsAll(_constrainedColumns);
  }

  /// Moves rows that the v10 constraints would reject into
  /// `<table>_invalid_v9`, so the upgrade cannot fail on historical data.
  ///
  /// Adding a CHECK constraint in SQLite means rebuilding the table and copying
  /// every row; a single violating row would abort that copy and leave the app
  /// unable to open its own database. Since validation only reached the write
  /// path in a later version, rows written by earlier builds may well violate
  /// it — an empty title, or a time like "9:00" that the old asserts let
  /// through in release. Quarantining keeps the data recoverable instead of
  /// choosing between deleting it and refusing to start.
  Future<int> _quarantineInvalidTaskRows() async {
    var moved = 0;
    for (final (table, extraCostColumn) in _taskLikeTables) {
      if (!await _isConstrainable(table)) continue;

      final costChecks = [
        'estimated_cost < 0.0',
        if (extraCostColumn.isNotEmpty) '$extraCostColumn < 0.0',
      ].join(' OR ');

      final invalid = 'length(title) NOT BETWEEN 1 AND 200'
          " OR start_time NOT GLOB '[0-2][0-9]:[0-5][0-9]'"
          " OR start_time > '23:59'"
          " OR end_time NOT GLOB '[0-2][0-9]:[0-5][0-9]'"
          " OR end_time > '23:59'"
          ' OR $costChecks';

      final count = await customSelect(
        'SELECT COUNT(*) AS cnt FROM $table WHERE $invalid',
      ).getSingle();
      final found = count.read<int>('cnt');
      if (found == 0) continue;

      await customStatement(
        'CREATE TABLE IF NOT EXISTS ${table}_invalid_v9 '
        'AS SELECT * FROM $table WHERE $invalid',
      );
      await customStatement('DELETE FROM $table WHERE $invalid');
      moved += found;
    }
    return moved;
  }

  /// Counts tasks still attached to a `day_plans` row that the v8 duplicate
  /// merge is about to delete.
  ///
  /// The merge reparents tasks onto the surviving row per date and then drops
  /// the duplicates. This is the invariant that has to hold in between: once
  /// reparenting is done, nothing may still point at a doomed row. A non-zero
  /// result means the delete would strand user data.
  @visibleForTesting
  Future<int> tasksStrandedByMerge() async {
    final row = await customSelect(
      'SELECT COUNT(*) AS cnt FROM tasks WHERE day_plan_id IN ('
      '  SELECT id FROM day_plans WHERE rowid NOT IN ('
      '    SELECT MIN(rowid) FROM day_plans GROUP BY date'
      '  )'
      ')',
    ).getSingle();
    return row.read<int>('cnt');
  }

  @override
  MigrationStrategy get migration => MigrationStrategy(
        onCreate: (m) async {
          await m.createAll();
        },
        // SQLite defaults `foreign_keys` to OFF on every connection, which
        // silently turns the ON DELETE CASCADE clauses in tables.dart into
        // no-ops. Set here rather than in onUpgrade because migrations run
        // inside a transaction (the pragma is a no-op there) and because
        // TableMigration's create-copy-drop-rename cycle would trip the
        // constraints it is in the middle of rebuilding.
        beforeOpen: (details) async {
          await customStatement('PRAGMA foreign_keys = ON');
        },
        onUpgrade: (m, from, to) async {
          if (from < 2) {
            final taskCols =
                await customSelect('PRAGMA table_info(tasks)').get();
            final taskColNames =
                taskCols.map((c) => c.read<String>('name')).toSet();
            if (!taskColNames.contains('source_template_id')) {
              await customStatement(
                "ALTER TABLE tasks ADD COLUMN source_template_id TEXT NOT NULL DEFAULT ''",
              );
            }

            final tmplCols =
                await customSelect('PRAGMA table_info(plan_templates)').get();
            final tmplColNames =
                tmplCols.map((c) => c.read<String>('name')).toSet();
            if (!tmplColNames.contains('active_days')) {
              await customStatement(
                "ALTER TABLE plan_templates ADD COLUMN active_days TEXT NOT NULL DEFAULT ''",
              );
            }
          }
          if (from < 3) {
            // Use customStatement to check existence before creating
            final existing = await customSelect(
              "SELECT COUNT(*) as cnt FROM sqlite_master WHERE type='table' AND name='todo_items'",
            ).get();
            if ((existing.first.read<int>('cnt')) == 0) {
              await m.createTable(todoItems);
            }
          }
          if (from < 4) {
            // Check existing columns before adding to handle partially-migrated DBs
            final taskCols =
                await customSelect('PRAGMA table_info(tasks)').get();
            final taskColNames =
                taskCols.map((c) => c.read<String>('name')).toSet();

            if (!taskColNames.contains('energy_level')) {
              await customStatement(
                "ALTER TABLE tasks ADD COLUMN energy_level TEXT NOT NULL DEFAULT 'medium'",
              );
            }
            if (!taskColNames.contains('estimated_cost')) {
              await customStatement(
                'ALTER TABLE tasks ADD COLUMN estimated_cost REAL NOT NULL DEFAULT 0.0',
              );
            }
            if (!taskColNames.contains('actual_cost')) {
              await customStatement(
                'ALTER TABLE tasks ADD COLUMN actual_cost REAL NOT NULL DEFAULT 0.0',
              );
            }

            final tmplCols =
                await customSelect('PRAGMA table_info(template_tasks)').get();
            final tmplColNames =
                tmplCols.map((c) => c.read<String>('name')).toSet();

            if (!tmplColNames.contains('energy_level')) {
              await customStatement(
                "ALTER TABLE template_tasks ADD COLUMN energy_level TEXT NOT NULL DEFAULT 'medium'",
              );
            }
            if (!tmplColNames.contains('estimated_cost')) {
              await customStatement(
                'ALTER TABLE template_tasks ADD COLUMN estimated_cost REAL NOT NULL DEFAULT 0.0',
              );
            }
          }
          if (from < 5) {
            // Helper to check if a table exists
            Future<bool> tableExists(String name) async {
              final result = await customSelect(
                "SELECT COUNT(*) as cnt FROM sqlite_master WHERE type='table' AND name=?",
                variables: [Variable.withString(name)],
              ).get();
              return (result.first.read<int>('cnt')) > 0;
            }

            // Helper to check if a column exists in a table
            Future<Set<String>> getColumnNames(String tableName) async {
              final cols =
                  await customSelect('PRAGMA table_info($tableName)').get();
              return cols.map((c) => c.read<String>('name')).toSet();
            }

            // Helper to check if an index exists
            Future<bool> indexExists(String name) async {
              final result = await customSelect(
                "SELECT COUNT(*) as cnt FROM sqlite_master WHERE type='index' AND name=?",
                variables: [Variable.withString(name)],
              ).get();
              return (result.first.read<int>('cnt')) > 0;
            }

            // 1. Create junction table (if not already created by a previous failed attempt)
            if (!await tableExists('template_active_days')) {
              await m.createTable(templateActiveDays);
            }

            // 2. Migrate active_days data from plan_templates (if column still exists)
            final ptCols = await getColumnNames('plan_templates');
            if (ptCols.contains('active_days')) {
              final templates = await customSelect(
                      'SELECT id, active_days FROM plan_templates',)
                  .get();
              for (final row in templates) {
                final id = row.read<String>('id');
                final activeDaysStr = row.read<String>('active_days');
                if (activeDaysStr.isNotEmpty) {
                  final indices = activeDaysStr
                      .split(',')
                      .map((e) => int.tryParse(e.trim()))
                      .whereType<int>()
                      .where((d) => d >= 0 && d <= 6);
                  for (final dayIndex in indices) {
                    // Use INSERT OR IGNORE to handle duplicates from retries
                    await customStatement(
                      'INSERT OR IGNORE INTO template_active_days (template_id, day_index) VALUES (?, ?)',
                      [id, dayIndex],
                    );
                  }
                }
              }

              // 3. Drop active_days from PlanTemplates
              // ignore: experimental_member_use
              await m.alterTable(TableMigration(planTemplates));
            }

            // 4. Remove date_str and day_of_week from DayPlans (if they still exist)
            final dpCols = await getColumnNames('day_plans');
            if (dpCols.contains('date_str') || dpCols.contains('day_of_week')) {
              // ignore: experimental_member_use
              await m.alterTable(TableMigration(dayPlans));
            }

            // 5. Recreate tasks and template_tasks with ON DELETE CASCADE
            // (alterTable is safe to re-run — it creates new, copies, drops old, renames)
            // ignore: experimental_member_use
            await m.alterTable(TableMigration(tasks));
            // ignore: experimental_member_use
            await m.alterTable(TableMigration(templateTasks));

            // 6. Create indexes (only if they don't already exist)
            if (!await indexExists('idx_tasks_day_plan_id')) {
              await m.createIndex(idxTasksDayPlanId);
            }
            if (!await indexExists('idx_template_tasks_template_id')) {
              await m.createIndex(idxTemplateTasksTemplateId);
            }
            if (!await indexExists('idx_day_plans_week_key')) {
              await m.createIndex(idxDayPlansWeekKey);
            }
            if (!await indexExists('idx_day_plans_date')) {
              await m.createIndex(idxDayPlansDate);
            }

            // 7. Ensure TodoItems has all v5 columns
            final todoColNames = await getColumnNames('todo_items');

            if (!todoColNames.contains('item_type')) {
              await customStatement(
                  "ALTER TABLE todo_items ADD COLUMN item_type TEXT NOT NULL DEFAULT 'note'",);
            }
            if (!todoColNames.contains('duration_minutes')) {
              await customStatement(
                  'ALTER TABLE todo_items ADD COLUMN duration_minutes INTEGER NOT NULL DEFAULT 0',);
            }
            if (!todoColNames.contains('checklist_json')) {
              await customStatement(
                  "ALTER TABLE todo_items ADD COLUMN checklist_json TEXT NOT NULL DEFAULT ''",);
            }
            if (!todoColNames.contains('audio_file_path')) {
              await customStatement(
                  "ALTER TABLE todo_items ADD COLUMN audio_file_path TEXT NOT NULL DEFAULT ''",);
            }
          }
          if (from < 6) {
            // Forcefully clean up any legacy columns that survived v5 due to partial migrations or skipped version bumps
            Future<Set<String>> getColumnNames(String tableName) async {
              final cols =
                  await customSelect('PRAGMA table_info($tableName)').get();
              return cols.map((c) => c.read<String>('name')).toSet();
            }

            // Clean day_plans
            final dpCols = await getColumnNames('day_plans');
            if (dpCols.contains('date_str') || dpCols.contains('day_of_week')) {
              // ignore: experimental_member_use
              await m.alterTable(TableMigration(dayPlans));
            }

            // Clean plan_templates
            final ptCols = await getColumnNames('plan_templates');
            if (ptCols.contains('active_days')) {
              // ignore: experimental_member_use
              await m.alterTable(TableMigration(planTemplates));
            }
          }
          if (from < 7) {
            final todoCols =
                await customSelect('PRAGMA table_info(todo_items)').get();
            final todoColNames =
                todoCols.map((c) => c.read<String>('name')).toSet();
            if (!todoColNames.contains('updated_at')) {
              // SQLite forbids non-constant defaults in ADD COLUMN, so add
              // with 0 and backfill from created_at.
              await customStatement(
                'ALTER TABLE todo_items ADD COLUMN updated_at INTEGER NOT NULL DEFAULT 0',
              );
              await customStatement(
                'UPDATE todo_items SET updated_at = created_at',
              );
            }
          }
          if (from < 8) {
            Future<bool> tableExists(String name) async {
              final result = await customSelect(
                "SELECT COUNT(*) as cnt FROM sqlite_master WHERE type='table' AND name=?",
                variables: [Variable.withString(name)],
              ).get();
              return (result.first.read<int>('cnt')) > 0;
            }

            // Historically nothing stopped two day_plans rows from sharing a
            // date; when that happened only one was ever read back, so tasks
            // attached to the others silently disappeared. Merge duplicates
            // into the oldest row per date, then enforce uniqueness.
            if (await tableExists('day_plans') && await tableExists('tasks')) {
              // Snapshot both tables before a destructive, non-reversible
              // merge. Cheap — day_plans holds roughly seven rows per week —
              // and it is the only route back if the reparenting below turns
              // out to be wrong on a shape we have not seen.
              await customStatement(
                'CREATE TABLE IF NOT EXISTS day_plans_backup_v7 '
                'AS SELECT * FROM day_plans',
              );
              await customStatement(
                'CREATE TABLE IF NOT EXISTS tasks_backup_v7 '
                'AS SELECT * FROM tasks',
              );

              await customStatement(
              'UPDATE tasks SET day_plan_id = ('
              '  SELECT dp_keep.id FROM day_plans dp_keep'
              '  WHERE dp_keep.date = ('
              '    SELECT dp.date FROM day_plans dp WHERE dp.id = tasks.day_plan_id'
              '  )'
              '  ORDER BY dp_keep.rowid LIMIT 1'
              ') WHERE day_plan_id IN ('
              '  SELECT id FROM day_plans WHERE rowid NOT IN ('
              '    SELECT MIN(rowid) FROM day_plans GROUP BY date'
              '  )'
              ')',
              );

              // Fail closed: refuse to delete rows that still own tasks
              // rather than silently dropping the user's schedule. Should be
              // unreachable — the reparent above covers every duplicate — so
              // reaching it means the merge does not understand the data.
              final stranded = await tasksStrandedByMerge();
              if (stranded > 0) {
                throw StateError(
                  'v8 migration aborted: $stranded task(s) still reference a '
                  'duplicate day_plans row after reparenting. No rows were '
                  'deleted; the pre-migration state is preserved in '
                  'day_plans_backup_v7 and tasks_backup_v7.',
                );
              }

              await customStatement(
                'DELETE FROM day_plans WHERE rowid NOT IN ('
                '  SELECT MIN(rowid) FROM day_plans GROUP BY date'
                ')',
              );
              await customStatement('DROP INDEX IF EXISTS idx_day_plans_date');
              await m.createIndex(idxDayPlansDate);
            }

            if (await tableExists('todo_items')) {
              final todoCols =
                  await customSelect('PRAGMA table_info(todo_items)').get();
              final todoColNames =
                  todoCols.map((c) => c.read<String>('name')).toSet();
              if (!todoColNames.contains('scheduled_at')) {
                await customStatement(
                  'ALTER TABLE todo_items ADD COLUMN scheduled_at INTEGER',
                );
              }
              if (!todoColNames.contains('enabled')) {
                await customStatement(
                  'ALTER TABLE todo_items ADD COLUMN enabled INTEGER NOT NULL DEFAULT 1',
                );
              }
            }
          }
          if (from < 9) {
            // Clears the backlog left by v5–v8 deletes that ran without
            // foreign key enforcement. Safe to re-run: the sweep is a no-op
            // once no orphans remain.
            await _sweepOrphans();
          }
          if (from < 10) {
            // Rebuild both task tables so their CHECK constraints exist in
            // SQL. Violating rows are moved aside first, or the copy would
            // abort and leave the database unopenable.
            await _quarantineInvalidTaskRows();

            if (await _isConstrainable('tasks')) {
              // ignore: experimental_member_use
              await m.alterTable(TableMigration(tasks));
            }
            if (await _isConstrainable('template_tasks')) {
              // ignore: experimental_member_use
              await m.alterTable(TableMigration(templateTasks));
            }
          }
        },
      );
}

LazyDatabase _openConnection() {
  return LazyDatabase(() async {
    final dbFolder = await getApplicationDocumentsDirectory();
    final file = File(p.join(dbFolder.path, 'chronos_planner.sqlite'));

    if (Platform.isAndroid) {
      // Work around limitations on old Android versions
      await applyWorkaroundToOpenSqlite3OnOldAndroidVersions();

      // SQLite needs a place to store temporary files for large transactions/migrations
      // The default /tmp is not accessible on Android due to sandboxing.
      final cachebase = (await getTemporaryDirectory()).path;
      sqlite3.tempDirectory = cachebase;
    }

    return NativeDatabase.createInBackground(file);
  });
}
