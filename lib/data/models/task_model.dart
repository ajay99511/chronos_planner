import 'package:flutter/foundation.dart';

import 'package:chronosky/core/result.dart';
import 'package:chronosky/domain/clock_time.dart';
import 'package:chronosky/domain/reminder_lead.dart';

/// Validates the fields common to a task and a template task.
///
/// Returns the first [ValidationFailure] found, or null when everything is
/// legal. Kept as a shared function because the two models express the same
/// invariants and must not drift apart.
ValidationFailure? validateTaskFields({
  required String title,
  required String startTime,
  required String endTime,
  required double estimatedCost,
  double actualCost = 0,
  int reminderLeadMinutes = defaultReminderLeadMinutes,
}) {
  if (title.isEmpty || title.length > 200) {
    return const ValidationFailure('Title must be 1-200 characters.');
  }
  if (!ClockTime.isValid(startTime)) {
    return ValidationFailure('Invalid start time: "$startTime". Use HH:mm.');
  }
  if (!ClockTime.isValid(endTime)) {
    return ValidationFailure('Invalid end time: "$endTime". Use HH:mm.');
  }
  if (estimatedCost < 0 || !estimatedCost.isFinite) {
    return const ValidationFailure('Estimated cost must be zero or more.');
  }
  if (actualCost < 0 || !actualCost.isFinite) {
    return const ValidationFailure('Actual cost must be zero or more.');
  }
  if (!isValidReminderLead(reminderLeadMinutes)) {
    return ValidationFailure(
      'Reminder lead time must be between 0 and $maxReminderLeadMinutes '
      'minutes, not $reminderLeadMinutes.',
    );
  }
  return null;
}

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

  /// Whether to notify the user before this task starts.
  final bool reminderEnabled;

  /// Minutes before [startTime] to notify. 0 means "when it starts".
  ///
  /// Kept meaningful even while [reminderEnabled] is false, so toggling a
  /// reminder back on restores the lead time the user chose rather than
  /// resetting it.
  final int reminderLeadMinutes;

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
    this.reminderEnabled = false,
    this.reminderLeadMinutes = defaultReminderLeadMinutes,
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
    assert(isValidReminderLead(reminderLeadMinutes),
        'reminderLeadMinutes must be 0..$maxReminderLeadMinutes',);
  }

  /// Validates [title], the clock times and the costs, returning either the
  /// task or the reason it was rejected.
  ///
  /// Use this for anything originating outside the database — user input, an
  /// import, a template being materialised. The unnamed constructor asserts
  /// the same invariants, but asserts are compiled out of release builds, so
  /// they document intent rather than enforce it. This returns a [Result]
  /// instead of throwing because invalid input is an expected outcome that
  /// belongs in the contract, not an exceptional one.
  static Result<Task> create({
    required String id,
    required String title,
    required String startTime,
    required String endTime,
    required TaskType type,
    TaskPriority priority = TaskPriority.medium,
    TaskEnergyLevel energyLevel = TaskEnergyLevel.medium,
    double estimatedCost = 0.0,
    double actualCost = 0.0,
    String description = '',
    String sourceTemplateId = '',
    bool completed = false,
    bool reminderEnabled = false,
    int reminderLeadMinutes = defaultReminderLeadMinutes,
  }) {
    final failure = validateTaskFields(
      title: title,
      startTime: startTime,
      endTime: endTime,
      estimatedCost: estimatedCost,
      actualCost: actualCost,
      reminderLeadMinutes: reminderLeadMinutes,
    );
    if (failure != null) return Failure(failure);

    return Success(
      Task(
        id: id,
        title: title,
        startTime: startTime,
        endTime: endTime,
        type: type,
        priority: priority,
        energyLevel: energyLevel,
        estimatedCost: estimatedCost,
        actualCost: actualCost,
        description: description,
        sourceTemplateId: sourceTemplateId,
        completed: completed,
        reminderEnabled: reminderEnabled,
        reminderLeadMinutes: reminderLeadMinutes,
      ),
    );
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
    bool? reminderEnabled,
    int? reminderLeadMinutes,
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
      reminderEnabled: reminderEnabled ?? this.reminderEnabled,
      reminderLeadMinutes: reminderLeadMinutes ?? this.reminderLeadMinutes,
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
        'reminderEnabled': reminderEnabled,
        'reminderLeadMinutes': reminderLeadMinutes,
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
      reminderEnabled: (json['reminderEnabled'] ?? false) as bool,
      reminderLeadMinutes:
          (json['reminderLeadMinutes'] ?? defaultReminderLeadMinutes) as int,
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
          completed == other.completed &&
          reminderEnabled == other.reminderEnabled &&
          reminderLeadMinutes == other.reminderLeadMinutes;

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
      completed.hashCode ^
      reminderEnabled.hashCode ^
      reminderLeadMinutes.hashCode;
}
