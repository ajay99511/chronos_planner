/// Categorization of tasks by life domain.
/// 
/// Used for:
/// - Visual color coding in [TaskCard]
/// - Time distribution analytics in [AnalyticsView]
/// - Filtering and grouping (future feature)
enum TaskType { work, personal, health, leisure }

/// Task importance level.
/// 
/// Affects:
/// - Priority indicator icon in [TaskCard]
/// - ROI calculation in [IntelligenceService]
/// - Sort ordering (optional)
enum TaskPriority { low, medium, high }

/// Mental/physical energy required for the task.
/// 
/// Used for:
/// - Optimal time recommendations in [IntelligenceService.recommendTime]
/// - Energy peaks analysis in [AnalyticsView]
/// - Visual pill indicator in [TaskCard]
enum TaskEnergyLevel { low, medium, high }

/// Core domain model representing a scheduled task.
/// 
/// A task is a time-blocked activity with:
/// - Time range (start/end in "HH:mm" format)
/// - Category (type), importance (priority), energy required
/// - Optional cost tracking (estimated/actual)
/// - Completion status
/// - Source template tracking (for recurring templates)
/// 
/// ## Lifecycle:
/// 1. Created via [AddTaskSheet] or from template
/// 2. Stored in [Tasks] table via [TaskDao]
/// 3. Displayed in [TaskCard]
/// 4. Toggled/deleted via [ScheduleProvider]
/// 
/// ## Relationships:
/// - Belongs to a [DayPlan] via `dayPlanId`
/// - Optionally linked to [PlanTemplate] via `sourceTemplateId`
/// 
/// ## Serialization:
/// - JSON via [toJson]/[fromJson] for SharedPreferences migration
/// - Drift via [TasksCompanion] for database operations
/// 
/// Usage:
/// ```dart
/// final task = Task(
///   id: uuid.v4(),
///   title: 'Deep Work',
///   startTime: '09:00',
///   endTime: '12:00',
///   type: TaskType.work,
///   priority: TaskPriority.high,
/// );
/// 
/// // Immutable update
/// final updated = task.copyWith(completed: true);
/// ```
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
  bool completed;

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
  });

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
        'type': type.toString(),
        'priority': priority.toString(),
        'energyLevel': energyLevel.toString(),
        'estimatedCost': estimatedCost,
        'actualCost': actualCost,
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
      energyLevel: TaskEnergyLevel.values.firstWhere(
        (e) => e.toString() == (json['energyLevel'] ?? 'TaskEnergyLevel.medium'),
        orElse: () => TaskEnergyLevel.medium,
      ),
      estimatedCost: (json['estimatedCost'] ?? 0.0).toDouble(),
      actualCost: (json['actualCost'] ?? 0.0).toDouble(),
      description: json['description'] ?? '',
      sourceTemplateId: json['sourceTemplateId'] ?? '',
      completed: json['completed'] ?? false,
    );
  }
}
