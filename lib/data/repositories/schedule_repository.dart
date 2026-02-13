import '../models/day_plan_model.dart';
import '../models/task_model.dart';

/// Abstract interface for schedule (week plan + tasks) operations.
/// The UI layer only depends on this interface — never on Drift directly.
abstract class ScheduleRepository {
  /// Load (or initialize) the current week's day plans.
  Future<List<DayPlan>> getWeekPlan();

  /// Persist a full day plan (all tasks for one day).
  Future<void> saveDayPlan(DayPlan dayPlan);

  /// Add a task to a day plan.
  Future<void> addTask(String dayPlanId, Task task);

  /// Update an existing task.
  Future<void> updateTask(String dayPlanId, String taskId, Task updatedTask);

  /// Delete a task by id.
  Future<void> deleteTask(String dayPlanId, String taskId);

  /// Delete all tasks for a day plan.
  Future<void> clearDay(String dayPlanId);

  /// Check if the stored week is stale (belongs to a previous week).
  Future<bool> isWeekStale();

  /// Initialize a fresh week (7 empty day plans).
  Future<List<DayPlan>> initializeWeek();
}
