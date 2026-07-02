import 'dart:convert';
import 'package:chronosky/data/models/todo_item_model.dart';

/// Data Transfer Object for [TodoItem] persistence and serialization.
class TodoItemDto {
  final int schemaVersion;
  final String id;
  final String title;
  final String description;
  final bool completed;
  final String createdAt;
  final String updatedAt;
  final String itemType;
  final int durationMinutes;
  final String checklistJson;
  final String audioFilePath;

  const TodoItemDto({
    this.schemaVersion = 1,
    required this.id,
    required this.title,
    required this.description,
    required this.completed,
    required this.createdAt,
    String? updatedAt,
    required this.itemType,
    required this.durationMinutes,
    required this.checklistJson,
    required this.audioFilePath,
  }) : updatedAt = updatedAt ?? createdAt;

  Map<String, dynamic> toJson() => {
        'schemaVersion': schemaVersion,
        'id': id,
        'title': title,
        'description': description,
        'completed': completed,
        'createdAt': createdAt,
        'updatedAt': updatedAt,
        'itemType': itemType,
        'durationMinutes': durationMinutes,
        'checklistJson': checklistJson,
        'audioFilePath': audioFilePath,
      };

  factory TodoItemDto.fromJson(Map<String, dynamic> json) {
    return TodoItemDto(
      schemaVersion: json['schemaVersion'] as int? ?? 1,
      id: json['id'] as String,
      title: json['title'] as String,
      description: json['description'] as String,
      completed: json['completed'] as bool,
      createdAt: json['createdAt'] as String,
      updatedAt: json['updatedAt'] as String?,
      itemType: json['itemType'] as String,
      durationMinutes: json['durationMinutes'] as int,
      checklistJson: json['checklistJson'] as String,
      audioFilePath: json['audioFilePath'] as String,
    );
  }

  factory TodoItemDto.fromDomain(TodoItem domain) {
    return TodoItemDto(
      id: domain.id,
      title: domain.title,
      description: domain.description,
      completed: domain.completed,
      createdAt: domain.createdAt.toIso8601String(),
      updatedAt: domain.updatedAt.toIso8601String(),
      itemType: domain.itemType.name,
      durationMinutes: domain.durationMinutes,
      checklistJson:
          jsonEncode(domain.checklist.map((i) => i.toJson()).toList()),
      audioFilePath: domain.audioFilePath,
    );
  }

  TodoItem toDomain() {
    final List<dynamic> decodedChecklist = jsonDecode(checklistJson);
    return TodoItem(
      id: id,
      title: title,
      description: description,
      completed: completed,
      createdAt: DateTime.parse(createdAt),
      updatedAt: DateTime.parse(updatedAt),
      itemType: TodoItemType.values.firstWhere((e) => e.name == itemType,
          orElse: () => TodoItemType.note,),
      durationMinutes: durationMinutes,
      checklist: decodedChecklist
          .map((i) => ChecklistItem.fromJson(i as Map<String, dynamic>))
          .toList(),
      audioFilePath: audioFilePath,
    );
  }
}
