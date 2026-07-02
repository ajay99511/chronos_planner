import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:chronosky/core/services/intelligence_service.dart';
import 'package:chronosky/data/models/task_model.dart';
import 'package:chronosky/data/repositories/schedule_repository.dart';
import 'package:chronosky/providers/schedule_state_provider.dart';

/// Exposes derived productivity metrics for the Insights screen.
///
/// All week-scoped metrics are memoized and recomputed only when the
/// underlying schedule changes, rather than on every getter access.
/// Energy peaks are derived by [IntelligenceService] from historical task
/// data (loaded once via [ScheduleRepository]) combined with the live week.
class AnalyticsProvider extends ChangeNotifier {
  final ScheduleStateProvider _stateProvider;
  final ScheduleRepository? _scheduleRepo;
  final IntelligenceService _intel = IntelligenceService();

  /// How far back to pull completed-task history for energy-peak analysis.
  static const int _historyWindowDays = 90;

  // ── Memoized week metrics ──
  int _totalTasks = 0;
  int _completedTasks = 0;
  double _totalFocusHours = 0;
  Map<TaskType, double> _categoryDistribution = {
    for (final type in TaskType.values) type: 0.0,
  };

  // ── Energy peaks ──
  Map<int, double> _energyPeaks = {};
  List<Task> _history = const [];
  bool _peaksInFlight = false;
  bool _peaksDirty = false;

  AnalyticsProvider(this._stateProvider, [this._scheduleRepo]) {
    _stateProvider.addListener(_onScheduleChanged);
    _recomputeWeekMetrics();
    _loadHistory();
  }

  @override
  void dispose() {
    _stateProvider.removeListener(_onScheduleChanged);
    super.dispose();
  }

  // ── Public getters (read memoized values) ──
  int get totalTasks => _totalTasks;
  int get completedTasks => _completedTasks;
  double get efficiency =>
      _totalTasks == 0 ? 0 : (_completedTasks / _totalTasks) * 100;
  double get totalFocusHours => _totalFocusHours;
  Map<TaskType, double> get categoryDistribution => _categoryDistribution;
  Map<int, double> get energyPeaks => _energyPeaks;

  void _onScheduleChanged() {
    _recomputeWeekMetrics();
    notifyListeners();
    // Newly completed tasks in the live week affect energy peaks too.
    _recomputeEnergyPeaks();
  }

  /// Single pass over the week to compute all week-scoped metrics at once.
  void _recomputeWeekMetrics() {
    int total = 0;
    int completed = 0;
    double focusHours = 0;
    final dist = {for (final type in TaskType.values) type: 0.0};

    for (final day in _stateProvider.weekPlan) {
      for (final task in day.tasks) {
        total++;
        if (task.completed) completed++;
        final duration = _calculateDuration(task.startTime, task.endTime);
        focusHours += duration;
        dist[task.type] = (dist[task.type] ?? 0) + duration;
      }
    }

    _totalTasks = total;
    _completedTasks = completed;
    _totalFocusHours = focusHours;
    _categoryDistribution = dist;
  }

  Future<void> _loadHistory() async {
    final repo = _scheduleRepo;
    if (repo == null) return;
    final since =
        DateTime.now().subtract(const Duration(days: _historyWindowDays));
    final result = await repo.getTaskHistory(since);
    result.fold(
      onSuccess: (tasks) {
        _history = tasks;
        _recomputeEnergyPeaks();
      },
      onFailure: (_) {
        // Non-fatal: energy peaks simply fall back to live-week data.
        _recomputeEnergyPeaks();
      },
    );
  }

  /// Recomputes energy peaks from cached history merged with the live week,
  /// deduplicated by task id so in-session edits are reflected immediately.
  /// Coalesces concurrent requests to avoid hammering the isolate.
  Future<void> _recomputeEnergyPeaks() async {
    if (_peaksInFlight) {
      _peaksDirty = true;
      return;
    }
    _peaksInFlight = true;
    try {
      final merged = <String, Task>{};
      for (final t in _history) {
        merged[t.id] = t;
      }
      for (final day in _stateProvider.weekPlan) {
        for (final t in day.tasks) {
          merged[t.id] = t;
        }
      }

      final peaks = await _intel.getEnergyPeaks(merged.values.toList());
      _energyPeaks = peaks;
      notifyListeners();
    } finally {
      _peaksInFlight = false;
      if (_peaksDirty) {
        _peaksDirty = false;
        unawaited(_recomputeEnergyPeaks());
      }
    }
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
}
