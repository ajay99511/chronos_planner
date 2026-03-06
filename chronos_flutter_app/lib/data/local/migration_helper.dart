import 'dart:convert';

import 'package:drift/drift.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/day_plan_model.dart' as model;
import '../models/plan_template_model.dart' as model;
import 'app_database.dart';

/// One-time migration from SharedPreferences JSON to Drift tables.
/// Called on first launch after the upgrade; deletes SP keys afterwards.
class MigrationHelper {
  static const _spWeekKey = 'chronos-week';
  static const _spTemplatesKey = 'chronos-templates';
  static const _spSortOrderKey = 'chronos-sort-order';
  static const _spMigratedFlag = 'chronos-drift-migrated';

  static Future<void> migrateIfNeeded(AppDatabase db) async {
    final prefs = await SharedPreferences.getInstance();
    final alreadyMigrated = prefs.getBool(_spMigratedFlag) ?? false;

    if (alreadyMigrated) return;

    debugPrint('[MigrationHelper] Starting SP → Drift migration...');

    try {
      await _migrateWeekPlan(prefs, db);
      await _migrateTemplates(prefs, db);
      await _migratePreferences(prefs, db);

      // Mark migration complete
      await prefs.setBool(_spMigratedFlag, true);

      // Clean up old keys (keep flag)
      await prefs.remove(_spWeekKey);
      await prefs.remove(_spTemplatesKey);
      await prefs.remove(_spSortOrderKey);

      debugPrint('[MigrationHelper] Migration complete ✓');
    } catch (e) {
      debugPrint('[MigrationHelper] Migration error: $e');
      // Don't set flag — retry next launch
    }
  }

  static Future<void> _migrateWeekPlan(
      SharedPreferences prefs, AppDatabase db) async {
    final weekJson = prefs.getString(_spWeekKey);
    if (weekJson == null) return;

    final List<dynamic> decoded = jsonDecode(weekJson);
    final dayPlans = decoded.map((e) => model.DayPlan.fromJson(e)).toList();
    if (dayPlans.isEmpty) return;

    // Derive weekKey from the first day
    final monday = dayPlans.first.date;
    final weekNumber =
        ((monday.difference(DateTime(monday.year, 1, 1)).inDays) / 7).ceil() +
            1;
    final weekKey = '${monday.year}-W${weekNumber.toString().padLeft(2, '0')}';

    // Check if week already exists in Drift
    final exists = await db.dayPlanDao.weekExists(weekKey);
    if (exists) return;

    for (final dp in dayPlans) {
      await db.dayPlanDao.insertDayPlan(DayPlansCompanion(
        id: Value(dp.id),
        dateStr: Value(dp.dateStr),
        dayOfWeek: Value(dp.dayOfWeek),
        date: Value(dp.date),
        weekKey: Value(weekKey),
      ));

      for (final task in dp.tasks) {
        await db.taskDao.insertTask(TasksCompanion(
          id: Value(task.id),
          title: Value(task.title),
          description: Value(task.description),
          startTime: Value(task.startTime),
          endTime: Value(task.endTime),
          type: Value(task.type.name),
          priority: Value(task.priority.name),
          completed: Value(task.completed),
          dayPlanId: Value(dp.id),
        ));
      }
    }

    debugPrint(
        '[MigrationHelper] Migrated ${dayPlans.length} day plans with tasks');
  }

  static Future<void> _migrateTemplates(
      SharedPreferences prefs, AppDatabase db) async {
    final templatesJson = prefs.getString(_spTemplatesKey);
    if (templatesJson == null) return;

    final List<dynamic> decoded = jsonDecode(templatesJson);
    final templates =
        decoded.map((e) => model.PlanTemplate.fromJson(e)).toList();

    for (final tmpl in templates) {
      await db.templateDao.insertTemplate(PlanTemplatesCompanion(
        id: Value(tmpl.id),
        name: Value(tmpl.name),
        description: Value(tmpl.description),
      ));

      for (final task in tmpl.tasks) {
        await db.templateDao.insertTemplateTask(TemplateTasksCompanion(
          id: Value(task.id),
          templateId: Value(tmpl.id),
          title: Value(task.title),
          description: Value(task.description),
          startTime: Value(task.startTime),
          endTime: Value(task.endTime),
          type: Value(task.type.name),
          priority: Value(task.priority.name),
        ));
      }
    }

    debugPrint('[MigrationHelper] Migrated ${templates.length} templates');
  }

  static Future<void> _migratePreferences(
      SharedPreferences prefs, AppDatabase db) async {
    final sortOrder = prefs.getString(_spSortOrderKey);
    if (sortOrder != null) {
      await db.preferenceDao.setValue('sort_order', sortOrder);
    }
  }
}
