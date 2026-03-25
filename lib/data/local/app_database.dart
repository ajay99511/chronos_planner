import 'dart:io';

import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;

import 'tables.dart';
import 'daos/task_dao.dart';
import 'daos/day_plan_dao.dart';
import 'daos/template_dao.dart';
import 'daos/preference_dao.dart';
import 'daos/todo_item_dao.dart';

part 'app_database.g.dart';

/// Main Drift database for Chronos Planner.
/// 
/// ## Responsibilities:
/// - Singleton database connection management
/// - Schema version control and migrations
/// - DAO factory (provides access to all data access objects)
/// 
/// ## Schema Version: 4
/// Migration history:
/// - **v1→v2**: Added `sourceTemplateId` to tasks, `activeDays` to templates
/// - **v2→v3**: Added `TodoItems` table
/// - **v3→v4**: Added energy/cost fields to tasks and template tasks
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
    TemplateTasks,
    Preferences,
    TodoItems
  ],
  daos: [TaskDao, DayPlanDao, TemplateDao, PreferenceDao, TodoItemDao],
)
class AppDatabase extends _$AppDatabase {
  AppDatabase._() : super(_openConnection());

  static AppDatabase? _instance;

  /// Singleton accessor. Lazily initializes on first access.
  /// 
  /// Thread-safe via Dart's single-threaded execution model.
  /// 
  /// **Important**: Call this at least once before accessing any DAOs
  /// to ensure the database is initialized.
  static AppDatabase get instance {
    _instance ??= AppDatabase._();
    return _instance!;
  }

  @override
  int get schemaVersion => 4;

  /// Migration strategy for schema upgrades.
  /// 
  /// Runs automatically when database version changes.
  /// Each `if (from < N)` block handles upgrade from version N-1 to N.
  @override
  MigrationStrategy get migration => MigrationStrategy(
        onCreate: (m) async {
          await m.createAll();
        },
        onUpgrade: (m, from, to) async {
          if (from < 2) {
            // Add sourceTemplateId to tasks table
            await customStatement(
                "ALTER TABLE tasks ADD COLUMN source_template_id TEXT NOT NULL DEFAULT ''");
            // Add activeDays to plan_templates table
            await customStatement(
                "ALTER TABLE plan_templates ADD COLUMN active_days TEXT NOT NULL DEFAULT ''");
          }
          if (from < 3) {
            // Add TodoItems table
            await m.createTable(todoItems);
          }
          if (from < 4) {
            // Add energy_level, estimated_cost, actual_cost to tasks
            await customStatement(
                "ALTER TABLE tasks ADD COLUMN energy_level TEXT NOT NULL DEFAULT 'medium'");
            await customStatement(
                "ALTER TABLE tasks ADD COLUMN estimated_cost REAL NOT NULL DEFAULT 0.0");
            await customStatement(
                "ALTER TABLE tasks ADD COLUMN actual_cost REAL NOT NULL DEFAULT 0.0");

            // Add energy_level, estimated_cost to template_tasks
            await customStatement(
                "ALTER TABLE template_tasks ADD COLUMN energy_level TEXT NOT NULL DEFAULT 'medium'");
            await customStatement(
                "ALTER TABLE template_tasks ADD COLUMN estimated_cost REAL NOT NULL DEFAULT 0.0");
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
