import 'task_model.dart';

class DayPlan {
  final String id;
  final String dateStr;
  final String dayOfWeek;
  List<Task> tasks;

  DayPlan({
    required this.id,
    required this.dateStr,
    required this.dayOfWeek,
    required this.tasks,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'dateStr': dateStr,
        'dayOfWeek': dayOfWeek,
        'tasks': tasks.map((t) => t.toJson()).toList(),
      };

  factory DayPlan.fromJson(Map<String, dynamic> json) {
    return DayPlan(
      id: json['id'],
      dateStr: json['dateStr'],
      dayOfWeek: json['dayOfWeek'],
      tasks: (json['tasks'] as List).map((t) => Task.fromJson(t)).toList(),
    );
  }
}
