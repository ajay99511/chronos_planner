import '../../data/models/task_model.dart';

/// Analytics and recommendation engine for productivity insights.
/// 
/// Provides:
/// - Efficiency score calculation (completion rate)
/// - Peak hour analysis (best productivity times)
/// - Optimal time recommendations based on energy level
/// - Task ROI calculation (priority vs cost)
/// 
/// This is a stateless service - safe to instantiate anywhere.
/// 
/// Dependencies:
/// - [Task] model for data input
/// 
/// Used by:
/// - [AddTaskSheet] for time suggestions
/// - [AnalyticsView] for energy peaks chart
class IntelligenceService {
  /// Calculates an efficiency score (0-100) based on completed tasks vs total tasks.
  /// 
  /// Returns 0.0 for empty task lists (no error thrown).
  double calculateEfficiency(List<Task> tasks) {
    if (tasks.isEmpty) return 0.0;
    final completed = tasks.where((t) => t.completed).length;
    return (completed / tasks.length) * 100;
  }

  /// Analyzes historical data to find the user's peak productivity hours.
  /// Returns a map of Hour (0-23) to a "Productivity Score".
  Map<int, double> getEnergyPeaks(List<Task> history) {
    final Map<int, List<bool>> hourStats = {};

    for (var task in history) {
      if (task.startTime.contains(':')) {
        final hour = int.tryParse(task.startTime.split(':')[0]);
        if (hour != null) {
          hourStats.putIfAbsent(hour, () => []).add(task.completed);
        }
      }
    }

    final Map<int, double> peaks = {};
    hourStats.forEach((hour, completions) {
      final successRate = completions.where((c) => c).length / completions.length;
      peaks[hour] = successRate;
    });

    return peaks;
  }

  /// Recommends an optimal time for a task based on its energy requirement.
  String recommendTime(TaskEnergyLevel energy, Map<int, double> peaks) {
    if (peaks.isEmpty) return "09:00"; // Default

    var bestHour = 9;
    var maxScore = -1.0;

    if (energy == TaskEnergyLevel.high) {
      // Find the hour with the highest success rate
      peaks.forEach((hour, score) {
        if (score > maxScore) {
          maxScore = score;
          bestHour = hour;
        }
      });
    } else if (energy == TaskEnergyLevel.low) {
      // Find the hour with the lowest success rate (assuming these are "dip" times)
      var minScore = 2.0;
      peaks.forEach((hour, score) {
        if (score < minScore) {
          minScore = score;
          bestHour = hour;
        }
      });
    }

    return "${bestHour.toString().padLeft(2, '0')}:00";
  }

  /// Calculates ROI: (Task Importance/Priority / Cost)
  double calculateTaskROI(Task task) {
    if (task.actualCost <= 0) return 1.0; // Avoid division by zero

    double priorityWeight = 1.0;
    if (task.priority == TaskPriority.high) priorityWeight = 3.0;
    if (task.priority == TaskPriority.medium) priorityWeight = 2.0;

    return priorityWeight / task.actualCost;
  }
}
