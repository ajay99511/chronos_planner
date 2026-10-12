import 'package:chronosky/core/result.dart';
import 'package:chronosky/data/models/day_plan_model.dart';
import 'package:chronosky/data/models/task_model.dart';

/// Abstract interface for schedule (week plan + tasks) operations.
abstract class ScheduleRepository {
  /// Get the upcoming [count] days starting from Today.
  Future<Result<List<DayPlan>>> getUpcomingDays(int count);

  /// Watches the tasks scheduled in the next [count] days, grouped by day.
  ///
  /// Read-only, unlike [getUpcomingDays], which creates any missing day rows:
  /// a watcher must not write. Days with no tasks are therefore omitted rather
  /// than returned empty — a caller that needs the full window for display
  /// should use [getUpcomingDays]; this exists for callers that only care
  /// about the tasks themselves, such as the notification schedule.
  ///
  /// The window is bound when the stream is subscribed, so a caller that must
  /// follow the calendar past midnight has to re-subscribe.
  Stream<List<DayPlan>> watchUpcomingDays(int count);

  /// Add a task to a specific date.
  Future<Result<void>> addTaskToDate(DateTime date, Task task);

  /// Add multiple tasks to a specific date in a single batch (used when
  /// applying a template so a whole plan is one write instead of N).
  Future<Result<void>> addTasksToDate(DateTime date, List<Task> tasks);

  /// Add a task to a day plan.
  Future<Result<void>> addTask(String dayPlanId, Task task);

  /// Update an existing task.
  Future<Result<void>> updateTask(
      String dayPlanId, String taskId, Task updatedTask,);

  /// Delete a task by id.
  Future<Result<void>> deleteTask(String dayPlanId, String taskId);

  /// Get every task scheduled on or after [since], across all day plans.
  ///
  /// Used by analytics to compute history-based insights (e.g. energy peaks).
  Future<Result<List<Task>>> getTaskHistory(DateTime since);
}
