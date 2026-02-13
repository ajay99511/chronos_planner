enum TaskType { work, personal, health, leisure }

class Task {
  final String id;
  final String title;
  final String startTime;
  final String endTime;
  final TaskType type;
  final String description;
  bool completed;

  Task({
    required this.id,
    required this.title,
    required this.startTime,
    required this.endTime,
    required this.type,
    this.description = '',
    this.completed = false,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'startTime': startTime,
        'endTime': endTime,
        'type': type.toString(),
        'description': description,
        'completed': completed,
      };

  factory Task.fromJson(Map<String, dynamic> json) {
    return Task(
      id: json['id'],
      title: json['title'],
      startTime: json['startTime'],
      endTime: json['endTime'],
      type: TaskType.values.firstWhere(
        (e) => e.toString() == json['type'],
        orElse: () => TaskType.work,
      ),
      description: json['description'] ?? '',
      completed: json['completed'] ?? false,
    );
  }
}
