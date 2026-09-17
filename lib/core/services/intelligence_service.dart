import 'package:flutter/foundation.dart';
import 'package:chronosky/data/models/task_model.dart';
import 'package:chronosky/domain/clock_time.dart';

/// Analytics and recommendation engine for productivity insights.
class IntelligenceService {
  /// Calculates an efficiency score (0-100) based on completed tasks vs total tasks.
  double calculateEfficiency(List<Task> tasks) {
    if (tasks.isEmpty) return 0.0;
    final completed = tasks.where((t) => t.completed).length;
    return (completed / tasks.length) * 100;
  }

  /// Analyzes historical data to find the user's peak productivity hours.
  /// Returns a map of Hour (0-23) to intensity score.
  Future<Map<int, double>> getEnergyPeaks(List<Task> history) async {
    if (history.length > 500) {
      return compute(_calculatePeaks, history);
    } else {
      return _calculatePeaks(history);
    }
  }

  /// Internal calculation logic.
  static Map<int, double> _calculatePeaks(List<Task> history) {
    if (history.isEmpty) return {};

    final Map<int, double> hourlyIntensity = {
      for (int i = 0; i < 24; i++) i: 0.0,
    };

    // Only consider completed tasks for "actual" energy peaks
    final completedTasks = history.where((t) => t.completed);

    for (final task in completedTasks) {
      final range = TimeRange.tryParse(task.startTime, task.endTime);
      if (range == null) continue;

      // Intensity weight based on priority and energy level
      double weight = 1.0;
      if (task.priority == TaskPriority.high) weight += 0.5;
      if (task.energyLevel == TaskEnergyLevel.high) weight += 0.5;

      for (var hour = 0; hour < 24; hour++) {
        final minutes = range.minutesInHour(hour);
        if (minutes == 0) continue;
        hourlyIntensity[hour] =
            (hourlyIntensity[hour] ?? 0.0) + (minutes / 60.0) * weight;
      }
    }

    // Normalize: divide by total number of days in history to get "average daily intensity"
    // For now, we'll just return raw aggregated intensity as relative peaks.
    return hourlyIntensity;
  }

  /// Recommends an optimal time for a task based on its energy requirement.
  String recommendTime(TaskEnergyLevel energy, Map<int, double> peaks) {
    if (peaks.isEmpty) return '09:00';

    var bestHour = 9;
    var maxScore = -1.0;
    var minScore = double.infinity;

    if (energy == TaskEnergyLevel.high) {
      peaks.forEach((hour, score) {
        if (score > maxScore) {
          maxScore = score;
          bestHour = hour;
        }
      });
    } else {
      peaks.forEach((hour, score) {
        if (score < minScore) {
          minScore = score;
          bestHour = hour;
        }
      });
    }

    return "${bestHour.toString().padLeft(2, '0')}:00";
  }

  /// Calculates ROI: (Priority Weight / Cost)
  double calculateTaskROI(Task task) {
    if (task.estimatedCost <= 0) return 1.0;

    double priorityWeight = 1.0;
    if (task.priority == TaskPriority.high) priorityWeight = 3.0;
    if (task.priority == TaskPriority.medium) priorityWeight = 2.0;

    return priorityWeight / task.estimatedCost;
  }
}
