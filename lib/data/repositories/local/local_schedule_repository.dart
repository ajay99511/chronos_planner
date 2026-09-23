import 'dart:io';
import 'package:drift/drift.dart';
import 'package:uuid/uuid.dart';

import 'package:chronosky/core/result.dart';
import 'package:chronosky/data/repositories/local/db_guard.dart';
import 'package:chronosky/data/models/day_plan_model.dart' as domain;
import 'package:chronosky/data/models/task_model.dart' as domain;
import 'package:chronosky/data/local/app_database.dart';
import 'package:chronosky/data/local/daos/day_plan_dao.dart';
import 'package:chronosky/data/local/daos/task_dao.dart';
import 'package:chronosky/data/repositories/schedule_repository.dart';

/// Drift-backed implementation of [ScheduleRepository].
class LocalScheduleRepository implements ScheduleRepository {
  final DayPlanDao _dayPlanDao;
  final TaskDao _taskDao;

  LocalScheduleRepository(this._dayPlanDao, this._taskDao);

  /// Strips the time component so a stored row and a generated date compare
  /// equal as map keys.
  static DateTime _dayKey(DateTime date) =>
      DateTime(date.year, date.month, date.day);

  String _calculateWeekKey(DateTime date) {
    final monday = date.subtract(Duration(days: date.weekday - 1));
    final weekNumber =
        ((monday.difference(DateTime(monday.year, 1, 1)).inDays) / 7).ceil() +
            1;
    return '${monday.year}-W${weekNumber.toString().padLeft(2, '0')}';
  }

  Future<T> _retry<T>(Future<T> Function() action) async {
    int attempts = 0;
    int delay = 200;
    while (true) {
      try {
        return await action();
      } on FileSystemException {
        attempts++;
        if (attempts >= 3) rethrow;
        await Future.delayed(Duration(milliseconds: delay));
        delay *= 2;
      }
    }
  }

  /// Retries transient filesystem contention, then maps failures via [guardDb].
  Future<Result<T>> _wrap<T>(Future<T> Function() action) =>
      guardDb(() => _retry(action));

  @override
  Future<Result<List<domain.DayPlan>>> getUpcomingDays(int count) async {
    return _wrap(() async {
      final now = DateTime.now();
      final today = DateTime(now.year, now.month, now.day);

      // Run the read-create-read cycle atomically so concurrent callers
      // cannot each decide a day is missing and insert competing rows.
      return _dayPlanDao.attachedDatabase.transaction(() async {
        /// Day rows keyed by calendar day, so lookups are O(1). The previous
        /// linear scan ran inside the per-day loop, making it O(n^2).
        Map<DateTime, DayPlan> byDate(List<DayPlan> plans) => {
              for (final p in plans) _dayKey(p.date): p,
            };

        var plansByDate = byDate(await _dayPlanDao.getDayPlansFrom(today, count));

        final List<DayPlansCompanion> newDays = [];
        for (int i = 0; i < count; i++) {
          final date = today.add(Duration(days: i));
          if (!plansByDate.containsKey(date)) {
            newDays.add(
              DayPlansCompanion(
                id: Value(const Uuid().v4()),
                date: Value(date),
                weekKey: Value(_calculateWeekKey(date)),
              ),
            );
          }
        }

        if (newDays.isNotEmpty) {
          // insertOrIgnore: if a row for the date appeared meanwhile, keep it.
          await _dayPlanDao.insertDayPlans(newDays);
          // Re-read so returned ids always match the rows that actually won.
          plansByDate =
              byDate(await _dayPlanDao.getDayPlansFrom(today, count));
        }

        // Resolve every day first, then read all their tasks in one query
        // rather than one per day.
        final List<DayPlan> resolved = [];
        for (int i = 0; i < count; i++) {
          final date = today.add(Duration(days: i));
          final existing = plansByDate[date];
          if (existing == null) {
            throw StateError('Day plan missing after insert for $date');
          }
          resolved.add(existing);
        }

        final dbTasks = await _taskDao.getTasksForDays(
          [for (final plan in resolved) plan.id],
        );
        final tasksByPlan = <String, List<domain.Task>>{};
        for (final task in dbTasks) {
          tasksByPlan
              .putIfAbsent(task.dayPlanId, () => [])
              .add(_dbTaskToModel(task));
        }

        return [
          for (final plan in resolved)
            domain.DayPlan(
              id: plan.id,
              date: plan.date,
              // Already ordered by start time by the query.
              tasks: tasksByPlan[plan.id] ?? const [],
            ),
        ];
      });
    });
  }

