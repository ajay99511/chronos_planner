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
/// ## Schema Version: 5
/// Migration history:
/// - **v1→v2**: Added `sourceTemplateId` to tasks, `activeDays` to templates
/// - **v2→v3**: Added `TodoItems` table
/// - **v3→v4**: Added energy/cost fields to tasks and template tasks
/// - **v4→v5**: Added itemType/durationMinutes/checklistJson/audioFilePath to TodoItems
/// - **v5→v6**: Cleanup of legacy columns from partial v5 migrations
/// - **v6→v7**: Added `updatedAt` to TodoItems (backfilled from createdAt)
/// - **v7→v8**: Merged duplicate DayPlans rows, made `day_plans.date` unique,
///   added `scheduledAt`/`enabled` to TodoItems for alarms
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
  int get schemaVersion => 8;

  @override
  MigrationStrategy get migration => MigrationStrategy(
        onCreate: (m) async {
          await m.createAll();
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
