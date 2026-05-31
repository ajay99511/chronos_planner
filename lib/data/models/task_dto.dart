import 'package:chronosky/data/models/task_model.dart';

/// Data Transfer Object for [Task] persistence and serialization.
class TaskDto {
  final int schemaVersion;
  final String id;
  final String title;
  final String startTime;
  final String endTime;
  final String type;
  final String priority;
  final String energyLevel;
  final double estimatedCost;
  final double actualCost;
  final String description;
  final String dayPlanId;
  final String sourceTemplateId;
  final bool completed;

  const TaskDto({
    this.schemaVersion = 1,
    required this.id,
    required this.title,
    required this.startTime,
    required this.endTime,
    required this.type,
    required this.priority,
    required this.energyLevel,
    required this.estimatedCost,
    required this.actualCost,
    required this.description,
    required this.dayPlanId,
    required this.sourceTemplateId,
    required this.completed,
  });

  Map<String, dynamic> toJson() => {
        'schemaVersion': schemaVersion,
        'id': id,
        'title': title,
        'startTime': startTime,
        'endTime': endTime,
        'type': type,
        'priority': priority,
        'energyLevel': energyLevel,
        'estimatedCost': estimatedCost,
        'actualCost': actualCost,
        'description': description,
        'dayPlanId': dayPlanId,
        'sourceTemplateId': sourceTemplateId,
        'completed': completed,
      };

  factory TaskDto.fromJson(Map<String, dynamic> json) {
    return TaskDto(
      schemaVersion: json['schemaVersion'] as int? ?? 1,
      id: json['id'] as String,
      title: json['title'] as String,
      startTime: json['startTime'] as String,
      endTime: json['endTime'] as String,
      type: json['type'] as String,
      priority: json['priority'] as String,
      energyLevel: json['energyLevel'] as String,
      estimatedCost: (json['estimatedCost'] as num).toDouble(),
      actualCost: (json['actualCost'] as num).toDouble(),
      description: json['description'] as String,
      dayPlanId: json['dayPlanId'] as String,
      sourceTemplateId: json['sourceTemplateId'] as String,
      completed: json['completed'] as bool,
    );
  }

  factory TaskDto.fromDomain(Task domain, String dayPlanId) {
    return TaskDto(
      id: domain.id,
      title: domain.title,
      startTime: domain.startTime,
      endTime: domain.endTime,
      type: domain.type.name,
      priority: domain.priority.name,
      energyLevel: domain.energyLevel.name,
      estimatedCost: domain.estimatedCost,
      actualCost: domain.actualCost,
      description: domain.description,
      dayPlanId: dayPlanId,
      sourceTemplateId: domain.sourceTemplateId,
      completed: domain.completed,
    );
  }

  Task toDomain() {
    return Task(
      id: id,
      title: title,
      startTime: startTime,
      endTime: endTime,
      type: TaskType.values.firstWhere((e) => e.name == type, orElse: () => TaskType.work),
      priority: TaskPriority.values.firstWhere((e) => e.name == priority, orElse: () => TaskPriority.medium),
      energyLevel: TaskEnergyLevel.values.firstWhere((e) => e.name == energyLevel, orElse: () => TaskEnergyLevel.medium),
      estimatedCost: estimatedCost,
      actualCost: actualCost,
      description: description,
      sourceTemplateId: sourceTemplateId,
      completed: completed,
    );
  }
}
