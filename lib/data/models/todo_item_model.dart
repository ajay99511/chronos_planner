import 'package:flutter/foundation.dart';

/// Type of todo item.
enum TodoItemType { note, timer, list }

/// Represents a single item in a checklist.
@immutable
class ChecklistItem {
  final String text;
  final bool done;

  const ChecklistItem({
    required this.text,
    this.done = false,
  });

  ChecklistItem copyWith({
    String? text,
    bool? done,
  }) {
    return ChecklistItem(
      text: text ?? this.text,
      done: done ?? this.done,
    );
  }

  Map<String, dynamic> toJson() => {
        'text': text,
        'done': done,
      };

  factory ChecklistItem.fromJson(Map<String, dynamic> json) {
    return ChecklistItem(
      text: json['text'] as String,
      done: json['done'] as bool,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ChecklistItem &&
          runtimeType == other.runtimeType &&
          text == other.text &&
          done == other.done;

  @override
  int get hashCode => text.hashCode ^ done.hashCode;
}

/// Core domain model representing a standalone todo item.
@immutable
class TodoItem {
  final String id;
  final String title;
  final String description;
  final bool completed;
  final DateTime createdAt;
  final TodoItemType itemType;
  final int durationMinutes;
  final List<ChecklistItem> checklist;
  final String audioFilePath;

  TodoItem({
    required this.id,
    required this.title,
    this.description = '',
    this.completed = false,
    required this.createdAt,
    this.itemType = TodoItemType.note,
    this.durationMinutes = 0,
    this.checklist = const [],
    this.audioFilePath = '',
  }) {
    assert(title.isNotEmpty && title.length <= 200, 'Title must be 1-200 characters');
  }

  TodoItem copyWith({
    String? id,
    String? title,
    String? description,
    bool? completed,
    DateTime? createdAt,
    TodoItemType? itemType,
    int? durationMinutes,
    List<ChecklistItem>? checklist,
    String? audioFilePath,
  }) {
    return TodoItem(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      completed: completed ?? this.completed,
      createdAt: createdAt ?? this.createdAt,
      itemType: itemType ?? this.itemType,
      durationMinutes: durationMinutes ?? this.durationMinutes,
      checklist: checklist ?? this.checklist,
      audioFilePath: audioFilePath ?? this.audioFilePath,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'description': description,
        'completed': completed,
        'createdAt': createdAt.toIso8601String(),
        'itemType': itemType.name,
        'durationMinutes': durationMinutes,
        'checklist': checklist.map((i) => i.toJson()).toList(),
        'audioFilePath': audioFilePath,
      };

  factory TodoItem.fromJson(Map<String, dynamic> json) {
    return TodoItem(
      id: json['id'] as String,
      title: json['title'] as String,
      description: (json['description'] ?? '') as String,
      completed: (json['completed'] ?? false) as bool,
      createdAt: json['createdAt'] != null ? DateTime.parse(json['createdAt'] as String) : DateTime.now(),
      itemType: TodoItemType.values.firstWhere(
        (e) => e.name == json['itemType'],
        orElse: () => TodoItemType.note,
      ),
      durationMinutes: (json['durationMinutes'] ?? 0) as int,
      checklist: List<ChecklistItem>.unmodifiable(
        (json['checklist'] as List?)?.map((i) => ChecklistItem.fromJson(i as Map<String, dynamic>)) ?? const [],
      ),
      audioFilePath: (json['audioFilePath'] ?? '') as String,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is TodoItem &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          title == other.title &&
          description == other.description &&
          completed == other.completed &&
          createdAt == other.createdAt &&
          itemType == other.itemType &&
          durationMinutes == other.durationMinutes &&
          listEquals(checklist, other.checklist) &&
          audioFilePath == other.audioFilePath;

  @override
  int get hashCode =>
      id.hashCode ^
      title.hashCode ^
      description.hashCode ^
      completed.hashCode ^
      createdAt.hashCode ^
      itemType.hashCode ^
      durationMinutes.hashCode ^
      checklist.hashCode ^
      audioFilePath.hashCode;
}
