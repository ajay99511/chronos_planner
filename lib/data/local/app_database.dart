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

  /// Singleton accessor.
  static AppDatabase get instance {
    _instance ??= AppDatabase._();
    return _instance!;
  }

  @override
  int get schemaVersion => 3;

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
