import 'package:chronosky/core/result.dart';
import 'package:chronosky/data/models/day_plan_model.dart';
import 'package:chronosky/data/models/task_model.dart';

/// Abstract interface for schedule (week plan + tasks) operations.
abstract class ScheduleRepository {
  /// Get the upcoming [count] days starting from Today.
  Future<Result<List<DayPlan>>> getUpcomingDays(int count);

  /// Add a task to a specific date.
  Future<Result<void>> addTaskToDate(DateTime date, Task task);

  /// Persist a full day plan (all tasks for one day).
  Future<Result<void>> saveDayPlan(DayPlan dayPlan);

  /// Add a task to a day plan.
  Future<Result<void>> addTask(String dayPlanId, Task task);

  /// Update an existing task.
  Future<Result<void>> updateTask(String dayPlanId, String taskId, Task updatedTask);

  /// Delete a task by id.
  Future<Result<void>> deleteTask(String dayPlanId, String taskId);

  /// Delete all tasks for a day plan.
  Future<Result<void>> clearDay(String dayPlanId);
}