  /// Returns the id of the day plan for [targetDate], creating the row if it
  /// does not exist yet. The insert uses `INSERT OR IGNORE`, so under a race
  /// the id is re-resolved to whichever row survived.
  Future<String> _ensureDayPlanId(DateTime targetDate) async {
    final existing = await _dayPlanDao.getDayPlanId(targetDate);
    if (existing != null) return existing;

    await _dayPlanDao.insertDayPlan(
      DayPlansCompanion(
        id: Value(const Uuid().v4()),
        date: Value(targetDate),
        weekKey: Value(_calculateWeekKey(targetDate)),
      ),
    );

    final id = await _dayPlanDao.getDayPlanId(targetDate);
    if (id == null) {
      throw StateError('Failed to create day plan for $targetDate');
    }
    return id;
  }

  @override
  Future<Result<void>> addTaskToDate(DateTime date, domain.Task task) async {
    return _wrap(() async {
      final targetDate = DateTime(date.year, date.month, date.day);
      await _dayPlanDao.attachedDatabase.transaction(() async {
        final dayPlanId = await _ensureDayPlanId(targetDate);
        await _taskDao.insertTask(_modelTaskToCompanion(task, dayPlanId));
      });
    });
  }

  @override
  Future<Result<void>> addTasksToDate(
    DateTime date,
    List<domain.Task> tasksToAdd,
  ) async {
    return _wrap(() async {
      if (tasksToAdd.isEmpty) return;
      final targetDate = DateTime(date.year, date.month, date.day);
      await _dayPlanDao.attachedDatabase.transaction(() async {
        final dayPlanId = await _ensureDayPlanId(targetDate);
        await _taskDao.insertTasks(
          tasksToAdd.map((t) => _modelTaskToCompanion(t, dayPlanId)).toList(),
        );
      });
    });
  }

  @override
  Future<Result<void>> addTask(String dayPlanId, domain.Task task) {
    return _wrap(() async {
      await _taskDao.insertTask(_modelTaskToCompanion(task, dayPlanId));
    });
  }

  @override
  Future<Result<void>> updateTask(
    String dayPlanId,
    String taskId,
    domain.Task updatedTask,
  ) {
    return _wrap(() async {
      await _taskDao.updateTask(
        taskId,
        _modelTaskToCompanion(updatedTask, dayPlanId),
      );
    });
  }

  @override
  Future<Result<void>> deleteTask(String dayPlanId, String taskId) {
    return _wrap(() async {
      await _taskDao.deleteTaskById(taskId);
    });
  }

  @override
  Future<Result<List<domain.Task>>> getTaskHistory(DateTime since) {
    return _wrap(() async {
      final since0 = DateTime(since.year, since.month, since.day);
      final dbTasks = await _taskDao.getTasksSince(since0);
      return dbTasks.map(_dbTaskToModel).toList();
    });
  }

  // ── Mappers ───────────────────────────────────

  domain.Task _dbTaskToModel(Task dbTask) {
    return domain.Task(
      id: dbTask.id,
      title: dbTask.title,
      description: dbTask.description,
      startTime: dbTask.startTime,
      endTime: dbTask.endTime,
      type: domain.TaskType.values.firstWhere(
        (e) => e.name == dbTask.type,
        orElse: () => domain.TaskType.work,
      ),
      priority: domain.TaskPriority.values.firstWhere(
        (e) => e.name == dbTask.priority,
        orElse: () => domain.TaskPriority.medium,
      ),
      energyLevel: domain.TaskEnergyLevel.values.firstWhere(
        (e) => e.name == dbTask.energyLevel,
        orElse: () => domain.TaskEnergyLevel.medium,
      ),
      estimatedCost: dbTask.estimatedCost,
      actualCost: dbTask.actualCost,
      completed: dbTask.completed,
      sourceTemplateId: dbTask.sourceTemplateId,
    );
  }

  TasksCompanion _modelTaskToCompanion(domain.Task task, String dayPlanId) {
    return TasksCompanion(
      id: Value(task.id),
      title: Value(task.title),
      description: Value(task.description),
      startTime: Value(task.startTime),
      endTime: Value(task.endTime),
      type: Value(task.type.name),
      priority: Value(task.priority.name),
      energyLevel: Value(task.energyLevel.name),
      estimatedCost: Value(task.estimatedCost),
      actualCost: Value(task.actualCost),
      completed: Value(task.completed),
      dayPlanId: Value(dayPlanId),
      sourceTemplateId: Value(task.sourceTemplateId),
    );
  }
}
