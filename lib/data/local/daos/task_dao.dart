import 'package:drift/drift.dart';

import 'package:chronosky/data/local/app_database.dart';
import 'package:chronosky/data/local/tables.dart';

part 'task_dao.g.dart';

@DriftAccessor(tables: [Tasks])
class TaskDao extends DatabaseAccessor<AppDatabase> with _$TaskDaoMixin {
  TaskDao(super.db);

  /// Get all tasks for a specific day plan.
  Future<List<Task>> getTasksForDay(String dayPlanId) {
    return (select(tasks)..where((t) => t.dayPlanId.equals(dayPlanId))).get();
  }

  /// Watch tasks for a day (reactive stream).
  Stream<List<Task>> watchTasksForDay(String dayPlanId) {
    return (select(tasks)
          ..where((t) => t.dayPlanId.equals(dayPlanId))
          ..orderBy([(t) => OrderingTerm.asc(t.startTime)]))
        .watch();
  }

  /// Insert a single task.
  Future<void> insertTask(TasksCompanion task) {
    return into(tasks).insert(task);
  }

  /// Insert multiple tasks at once (within a transaction).
  Future<void> insertTasks(List<TasksCompanion> taskList) {
    return batch((b) => b.insertAll(tasks, taskList));
  }

  /// Update a task by its id.
  Future<void> updateTask(String taskId, TasksCompanion updates) {
    return (update(tasks)..where((t) => t.id.equals(taskId))).write(updates);
  }

  /// Delete a single task.
  Future<int> deleteTaskById(String taskId) {
    return (delete(tasks)..where((t) => t.id.equals(taskId))).go();
  }

  /// Delete all tasks for a day plan.
  Future<int> deleteTasksForDay(String dayPlanId) {
    return (delete(tasks)..where((t) => t.dayPlanId.equals(dayPlanId))).go();
  }

  /// Get a single task by id.
  Future<Task?> getTaskById(String taskId) {
    return (select(tasks)..where((t) => t.id.equals(taskId))).getSingleOrNull();
  }

  /// Returns all tasks whose owning day plan falls on or after [since],
  /// joined across the `day_plans` table by date.
  ///
  /// Used by the analytics/intelligence layer to derive energy peaks and
  /// other history-based insights. A raw join is used so this DAO does not
  /// need a generated accessor for [DayPlans].
  Future<List<Task>> getTasksSince(DateTime since) async {
    final rows = await customSelect(
      'SELECT t.* FROM tasks t '
      'INNER JOIN day_plans d ON t.day_plan_id = d.id '
      'WHERE d.date >= ? '
      'ORDER BY d.date ASC, t.start_time ASC',
      variables: [Variable.withDateTime(since)],
      readsFrom: {tasks},
    ).get();
    return rows.map((row) => tasks.map(row.data)).toList();
  }
}
