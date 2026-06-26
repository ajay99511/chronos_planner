import 'dart:io';
import 'package:drift/drift.dart';
import 'package:uuid/uuid.dart';

import 'package:chronosky/core/result.dart';
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

  Future<Result<T>> _wrap<T>(Future<T> Function() action) async {
    try {
      final value = await _retry(action);
      return Success(value);
    } on DriftWrappedException catch (e) {
      return Failure(DatabaseFailure('Database operation failed', e.toString()));
    } on Exception catch (e) {
      return Failure(UnknownFailure('Unexpected error', e.toString()));
    }
  }

  @override
  Future<Result<List<domain.DayPlan>>> getUpcomingDays(int count) async {
    return _wrap(() async {
      final now = DateTime.now();
      final today = DateTime(now.year, now.month, now.day);

      final dbPlans = await _dayPlanDao.getDayPlansFrom(today, count);
      final List<domain.DayPlan> fullList = [];
      final List<DayPlansCompanion> newDays = [];

      for (int i = 0; i < count; i++) {
        final date = today.add(Duration(days: i));
        final existing = dbPlans.cast<DayPlan?>().firstWhere(
              (p) =>
                  p!.date.year == date.year &&
                  p.date.month == date.month &&
                  p.date.day == date.day,
              orElse: () => null,
            );

        if (existing != null) {
          final dbTasks = await _taskDao.getTasksForDay(existing.id);
          fullList.add(domain.DayPlan(
            id: existing.id,
            date: existing.date,
            tasks: dbTasks.map(_dbTaskToModel).toList()
              ..sort((a, b) => a.startTime.compareTo(b.startTime)),
          ),);
        } else {
          final id = const Uuid().v4();
          final weekKey = _calculateWeekKey(date);

          newDays.add(DayPlansCompanion(
            id: Value(id),
            date: Value(date),
            weekKey: Value(weekKey),
          ),);

          fullList.add(domain.DayPlan(
            id: id,
            date: date,
            tasks: [],
          ),);
        }
      }

      if (newDays.isNotEmpty) {
        await _dayPlanDao.insertDayPlans(newDays);
      }

      return fullList;
    });
  }

  @override
  Future<Result<void>> addTaskToDate(DateTime date, domain.Task task) async {
    return _wrap(() async {
      final targetDate = DateTime(date.year, date.month, date.day);
      String? dayPlanId = await _dayPlanDao.getDayPlanId(targetDate);

      if (dayPlanId == null) {
        dayPlanId = const Uuid().v4();
        final weekKey = _calculateWeekKey(targetDate);

        await _dayPlanDao.insertDayPlan(DayPlansCompanion(
          id: Value(dayPlanId),
          date: Value(targetDate),
          weekKey: Value(weekKey),
        ),);
      }

      await _taskDao.insertTask(_modelTaskToCompanion(task, dayPlanId));
    });
  }

  @override
  Future<Result<void>> addTasksToDate(
      DateTime date, List<domain.Task> tasksToAdd,) async {
    return _wrap(() async {
      if (tasksToAdd.isEmpty) return;
      final targetDate = DateTime(date.year, date.month, date.day);
      String? dayPlanId = await _dayPlanDao.getDayPlanId(targetDate);

      if (dayPlanId == null) {
        dayPlanId = const Uuid().v4();
        final weekKey = _calculateWeekKey(targetDate);
        await _dayPlanDao.insertDayPlan(DayPlansCompanion(
          id: Value(dayPlanId),
          date: Value(targetDate),
          weekKey: Value(weekKey),
        ),);
      }

      final planId = dayPlanId;
      await _taskDao.insertTasks(
        tasksToAdd.map((t) => _modelTaskToCompanion(t, planId)).toList(),
      );
    });
  }

  @override
  Future<Result<void>> saveDayPlan(domain.DayPlan dayPlan) async {
    return _wrap(() async {
      await _taskDao.deleteTasksForDay(dayPlan.id);
      if (dayPlan.tasks.isNotEmpty) {
        await _taskDao.insertTasks(
          dayPlan.tasks.map((t) => _modelTaskToCompanion(t, dayPlan.id)).toList(),
        );
      }
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
      String dayPlanId, String taskId, domain.Task updatedTask,) {
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
  Future<Result<void>> clearDay(String dayPlanId) {
    return _wrap(() async {
      await _taskDao.deleteTasksForDay(dayPlanId);
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
