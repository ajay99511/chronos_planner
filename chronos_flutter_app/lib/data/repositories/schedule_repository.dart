import '../models/day_plan_model.dart';
import '../models/task_model.dart';

/// Abstract interface for schedule (week plan + tasks) operations.
/// The UI layer only depends on this interface — never on Drift directly.
abstract class ScheduleRepository {
  /// Get the upcoming [count] days starting from Today.
  /// Automatically initializes missing days if needed.
  Future<List<DayPlan>> getUpcomingDays(int count);

  /// Add a task to a specific date.
  /// Automatically creates the day plan if it doesn't exist.
  Future<void> addTaskToDate(DateTime date, Task task);

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
}
