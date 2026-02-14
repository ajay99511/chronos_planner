import 'package:drift/drift.dart';
import 'package:intl/intl.dart';
import 'package:uuid/uuid.dart';

import '../../models/day_plan_model.dart' as model;
import '../../models/task_model.dart' as model;
import '../../local/app_database.dart';
import '../../local/daos/day_plan_dao.dart';
import '../../local/daos/task_dao.dart';
import '../schedule_repository.dart';

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

  @override
  Future<List<model.DayPlan>> getUpcomingDays(int count) async {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    // 1. Fetch existing day plans from DB
    final dbPlans = await _dayPlanDao.getDayPlansFrom(today, count);

    final List<model.DayPlan> fullList = [];
    final List<DayPlansCompanion> newDays = [];

    // 2. Iterate through the requested range, matching or creating days
    for (int i = 0; i < count; i++) {
      final date = today.add(Duration(days: i));

      // Find existing plan for this date
      final existing = dbPlans.cast<DayPlan?>().firstWhere(
            (p) =>
                p!.date.year == date.year &&
                p.date.month == date.month &&
                p.date.day == date.day,
            orElse: () => null,
          );

      if (existing != null) {
        // Load tasks for existing day
        final dbTasks = await _taskDao.getTasksForDay(existing.id);
        fullList.add(model.DayPlan(
          id: existing.id,
          dateStr: existing.dateStr,
          dayOfWeek: existing.dayOfWeek,
          date: existing.date,
          tasks: dbTasks.map(_dbTaskToModel).toList()
            ..sort((a, b) => a.startTime.compareTo(b.startTime)),
        ));
      } else {
        // Create new day plan
        final id = const Uuid().v4();
        final weekKey = _calculateWeekKey(date);

        // Prepare for DB insertion
        newDays.add(DayPlansCompanion(
          id: Value(id),
          dateStr: Value(DateFormat('MMM d').format(date)),
          dayOfWeek: Value(DateFormat('EEEE').format(date)),
          date: Value(date),
          weekKey: Value(weekKey),
        ));

        // Add empty model to return list
        fullList.add(model.DayPlan(
          id: id,
          dateStr: DateFormat('MMM d').format(date),
          dayOfWeek: DateFormat('EEEE').format(date),
          date: date,
          tasks: [],
        ));
      }
    }

    // 3. Batch insert new days if any
    if (newDays.isNotEmpty) {
      await _dayPlanDao.insertDayPlans(newDays);
    }

    return fullList;
  }

  @override
  Future<void> addTaskToDate(DateTime date, model.Task task) async {
    // Normalize date to midnight
    final targetDate = DateTime(date.year, date.month, date.day);

    // Check if day plan exists using the DAO helper
    String? dayPlanId = await _dayPlanDao.getDayPlanId(targetDate);

    if (dayPlanId == null) {
      // Create it if missing
      dayPlanId = const Uuid().v4();
      final weekKey = _calculateWeekKey(targetDate);

      await _dayPlanDao.insertDayPlan(DayPlansCompanion(
        id: Value(dayPlanId),
        dateStr: Value(DateFormat('MMM d').format(targetDate)),
        dayOfWeek: Value(DateFormat('EEEE').format(targetDate)),
        date: Value(targetDate),
        weekKey: Value(weekKey),
      ));
    }

    // Add task
    await addTask(dayPlanId, task);
  }

  @override
  Future<void> saveDayPlan(model.DayPlan dayPlan) async {
    // Delete existing tasks for this day, then re-insert
    await _taskDao.deleteTasksForDay(dayPlan.id);
    if (dayPlan.tasks.isNotEmpty) {
      await _taskDao.insertTasks(
        dayPlan.tasks.map((t) => _modelTaskToCompanion(t, dayPlan.id)).toList(),
      );
    }
  }

  @override
  Future<void> addTask(String dayPlanId, model.Task task) {
    return _taskDao.insertTask(_modelTaskToCompanion(task, dayPlanId));
  }

  @override
  Future<void> updateTask(
      String dayPlanId, String taskId, model.Task updatedTask) {
    return _taskDao.updateTask(
      taskId,
      TasksCompanion(
        title: Value(updatedTask.title),
        description: Value(updatedTask.description),
        startTime: Value(updatedTask.startTime),
        endTime: Value(updatedTask.endTime),
        type: Value(updatedTask.type.name),
        priority: Value(updatedTask.priority.name),
        completed: Value(updatedTask.completed),
      ),
    );
  }

  @override
  Future<void> deleteTask(String dayPlanId, String taskId) {
    return _taskDao.deleteTaskById(taskId);
  }

  @override
  Future<void> clearDay(String dayPlanId) {
    return _taskDao.deleteTasksForDay(dayPlanId);
  }

  // ── Mappers ───────────────────────────────────

  model.Task _dbTaskToModel(Task dbTask) {
    return model.Task(
      id: dbTask.id,
      title: dbTask.title,
      description: dbTask.description,
      startTime: dbTask.startTime,
      endTime: dbTask.endTime,
      type: model.TaskType.values.firstWhere(
        (e) => e.name == dbTask.type,
        orElse: () => model.TaskType.work,
      ),
      priority: model.TaskPriority.values.firstWhere(
        (e) => e.name == dbTask.priority,
        orElse: () => model.TaskPriority.medium,
      ),
      completed: dbTask.completed,
    );
  }

  TasksCompanion _modelTaskToCompanion(model.Task task, String dayPlanId) {
    return TasksCompanion(
      id: Value(task.id),
      title: Value(task.title),
      description: Value(task.description),
      startTime: Value(task.startTime),
      endTime: Value(task.endTime),
      type: Value(task.type.name),
      priority: Value(task.priority.name),
      completed: Value(task.completed),
      dayPlanId: Value(dayPlanId),
    );
  }
}
