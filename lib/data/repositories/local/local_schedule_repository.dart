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

  String _currentWeekKey() {
    final now = DateTime.now();
    final monday = now.subtract(Duration(days: now.weekday - 1));
    final weekNumber =
        ((monday.difference(DateTime(monday.year, 1, 1)).inDays) / 7).ceil() +
            1;
    return '${monday.year}-W${weekNumber.toString().padLeft(2, '0')}';
  }

  @override
  Future<bool> isWeekStale() async {
    final weekKey = _currentWeekKey();
    final exists = await _dayPlanDao.weekExists(weekKey);
    return !exists;
  }

  @override
  Future<List<model.DayPlan>> initializeWeek() async {
    final now = DateTime.now();
    final monday = now.subtract(Duration(days: now.weekday - 1));
    final weekKey = _currentWeekKey();

    final plans = <model.DayPlan>[];
    final companions = <DayPlansCompanion>[];

    for (int i = 0; i < 7; i++) {
      final date = monday.add(Duration(days: i));
      final id = const Uuid().v4();

      companions.add(DayPlansCompanion(
        id: Value(id),
        dateStr: Value(DateFormat('MMM d').format(date)),
        dayOfWeek: Value(DateFormat('EEEE').format(date)),
        date: Value(date),
        weekKey: Value(weekKey),
      ));

      plans.add(model.DayPlan(
        id: id,
        dateStr: DateFormat('MMM d').format(date),
        dayOfWeek: DateFormat('EEEE').format(date),
        date: date,
        tasks: [],
      ));
    }

    await _dayPlanDao.insertDayPlans(companions);
    return plans;
  }

  @override
  Future<List<model.DayPlan>> getWeekPlan() async {
    final weekKey = _currentWeekKey();
    final stale = await isWeekStale();

    if (stale) {
      return initializeWeek();
    }

    final dbPlans = await _dayPlanDao.getDayPlansForWeek(weekKey);
    final plans = <model.DayPlan>[];

    for (final dp in dbPlans) {
      final dbTasks = await _taskDao.getTasksForDay(dp.id);
      plans.add(model.DayPlan(
        id: dp.id,
        dateStr: dp.dateStr,
        dayOfWeek: dp.dayOfWeek,
        date: dp.date,
        tasks: dbTasks.map(_dbTaskToModel).toList()
          ..sort((a, b) => a.startTime.compareTo(b.startTime)),
      ));
    }

    return plans;
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
