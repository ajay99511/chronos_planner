import 'package:chronosky/core/result.dart';
import 'package:chronosky/data/models/day_plan_model.dart';
import 'package:chronosky/data/models/task_model.dart';

/// Abstract interface for schedule (week plan + tasks) operations.
abstract class ScheduleRepository {
  /// Get the upcoming [count] days starting from Today.
  Future<Result<List<DayPlan>>> getUpcomingDays(int count);

  /// Add a task to a specific date.
  Future<Result<void>> addTaskToDate(DateTime date, Task task);

  /// Add multiple tasks to a specific date in a single batch (used when
  /// applying a template so a whole plan is one write instead of N).
  Future<Result<void>> addTasksToDate(DateTime date, List<Task> tasks);

  /// Persist a full day plan (all tasks for one day).
  Future<Result<void>> saveDayPlan(DayPlan dayPlan);

  /// Add a task to a day plan.
  Future<Result<void>> addTask(String dayPlanId, Task task);

  /// Update an existing task.
  Future<Result<void>> updateTask(
      String dayPlanId, String taskId, Task updatedTask,);

  /// Delete a task by id.
  Future<Result<void>> deleteTask(String dayPlanId, String taskId);

  /// Delete all tasks for a day plan.
  Future<Result<void>> clearDay(String dayPlanId);

  /// Get every task scheduled on or after [since], across all day plans.
  ///
  /// Used by analytics to compute history-based insights (e.g. energy peaks).
  Future<Result<List<Task>>> getTaskHistory(DateTime since);
}
