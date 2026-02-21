import 'task_model.dart';

class PlanTemplate {
  final String id;
  final String name;
  final String description;
  final List<Task> tasks;
  final List<int> activeDays;

  bool get isRecurring => activeDays.isNotEmpty;

  PlanTemplate({
    required this.id,
    required this.name,
    required this.description,
    required this.tasks,
    this.activeDays = const [],
  });

  PlanTemplate copyWith({
    String? id,
    String? name,
    String? description,
    List<Task>? tasks,
    List<int>? activeDays,
  }) {
    return PlanTemplate(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      tasks: tasks ?? this.tasks,
      activeDays: activeDays ?? this.activeDays,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'description': description,
        'tasks': tasks.map((t) => t.toJson()).toList(),
        'activeDays': activeDays,
      };

  factory PlanTemplate.fromJson(Map<String, dynamic> json) {
    return PlanTemplate(
      id: json['id'],
      name: json['name'],
      description: json['description'],
      tasks: (json['tasks'] as List).map((t) => Task.fromJson(t)).toList(),
      activeDays: json['activeDays'] != null
          ? (json['activeDays'] as List).cast<int>()
          : const [],
    );
  }
}
