import 'task_model.dart';

class PlanTemplate {
  final String id;
  final String name;
  final String description;
  final List<Task> tasks;

  PlanTemplate({
    required this.id,
    required this.name,
    required this.description,
    required this.tasks,
  });
  
  Map<String, dynamic> toJson() => {
    'id': id, 
    'name': name, 
    'description': description, 
    'tasks': tasks.map((t) => t.toJson()).toList()
  };

   factory PlanTemplate.fromJson(Map<String, dynamic> json) {
    return PlanTemplate(
      id: json['id'],
      name: json['name'],
      description: json['description'],
      tasks: (json['tasks'] as List).map((t) => Task.fromJson(t)).toList(),
    );
  }
}
