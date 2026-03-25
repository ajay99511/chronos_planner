import 'task_model.dart';

/// Reusable template for creating recurring day plans.
/// 
/// Templates capture "perfect day" patterns like:
/// - "Deep Work Friday" - focused coding schedule
/// - "Lazy Sunday" - recovery and leisure
/// 
/// ## Features:
/// - **Reusable**: Apply to any day manually
/// - **Recurring**: Auto-apply on specific weekdays (activeDays)
/// - **Source Tracking**: Applied tasks link back via `sourceTemplateId`
/// 
/// ## Lifecycle:
/// 1. Created via [WorkPlansView] or [ScheduleProvider.saveCurrentDayAsTemplate]
/// 2. Stored in [PlanTemplates] + [TemplateTasks] tables
/// 3. Applied via [ScheduleProvider.applyTemplate]
/// 4. Recurring auto-apply in [_applyRecurringTemplates]
/// 
/// ## Recurring Logic:
/// ```dart
/// // Apply every Monday, Wednesday, Friday
/// template.activeDays = [0, 2, 4]; // 0=Monday, 6=Sunday
/// 
/// // Auto-apply checks:
/// // 1. Day's weekday matches activeDays
/// // 2. Task with sourceTemplateId doesn't already exist
/// ```
/// 
/// ## Usage:
/// ```dart
/// final template = PlanTemplate(
///   id: uuid.v4(),
///   name: 'Deep Work Friday',
///   description: 'Focus heavy schedule',
///   tasks: [/* ... */],
///   activeDays: [4], // Fridays
/// );
/// 
/// if (template.isRecurring) {
///   // Auto-apply logic
/// }
/// ```
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
