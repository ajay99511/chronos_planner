import 'package:flutter/foundation.dart';
import 'package:chronosky/data/models/task_model.dart';
import 'package:chronosky/providers/schedule_state_provider.dart';

class AnalyticsProvider extends ChangeNotifier {
  final ScheduleStateProvider _stateProvider;

  AnalyticsProvider(this._stateProvider) {
    _stateProvider.addListener(notifyListeners);
  }

  @override
  void dispose() {
    _stateProvider.removeListener(notifyListeners);
    super.dispose();
  }

  int get totalTasks => _stateProvider.weekPlan.fold(0, (sum, day) => sum + day.tasks.length);
  
  int get completedTasks => _stateProvider.weekPlan.fold(
      0, (sum, day) => sum + day.tasks.where((t) => t.completed).length,);
  
  double get efficiency => totalTasks == 0 ? 0 : (completedTasks / totalTasks) * 100;

  double get totalFocusHours {
    double hours = 0;
    for (var day in _stateProvider.weekPlan) {
      for (var task in day.tasks) {
        hours += _calculateDuration(task.startTime, task.endTime);
      }
    }
    return hours;
  }

  Map<TaskType, double> get categoryDistribution {
    Map<TaskType, double> dist = {
      for (var type in TaskType.values) type: 0.0,
    };

    for (var day in _stateProvider.weekPlan) {
      for (var task in day.tasks) {
        dist[task.type] = (dist[task.type] ?? 0) +
            _calculateDuration(task.startTime, task.endTime);
      }
    }
    return dist;
  }

  double _calculateDuration(String start, String end) {
    try {
      final s = start.split(':').map(int.parse).toList();
      final e = end.split(':').map(int.parse).toList();
      double startH = s[0] + s[1] / 60.0;
      double endH = e[0] + e[1] / 60.0;
      if (endH <= startH) endH += 24;
      return (endH - startH).clamp(0, 24);
    } catch (e) {
      return 0;
    }
  }

  // Energy peaks will be implemented after IntelligenceService refactor (Task 9.2)
  // For now, returning empty map
  Map<int, double> get energyPeaks => {};
}
