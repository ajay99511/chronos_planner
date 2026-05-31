import 'package:flutter/foundation.dart';
import 'package:chronosky/data/models/task_model.dart';

/// Core domain model representing a task within a template.
@immutable
class TemplateTask {
  final String id;
  final String templateId;
  final String title;
  final String startTime;
  final String endTime;
  final TaskType type;
  final TaskPriority priority;
  final TaskEnergyLevel energyLevel;
  final double estimatedCost;
  final String description;

  TemplateTask({
    required this.id,
    required this.templateId,
    required this.title,
    required this.startTime,
    required this.endTime,
    required this.type,
    this.priority = TaskPriority.medium,
    this.energyLevel = TaskEnergyLevel.medium,
    this.estimatedCost = 0.0,
    this.description = '',
  }) {
    assert(title.isNotEmpty && title.length <= 200, 'Title must be 1-200 characters');
    final timeRegex = RegExp(r'^([01]\d|2[0-3]):[0-5]\d$');
    assert(timeRegex.hasMatch(startTime), 'Invalid startTime format: $startTime');
    assert(timeRegex.hasMatch(endTime), 'Invalid endTime format: $endTime');
    assert(estimatedCost >= 0.0 && estimatedCost.isFinite, 'estimatedCost must be >= 0.0 and finite');
  }

  TemplateTask copyWith({
    String? id,
    String? templateId,
    String? title,
    String? startTime,
    String? endTime,
    TaskType? type,
    TaskPriority? priority,
    TaskEnergyLevel? energyLevel,
    double? estimatedCost,
    String? description,
  }) {
    return TemplateTask(
      id: id ?? this.id,
      templateId: templateId ?? this.templateId,
      title: title ?? this.title,
      startTime: startTime ?? this.startTime,
      endTime: endTime ?? this.endTime,
      type: type ?? this.type,
      priority: priority ?? this.priority,
      energyLevel: energyLevel ?? this.energyLevel,
      estimatedCost: estimatedCost ?? this.estimatedCost,
      description: description ?? this.description,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'templateId': templateId,
        'title': title,
        'startTime': startTime,
        'endTime': endTime,
        'type': type.name,
        'priority': priority.name,
        'energyLevel': energyLevel.name,
        'estimatedCost': estimatedCost,
        'description': description,
      };

  factory TemplateTask.fromJson(Map<String, dynamic> json) {
    return TemplateTask(
      id: json['id'] as String,
      templateId: json['templateId'] as String,
      title: json['title'] as String,
      startTime: json['startTime'] as String,
      endTime: json['endTime'] as String,
      type: TaskType.values.firstWhere(
        (e) => e.name == json['type'],
        orElse: () => TaskType.work,
      ),
      priority: TaskPriority.values.firstWhere(
        (e) => e.name == json['priority'],
        orElse: () => TaskPriority.medium,
      ),
      energyLevel: TaskEnergyLevel.values.firstWhere(
        (e) => e.name == (json['energyLevel'] ?? 'medium'),
        orElse: () => TaskEnergyLevel.medium,
      ),
      estimatedCost: ((json['estimatedCost'] as num?) ?? 0.0).toDouble(),
      description: (json['description'] ?? '') as String,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is TemplateTask &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          templateId == other.templateId &&
          title == other.title &&
          startTime == other.startTime &&
          endTime == other.endTime &&
          type == other.type &&
          priority == other.priority &&
          energyLevel == other.energyLevel &&
          estimatedCost == other.estimatedCost &&
          description == other.description;

  @override
  int get hashCode =>
      id.hashCode ^
      templateId.hashCode ^
      title.hashCode ^
      startTime.hashCode ^
      endTime.hashCode ^
      type.hashCode ^
      priority.hashCode ^
      energyLevel.hashCode ^
      estimatedCost.hashCode ^
      description.hashCode;
}

/// Reusable template for creating recurring day plans.
@immutable
class PlanTemplate {
  final String id;
  final String name;
  final String description;
  final List<TemplateTask> tasks;
  final List<int> activeDays;

  bool get isRecurring => activeDays.isNotEmpty;

  const PlanTemplate({
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
    List<TemplateTask>? tasks,
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
      id: json['id'] as String,
      name: json['name'] as String,
      description: (json['description'] ?? '') as String,
      tasks: List<TemplateTask>.unmodifiable(
        (json['tasks'] as List).map((t) => TemplateTask.fromJson(t as Map<String, dynamic>)),
      ),
      activeDays: List<int>.unmodifiable(
        (json['activeDays'] as List<dynamic>?)?.map((e) => e as int) ?? const [],
      ),
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is PlanTemplate &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          name == other.name &&
          description == other.description &&
          listEquals(tasks, other.tasks) &&
          listEquals(activeDays, other.activeDays);

  @override
  int get hashCode =>
      id.hashCode ^
      name.hashCode ^
      description.hashCode ^
      tasks.hashCode ^
      activeDays.hashCode;
}
