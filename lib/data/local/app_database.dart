import 'dart:io';

import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:meta/meta.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;

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
  int get schemaVersion => 5;

  @override
  MigrationStrategy get migration => MigrationStrategy(
        onCreate: (m) async {
          await m.createAll();
        },
        onUpgrade: (m, from, to) async {
          if (from < 2) {
            await customStatement(
                "ALTER TABLE tasks ADD COLUMN source_template_id TEXT NOT NULL DEFAULT ''",);
            await customStatement(
                "ALTER TABLE plan_templates ADD COLUMN active_days TEXT NOT NULL DEFAULT ''",);
          }
          if (from < 3) {
            await m.createTable(todoItems);
          }
          if (from < 4) {
            await customStatement(
                "ALTER TABLE tasks ADD COLUMN energy_level TEXT NOT NULL DEFAULT 'medium'",);
            await customStatement(
                'ALTER TABLE tasks ADD COLUMN estimated_cost REAL NOT NULL DEFAULT 0.0',);
            await customStatement(
                'ALTER TABLE tasks ADD COLUMN actual_cost REAL NOT NULL DEFAULT 0.0',);

            await customStatement(
                "ALTER TABLE template_tasks ADD COLUMN energy_level TEXT NOT NULL DEFAULT 'medium'",);
            await customStatement(
                'ALTER TABLE template_tasks ADD COLUMN estimated_cost REAL NOT NULL DEFAULT 0.0',);
          }
          if (from < 5) {
            await transaction(() async {
              // 1. Create junction table
              await m.createTable(templateActiveDays);

              // 2. Migrate data from PlanTemplates.active_days to TemplateActiveDays
              final templates = await customSelect('SELECT id, active_days FROM plan_templates').get();
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
                    await customStatement(
                      'INSERT INTO template_active_days (template_id, day_index) VALUES (?, ?)',
                      [id, dayIndex],
                    );
                  }
                }
              }

              // 3. Drop active_days from PlanTemplates
              // ignore: experimental_member_use
              await m.alterTable(TableMigration(planTemplates));

              // 4. Remove date_str and day_of_week from DayPlans
              // ignore: experimental_member_use
              await m.alterTable(TableMigration(dayPlans));

              // 5. Recreate tasks and template_tasks with ON DELETE CASCADE
              // ignore: experimental_member_use
              await m.alterTable(TableMigration(tasks));
              // ignore: experimental_member_use
              await m.alterTable(TableMigration(templateTasks));
              
              // 6. Create indexes
              await m.createIndex(idxTasksDayPlanId);
              await m.createIndex(idxTemplateTasksTemplateId);
              await m.createIndex(idxDayPlansWeekKey);
              await m.createIndex(idxDayPlansDate);
              
              // 7. Ensure TodoItems has all v5 columns
              final columns = await customSelect('PRAGMA table_info(todo_items)').get();
              final columnNames = columns.map((c) => c.read<String>('name')).toSet();
              
              if (!columnNames.contains('item_type')) {
                await customStatement("ALTER TABLE todo_items ADD COLUMN item_type TEXT NOT NULL DEFAULT 'note'");
              }
              if (!columnNames.contains('duration_minutes')) {
                await customStatement('ALTER TABLE todo_items ADD COLUMN duration_minutes INTEGER NOT NULL DEFAULT 0');
              }
              if (!columnNames.contains('checklist_json')) {
                await customStatement("ALTER TABLE todo_items ADD COLUMN checklist_json TEXT NOT NULL DEFAULT ''");
              }
              if (!columnNames.contains('audio_file_path')) {
                await customStatement("ALTER TABLE todo_items ADD COLUMN audio_file_path TEXT NOT NULL DEFAULT ''");
              }
            });
          }
        },
      );
}

LazyDatabase _openConnection() {
  return LazyDatabase(() async {
    final dbFolder = await getApplicationDocumentsDirectory();
    final file = File(p.join(dbFolder.path, 'chronos_planner.sqlite'));
    return NativeDatabase.createInBackground(file);
  });
}
