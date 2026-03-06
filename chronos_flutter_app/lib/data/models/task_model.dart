enum TaskType { work, personal, health, leisure }

enum TaskPriority { low, medium, high }

class Task {
  final String id;
  final String title;
  final String startTime;
  final String endTime;
  final TaskType type;
  final TaskPriority priority;
  final String description;
  final String sourceTemplateId;
  bool completed;

  Task({
    required this.id,
    required this.title,
    required this.startTime,
    required this.endTime,
    required this.type,
    this.priority = TaskPriority.medium,
    this.description = '',
    this.sourceTemplateId = '',
    this.completed = false,
  });

  Task copyWith({
    String? id,
    String? title,
    String? startTime,
    String? endTime,
    TaskType? type,
    TaskPriority? priority,
    String? description,
    String? sourceTemplateId,
    bool? completed,
  }) {
    return Task(
      id: id ?? this.id,
      title: title ?? this.title,
      startTime: startTime ?? this.startTime,
      endTime: endTime ?? this.endTime,
      type: type ?? this.type,
      priority: priority ?? this.priority,
      description: description ?? this.description,
      sourceTemplateId: sourceTemplateId ?? this.sourceTemplateId,
      completed: completed ?? this.completed,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'startTime': startTime,
        'endTime': endTime,
        'type': type.toString(),
        'priority': priority.toString(),
        'description': description,
        'sourceTemplateId': sourceTemplateId,
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
      priority: TaskPriority.values.firstWhere(
        (e) => e.toString() == json['priority'],
        orElse: () => TaskPriority.medium,
      ),
      description: json['description'] ?? '',
      sourceTemplateId: json['sourceTemplateId'] ?? '',
      completed: json['completed'] ?? false,
    );
  }
}
