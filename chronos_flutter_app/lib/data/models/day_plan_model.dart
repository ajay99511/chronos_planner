import 'task_model.dart';

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
