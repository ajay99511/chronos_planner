import 'package:flutter/foundation.dart';
import 'package:intl/intl.dart';
import 'package:chronosky/data/models/task_model.dart';

/// Aggregates tasks for a specific date in the weekly schedule.
@immutable
class DayPlan {
  final String id;
  final DateTime date;
  final List<Task> tasks;

  /// Computed display string for the date (e.g., "Feb 10").
  String get dateStr => DateFormat.MMMd().format(date);

  /// Computed day of week (e.g., "Monday").
  String get dayOfWeek => DateFormat.EEEE().format(date);

  const DayPlan({
    required this.id,
    required this.date,
    required this.tasks,
  });

  DayPlan copyWith({
    String? id,
    DateTime? date,
    List<Task>? tasks,
  }) {
    return DayPlan(
      id: id ?? this.id,
      date: date ?? this.date,
      tasks: tasks ?? this.tasks,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'date': date.toIso8601String(),
        'tasks': tasks.map((t) => t.toJson()).toList(),
      };

  factory DayPlan.fromJson(Map<String, dynamic> json) {
    return DayPlan(
      id: json['id'] as String,
      date: json['date'] != null
          ? DateTime.parse(json['date'] as String)
          : DateTime.now(),
      tasks: List<Task>.unmodifiable(
        (json['tasks'] as List)
            .map((t) => Task.fromJson(t as Map<String, dynamic>)),
      ),
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is DayPlan &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          date == other.date &&
          listEquals(tasks, other.tasks);

  @override
  int get hashCode => id.hashCode ^ date.hashCode ^ tasks.hashCode;
}
