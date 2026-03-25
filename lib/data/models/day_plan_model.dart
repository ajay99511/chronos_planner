import 'task_model.dart';

/// Aggregates tasks for a specific date in the weekly schedule.
/// 
/// Represents one day in the rolling 7-day view:
/// - Metadata: date, day of week, display string
/// - Tasks: mutable list of scheduled activities
/// 
/// ## Lifecycle:
/// 1. Auto-created by [LocalScheduleRepository.getUpcomingDays] if missing
/// 2. Stored in [DayPlans] table via [DayPlanDao]
/// 3. Displayed in [ScheduleView] day selector
/// 4. Tasks managed via [ScheduleProvider]
/// 
/// ## Relationships:
/// - Has many [Task] objects
/// - Grouped by week via `weekKey` in database
/// 
/// ## Usage:
/// ```dart
/// final dayPlan = DayPlan(
///   id: uuid.v4(),
///   dateStr: 'Feb 10',
///   dayOfWeek: 'Monday',
///   date: DateTime(2026, 2, 10),
///   tasks: [],
/// );
/// 
/// // Add task (mutable list)
/// dayPlan.tasks.add(task);
/// ```
class DayPlan {
  final String id;
  final String dateStr;
  final String dayOfWeek;
  final DateTime date;
  List<Task> tasks;

  DayPlan({
    required this.id,
    required this.dateStr,
    required this.dayOfWeek,
    required this.date,
    required this.tasks,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'dateStr': dateStr,
        'dayOfWeek': dayOfWeek,
        'date': date.toIso8601String(),
        'tasks': tasks.map((t) => t.toJson()).toList(),
      };

  factory DayPlan.fromJson(Map<String, dynamic> json) {
    return DayPlan(
      id: json['id'],
      dateStr: json['dateStr'],
      dayOfWeek: json['dayOfWeek'],
      date:
          json['date'] != null ? DateTime.parse(json['date']) : DateTime.now(),
      tasks: (json['tasks'] as List).map((t) => Task.fromJson(t)).toList(),
    );
  }
}
