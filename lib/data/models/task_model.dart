import 'package:flutter/foundation.dart';

/// Categorization of tasks by life domain.
enum TaskType { work, personal, health, leisure }

/// Task importance level.
enum TaskPriority { low, medium, high }

/// Mental/physical energy required for the task.
enum TaskEnergyLevel { low, medium, high }

/// Core domain model representing a scheduled task.
@immutable
class Task {
  final String id;
  final String title;
  final String startTime;
  final String endTime;
  final TaskType type;
  final TaskPriority priority;
  final TaskEnergyLevel energyLevel;
  final double estimatedCost;
  final double actualCost;
  final String description;
  final String sourceTemplateId;
  final bool completed;

  Task({
    required this.id,
    required this.title,
    required this.startTime,
    required this.endTime,
    required this.type,
    this.priority = TaskPriority.medium,
    this.energyLevel = TaskEnergyLevel.medium,
    this.estimatedCost = 0.0,
    this.actualCost = 0.0,
    this.description = '',
    this.sourceTemplateId = '',
    this.completed = false,
  }) {
    assert(title.isNotEmpty && title.length <= 200,
        'Title must be 1-200 characters',);
    final timeRegex = RegExp(r'^([01]\d|2[0-3]):[0-5]\d$');
    assert(
        timeRegex.hasMatch(startTime), 'Invalid startTime format: $startTime',);
    assert(timeRegex.hasMatch(endTime), 'Invalid endTime format: $endTime');
    assert(estimatedCost >= 0.0 && estimatedCost.isFinite,
        'estimatedCost must be >= 0.0 and finite',);
    assert(actualCost >= 0.0 && actualCost.isFinite,
        'actualCost must be >= 0.0 and finite',);
  }

  Task copyWith({
    String? id,
    String? title,
    String? startTime,
    String? endTime,
    TaskType? type,
    TaskPriority? priority,
    TaskEnergyLevel? energyLevel,
    double? estimatedCost,
    double? actualCost,
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
      energyLevel: energyLevel ?? this.energyLevel,
      estimatedCost: estimatedCost ?? this.estimatedCost,
      actualCost: actualCost ?? this.actualCost,
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
        'type': type.name,
        'priority': priority.name,
        'energyLevel': energyLevel.name,
        'estimatedCost': estimatedCost,
        'actualCost': actualCost,
        'description': description,
        'sourceTemplateId': sourceTemplateId,
        'completed': completed,
      };

  factory Task.fromJson(Map<String, dynamic> json) {
    return Task(
      id: json['id'] as String,
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
      actualCost: ((json['actualCost'] as num?) ?? 0.0).toDouble(),
      description: (json['description'] ?? '') as String,
      sourceTemplateId: (json['sourceTemplateId'] ?? '') as String,
      completed: (json['completed'] ?? false) as bool,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Task &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          title == other.title &&
          startTime == other.startTime &&
          endTime == other.endTime &&
          type == other.type &&
          priority == other.priority &&
          energyLevel == other.energyLevel &&
          estimatedCost == other.estimatedCost &&
          actualCost == other.actualCost &&
          description == other.description &&
          sourceTemplateId == other.sourceTemplateId &&
          completed == other.completed;

  @override
  int get hashCode =>
      id.hashCode ^
      title.hashCode ^
      startTime.hashCode ^
      endTime.hashCode ^
      type.hashCode ^
      priority.hashCode ^
      energyLevel.hashCode ^
      estimatedCost.hashCode ^
      actualCost.hashCode ^
      description.hashCode ^
      sourceTemplateId.hashCode ^
      completed.hashCode;
}
